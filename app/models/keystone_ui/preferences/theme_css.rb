# frozen_string_literal: true

module KeystoneUi
  module Preferences
    class ThemeCss
      VERSION = "1"
      HOVERS = { "primary" => "--ks-color-accent-hover", "secondary" => "--ks-color-neutral-hover", "destructive" => "--ks-color-danger-hover" }.freeze

      def initialize(theme)
        @theme = theme
      end

      def to_s
        ":root, html:root[data-look] {\n#{lines.join("\n")}\n}"
      end

      private

      def lines
        @theme.flat_map do |role, sides|
          ThemeRoles::ROLES.fetch(role)[:variables].flat_map { |variable| declarations(variable, sides) } + hover_declarations(role, sides)
        end
      end

      def hover_declarations(role, sides)
        return [] unless HOVERS.key?(role)

        declarations(HOVERS[role], sides.transform_values { |colour| "color-mix(in oklab, #{colour} 85%, white)" })
      end

      def declarations(variable, sides)
        { variable => sides["light"], "#{variable}-dark" => sides["dark"] }.compact.map { |name, value| "  #{name}: #{value};" }
      end
    end
  end
end
