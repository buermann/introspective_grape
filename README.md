# IntrospectiveGrape

[![Gem Version][GV img]][Gem Version]
[![Coverage Status][CS img]][Coverage Status]
[![Tests](https://github.com/buermann/introspective_grape/actions/workflows/test.yml/badge.svg)][Tests]
[![Lints](https://github.com/buermann/introspective_grape/actions/workflows/lint.yml/badge.svg)][Lints]

[Tests]: https://github.com/buermann/introspective_grape/actions
[Lints]: https://github.com/buermann/introspective_grape/actions
[Gem Version]: https://rubygems.org/gems/introspective_grape
[Coverage Status]: https://coveralls.io/r/buermann/introspective_grape

[GV img]: https://badge.fury.io/rb/introspective_grape.png
[CS img]: https://coveralls.io/repos/buermann/introspective_grape/badge.png?branch=master

IntrospectiveGrape is a rails plugin for DRYing up [Grape APIs](https://github.com/ruby-grape/grape) by laying out simple
RESTful defaults based on the model definitions and, via
[SchemaPlusValidations](https://github.com/SchemaPlus/schema_validations), your database schema.

(SchemaPlus is not currently being maintained and is unavailable for Rails > 2.5, so so is
IntrospectiveGrape. Which is too bad, I don't know how anybody with a SQL database gets by
without it! We're working on it when we get the chance.)

IntrospectiveGrape provides handling for deeply nested relations according to the models'
`accepts_nested_attributes_for` declarations, generating all the necessary
boilerplate for flexible and consistent bulk endpoints on plural associations,
and building nested routes for the same.

To facilitate idiomatic ruby and javascript, respectively, it also makes it easy to snakecase incoming parameters and camelizes outputs, all the way through to your swagger docs.

## Documentation

In your Gemfile:

```
gem 'introspective_grape'
```

And bundle install.

## Grape Configuration

### Camelization

To camelcase your JSON outputs you'll need to use IntrospectiveGrape's formatter in your API:

```
require 'introspective_grape/camel_snake'
class MyAPI < Grape::API
  formatter :json, IntrospectiveGrape::Formatter::CamelJson
end
```

This also monkey patches Grape::Swagger to camelize your API's self-documentation, while snakecasing parameters passed to your API.

To include this behavior in your test coverage you need to either access the API's params hash or you can format the response body to `JSON.parse(response.body).with_snake_keys` in a helper method with the `using CamelSnakeKeys` refinement.

You can disable this behavior by setting `IntrospectiveGrape.config.camelize_parameters = false` down in `config/initializers`.

## Authentication and authorization

Authentication and authorization are presently enforced on every endpoint. If you have named the authentication helper method in Grape something other than "authenticate!" or "authorize!" you can set it with:

```
IntrospectiveGrape::API.authentication_method = "whatever!"
```

Pundit authorization is invoked against index?, show?, update?, create?, and destroy? methods with the model instance in question (or a new instance in the case of index).

The joke goes that you may find you need to allow an unauthenticated user to attempt a log in, which can be handled with something like:

```
 def authorize!
    unauthorized! unless current_user || login_request?
  end

  def login_request?
    # is it the session login endpoint?
    self.method_name.start_with?('POST') && self.namespace == '/login'
  end
```

## Generating End Points for Models

IntrospectiveGrape's parameterization of a model begins with the `restful` declaration, which expects an array of parameters that can be passed on to the model for update and create actions, including its nested models.

The simplest app/api/v1/my_model_api.rb with the broadest functionality would look like:

```
class MyModelAPI < IntrospectiveGrape::API
  filter_on :all

  restful MyModel, [:strong, :param, :fields, :and, { nested_model_attributes: [:nested,:fields, :_destroy] }]

  class <NestedModel>Entity < Grape::Entity
    expose :id, :attribute
  end

  class MyModelEntity < Grape::Entity
    expose :id, :attribute1, :attribute2
    expose :nested, using: <NestedModel>Entity>
  end
end
```

This would set up all the basic RESTFUL actions with nested routes for the associated model and its association, providing a good deal of flexibility for API consumers out of the box.

IntrospectiveGrape looks in the MyModelAPI class for grape-entity definitions. If you prefer to define your entities elsewhere you could inherit them here instead.

NOTE: Nested entities must be defined before their parents, inside-out, or you'll run into loading errors.

## Customizing End Points

Many simple customizations are available to carve out behaviors from the expansive defaults:

```
class MyModelAPI < IntrospectiveGrape::API
  skip_presence_validations :attribute_with_generated_default_value

  exclude_actions Model, <:index,:show,:create,:update,:destroy>
  default_includes Model, <associations for eager loading>

  include_actions NestedModel, <:index,:show,:create,:update,:destroy>
  default_includes NestedModel, <associations for eager loading>

  paginate per_page 25, offset: 0, max_per_page: false

  filter_on :param

  restful MyModel, [:strong, :param, :fields, :and, { nested_model_attributes: [:nested,:fields, :_destroy] }] do
    # Here you can add additional end points to the model's namespace, or customize one you've recently excluded so you can implement a caching strategy.
  end

  class <NestedModel>Entity < Grape::Entity
    expose :id, :attribute
  end

  class <MyModel>Entity < Grape::Entity
    expose :id, :attribute
    expose :nested, using: <NestedModel>Entity>
  end
end
```

## Skipping a Presence Validation for a Required Field

If a model has, say, a procedurally generated default for a not-null field
`skip_presence_validations` will make IntrospectiveGrape declare the parameter
optional rather than required.

## Excluding Endpoints

By default any association included in the strong params argument will have all
RESTful (`:index,:show,:create,:update, :destroy`) endpoints defined. These can
be excluded (or conversely included) with the `exclude_actions` (or `include_actions`)
declarations in the API class. You can also include or exclude :all or :none as shorthand.

## Eager Loading

Declaring `default_includes` on an activerecord class will tell IntrospectiveGrape which associations to eager load when fetching a collection or instance.

## Pagination

The index action by default will not be paginated. Simply declare `paginate` before the `restful` declaration will enable [Kaminari](https://github.com/amatsuda/kaminari) pagination on the index results using a default 25 results per page with an offset of 0. You can pass Kaminari's options to the paginate declaration, `per_page`, `max_per_page`, etc.

## Validating Virtual Attributes and Overriding Grape Validations

To define a Grape param type for a virtual attribute or override the defaut param type
from database introspection, define a class method in the model with the param
types for the attributes specified in a hash, e.g.:

```
   def self.grape_param_types
    { "<attribute name 1>" => String,
      "<attribute name 2>" => Integer,
      "<attribute name 3>" => Grape::API::Boolean }
   end
```

To add additional validations on API inputs you can define a hash of hashes in the model in a
class method ("grape_validations") that will be applied to that field's param declaration:

```
  def self.grape_validations
    { field1: { values: %w(red blue green) },
      field2: { json_array: true },
      field3: { regexp: /\w+/ }
  end
```

Many bespoke behaviors can be relegated to the model via virtual attributes in this way.

## Validating JSON Parameters

IntrospectiveGrape provides the following custom grape validators for JSON string parameters:

```
json: true       # validates that the JSON string parses
json_array: true # validates that the JSON string parses and returns an Array
json_hash: true  # validates that the JSON string parses and returns a Hash
```


## Filtering and Searching on GET :index

Simple filters on field values (and start and end values for timestamps) can be added with the `filter_on` declaration. Declaring `filter_on :all` will add filters for every attribute of the model.

```
class MyModelAPI < IntrospectiveGrape::API
  filter_on :my_attribute, :my_other_attribute
end
```

Multiple values can be specified at once for Integer attributes that end in "id" (i.e.
conventional primary and foreign keys) by passing a comma separated list of IDs.

For timestamp attributes it will generate `<name_of_timestamp>_start` and
`<name_of_timestamp>_end` range constraints.

There is also a special "filter" filter that accepts a JSON hash of attributes and values:
this allows more complex filtering if one is familiar with ActiveRecord's query conventions,
a special for you full-stack developers.

### Overriding Filter Queries

If, e.g., a field is some sort of complex composite rather than a simple field value you can
override the default behavior (`where(field: params[field])`) by adding a query method on the
model class:

```
class MyAPI < IntrospectiveGrape::API
  filter_on :my_composite_field
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

### Performance Tuning: IntrospectiveGrape defaults to reloading the object after updates!

By default the gem reloads the object instance before presenting the updated model, a lazy but
effective workaround to updates that may not propagate in the working instance due to actions
a user may take in hooks, or some updates to has_many :through associations. We want to put up
APIs with haste rather than digging our way out of tricky minutae that can be handled later as
technical debt.

This behavior can be disabled by setting `IntrospectiveGrape.config.skip_object_reload = true`,
when you have time for technical debt you can toggle it and work on fixing broken tests (you
did take the time to write comprehensive test coverage, didn't you?).

It is presently only an application wide configuration setting, which would be trivial to make
more atomistic.

## Documenting Endpoints

If you wish to provide additional documentation for end points you can define
`self.<action>_documentation` class methods in the API class (or extend them
from a documentation module, which would be preferable).

## Grape Hooks - The Precedence of Declaration Matters

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


