require 'spec_helper'

require_relative '../lib/rubocop/cop/dark_finger/active_model_node_decorator.rb'

module RuboCop::Cop::DarkFinger
  describe ActiveModelNodeDecorator do
    def node_for(source, misc_method_names: [])
      described_class.new(
        parse_source(source).ast,
        misc_method_names: misc_method_names
      )
    end

    describe '#node_type' do
      def node_type_for(source, misc_method_names: [])
        node_for(source, misc_method_names: misc_method_names).node_type
      end

      it 'returns nil for unknown nodes' do
        expect(node_type_for('random_function_call(arg)')).to be_nil
      end

      it 'identifies associations' do
        expect(node_type_for('belongs_to :foo')).to eq(ModelStructure::ASSOCIATION)
        expect(node_type_for('has_many :foo')).to eq(ModelStructure::ASSOCIATION)
        expect(node_type_for('has_and_belongs_to_many :foo')).to eq(ModelStructure::ASSOCIATION)
      end

      it 'identifies callbacks' do
        expect(node_type_for('after_save :foo')).to eq(ModelStructure::CALLBACK)
        expect(node_type_for('before_save :foo')).to eq(ModelStructure::CALLBACK)
        expect(node_type_for('after_commit :foo')).to eq(ModelStructure::CALLBACK)
        expect(node_type_for('before_validation :foo')).to eq(ModelStructure::CALLBACK)
      end

      it 'identifies enums' do
        expect(node_type_for('enum :foo')).to eq(ModelStructure::ENUM)
      end

      it 'identifies includes' do
        expect(node_type_for('include Foo')).to eq(ModelStructure::INCLUDE)
      end

      it 'identifies scopes' do
        expect(node_type_for('scope :foo')).to eq(ModelStructure::SCOPE)
        expect(node_type_for('detault_scope :foo')).to eq(ModelStructure::SCOPE)
      end

      it 'identifies validations' do
        expect(node_type_for('validates :foo, presence: true')).to eq(ModelStructure::VALIDATION)
        expect(node_type_for('validate :foo')).to eq(ModelStructure::VALIDATION)
      end

      it 'identifies "misc" methods' do
        expect(
          node_type_for('serialize :foos, Array', misc_method_names: [:serialize])
        ).to eq(ModelStructure::MISC)
      end
    end

    describe '#ignore_due_to_nesting?' do
      it 'returns false for nodes that are directly inside a class' do
        source = <<-EOS
          class Foo
            has_one :foo
          end
        EOS

        class_node = node_for(source)
        has_one_node = described_class.new(class_node.child_nodes.last)
        expect(has_one_node.ignore_due_to_nesting?).to be_falsey
      end

      it 'returns false for nodes single nodes inside a with_options block' do
        source = <<-EOS
          class Foo
            with_options dependent: :destroy do |l|
              l.has_one :foo
            end
          end
        EOS

        class_node = node_for(source)
        has_one_node = described_class.new(class_node.child_nodes.last.child_nodes.last)
        expect(has_one_node.source).to eq('l.has_one :foo')
        expect(has_one_node.ignore_due_to_nesting?).to be_falsey
      end

      it 'returns false for nodes inside a begin/end inside a with_options block' do
        source = <<-EOS
          class Foo
            with_options dependent: :destroy do |l|
              l.has_one :foo
              l.has_one :bar
            end
          end
        EOS

        class_node = node_for(source)
        has_one_node = described_class.new(class_node.child_nodes.last.child_nodes.last.child_nodes.first)
        expect(has_one_node.source).to eq('l.has_one :foo')
        expect(has_one_node.ignore_due_to_nesting?).to be_falsey
      end

      it 'returns true for nodes that are nested inside a module' do
        source = <<-EOS
          class Foo
            module Bar
              def a_method
              end
            end
          end
        EOS

        class_node = node_for(source)
        method_node = described_class.new(class_node.child_nodes.last.child_nodes.last)
        expect(method_node.ignore_due_to_nesting?).to be_truthy
      end
    end

    describe '#preceeding_comment' do
      def comment_for(source)
        node_for(source).preceeding_comment(parse_source(source))
      end

      it 'returns the comment' do
        source = <<-EOS
          # the comment
          validate :foo
        EOS
        expect(comment_for(source)).to eq('# the comment')
      end

      # this is a special case where the parser wants to associate the comment
      # to the content of the block
      it 'returns the comment when a block is involved' do
        source = <<-EOS
          # the comment
          validate { foo }
        EOS
        expect(comment_for(source)).to eq('# the comment')
      end

      it 'returns the comment preceeding the "with_options" if one is involved' do
        source = <<-EOS
          # the comment
          with_options dependent: :destroy do |l|
            l.has_one :foo
          end
        EOS

        node = node_for(source)
        has_one_node = described_class.new(node.child_nodes.last)
        expect(
          has_one_node.preceeding_comment(parse_source(source))
        ).to eq('# the comment')
      end
    end
  end
end
