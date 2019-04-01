require 'action_controller'
require 'kaminari'
require 'grape-kaminari'
require 'introspective_grape/validators'

class IntrospectiveGrapeError < StandardError
end

module IntrospectiveGrape
  class API < Grape::API::Instance
    extend IntrospectiveGrape::Helpers
    extend IntrospectiveGrape::CreateHelpers
    extend IntrospectiveGrape::Filters
    extend IntrospectiveGrape::Traversal
    extend IntrospectiveGrape::Doc
    extend IntrospectiveGrape::SnakeParams

    # Allow files to be uploaded through ActionController:
    ActionController::Parameters::PERMITTED_SCALAR_TYPES.push Rack::Multipart::UploadedFile, ActionController::Parameters

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
    #  def self.grape_param_types
    #   { "<attribute name>" => Virtus::Attribute::Boolean,
    #     "<attribute name>" => Integer,
    #     "<attribute name>" => String }
    #  end
    #
    # For nested models declared in Rails' strong params both the Grape params for the
    # nested params as well as nested routes will be declared, allowing for
    # a good deal of flexibility for API consumers out of the box, nested params for
    # bulk updates and nested routes for interacting with single records.
    #

    class << self
      PLURAL_REFLECTIONS = [ ActiveRecord::Reflection::HasManyReflection, ActiveRecord::Reflection::HasManyReflection].freeze
      # mapping of activerecord/postgres 'type's to ruby data classes, where they differ
      Pg2Ruby = { datetime: DateTime }.freeze

      def inherited(child)
        super(child)
        child.before do
          # Ensure that a user is logged in.
          self.send(IntrospectiveGrape::API.authentication_method(self))
        end

        child.snake_params_before_validation if IntrospectiveGrape.config.camelize_parameters
      end

      # We will probably need before and after hooks eventually, but haven't yet...
      #api_actions.each do |a|
      #  define_method "before_#{a}_hook" do |model,params| ; end
      #  define_method "after_#{a}_hook" do |model,params| ; end
      #end

      def restful(model, strong_params=[], routes=[])
        if model.respond_to?(:attribute_param_types)
          raise IntrospectiveGrapeError.new("#{model.name}'s attribute_param_types class method needs to be changed to grape_param_types")
        end
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
        define_routes(routes, whitelist)

        # Top level declaration of the Grape::API namespace for the resource:
        resource routes.first.name.pluralize do
          # yield to append additional routes under the root namespace
          yield if block_given?
        end
      end

      def define_routes(routes, api_params)
        define_endpoints(routes, api_params)
        # recursively define endpoints
        model = routes.last.model || return

        api_params.select{|a| a.kind_of?(Hash) }.each do |nested|
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

      def convert_nested_params_hash(dsl, routes)
        root  = routes.first
        klass = root.klass
        dsl.after_validation do
          # After Grape validates its parameters:
          # 1) Find the root model instance for the API if its passed (implicitly either
          #    an update/destroy on the root node or it's a nested route
          # 2) For nested endpoints convert the params hash into Rails-compliant nested
          #    attributes, to be passed to the root instance for update. This keeps
          #    behavior consistent between bulk and single record updates.

          if params[root.key]
            @model = root.model.includes( klass.default_includes(root.model) ).find(params[root.key])
          end

          if routes.size > 1
            nested_attributes = klass.build_nested_attributes(routes[1..-1], params.except(root.key,:api_key) )
            @params.merge!( nested_attributes ) if nested_attributes.kind_of?(Hash)
          end
        end
      end

      def define_restful_api(dsl, routes, model, api_params)
        # declare index, show, update, create, and destroy methods:
        API_ACTIONS.each do |action|
          send("define_#{action}", dsl, routes, model, api_params) unless exclude_actions(model).include?(action)
        end
      end

      def define_endpoints(routes,api_params)
        # De-reference these as local variables from their class scope, or when we make
        # calls to the API they will be whatever they were last set to by the recursive
        # calls to "nest_routes".
        routes     = routes.clone
        api_params = api_params.clone

        model     = routes.last.model || return

        # We define the param keys for ID fields in camelcase for swagger's URL substitution,
        # they'll come back in snake case in the params hash, the API as a whole is agnostic:
        namespace = routes[0..-2].map{|p| "#{p.name.pluralize}/:#{p.swaggerKey}/" }.join + routes.last.name.pluralize

        resource namespace do
          convert_nested_params_hash(self, routes)
          define_restful_api(self, routes, model, api_params)
        end
      end

      def define_index(dsl, routes, model, api_params)
        include Grape::Kaminari
        root  = routes.first
        klass = routes.first.klass
        name  = routes.last.name.pluralize
        simple_filters(klass, model, api_params)

        dsl.desc "list #{name}" do
          detail klass.index_documentation || "returns list of all #{name}"
        end
        dsl.params do
          klass.declare_filter_params(self, klass, model, api_params)
        end
        if klass.pagination
          paginate per_page: klass.pagination[:per_page]||25, max_per_page: klass.pagination[:max_per_page], offset: klass.pagination[:offset]||0
        end
        dsl.get '/' do
          # Invoke the policy for the action, defined in the policy classes for the model:
          authorize root.model.new, :index?

          # Nested route indexes need to be scoped by the API's top level policy class:
          records = policy_scope( root.model.includes(klass.default_includes(root.model)) )

          records = klass.apply_filter_params(klass, model, api_params, params, records)

          records = records.map{|r| klass.find_leaves( routes, r, params ) }.flatten.compact.uniq

          # paginate the records using Kaminari
          records = paginate(Kaminari.paginate_array(records)) if klass.pagination
          present records, with: "#{klass}::#{model}Entity".constantize
        end
      end

      def define_show(dsl, routes, model, _api_params)
        name = routes.last.name.singularize
        klass = routes.first.klass
        dsl.desc "retrieve a #{name}" do
          detail klass.show_documentation || "returns details on a #{name}"
        end
        dsl.get ":#{routes.last.swaggerKey}" do
          authorize @model, :show?
          present klass.find_leaf(routes, @model, params), with: "#{klass}::#{model}Entity".constantize
        end
      end

      def define_create(dsl, routes, model, api_params)
        name  = routes.last.name.singularize
        klass = routes.first.klass
        dsl.desc "create a #{name}" do
          detail klass.create_documentation || "creates a new #{name} record"
        end
        dsl.params do
          klass.generate_params(self, :create, model, api_params, true)
        end
        dsl.post do
          representation = @model ? klass.add_new_records_to_root_record(self, routes, params, @model) : klass.create_new_record(self, routes, params)
          present representation, with: "#{klass}::#{model}Entity".constantize
        end
      end

      def define_update(dsl, routes, model, api_params)
        klass = routes.first.klass
        name = routes.last.name.singularize
        dsl.desc "update a #{name}" do
          detail klass.update_documentation || "updates the details of a #{name}"
        end
        dsl.params do
          klass.generate_params(self, :update, model, api_params, true)
        end
        dsl.put ":#{routes.last.swaggerKey}" do
          authorize @model, :update?

          @model.update_attributes!( safe_params(params).permit(klass.whitelist) )
         
          default_includes = routes.first.klass.default_includes(routes.first.model)

          present klass.find_leaf(routes, @model.class.includes(default_includes).find(@model.id), params), with: "#{klass}::#{model}Entity".constantize
        end
      end

      def define_destroy(dsl, routes, _model, _api_params)
        klass = routes.first.klass
        name = routes.last.name.singularize
        dsl.desc "destroy a #{name}" do
          detail klass.destroy_documentation || "destroys the details of a #{name}"
        end
        dsl.delete ":#{routes.last.swaggerKey}" do
          authorize @model, :destroy?
          present status: (klass.find_leaf(routes, @model, params).destroy ? true : false)
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
        reflection = parent_model.try(:reflections).try(:fetch,reflection_name)
        many       = parent_model && PLURAL_REFLECTIONS.include?( reflection.class ) ? true : false
        swaggerKey = IntrospectiveGrape.config.camelize_parameters ? "#{name.singularize.camelize(:lower)}Id" : "#{name.singularize}_id"

        routes.push OpenStruct.new(klass: self, name: name, param: "#{name}_attributes", model: model, many?: many, key: "#{name.singularize}_id".to_sym, swaggerKey: swaggerKey, reflection: reflection)
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



      def generate_params(dsl, action, model, fields, is_root_endpoint=false)
        # We'll be doing a recursive walk (to handle nested attributes) down the
        # whitelisted params, generating the Grape param definitions by introspecting
        # on the model and its associations.
        raise "Invalid action: #{action}" unless [:update, :create].include?(action)
        # dsl   : The Grape::Validations::ParamsScope object
        # action: create or update
        # model : The ActiveRecord model class
        # fields: The whitelisted data structure for Rails' strong params, from which we
        #         infer Grape's parameters

        # skip the ID param at the root level endpoint, so we don't duplicate the URL parameter (api/v#/model/modelId)
        fields -= [:id] if is_root_endpoint

        fields.each do |field|
          if field.kind_of?(Hash)
            generate_nested_params(dsl,action,model,field)
          elsif (action==:create && param_required?(model,field) )
            # All params are optional on an update, only require them during creation.
            # Updating a record with new child models will have to rely on ActiveRecord
            # validations:
            dsl.requires field, { type: param_type(model,field) }.merge( validations(model, field) )
          else
            #dsl.optional field, *options
            dsl.optional field, { type: param_type(model,field) }.merge( validations(model, field) )
          end
        end
      end

      def validations(model, field)
        (model.try(:grape_validations) || {}).with_indifferent_access[field] || {}
      end

      def generate_nested_params(dsl,action,model,fields)
        klass = self
        fields.each do |r,v|
          # Look at model.reflections to find the association's class name:
          reflection = r.to_s.sub(/_attributes$/,'') # the reflection name
          relation = begin model.reflections[reflection].class_name.constantize rescue model end

          if is_file_attachment?(model,r)
            # Handle Carrierwave file upload fields
            s = [:filename, :type, :name, :tempfile, :head]-v
            if s.present?
              Rails.logger.warn "Missing required file upload parameters #{s} for uploader field #{r}"
            end
          elsif PLURAL_REFLECTIONS.include?( model.reflections[reflection].class )
            # In case you need a refresher on how these work:
            # http://api.rubyonrails.org/classes/ActiveRecord/NestedAttributes/ClassMethods.html
            dsl.optional r, type: Array do |dl|
              klass.generate_params(dl,action,relation,v)
              klass.add_destroy_param(dl,model,reflection) unless action==:create
            end
          else
            # TODO: handle any remaining correctly. Presently defaults to a Hash
            # http://www.rubydoc.info/github/rails/rails/ActiveRecord/Reflection
            # ThroughReflection, HasOneReflection,
            # HasAndBelongsToManyReflection, BelongsToReflection
            dsl.optional r, type: Hash do |dl|
              klass.generate_params(dl,action,relation,v)
              klass.add_destroy_param(dl,model,reflection) unless action==:create
            end
          end
        end
      end

      def is_file_attachment?(model,field)
        model.respond_to?(:uploaders) && model.uploaders[field.to_sym] || # carrierwave
          (model.respond_to?(:attachment_definitions) && model.attachment_definitions[field.to_sym]) ||
          defined?(Paperclip::Attachment) && model.send(:new).try(field).kind_of?(Paperclip::Attachment)
      end

      def param_type(model,f)
        # Translate from the AR type to the GrapeParam types
        f       = f.to_s
        db_type = (model.try(:columns_hash)||{})[f].try(:type)

        # Check if it's a file attachment, look for an override class from the model,
        # check Pg2Ruby, use the database type, or fail over to a String:
        ( is_file_attachment?(model,f) && Rack::Multipart::UploadedFile ) ||
          (model.try(:grape_param_types)||{}).with_indifferent_access[f]  ||
          Pg2Ruby[db_type]                                                ||
          begin db_type.to_s.camelize.constantize rescue nil end          ||
          String
      end

      def param_required?(model,f)
        # Detect if the field is a required field for the create action
        return false if skip_presence_validations.include?(f)

        validated_field = f =~ /_id/ ? f.to_s.sub(/_id\z/,'').to_sym : f.to_sym

        model.validators_on(validated_field).any? {|v| v.kind_of? ActiveRecord::Validations::PresenceValidator }
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
