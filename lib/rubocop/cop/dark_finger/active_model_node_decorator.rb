require 'delegate'

module RuboCop
  module Cop
    module DarkFinger
      class ActiveModelNodeDecorator < SimpleDelegator

        attr_reader :misc_method_names

        def initialize(node, misc_method_names: [])
          super(node)
          raise "Cannot decorate nil node" if node.nil?
          @misc_method_names = misc_method_names
        end

        def node_type
          if validation?
            ModelStructure::VALIDATION
          elsif association?
            ModelStructure::ASSOCIATION
          elsif callback?
            ModelStructure::CALLBACK
          elsif scope?
            ModelStructure::SCOPE
          elsif is_include?
            ModelStructure::INCLUDE
          elsif enum?
            ModelStructure::ENUM
          elsif attributes?
            ModelStructure::ATTRIBUTE
          elsif misc_method?
            ModelStructure::MISC
          else
            nil
          end
        end

        def ignore_due_to_nesting?
          return false if nested_directly_in_class?
          return false if nested_in_with_options?
          true
        end

        def preceeding_comment(processed_source)
          comment = processed_source.ast_with_comments[self].last&.text
          return comment if comment

          # This is needed since, in this example, ast_with_comments maps the
          # comment to `:foo` instead of the outter `validate`. Not sure how
          # else to do this.
          #
          # ## Validations ##
          # validate { :foo }
          comment = processed_source.comments.find do |comment|
            comment.location.line == location.first_line - 1
          end

          return comment.text if comment

          if nested_in_with_options?
            ActiveModelNodeDecorator.new(parent).preceeding_comment(processed_source)
          end
        end

        def private_declaration?
          # need to check respond_to since this may not be called only "on_send"
          respond_to?(:method_name) && method_name == :private && receiver.nil?
        end

        private

        def nested_in_with_options?
          parent_is_with_options? || grandparent_is_with_options?
        end

        def parent_is_with_options?
          parent.respond_to?(:method_name) && parent&.method_name == :with_options
        end

        def grandparent_is_with_options?
          grandparent = parent&.parent
          return false unless grandparent
          return false unless grandparent.respond_to?(:method_name)

          parent.begin_type? && grandparent.method_name == :with_options
        end

        def nested_directly_in_class?
          return false unless parent

          return true if parent.class_type?

          return true if parent.begin_type? && parent.parent&.class_type?

          if parent.block_type? || parent.lambda_or_proc?
            grand_parent = parent.parent
            great_grand_parent = parent.parent&.parent
            return true if grand_parent.begin_type? && great_grand_parent&.class_type?
          end

          false
        end

        def validation?
          method_name =~ /^validate/
        end

        def association?
          method_name =~ /^(has_one|has_many|has_and_belongs_to_many|belongs_to)$/
        end

        def callback?
          method_name =~ %r{
            ^(after|before|around)
            _
            (initialize|find|touch|save|validation|create|update|destroy|commit|rollback)$
          }x
        end

        def scope?
          method_name =~ /(default_)?scope/
        end

        def is_include?
          method_name.to_s == 'include'
        end

        def enum?
          method_name.to_s == 'enum'
        end

        def attributes?
          method_name =~ /^attr_/
        end

        def misc_method?
          misc_method_names.include?(method_name)
        end
      end

    end
  end
end
