# encoding: utf-8

module RuboCop
  module Cop
    module Lint
      # This cop checks for nested method definitions.
      #
      # @example
      #   # `bar` definition actually produces methods in the same scope
      #   # as the outer `foo` method. Furthermore, the `bar` method
      #   # will be redefined every time `foo` is invoked.
      #   def foo
      #     def bar
      #     end
      #   end
      #
      class NestedMethodDefinition < Cop
        include OnMethodDef
        extend RuboCop::NodePattern::Macros

        MSG = 'Method definitions must not be nested. ' \
              'Use `lambda` instead.'

        def_node_matcher :eval_call?, <<-PATTERN
          (block (send _ {:instance_eval :class_eval :module_eval} ...) ...)
        PATTERN

        def on_method_def(node, _method_name, _args, _body)
          find_nested_defs(node) do |nested_def_node|
            add_offense(nested_def_node, :expression)
          end
        end

        def find_nested_defs(node, &block)
          node.each_child_node do |child|
            if child.def_type? || child.defs_type?
              block.call(child)
            elsif !eval_call?(child)
              find_nested_defs(child, &block)
            end
          end
        end
      end
    end
  end
end
