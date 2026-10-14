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
        lines = KeystoneUi::Looks::Palettes.accent(@accent).map { |shade, hex| "  --color-accent-#{shade}: #{hex};" }
        ":root {\n#{lines.join("\n")}\n}"
      end
    end
  end
end
