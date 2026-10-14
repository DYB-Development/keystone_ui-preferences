# frozen_string_literal: true

module KeystoneUi
  module Preferences
    class AppearanceChoice
      DEFAULT_TEMPLATE = "default"
      HEX = /\A#\h{6}\z/
      PALETTE_NAME = /\A[a-z][a-z0-9_]*\z/

      def initialize(person:, account:)
        @person = person
        @account = account
      end

      def colours
        return default_colours if saved["template_name"] == DEFAULT_TEMPLATE
        return template_colours if saved["template_name"].present?

        surface = palette_colour(saved["surface"]) || configuration.default_surface
        {
          accent: palette_colour(saved["accent"]) || configuration.default_accent,
          surface: surface,
          background: surface.start_with?("#") ? surface : configuration.default_background,
          text: (saved["text"] if saved["text"].to_s.match?(HEX)) || configuration.default_text
        }
      end

      private

      def palette_colour(value)
        value if value.to_s.match?(HEX) || value.to_s.match?(PALETTE_NAME)
      end

      def default_colours
        { accent: configuration.default_accent, surface: configuration.default_surface, background: configuration.default_background, text: configuration.default_text }
      end

      def template_colours
        template = KeystoneUi::Looks::Templates[saved["template_name"]]
        { accent: template[:accent].to_s, surface: template[:surface].to_s, background: template[:background], text: template[:text] }
      end

      def saved
        @saved ||= LayoutChoice.new(person: @person, account: @account, component_key: "colours").value.to_h
      end

      def configuration
        KeystoneUi::Preferences.configuration
      end
    end
  end
end
