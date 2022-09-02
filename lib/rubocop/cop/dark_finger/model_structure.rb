require File.dirname(__FILE__) + '/active_model_node_decorator'

module RuboCop
  module Cop
    module DarkFinger
      class ModelStructure < ::RuboCop::Cop::Cop
        class InvalidConfigError < StandardError; end

        ASSOCIATION = :association
        ATTRIBUTE = :attribute
        CALLBACK = :callback
        CLASS_METHOD = :class_method
        CONSTANT = :constant
        CONSTRUCTOR = :constructor
        ENUM = :enum
        INCLUDE = :include
        INSTANCE_METHOD = :instance_method
        MISC = :misc
        MODULE = :module
        SCOPE = :scope
        VALIDATION = :validation

        KNOWN_ELEMENTS = [
          ASSOCIATION,
          ATTRIBUTE,
          CALLBACK,
          CLASS_METHOD,
          CONSTANT,
          CONSTRUCTOR,
          ENUM,
          INCLUDE,
          INSTANCE_METHOD,
          MISC,
          MODULE,
          SCOPE,
          VALIDATION,
        ]

        DEFAULT_REQUIRED_ORDER = [
          MODULE,
          INCLUDE,
          ENUM,
          CONSTANT,
          ASSOCIATION,
          VALIDATION,
          SCOPE,
          ATTRIBUTE,
          CALLBACK,
          MISC,
          CONSTRUCTOR,
          CLASS_METHOD,
          INSTANCE_METHOD,
        ]

        DEFAULT_REQUIRED_COMMENTS = {
          ASSOCIATION => '# Relationships',
          ATTRIBUTE => '# Attributes',
          CALLBACK => '# Callbacks',
          CONSTANT => '# Constants',
          ENUM => '# Enums',
          INCLUDE => '# Includes',
          MODULE => '# Modules',
          SCOPE => '# Scopes',
          VALIDATION => '# Validations'
        }

        DEFAULT_MISC_METHOD_NAMES = []

        attr_reader :required_order, :required_comments, :misc_method_names

        def initialize(*args, options)
          super
          @class_elements_seen = []
          @required_order = options[:required_order] || cop_config['required_order'] || DEFAULT_REQUIRED_ORDER
          @required_comments = options[:required_comments] || cop_config['required_comments'] || DEFAULT_REQUIRED_COMMENTS
          @misc_method_names = options[:misc_method_names] || cop_config['misc_method_names'] || DEFAULT_MISC_METHOD_NAMES

          # symbolize configs
          @required_order.map!(&:to_sym)
          @required_comments = Hash[ @required_comments.map {|k,v| [k.to_sym, v]} ]
          @misc_method_names.map!(&:to_sym)

          validate_config!
        end

        def on_send(node)
          process_node(node)
        end

        def on_casgn(node)
          process_node(node, seen_element: CONSTANT)
        end

        def on_module(node)
          process_node(node, seen_element: MODULE)
        end

        def on_def(node)
          seen_element = if node.method_name == :initialize
                           CONSTRUCTOR
                         else
                           INSTANCE_METHOD
                         end
          process_node(node, seen_element: seen_element)
        end

        def on_defs(node)
          process_node(node, seen_element: CLASS_METHOD)
        end

        private

        attr_reader :class_elements_seen

        def process_node(node, seen_element: nil)
          return if @order_violation_reported
          return if @seen_private_declaration

          node = ActiveModelNodeDecorator.new(node, misc_method_names: misc_method_names)

          if node.private_declaration?
            @seen_private_declaration = true
            return
          end

          seen_element ||= node.node_type
          return unless seen_element

          return if node.ignore_due_to_nesting?

          if first_time_seeing?(seen_element)
            detect_comment_violation(node, seen_element)
          end

          seen(seen_element)
          detect_order_violation(node)
        end

        def seen(class_element)
          return unless required_order.include?(class_element)
          class_elements_seen << class_element
          class_elements_seen.compact!
        end

        def first_time_seeing?(class_element)
          !class_elements_seen.include?(class_element)
        end

        def detect_comment_violation(node, class_element)
          return false unless required_comments[class_element]

          comment = node.preceeding_comment(processed_source)
          unless comment && comment.strip == required_comments[class_element]
            add_offense(node, message: "Expected preceeding comment: \"#{required_comments[class_element]}\"")
          end
        end

        def detect_order_violation(node)
          if order_violation_detected?
            @order_violation_reported = true
            message = "Model elements must appear in order:#{to_bullet_list(required_order)}\n"
            message << "Observed order:#{to_bullet_list(class_elements_seen)}"

            add_offense(node, message: message)
          end
        end

        def to_bullet_list(array)
          "\n* #{array.join("\n* ")}\n"
        end

        def order_violation_detected?
          required_order_for_elements_seen != class_elements_seen
        end

        def required_order_for_elements_seen
          class_elements_seen.sort do |class_elem_1, class_elem_2|
            required_order.index(class_elem_1) <=> required_order.index(class_elem_2)
          end
        end

        def validate_config!
          required_order.each do |i|
            if !KNOWN_ELEMENTS.include?(i)
              raise(InvalidConfigError, "Unknown 'required_order' model element: #{i}")
            end
          end

          required_comments.keys.each do |i|
            if !KNOWN_ELEMENTS.include?(i)
              raise(InvalidConfigError, "Unknown 'required_comments' model element: #{i}")
            end
          end
        end
      end
    end
  end
end
