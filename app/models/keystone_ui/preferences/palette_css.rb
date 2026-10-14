# frozen_string_literal: true

module KeystoneUi
  module Preferences
    class PaletteCss
      def initialize(accent:, surface:, background:, text:)
        @accent = accent
        @surface = surface
        @background = background
        @text = text
      end

      def to_s
        lines = shade_lines("accent", shades(@accent) { KeystoneUi::Looks::Palettes.accent(@accent) }) + shade_lines("surface", shades(@surface) { KeystoneUi::Looks::Palettes.surface(@surface) })
        ":root {\n#{lines.join("\n")}\n}"
      end

      private

      def shades(colour)
        return KeystoneUi::Looks::Palettes.generate_shades(colour) if colour.start_with?("#")

        yield
      end

      def shade_lines(name, shades)
        shades.map { |shade, hex| "  --color-#{name}-#{shade}: #{hex};" }
      end
    end
  end
end
