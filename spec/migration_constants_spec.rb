require 'spec_helper'

describe RuboCop::Cop::DarkFinger::MigrationConstants do
  let(:config) { RuboCop::Config.new }

  def offenses_for(source, **cop_options)
    cop = described_class.new(config, cop_options)
    processed_source = parse_source(source)
    _investigate(cop, processed_source)
    cop.offenses
  end

  def expect_no_offenses_for(source, **cop_options)
    expect(
      offenses_for(source, cop_options)
    ).to be_empty
  end

  it 'returns no violations when no constants are used' do
    source = <<-EOS
      class FooMigration < ActiveRecord::Migration[5.1]
        def up
        end
      end
    EOS

    expect_no_offenses_for(source)
  end

  it 'returns an error if an unknown and undeclared constant is sent a message' do
    source = <<-EOS
      class FooMigration < ActiveRecord::Migration[5.1]
        def up
          SomeModel.all.each do
            # stuff
          end
        end
      end
    EOS

    offenses = offenses_for(source)
    expect(offenses.size).to eq(1)
    expect(offenses.first.message).to match(%Q(Undeclared constant: "SomeModel"))
  end

  it 'does not return errors when using classes that are declared in the file' do
    source = <<-EOS
      class SomeModel < ActiveRecord::Base; end

      class FooMigration < ActiveRecord::Migration[5.1]
        def up
          SomeModel.all.each do
            # stuff
          end
        end
      end
    EOS

    expect_no_offenses_for(source)
  end

  it 'does not return errors when using modules that are declared in the file' do
    source = <<-EOS
      module Foo
        module Bar
          class Baz < ActiveRecord::Base; end
        end
      end

      class FooMigration < ActiveRecord::Migration[5.1]
        def up
          Foo::Bar::Baz.first
        end
      end
    EOS

    expect_no_offenses_for(source)
  end

  it 'does not return errors when using constants that are declared in the file' do
    source = <<-EOS
      SOME_CONSTANT="foobar"

      class FooMigration < ActiveRecord::Migration[5.1]
        def up
          puts SOME_CONSTANT
        end
      end
    EOS

    expect_no_offenses_for(source)
  end

  it 'does not return errors when using "top level system constants"' do
    source = <<-EOS
      class FooMigration < ActiveRecord::Migration[5.1]
        def up
          YAML.load_file("foo")
          File.read("foo")
          Array[:lol]
          Hash.new(:foo)
        end
      end
    EOS

    expect_no_offenses_for(source)
  end

  it 'does not return errors for whitelisted constants' do
    source = <<-EOS
      class FooMigration < ActiveRecord::Migration[5.1]
        def up
          AWhitelistedConstant.something
        end
      end
    EOS

    expect_no_offenses_for(source, whitelisted_constants: ['AWhitelistedConstant'])
  end
end
