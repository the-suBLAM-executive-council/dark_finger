require 'spec_helper'

describe DarkFinger do
  it 'has a version number' do
    expect(DarkFinger::VERSION).not_to be nil
  end
end

require_relative '../lib/rubocop/cop/dark_finger/model_structure.rb'

describe RuboCop::Cop::DarkFinger::ModelStructure do
  let(:config) { RuboCop::Config.new }

  def run_cop(cop, source)
    processed_source = parse_source(source)
    _investigate(cop, processed_source)
  end

  def expect_order_offense(cop)
    expect(cop.offenses.size).to eq(1)
    expect(cop.offenses.first.message).
      to match(/Model elements must appear in order/)
  end

  def expect_comment_offense(cop, expected_comment)
    expect(cop.offenses.size).to eq(1)
    expect(cop.offenses.first.message).
      to match(%Q(Expected preceeding comment: "#{expected_comment}"))
  end

  def cop_for(order: [], comments: {}, misc_method_names: [])
    described_class.new(
      config, required_order: order, required_comments: comments, misc_method_names: misc_method_names
    )
  end

  def run_and_expect_order_violation(order:, source:)
    cop = cop_for(order: order)
    run_cop(cop, wrap_in_class(source))
    expect_order_offense(cop)
  end

  def run_and_expect_comment_violation(element:, source:)
    cop = cop_for(comments: { element => 'Expected Comment' })
    run_cop(cop, wrap_in_class(source))
    expect_comment_offense(cop, 'Expected Comment')
  end

  def wrap_in_class(source)
    "class Foo < ActiveRecord::Base\n  #{source}\nend"
  end


  it 'returns no violations when everything is in order' do
    cop = cop_for(
      order: [
        described_class::MODULE,
        described_class::INCLUDE,
        described_class::ENUM,
        described_class::CONSTANT,
        described_class::ASSOCIATION,
        described_class::VALIDATION,
        described_class::SCOPE,
        described_class::ATTRIBUTES,
        described_class::CALLBACK,
        described_class::CLASS_METHOD,
        described_class::INSTANCE_METHOD,
      ]
    )

    run_cop cop, <<-EOS
      module Foo; end
      include Foo
      enum :foo
      Foo = "foo"
      belongs_to :foo
      scope :foo, -> { :bar }
      attr_reader :foo
      after_save :foo
      def self.foo; end
      def bar; end
    EOS

    expect(cop.offenses).to be_empty
  end

  it 'returns no violations when everything is commented as required' do
    cop = cop_for(
      order: [described_class::VALIDATION, described_class::SCOPE],
      comments: {
        described_class::ASSOCIATION => '## Relationships ##',
        described_class::ATTRIBUTES => '## Attributes ##',
        described_class::CALLBACK => '## Callbacks ##',
        described_class::CONSTANT => '## Constants ##',
        described_class::ENUM => '## Enums ##',
        described_class::INCLUDE => '## Includes ##',
        described_class::MODULE => '## Modules ##',
        described_class::SCOPE => '## Scopes ##',
        described_class::VALIDATION => '## Validations ##',
      }
    )

    run_cop cop, <<-EOS
      ## Modules ##
      module Foo; end

      ## Includes ##
      include Foo

      ## Enums ##
      enum :foo

      ## Constants ##
      Foo = "foo"

      ## Relationships ##
      belongs_to :foo

      ## Scopes ##
      scope :foo, -> { :bar }

      ## Attributes ##
      attr_reader :foo

      ## Callbacks ##
      after_save :foo

      ## Class Methods ##
      def self.foo; end

      ## Instance Methods ##
      def bar; end
    EOS

    expect(cop.offenses).to be_empty
  end

  describe 'associations' do
    it 'detects order violations' do
      run_and_expect_order_violation(
        order: [described_class::ASSOCIATION, described_class::SCOPE],
        source: <<-EOS
          scope :foo, -> { :bar }
          belongs_to :foo
        EOS
      )
    end

    it 'detects comment violations' do
      run_and_expect_comment_violation(
        element: described_class::ASSOCIATION,
        source: <<-EOS
          ## incorrect comment ##
          belongs_to :foo
        EOS
      )
    end
  end

  describe 'attributes' do
    it 'detects order violations' do
      run_and_expect_order_violation(
        order: [described_class::ATTRIBUTES, described_class::SCOPE],
        source: <<-EOS
          scope :foo, -> { :bar }
          attr_reader :foo
        EOS
      )
    end

    it 'detects comment violations' do
      run_and_expect_comment_violation(
        element: described_class::ATTRIBUTES,
        source: <<-EOS
          ## incorrect comment ##
          attr_reader :foo
        EOS
      )
    end
  end

  describe 'callbacks' do
    it 'detects order violations' do
      run_and_expect_order_violation(
        order: [described_class::CALLBACK, described_class::SCOPE],
        source: <<-EOS
          scope :foo, -> { :bar }
          after_save :foo
        EOS
      )
    end

    it 'detects comment violations' do
      run_and_expect_comment_violation(
        element: described_class::CALLBACK,
        source: <<-EOS
          ## incorrect comment ##
          after_save :foo
        EOS
      )
    end
  end

  describe 'class methods' do
    it 'detects order violations' do
      run_and_expect_order_violation(
        order: [described_class::CLASS_METHOD, described_class::SCOPE],
        source: <<-EOS
          scope :foo, -> { :bar }
          def self.foo; end
        EOS
      )
    end

    it 'detects comment violations' do
      run_and_expect_comment_violation(
        element: described_class::CLASS_METHOD,
        source: <<-EOS
          ## incorrect comment ##
          def self.foo; end
        EOS
      )
    end
  end

  describe 'constants' do
    it 'detects order violations' do
      run_and_expect_order_violation(
        order: [described_class::CONSTANT, described_class::SCOPE],
        source: <<-EOS
          scope :foo, -> { :bar }
          FOO = 'bar'
        EOS
      )
    end

    it 'detects comment violations' do
      run_and_expect_comment_violation(
        element: described_class::CLASS_METHOD,
        source: <<-EOS
          ## incorrect comment ##
          def self.foo; end
        EOS
      )
    end
  end

  describe 'constructors' do
    it 'detects order violations' do
      run_and_expect_order_violation(
        order: [described_class::CONSTRUCTOR, described_class::SCOPE],
        source: <<-EOS
          scope :foo, -> { :bar }
          def initialize; end
        EOS
      )
    end

    it 'detects comment violations' do
      run_and_expect_comment_violation(
        element: described_class::CONSTRUCTOR,
        source: <<-EOS
          ## incorrect comment ##
          def initialize; end
        EOS
      )
    end
  end

  describe 'enums' do
    it 'detects order violations' do
      run_and_expect_order_violation(
        order: [described_class::ENUM, described_class::SCOPE],
        source: <<-EOS
          scope :foo, -> { :bar }
          enum :foo
        EOS
      )
    end

    it 'detects comment violations' do
      run_and_expect_comment_violation(
        element: described_class::ENUM,
        source: <<-EOS
          ## incorrect comment ##
          enum :foo
        EOS
      )
    end
  end

  describe 'includes' do
    it 'detects order violations' do
      run_and_expect_order_violation(
        order: [described_class::INCLUDE, described_class::SCOPE],
        source: <<-EOS
          scope :foo, -> { :bar }
          include Foo
        EOS
      )
    end

    it 'detects comment violations' do
      run_and_expect_comment_violation(
        element: described_class::INCLUDE,
        source: <<-EOS
          ## incorrect comment ##
          include Foo
        EOS
      )
    end
  end

  describe 'modules' do
    it 'detects order violations' do
      run_and_expect_order_violation(
        order: [described_class::MODULE, described_class::SCOPE],
        source: <<-EOS
          scope :foo, -> { :bar }
          module Foo; end
        EOS
      )
    end

    it 'detects comment violations' do
      run_and_expect_comment_violation(
        element: described_class::MODULE,
        source: <<-EOS
          ## incorrect comment ##
          module Foo; end
        EOS
      )
    end
  end

  describe 'scopes' do
    it 'detects order violations' do
      run_and_expect_order_violation(
        order: [described_class::MODULE, described_class::SCOPE],
        source: <<-EOS
          scope :foo, -> { :bar }
          module Foo; end
        EOS
      )
    end

    it 'detects comment violations' do
      run_and_expect_comment_violation(
        element: described_class::SCOPE,
        source: <<-EOS
          ## incorrect comment ##
          scope :foo, -> { :bar }
        EOS
      )
    end
  end

  describe 'validations' do
    it 'detects order violations' do
      run_and_expect_order_violation(
        order: [described_class::VALIDATION, described_class::SCOPE],
        source: <<-EOS
          scope :foo, -> { :bar }
          validates :field, presence: true
        EOS
      )
    end

    it 'detects comment violations' do
      run_and_expect_comment_violation(
        element: described_class::VALIDATION,
        source: <<-EOS
          ## incorrect comment ##
          validates :field, presence: true
        EOS
      )
    end
  end

  describe 'misc method calls' do
    it 'detects order violations' do
      cop = cop_for(
        order: [described_class::MISC, described_class::SCOPE],
        misc_method_names: ['serialize']
      )

      source = <<-EOS
        scope :foo, -> { :bar }
        serialize :foobars, Array
      EOS

      run_cop(cop, wrap_in_class(source))
      expect_order_offense(cop)
    end

    it 'detects comment violations' do
      cop = cop_for(
        order: [described_class::MISC, described_class::SCOPE],
        comments: {
          described_class::MISC => "## Misc ##",
          described_class::SCOPE => "## Scopes ##"
        },
        misc_method_names: ['serialize']
      )

      source = <<-EOS
        ## Invalid comment ##
        serialize :foobars, Array

        ## Scopes ##
        scope :foo, -> { :bar }
      EOS

      run_cop(cop, wrap_in_class(source))
      expect_comment_offense(cop, "## Misc ##")
    end
  end
end
