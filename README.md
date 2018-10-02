# DarkFinger

A Rubocop extension to check the layout of ActiveModel files. The cop will
check that elements appear together, in the right order, and commented as
desired.

Supported elements:

* associations
* attributes
* callbacks
* constants
* enums
* includes
* modules
* scopes
* validations
* class_methods
* instance_methods


## Installation

Add this line to your application's Gemfile:

```ruby
gem 'dark_finger'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install dark_finger

## Usage

Install the gem. Then, in your `.rubycop.yml` file, require `dark_finger` and
add your desired config.

For example, here is the default config:

```ruby
# in .rubocop.yml


# this is required
require: dark_finger

DarkFinger/ModelStructure:
  Include:
    - 'app/models/*'
  required_order:
    - module
    - include
    - enum
    - constant
    - association
    - validation
    - scope
    - attributes
    - callback
    - class_method
    - instance_method
  required_comments:
    association: '# Relationships'
    attribute: '# Attributes'
    callback: '# Callbacks'
    constant: '# Constants'
    enum: '# Enums'
    include: '# Includes'
    module: '# Modules'
    scope: '# Scopes'
    validation: '# Validations'

```

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

