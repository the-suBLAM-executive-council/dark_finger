module RuboCop
  module Cop
    module DarkFinger
      class ModuleAncestorChainExtractor
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
