# frozen_string_literal: true

module KeystoneUi
  module Preferences
    class ThemeCss
      VERSION = "2"
      SHADOW_SETTINGS = %w[shadow-offset-x shadow-offset-y shadow-blur shadow-spread shadow-color shadow-opacity].freeze
      SHADOWS = %w[--ks-shadow-surface --ks-shadow-overlay --ks-shadow-menu].freeze
      HOVERS = { "primary" => "--ks-color-accent-hover", "secondary" => "--ks-color-neutral-hover", "destructive" => "--ks-color-danger-hover" }.freeze

      OUTRANKING_LOOKS = ":root, html:root[data-look]"

      def initialize(theme = {}, own_look: false, palette: nil)
        @theme = theme
        @own_look = own_look
        @palette = palette
      end

      def to_s
        rules.map { |selector, lines| "#{selector} {\n#{lines.join("\n")}\n}" }.join("\n")
      end

      private

      def rules
        return { ":root" => palette_lines } if @palette
        return { OUTRANKING_LOOKS => colour_lines, ":root" => shape_lines } if @own_look

        { OUTRANKING_LOOKS => colour_lines + shape_lines }
      end

      def palette_lines
        accent, surface, background, text = @palette.values_at(:accent, :surface, :background, :text)
        shade_lines("accent", shades(accent) { KeystoneUi::Looks::Palettes.accent(accent) }) +
          shade_lines("surface", shades(surface) { KeystoneUi::Looks::Palettes.surface(surface) }) +
          [ declaration("--color-custom-background", background), declaration("--color-custom-text", text) ]
      end

      def shades(colour)
        return KeystoneUi::Looks::Palettes.generate_shades(colour) if colour.start_with?("#")

        yield
      end

      def shade_lines(name, shades)
        shades.map { |shade, hex| declaration("--color-#{name}-#{shade}", hex) }
      end

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

        SHADOWS.map { |variable| declaration(variable, "#{x} #{y} #{blur} #{spread} color-mix(in srgb, #{colour} calc(#{opacity} * 100%), transparent)") }
      end

      def hover_declarations(role, sides)
        return [] unless HOVERS.key?(role)

        declarations(HOVERS[role], sides.transform_values { |colour| "color-mix(in oklab, #{colour} 85%, white)" })
      end

      def declarations(variable, sides)
        { variable => sides["light"], "#{variable}-dark" => sides["dark"] }.compact.map { |name, value| declaration(name, value) }
      end

      def declaration(name, value)
        "  #{name}: #{value};"
      end
    end
  end
end
