module RuboCop
  module Cop
    module DarkFinger
      class MigrationConstants < ::RuboCop::Cop::Cop
        DEFAULT_ALLOWED_CONSTANTS = [
          'Migration',
          'ActiveRecord',
          'ActiveRecord::Migration',
          'ActiveRecord::Base'
        ]

        attr_reader :allowed_constants

        def initialize(*args)
          super
          @allowed_constants = DEFAULT_ALLOWED_CONSTANTS + allowed_top_level_constants
        end

        def on_const(node)
          return if allowed_constants.include?(node.const_name)
          add_offense(node, message: %Q(Undeclared constant: "#{node.const_name}"))
        end

        def on_casgn(node)
          add_allowed_constant(node.children[1])
        end

        def on_class(node)
          add_allowed_constant(node.children.first.const_name)
          add_module_parent_chain_for(node)
        end

        def on_module(node)
          add_allowed_constant(node.children.first.const_name)
          add_module_parent_chain_for(node)
        end

        private

        def allowed_top_level_constants
          Module.constants.map(&:to_s) - top_level_model_classes_and_containing_modules
        end

        def top_level_model_classes_and_containing_modules
          return [] unless Object.const_defined?('ActiveRecord::Base')

          ::ActiveRecord::Base.descendants.map do |klass|
            klass.name.sub(/::.*/, '').to_s
          end.uniq
        end

        def add_allowed_constant(constant)
          @allowed_constants << constant.to_s
          @allowed_constants.uniq!
        end

        def add_module_parent_chain_for(node)
          chain = ModuleParentChainExtractor.new(node).perform
          add_allowed_constant(chain)
        end
      end

      class ModuleParentChainExtractor
        attr_reader :node

        def initialize(node)
          @node = node
        end

        def perform
          module_chain = [node.children.first.const_name]

          current_node = node
          while current_node.parent && current_node.parent.module_type?
            module_chain << current_node.parent.children.first.const_name
            current_node = current_node.parent
          end

          module_chain.reverse.join("::")
        end
      end
    end
  end
end

