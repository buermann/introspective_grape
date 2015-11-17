# IntrospectiveGrape

IntrospectiveGrape is a Rails Plugin for DRYing up Grape APIs by laying out simple
defaults and including deeply nested relations according to the models'
accepts_nested_attributes_for :relation declarations. 

IntrospectiveGrape supports file uploads via Paperclip and hypothetically supports CarrierWave.

Presently it is tightly coupled with two behaviors that I like but should be abstracted out:

1. It is dependent on Pundit for authorization and permissions.

2. Parameters in the front end of the API will be accepted in camel case and passed to the backend in snake case, following javascript conventions on the one and rails conventions in the other.

Libraries for Grape and Swagger docs are rather invasively duck typed to support this behavior. It modifies Grape's JSON Formatter module and Grape Swagger's documentation classes to camelize parameter keys, and then converts the keys back to snake case for handling in the API.

To include this behavior in your test coverage you need to either access the API's params hash or you can `include IntrospectiveGrape::CamelSnake` in your test helper and `snake_keys(JSON.parse(response.body))` to format the params in a helper method.

## Documentation

In your Gemfile:

```
gem 'introspective_grape'
```

And bundle install.  In app/api/v1/my_model_api.rb:

```
class MyModelAPI < IntrospectiveGrape::API
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

A Pundit policy will need to be defined for :index?,:show?,:update?,:create?, and
:destroy? as well as a policy scope for the index action. IntrospectiveGrape
automatically enforces Pundit's authorize! before all actions.
 
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


