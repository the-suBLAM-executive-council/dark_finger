# The Model Structure Cop

At work we've found that, as our model files grow in size, there are many
"macro" methods (scopes, validations, etc) at the top that become messy and
inconsistent across files.

This cop will issue warnings if the various model elements:

1. Aren't grouped together
2. The groups don't appear in the right order
3. The groups aren't commented properly

This is the kind of model file that we like. Notice how all the model elements
are grouped, commented, and ordered (although ordering is not visible from just
one file):

```ruby
class Horse < ApplicationRecord
  ## Includes ##
  include GallopingMagicPowers
  include LazerEyes

  ## Enums ##
  enum breed: %i[thoroughbred
                 arabian
                 american quarter horse
                 clydesdale
                 mustang]

  ## Associations ##
  has_many :legs
  belongs_to :brain
  belongs_to :saddle

  ## Validations ##
  validates_presence_of :breed
  validates_presence_of :age

  ## Scopes ##
  scope :dead, -> { where(state: 'dead') }
  scope :alive, -> { where(state: 'alive') }

  ## Attributes ##
  attr_accessor :promote_to_demon_horse

  ## Callbacks ##
  after_save :callbacks_are_evil_you_should_be_ashamed

  ## Misc ##
  serialize :nose_hairs, Array
  acts_as_taggable

  def self.foobario
    # foo
  end

  def gallop_hard
    # ...
  end
end

```

## Usage and Configuration

Install the gem. Then, in your `.rubycop.yml` file, require `dark_finger` and
add your desired config.

For example:

```yaml
# in .rubocop.yml

# this is required
require: dark_finger

DarkFinger/ModelStructure:

  # this is also required
  Include:
    - 'app/models/*'

  # specify the order that the model elements must appear in
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
    - misc
    - constructor
    - class_method
    - instance_method

  # specify the comments that must appear above each group of model elements
  required_comments:
    association: '## Relationships ##'
    attribute: '## Attributes ##'
    callback: '## Callbacks ##'
    constant: '## Constants ##'
    enum: '## Enums ##'
    include: '## Includes ##'
    misc: '## Misc ##'
    module: '## Modules ##'
    scope: '## Scopes ##'
    validation: '## Validations ##'

  # specify the methods that are categorized as "misc"
  misc_method_names:
    - acts_as_list
    - acts_as_taggable
    - friendly_id
    - serialize
    - workflow
```

Supported model elements:


| Config key      | Description (when not obvious)             |
|-----------------|--------------------------------------------|
| association     |                                            |
| attribute       | `attr_reader` and friends                  |
| callback        | `after_save` et al.                        |
| class_method    |                                            |
| constant        |                                            |
| constructor     |                                            |
| enum            |                                            |
| include         |                                            |
| instance_method |                                            |
| misc            | This is a configurable set of method calls |
| module          | Any `module Foo; ...; end` declarations    |
| scope           | Any `scope` or `default_scope` calls       |
| validation      |                                            |


Any model elements that are not included in "required order" will be ignored.

Dark Finger ignores everything that appears after `private`. This may change in
future, but for now we have just agreed that anything goes in the private
section of our models.
