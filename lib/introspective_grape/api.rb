require 'action_controller'

module IntrospectiveGrape
  # Allow files to be uploaded through ActionController:
  ActionController::Parameters::PERMITTED_SCALAR_TYPES.push Rack::Multipart::UploadedFile, ActionController::Parameters

  class API < Grape::API
    # Generate uniform RESTful APIs for an ActiveRecord Model:
    #
    # class <Some API Controller> < IntrospectiveGrape::API
    #   exclude_actions Model, :index,:show,:create,:update,:destroy
    #   default_includes Model, <associations for eager loading>
    #   restful <Model Class>, [<strong, param, fields>]
    #
    #   class <Model>Entity < Grape::Entity
    #     expose :id, :attribute
    #     expose :association, using: <Association>Entity>
    #   end
    # end
    #
    # To define a Grape param type for a virtual attribute or override the defaut param
    # type from model introspection, define a class method in the model with the param
    # types for the attributes specified in a hash:
    #
    #  def self.attribute_param_types
    #   { "<attribute name>" => Virtus::Attribute::Boolean }
    #  end
    #
    # For nested models declared in Rails' strong params both the Grape params for the
    # nested params as well as nested routes will be declared, allowing for
    # a good deal of flexibility for API consumers out of the box, nested params for
    # bulk updates and nested routes for interacting with single records.
    #

    class << self
      PLURAL_REFLECTIONS = [ ActiveRecord::Reflection::HasManyReflection, ActiveRecord::Reflection::HasManyReflection]

      Pg2Ruby = {
        # mapping of activerecord/postgres 'type's to ruby data classes, where they differ
        datetime: DateTime
      }

      def authentication_method=(method)
        # IntrospectiveGrape::API.authentication_method=
        @authentication_method = method
      end

      def authentication_method(context)
        # Default to "authenticate!" or as grape docs once suggested, "authorize!"
        if @authentication_method 
          @authentication_method
        elsif context.respond_to?('authenticate!')
          'authenticate!'
        elsif context.respond_to?('authorize!')
          'authorize!'
        end
      end

      def exclude_actions(model, *args)
        @exclude_actions ||= {}
        @@api_actions ||= [:index,:show,:create,:update,:destroy,nil]
        raise "#{model.name} defines invalid exclude_actions: #{args-@@api_actions}" if (args.flatten-@@api_actions).present?
        @exclude_actions[model.name] = args.present? ? args.flatten : @exclude_actions[model.name] || []
      end

      def default_includes(model, *args)
        @default_includes ||= {}
        @default_includes[model.name] = args.present? ? args.flatten : @default_includes[model.name] || []
      end

      def inherited(child)
        super(child)
        child.before do
          # Convert incoming camel case params to snake case: grape will totally blow this
          # if the params hash is not a Hashie::Mash, so make it one of those:
          @params = Hashie::Mash.new(params.with_snake_keys)
          # Ensure that a user is logged in.
          self.send(IntrospectiveGrape::API.authentication_method(self))
        end
      end

      # We will probably need before and after hooks eventually, but haven't yet...
      #api_actions.each do |a|
      #  define_method "before_#{a}_hook" do |model,params| ; end
      #  define_method "after_#{a}_hook" do |model,params| ; end
      #end

      def restful(model, strong_params=[], routes=[])
        # Recursively define endpoints for the model and any nested models.
        #
        # model: the model class for the API
        # whitelist: a list of fields in Rail's strong params structure, also used to
        #            generate grape's permitted params.
        # routes: An array of OpenStruct representations of a nested route's ancestors 
        #

        # Defining the api will break pending migrations during db:migrate, so bail:
        begin ActiveRecord::Migration.check_pending! rescue return end

        # normalize the whitelist to symbols
        strong_params.map!{|f| f.kind_of?(String) ? f.to_sym : f }
        # default to a flat representation of the model's attributes if left unspecified
        strong_params = strong_params.blank? ? model.attribute_names.map(&:to_sym)-[:id, :updated_at, :created_at] : strong_params

        # The strong params will be the same for all routes, differing from the Grape params
        # when routes are nested
        whitelist = whitelist( strong_params )

        # As routes are nested keep track of the routes, we are preventing siblings from 
        # appending to the routes array here:
        routes = build_routes(routes, model)

        define_routes(routes,whitelist)

        resource routes.first.name.pluralize do
          # yield to append additional routes under the root namespace
          yield if block_given? 
        end
      end

      def define_routes(routes, whitelist)
        define_endpoint(routes, whitelist)

        # recursively define endpoints
        model = routes.last.model || return

        whitelist.select{|a| a.kind_of?(Hash) }.each do |nested|
          # Recursively add RESTful nested routes for every nested model:
          nested.each do |r,fields|
            # Look at model.reflections to find the association's class name:
            reflection_name = r.to_s.sub(/_attributes$/,'')
            begin
              relation = model.reflections[reflection_name].class_name.constantize 
            rescue
              Rails.logger.fatal "Can't find associated model for #{r} on #{model}"
            end

            next_routes = build_routes(routes, relation, reflection_name)

            define_routes(next_routes, fields)
          end
        end
      end

      def build_routes(routes, model, reflection_name=nil)
        routes = routes.clone
        # routes: the existing routes array passed from the parent
        # model:  the model being manipulated in this leaf
        # reflection_name: the association name from the original strong_params declaration
        # 
        # Constructs an array representation of the route's models and their associations,
        # a /root/:rootId/branch/:branchId/leaf/:leafId path would have flat array like
        # [root,branch,leaf] representing the path structure and its models, used to
        # manipulate ActiveRecord relationships and params hashes and so on.
        parent_model = routes.last.try(:model)
        return routes if model == parent_model

        name       = reflection_name || model.name.underscore
        reflection = parent_model && parent_model.reflections[reflection_name]
        many       = parent_model && PLURAL_REFLECTIONS.include?( reflection.class ) ? true : false
        routes.push OpenStruct.new(name: name, param: "#{name}_attributes", model: model, many?: many, key: "#{name.singularize}_id".to_sym, swaggerKey: "#{name.singularize.camelize(:lower)}Id", reflection: reflection)
      end

      def define_endpoint(routes,api_params)
        # Inside the Grape DSL "self" will derefernece to its Endpoint classes,
        # so save a reference to our API class:
        klass     = self
        # De-reference these as local variables from their class scope, or when we make
        # calls to the API they will be whatever they were last set to by the recursive
        # calls to "nest_routes".
        routes     = routes.clone
        api_params = api_params.clone

        root      = routes.first
        model     = routes.last.model || return
        name      = routes.last.name.singularize
        # We define the param keys for ID fields in camelcase for swagger's URL substitution,
        # they'll come back in snake case in the params hash, the API as a whole is agnostic:
        swaggerKey = routes.last.swaggerKey

        namespace = routes[0..-2].map{|p| "#{p.name.pluralize}/:#{p.swaggerKey}/" }.join + name.pluralize

        resource namespace do

          after_validation do
            # After Grape validates its parameters:
            # 1) Find the root model instance for the API if its passed (implicitly either
            #    an update/destroy on the root node or it's a nested route
            # 2) For nested endpoints convert the params hash into Rails-compliant nested
            #    attributes, to be passed to the root instance for update. This keeps
            #    behavior consistent between bulk and single record updates.
            if params[root.key]
              default_includes = routes.size > 1 ? [] : klass.default_includes(root.model)
              @model = root.model.includes( default_includes ).find(params[root.key])
            end

            if routes.size > 1
              nested_attributes = klass.build_nested_attributes(routes[1..-1], params.except(root.key,:api_key) )

              @params.merge!( nested_attributes ) if nested_attributes.kind_of?(Hash)
            end

          end

          unless exclude_actions(model).include?(:index)
            desc "list #{name.pluralize}" do
              detail "returns list of all #{name.pluralize}"
            end
            get '/' do
              # Invoke the policy for the action, defined in the policy classes for the model:
              authorize root.model.new, :index?

              # Nested route indexes need to be scoped by the API's top level policy class:
              records = policy_scope( root.model.includes(klass.default_includes(root.model)) )

              records = records.map{|r| klass.find_leaves( routes, r, params ) }.flatten.compact.uniq

              present records, with: "#{klass}::#{model}Entity".constantize
            end
          end


          unless exclude_actions(model).include?(:show)
            desc "retrieve a #{name}" do
              detail "returns details on a #{name}"
            end
            get ":#{swaggerKey}" do
              authorize @model, :show?
              present klass.find_leaf(routes, @model, params), with: "#{klass}::#{model}Entity".constantize
            end
          end


          unless exclude_actions(model).include?(:create)
            desc "create a #{name}" do
              detail "creates a new #{name} record"
            end
            params do
              klass.generate_params(self, klass, :create, model, api_params)
            end
            post do
              if (@model) 
                @model.update_attributes( safe_params(params).permit(klass.whitelist) )
              else 
                @model = root.model.new( safe_params(params).permit(klass.whitelist) ) 
              end
              authorize @model, :create?
              @model.save!
              present klass.find_leaves(routes, @model, params), with: "#{klass}::#{model}Entity".constantize
            end
          end


          unless exclude_actions(model).include?(:update)
            desc "update a #{name}" do
              detail "updates the details of a #{name}"
            end
            params do
              klass.generate_params(self, klass, :update, model, api_params)
            end
            put ":#{swaggerKey}" do
              authorize @model, :update?

              @model.update_attributes!( safe_params(params).permit(klass.whitelist) )

              present klass.find_leaf(routes, @model, params), with: "#{klass}::#{model}Entity".constantize
            end
          end


          unless exclude_actions(model).include?(:destroy)
            desc "destroy a #{name}" do
              detail "destroys the details of a #{name}"
            end
            delete ":#{swaggerKey}" do
              authorize @model, :destroy?
              present status: (klass.find_leaf(routes, @model, params).destroy ? true : false)
            end
          end

        end
      end


      def whitelist(whitelist=nil)
        return @whitelist if !whitelist
        @whitelist = whitelist
      end

      def skip_presence_validations(fields=nil)
        return @skip_presence_fields||[] if !fields
        @skip_presence_fields = [fields].flatten
      end

      def build_nested_attributes(routes,hash) 
        # Recursively re-express the flat attributes hash from nested routes as nested
        # attributes that can be used to perform an update on the root model.

        # do nothing if the params are already nested.
        return {} if routes.blank? || hash[routes.first.param]

        route  = routes.shift
        # change 'x_id' to 'x_attributes': { id: id, y_attributes: {} }
        id      = hash.delete route.key
        attributes = id ? { id: id } : {}

        attributes.merge!( hash ) if routes.blank? # assign param values to the last reference 

        if route.many? # nest it in an array if it is a has_many association
          { route.param => [attributes.merge( build_nested_attributes(routes, hash) )] } 
        else 
          { route.param => attributes.merge( build_nested_attributes(routes, hash) ) } 
        end
      end


      def find_leaves(routes, record, params)
        # Traverse down our route and find the leaf's siblings from its parent, e.g.
        # project/#/teams/#/team_users ~> project.find.teams.find.team_users.
        # (the traversal of the intermediate nodes occurs in find_leaf())
        return record if routes.size < 2 # the leaf is the root
        if record = find_leaf(routes, record, params)
          assoc = routes.last
          if assoc.many? && leaves = record.send( assoc.reflection.name ).includes( default_includes(assoc.model) )
            if (leaves.map(&:class) - [routes.last.model]).size > 0 
              raise ActiveRecord::RecordNotFound.new("Records contain the wrong models, they should all be #{routes.last.model.name}, found #{records.map(&:class).map(&:name).join(',')}")
            end

            leaves
          else 
            # has_one associations don't return a CollectionProxy and so don't support 
            # eager loading.
            record.send( assoc.reflection.name )
          end
        end
      end

      def find_leaf(routes, record, params)
        return record unless routes.size > 1
        # For deeply nested routes we need to search from the root of the API to the leaf
        # of its nested associations in order to guarantee the validity of the relationship,
        # the authorization on the parent model, and the sanity of passed parameters. 
        routes[1..-1].each_with_index do |r|
          if record && params[r.key]
            if ref = r.reflection 
              record = record.send(ref.name).where( id: params[r.key] ).first
            end
          end
        end

        if params[routes.last.key] && record.class != routes.last.model
          raise ActiveRecord::RecordNotFound.new("No #{routes.last.model.name} with ID '#{params[routes.last.key]}'")
        end

        record
      end


      def generate_params(dsl, klass, action, model, fields)
        # We'll be doing a recursive walk (to handle nested attributes) down the
        # whitelisted params, generating the Grape param definitions by introspecting
        # on the model and its associations.
        raise "Invalid action: #{action}" unless [:update, :create].include?(action)
        # dsl   : The Grape::Validations::ParamsScope object
        # klass : A reference back to the original descendant of IntrospectiveGrape::API.
        #         You have to pass this around to remember who you were before the DSL
        #         scope hijacked your identity.
        # action: create or update
        # model : The ActiveRecord model class
        # fields: The whitelisted data structure for Rails' strong params, from which we
        #         infer Grape's parameters

        (fields-[:id]).each do |field|
          if ( field.kind_of?(Hash) )
            generate_nested_params(dsl,klass,action,model,field)
          else
            if (action==:create && klass.param_required?(model,field) )
              # All params are optional on an update, only require them during creation.
              # Updating a record with new child models will have to rely on ActiveRecord
              # validations:
              dsl.requires field, type: klass.param_type(model,field)
            else
              dsl.optional field, type: klass.param_type(model,field)
            end
          end
        end
      end

      def generate_nested_params(dsl,klass,action,model,fields)
        fields.each do |r,v|
          # Look at model.reflections to find the association's class name:
          reflection = r.to_s.sub(/_attributes$/,'') # the reflection name
          relation = begin
                       model.reflections[reflection].class_name.constantize # its class
                     rescue
                       model
                     end

          if is_file_attachment?(model,r)
            # Handle Carrierwave file upload fields
            if s = [:filename, :type, :name, :tempfile, :head]-v && s.present?
              Rails.logger.warn "Missing required file upload parameters #{s} for uploader field #{r}" 
            end
          elsif PLURAL_REFLECTIONS.include?( model.reflections[reflection].class )
            # In case you need a refresher on how these work:
            # http://api.rubyonrails.org/classes/ActiveRecord/NestedAttributes/ClassMethods.html
            dsl.optional r, type: Array do |dsl|
              klass.generate_params(dsl,klass,action,relation,v)
              klass.add_destroy_param(dsl,model,reflection) unless action==:create
            end
          else
            # TODO: handle any remaining correctly. Presently defaults to a Hash
            # http://www.rubydoc.info/github/rails/rails/ActiveRecord/Reflection
            # ThroughReflection, HasOneReflection,
            # HasAndBelongsToManyReflection, BelongsToReflection
            dsl.optional r, type: Hash do |dsl|
              klass.generate_params(dsl,klass,action,relation,v)
              klass.add_destroy_param(dsl,model,reflection) unless action==:create
            end
          end
        end
      end

      def is_file_attachment?(model,field)
        model.try(:uploaders) && model.uploaders[field.to_sym] || # carrierwave
          (model.try(:attachment_definitions) && model.attachment_definitions[field.to_sym]) ||
          model.send(:new).try(field).kind_of?(Paperclip::Attachment)
      end

      def param_type(model,f)
        # Translate from the AR type to the GrapeParam types
        f       = f.to_s
        db_type = (model.try(:columns_hash)||{})[f].try(:type)

        # Look for an override class from the model, check Pg2Ruby, use the database type,
        # or fail over to a String:
        ( is_file_attachment?(model,f) && Rack::Multipart::UploadedFile ) || 
          (model.try(:attribute_param_types)||{})[f]                      || 
          Pg2Ruby[db_type]                                                ||
          begin db_type.to_s.camelize.constantize rescue nil end          ||
          String
      end

      def param_required?(model,f)
        return false if skip_presence_validations.include? f
        # Detect if the field is a required field for the create action
        model.validators_on(f.to_sym).any?{|v| v.kind_of? ActiveRecord::Validations::PresenceValidator }
      end

      def add_destroy_param(dsl,model,reflection)
        raise "#{model} does not accept nested attributes for #{reflection}" if !model.nested_attributes_options[reflection.to_sym]
        # If destruction is allowed append the _destroy field
        if model.nested_attributes_options[reflection.to_sym][:allow_destroy]
          dsl.optional '_destroy', type: Integer
        end
      end

      end
    end

  end
