# The Migration Constants Cop

In our rails migration files we don't want dependencies on, for example,
ActiveRecord model files.

This is because migration files should be "timeless" and able to run at any
point in the future. Our model files change very frequently - and therefore
cannot be depended on directly. We must redeclare the model inside the
migration file.

For example:

```ruby
  # BAD :'(
  #
  # This migration depends on `SomeModel` and `.some_scope`. When this
  # migration is actually run, either of those things could have changed name,
  # or perhaps `some_scope` might behave differently by then or have been
  # deleted.
  class FooMigration < ActiveRecord::Migration[5.1]
    def up
      SomeModel.some_scope.each do
        # stuff
      end
    end
  end

  # GOOD :-D
  #
  # This migration has no external dependencies on our app. It is unlikely to
  # break in the future as our app changes.
  class FooMigration < ActiveRecord::Migration[5.1]
    class SomeModel < ActiveRecord::Base
      scope :some_scope, -> { ... }
    end

    def up
      SomeModel.some_scope.each do
        # stuff
      end
    end
  end
```

This cop will issue warnings if a migration file depends on certain constants
(like model files) that it doesn't declare.

## Usage

Install the gem and then add this to your `.rubocop.yml` file:

```yaml
# this is required
require: dark_finger

DarkFinger/MigrationConstants:
  Include:
    - 'db/migrate/*.rb'
  whitelisted_constants:
    - 'MyConstant'
    - 'MyOtherConstant'
```
