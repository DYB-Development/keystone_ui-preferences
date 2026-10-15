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
        ThemeCss.new(palette: { accent: @accent, surface: @surface, background: @background, text: @text }).to_s
      end
    end
  end
end
