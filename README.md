# IntrospectiveGrape

[![Gem Version][GV img]][Gem Version]
[![Build Status][BS img]][Build Status]
[![Dependency Status][DS img]][Dependency Status]
[![Coverage Status][CS img]][Coverage Status]

[Gem Version]: https://rubygems.org/gems/introspective_grape
[Build Status]: https://travis-ci.org/buermann/introspective_grape
[travis pull requests]: https://travis-ci.org/buermann/introspective_grape/pull_requests
[Dependency Status]: https://gemnasium.com/buermann/introspective_grape
[Coverage Status]: https://coveralls.io/r/buermann/introspective_grape

[GV img]: https://badge.fury.io/rb/introspective_grape.png
[BS img]: https://travis-ci.org/buermann/introspective_grape.png
[DS img]: https://gemnasium.com/buermann/introspective_grape.png
[CS img]: https://coveralls.io/repos/buermann/introspective_grape/badge.png?branch=master


IntrospectiveGrape is a Rails Plugin for DRYing up Grape APIs by laying out simple
RESTful defaults based on the model definitions. If you use a schema validator
like [SchemaPlus](https://github.com/SchemaPlus/schema_plus) it will, by
extension, define your endpoints according to your database schema.

It provides handling for deeply nested relations according to the models'
`accepts_nested_attributes_for` declarations, generating all the necessary
boilerplate for flexible and consistent bulk endpoints on plural associations,
and building nested routes for the same.

It also snake cases everything coming in and camelizes parameters in your swagger docs
by default if you `require 'introspective_grape/camel_snake'` in your API.
This behavior can be disabled.

In addition it provides a `IntrospectiveGrape::Formatter::CamelJson` json formatter to
recursively camelize the keys of all your outputs, so ruby and javascript developers
can speak in their own idioms.

## Documentation

In your Gemfile:

```
gem 'introspective_grape'
```

And bundle install.


## Grape Configuration

IntrospectiveGrape's default behavior is to camelize all outputs and snake case all inputs. To camel case all your json output you'll need to use its formatter in your API:

```
formatter :json, IntrospectiveGrape::Formatter::CamelJson
```

It also defaults to monkey patching Grape::Swagger to camelize the API's parameters in the swagger docs and, vice-versa, snake casing the parameters that are sent to your API.

You can disable this behavior by setting `IntrospectiveGrape.config.camelize_parameters = false`.

To include this behavior in your test coverage you need to either access the API's params hash or you can format the response body to `JSON.parse(response.body).with_snake_keys` in a helper method.

## Authentication and authorization

Authentication and authorization are presently enforced on every endpoint. If you have named the authentication helper method in Grape something other than "authenticate!" or "authorize!" you can set it with:

```
IntrospectiveGrape::API.authentication_method = "whatever!"
```

Pundit authorization is invoked against index?, show?, update?, create?, and destroy? methods with the model instance in question (or a new instance in the case of index).


## Generate End Points for Models

In app/api/v1/my_model_api.rb:

```
class MyModelAPI < IntrospectiveGrape::API
  skip_presence_validations :attribute_with_generated_default_value
  exclude_actions Model, <:index,:show,:create,:update,:destroy>
  default_includes Model, <associations for eager loading>

  include_actions NestedModel, <:index,:show,:create,:update,:destroy>
  default_includes NestedModel, <associations for eager loading>

  paginate per_page 25, offset: 0, max_per_page: false

  restful MyModel, [:strong, :param, :fields, :and, { nested_model_attributes: [:nested,:fields, :_destroy] }] do
    # Add additional end points to the model's namespace
  end
 
  class <MyModel>Entity < Grape::Entity
    expose :id, :attribute
    expose :nested, using: <NestedModel>Entity>
  end

  class <NestedModel>Entity < Grape::Entity
    expose :id, :attribute
  end
end
```

If a model has, say, a procedurally generated default for a not-null field
`skip_presence_validations` will make IntrospectiveGrape declare the parameter
optional rather than required.

To define a Grape param type for a virtual attribute or override the defaut param
type from model introspection, define a class method in the model with the param
types for the attributes specified in a hash, e.g.:
 
```
   def self.attribute_param_types
    { "<attribute name 1>" => String,
      "<attribute name 2>" => Integer,
      "<attribute name 3>" => Virtus::Attribute::Boolean }
   end
```

For nested models declared in Rails' strong params both the Grape params for the
nested params as well as nested routes will be declared, allowing for
a good deal of flexibility for API consumers out of the box, such as implicitly
creating bulk update endpoints for nested models.


## Filtering and Searching

IntrospectiveGrape will automatically generate and parse filters on all exposed fields in the API.

Multiple values can be specified at once for Integer attributes that end in "id" (i.e. conventional primary and foreign keys) at once by passing a comma separated list of IDs.

For timestamp attributes it will generate `<name_of_timestamp>_start` and `<name_of_timestamp>_end` constraints.

### Overriding Filter Queries

If, e.g., a field is some sort of complex composite rather than a simple field value you can override the default behavior (`where(field: params[field])`) by adding a query method on the model class:

```
class MyAPI < IntrospectiveGrape::API
  restful MyModel, [my_composite_field]
end

class MyModel
  self << class
    def my_composite_field=(parameters)
      # parse the passed parameters in some way and return a query scope
    end
  end
end
```

### Custom Filter Methods

To add a custom filter to the index action you can declare a method to be called
against the model class with `custom_filter`. You can pass documentation and type
constraints (it would default to String) and other Grape parameter options in a hash:

```
class MyAPI < IntrospectiveGrape::API
  custom_filter :my_filter, type: Boolean, description: "Filter on some scope"
end

class MyModel
  self << class
    def my_filter(filter=false)
      filter ? my_scope : where(nil)
    end
  end
end
```


## Pagination

The index action by default will not be paginated, simply declared `paginate` before the `restful` declaration will enable [Kaminari](https://github.com/amatsuda/kaminari) pagination on the index results using a default 25 results per page with an offset of 0. You can pass Kaminari's options to the paginate declaration, `per_page`, `max_per_page`, etc.

## Excluding Endpoints

By default any association included in the strong params argument will have all
RESTful (`:index,:show,:create,:update, :destroy`) endpoints defined. These can
be excluded (or conversely included) with the `exclude_actions` or `include_actions`
declarations on the model. You can also include or exclude :all or :none as shorthand.

## Grape Hooks

Grape only applies hooks in the order they were declared, so to hook into the default
RESTful actions defined by IntrospectiveGrape you need to declare any hooks before the
`restful` declaration, rather than inside its block, where the hook will only apply to
your own subsequently declared endpoints.


## Dependencies

Tool                  | Description
--------------------- | -----------
[Grape]               | An opinionated micro-framework for creating REST-like APIs in Ruby
[GrapeEntity]         | Adds Entity support to API frameworks, such as Grape.
[GrapeSwagger]        | Swagger docs.
[GrapeKaminari]       | Pagination.
[Pundit]              | Minimal authorization through OO design and pure Ruby classes

[Grape]:         https://github.com/ruby-grape/grape
[GrapeEntity]:   https://github.com/ruby-grape/grape-entity
[GrapeSwagger]:  https://github.com/ruby-grape/grape-swagger
[GrapeKaminari]: https://github.com/monterail/grape-kaminari
[Pundit]:        https://github.com/elabs/pundit


