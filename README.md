# IntrospectiveGrape

IntrospectiveGrape is a Rails Plugin for DRYing up Grape APIs by laying out simple
defaults and including deeply nested relations according to the models'
accepts_nested_attributes_for :relation declarations.

Presently it is tightly coupled with some other behaviors that I like and haven't abstracted out yet:

1. Parameters in the front end of the API will be in camel case and passed to the backend in snake case, following javascript conventions on the one and rails conventions in the other. Libraries for Grape and Swagger docs are duck typed to support this behavior.

2. It is dependent on Pundit for authorization and permissions. 


## Documentation

In your Gemfile:

```
gem 'introspective_grape'
```

And bundle install.  In app/api/v1/my_model_api.rb:

```
class MyModelAPI < IntrospectiveGrape::API
  exclude_actions Model, :index,:show,:create,:update,:destroy
  default_includes Model, <associations for eager loading>
  restful <Model Class>, [<strong, param, fields>]
 
    class <Model>Entity < Grape::Entity
      expose :id, :attribute
      expose :association, using: <Association>Entity>
    end
  end
 
  To define a Grape param type for a virtual attribute or override the defaut param
  type from model introspection, define a class method in the model with the param
  types for the attributes specified in a hash:
 
   def self.attribute_param_types
    { "<attribute name>" => Virtus::Attribute::Boolean }
   end
 
  For nested models declared in Rails' strong params both the Grape params for the
  nested params as well as nested routes will be declared, allowing for
  a good deal of flexibility for API consumers out of the box, nested params for
  bulk updates and nested routes for interacting with single records.
  end
```

## Dependencies

Tool                  | Description
--------------------- | -----------
[Grape]               | An opinionated micro-framework for creating REST-like APIs in Ruby
[GrapeSwagger]        | Swagger docs.
[Pundit]              | Minimal authorization through OO design and pure Ruby classes

[Grape]: https://github.com/ruby-grape/grape
[GrapeSwagger]: https://github.com/ruby-grape/grape-swagger
[Pundit]: https://github.com/elabs/pundit


