require 'spec_helper'

require_relative '../lib/rubocop/cop/dark_finger/module_ancestor_chain_extractor'

module RuboCop::Cop::DarkFinger
  describe ModuleAncestorChainExtractor do
    def node_for(source)
      parse_source(source).ast
    end

    describe '#perform' do
      it 'returns the module and its ancestor modules for a given module node' do
        source = <<-EOS
          module GrandParent
            module Parent
              module Child; end
            end
          end
        EOS

        # get the node for 'module Child; end'
        node = node_for(source).children[1].children[1]

        expect(
          described_class.new(node).perform
        ).to eq("GrandParent::Parent::Child")
      end

      it 'returns the class and its ancestor modules for a given class node' do
        source = <<-EOS
          module GrandParent
            module Parent
              class Child < Something; end
            end
          end
        EOS

        # get the node for 'class Child ...'
        node = node_for(source).children[1].children[1]

        expect(
          described_class.new(node).perform
        ).to eq("GrandParent::Parent::Child")
      end
    end
  end
end
