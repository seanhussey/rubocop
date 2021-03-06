# encoding: utf-8

module RuboCop
  module Cop
    module Style
      # This cop checks for strings that are just an interpolated expression.
      #
      # @example
      #
      #   # bad
      #   "#{@var}"
      #
      #   # good
      #   @var.to_s
      #
      #   # good if @var is already a String
      #   @var
      class UnneededInterpolation < Cop
        include PercentLiteral

        MSG = 'Prefer `to_s` over string interpolation.'

        VARIABLE_INTERPOLATION_TYPES = [
          :ivar, :cvar, :gvar,
          :back_ref, :nth_ref
        ].freeze

        def on_dstr(node)
          add_offense(node, :expression, MSG) if single_interpolation?(node)
        end

        private

        def single_interpolation?(node)
          single_child?(node) &&
            interpolation?(node.children.first) &&
            !implicit_concatenation?(node) &&
            !embedded_in_percent_array?(node)
        end

        def single_variable_interpolation?(node)
          single_child?(node) && variable_interpolation?(node.children.first)
        end

        def single_child?(node)
          node.children.size == 1
        end

        def interpolation?(node)
          variable_interpolation?(node) || node.type == :begin
        end

        def variable_interpolation?(node)
          VARIABLE_INTERPOLATION_TYPES.include?(node.type)
        end

        def implicit_concatenation?(node)
          node.parent && node.parent.type == :dstr
        end

        def embedded_in_percent_array?(node)
          node.parent &&
            node.parent.type == :array &&
            percent_literal?(node.parent)
        end

        def autocorrect(node)
          loc = node.loc
          embedded_node = node.children.first
          embedded_loc = embedded_node.loc

          if variable_interpolation?(embedded_node)
            replacement = "#{embedded_loc.expression.source}.to_s"
            ->(corrector) { corrector.replace(loc.expression, replacement) }
          elsif single_variable_interpolation?(embedded_node)
            variable_loc = embedded_node.children.first.loc
            replacement = "#{variable_loc.expression.source}.to_s"
            ->(corrector) { corrector.replace(loc.expression, replacement) }
          else
            lambda do |corrector|
              corrector.replace(loc.begin, '')
              corrector.replace(loc.end, '')
              corrector.replace(embedded_loc.begin, '(')
              corrector.replace(embedded_loc.end, ').to_s')
            end
          end
        end
      end
    end
  end
end
