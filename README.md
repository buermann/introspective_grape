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
defaults with handling for deeply nested relations according to the models'
accepts_nested_attributes_for :relation declarations, generating all the necessary
boilerplate for flexible and consistent bulk endpoints on plural associations.

IntrospectiveGrape supports file uploads via Paperclip and hypothetically supports CarrierWave.

Presently it is tightly coupled with two behaviors that I like but should be abstracted out:

1. It is dependent on Pundit for authorization and permissions.

2. Parameters in the front end of the API will be accepted in camel case and passed to the backend in snake case, following javascript conventions on the one and rails conventions in the other.

Libraries for Grape and Swagger docs are rather invasively duck typed to support this behavior. It modifies Grape's JSON Formatter module and Grape Swagger's documentation classes to camelize parameter keys, and then converts the keys back to snake case for handling in the API.

To include this behavior in your test coverage you need to either access the API's params hash or you can format the response body to `JSON.parse(response.body).with_snake_keys` to in a helper method.

## Documentation

In your Gemfile:

```
gem 'introspective_grape'
```

And bundle install.

## Authentication and authorization

Authentication and authorization are presently enforced on every endpoint. If you have named the authentication helper method in Grape something other than "authenticate!" or "authorize!" you can set it with:

```
IntrospectiveGrape::API.authentication_method = "whatever!"
```

Pundit authorization is invoked against index?, show?, update?, create?, and destroy? methods with the model instance in question (or a new instance in the case of index).


## Grape Configuration

IntrospectiveGrape's default behavior is to camelize all outputs and snake case all inputs, so ruby and javascript developers can speak in their own idioms. To camel case all your json output you can use its formatter in your API:

```
formatter :json, IntrospectiveGrape::Formatter::CamelJson
```

It also defaults to monkey patching Grape::Swagger to camelize the API's parameters in the swagger docs and, vice-versa, snake casing the parameters that are sent to your API.

You can disable this behavior by setting `IntrospectiveGrape.config.camelize_parameters = false`.


## Generate End Points for Models

In app/api/v1/my_model_api.rb:

```
class MyModelAPI < IntrospectiveGrape::API
  skip_presence_validations :attribute
  exclude_actions Model, <:index,:show,:create,:update,:destroy>
  default_includes Model, <associations for eager loading>

  exclude_actions NestedModel, <:index,:show,:create,:update,:destroy>
  default_includes NestedModel, <associations for eager loading>

  restful MyModel, [:strong, :param, :fields, :and, { nested_attributes: [:nested,:fields, :_destroy] }] do
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
    { "<attribute name>" => Virtus::Attribute::Boolean }
   end
```

For nested models declared in Rails' strong params both the Grape params for the
nested params as well as nested routes will be declared, allowing for
a good deal of flexibility for API consumers out of the box, such as implicitly
creating bulk update endpoints for nested models.


## Dependencies

Tool                  | Description
--------------------- | -----------
[Grape]               | An opinionated micro-framework for creating REST-like APIs in Ruby
[GrapeEntity]         | Adds Entity support to API frameworks, such as Grape.
[GrapeSwagger]        | Swagger docs.
[Pundit]              | Minimal authorization through OO design and pure Ruby classes

[Grape]:        https://github.com/ruby-grape/grape
[GrapeEntity]:  https://github.com/ruby-grape/grape-entity
[GrapeSwagger]: https://github.com/ruby-grape/grape-swagger
[Pundit]:       https://github.com/elabs/pundit


