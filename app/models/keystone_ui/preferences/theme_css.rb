# frozen_string_literal: true

module KeystoneUi
  module Preferences
    class ThemeCss
      VERSION = "2"
      SHADOW_SETTINGS = %w[shadow-offset-x shadow-offset-y shadow-blur shadow-spread shadow-color shadow-opacity].freeze
      SHADOWS = %w[--ks-shadow-surface --ks-shadow-overlay --ks-shadow-menu].freeze
      HOVERS = { "primary" => "--ks-color-accent-hover", "secondary" => "--ks-color-neutral-hover", "destructive" => "--ks-color-danger-hover" }.freeze

      OUTRANKING_LOOKS = ":root, html:root[data-look]"

      def initialize(theme, own_look: false)
        @theme = theme
        @own_look = own_look
      end

      def to_s
        rules = @own_look ? { OUTRANKING_LOOKS => colour_lines, ":root" => shape_lines } : { OUTRANKING_LOOKS => colour_lines + shape_lines }
        rules.map { |selector, lines| "#{selector} {\n#{lines.join("\n")}\n}" }.join("\n")
      end

      private

      def colour_lines
        lines(@theme.select { |role, _sides| colour?(role) })
      end

      def shape_lines
        lines(@theme.reject { |role, _sides| colour?(role) }) + shadow_declarations
      end

      def colour?(role)
        ThemeRoles::ROLES.fetch(role)[:kind] == :colour
      end

      def lines(roles)
        roles.flat_map do |role, sides|
          ThemeRoles::ROLES.fetch(role)[:variables].flat_map { |variable| declarations(variable, sides) } + hover_declarations(role, sides)
        end
      end

      def shadow_declarations
        x, y, blur, spread, colour, opacity = SHADOW_SETTINGS.map { |setting| @theme.dig(setting, "light") }
        return [] unless x && y && blur && spread && colour && opacity

        SHADOWS.map { |variable| "  #{variable}: #{x} #{y} #{blur} #{spread} color-mix(in srgb, #{colour} calc(#{opacity} * 100%), transparent);" }
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
