# frozen_string_literal: true

module KeystoneUi
  module Preferences
    class ThemeCss
      def initialize(theme)
        @theme = theme
      end

      def to_s
        ":root {\n#{lines.join("\n")}\n}"
      end

      private

      def lines
        @theme.flat_map do |role, sides|
          ThemeRoles::ROLES.fetch(role)[:variables].flat_map { |variable| declarations(variable, sides) }
        end
      end

      def declarations(variable, sides)
        { variable => sides["light"], "#{variable}-dark" => sides["dark"] }.compact.map { |name, value| "  #{name}: #{value};" }
      end
    end
  end
end
