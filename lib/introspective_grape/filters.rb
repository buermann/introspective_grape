module IntrospectiveGrape
  module Filters
    # Allow filters on all whitelisted model attributes (from api_params) and declare
    # customer filters for the index in a method.

    def default_sort(*args)
      @default_sort ||= args
    end

    def custom_filter(*args)
      custom_filters( *args )
    end

    def custom_filters(*args)
      @custom_filters ||= {}
      @custom_filters   = Hash[*args].merge(@custom_filters) if args.present?
      @custom_filters
    end

    def filter_on(*args)
      filters( *args )
    end

    def filters(*args)
      @filters ||= []
      @filters  += args if args.present?
      @filters
    end

    def simple_filters(klass, model, api_params)
      @simple_filters ||= api_params.select {|p| p.is_a? Symbol }.select {|field|
        filters.include?(:all) || filters.include?(field)
      }.map {|field|
        (klass.param_type(model, field) == DateTime ? ["#{field}_start", "#{field}_end"] : field.to_s)
      }.flatten
    end

    def timestamp_filter(klass, model, field)
      filter = field.sub(/_(end|start)\z/, '')
      if field =~ /_(end|start)\z/ && klass.param_type(model, filter) == DateTime
        filter
      else
        false
      end
    end

    def declare_filter_params(dsl, klass, model, api_params)
      # Declare optional parameters for filtering parameters, create two parameters per
      # timestamp, a Start and an End, to apply a date range.
      simple_filters(klass, model, api_params).each do |field|
        declare_simple_filter(dsl, klass, model, field)
      end

      custom_filters.each do |filter, details|
        dsl.optional filter, details
      end

      dsl.optional :filter, type: String, description: filter_doc if special_filter_enabled?(filters)
    end

    def declare_simple_filter(dsl, klass, model, field)
      if timestamp_filter(klass, model, field)
        dsl.optional field, type: klass.param_type(model, field), description: "Constrain #{field} by #{humanize_date_range(field)} date."
      elsif identifier_filter?(model, field)
        dsl.optional field, type: Array[String], coerce_with: ->(val) { val.split(',') }, description: 'Filter by a comma separated list of unique identifiers.'
      else
        dsl.optional field, type: klass.param_type(model, field), description: "Filter on #{field} by value."
      end
    end

    def humanize_date_range(field)
      field.ends_with?('_start') ? 'initial' : 'terminal'
    end

    def identifier_filter?(model, field)
      true if field.ends_with?('id') && %i(integer uuid).include?(model.columns_hash[field]&.type)
    end

    def special_filter_enabled?(filters)
      filters.include?(:all) || filters.include?(:filter)
    end

    def filter_doc
      <<-STR
        JSON of conditions for query.  If you're familiar with ActiveRecord's query conventions you can build more complex filters, i.e. against included child associations, e.g.: {\"&lt;association_name&gt;_&lt;parent&gt;\":{\"field\":\"value\"}}
      STR
    end

    def apply_simple_filter(klass, model, params, records, field)
      return records if params[field].blank?

      if timestamp_filter(klass, model, field)
        op      = field.ends_with?('_start') ? '>=' : '<='
        records.where("#{timestamp_filter(klass, model, field)} #{op} ?", Time.zone.parse(params[field]))
      elsif model.respond_to?("#{field}=")
        records.send("#{field}=", params[field])
      else
        records.where(field => params[field])
      end
    end

    def apply_filter_params(klass, model, api_params, params, records)
      records = records.order(default_sort) if default_sort.present?

      simple_filters(klass, model, api_params).each do |field|
        records = apply_simple_filter(klass, model, params, records, field)
      end

      klass.custom_filters.each do |filter, _details|
        records = records.send(filter, params[filter])
      end

      records = apply_filters(records, params[:filter])
      records.where( JSON.parse(params[:query]) ) if params[:query].present?
      records
    end

    def apply_filters(records, filters)
      if filters.present?
        filters = JSON.parse( filters.delete('\\') )
        filters.each do |key, value|
          records = records.where(key => value) if value.present?
        end
      end
      records
    end
  end
end
