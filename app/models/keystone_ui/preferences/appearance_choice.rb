# frozen_string_literal: true

module KeystoneUi
  module Preferences
    class AppearanceChoice
      DEFAULT_TEMPLATE = "default"
      HEX = /\A#\h{6}\z/
      PALETTE_NAME = /\A[a-z][a-z0-9_]*\z/
      WHITE = "#ffffff"

      def initialize(person:, account:)
        @person = person
        @account = account
      end

      def colours
        return default_colours unless configuration.account_colors
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

      def mode
        LayoutChoice.new(person: @person, account: nil, component_key: "mode").value.to_h["mode"] || configuration.default_mode
      end

      def look
        return nil unless @person

        [ (saved_look(@person) if person_chooses_look?), (saved_look(@account) if configuration.account_looks) ].find { |look| KeystoneUi.configuration.looks.key?(look) }
      end

      def person_chooses_look?
        configuration.user_looks && LayoutChoice.new(person: @person, account: @account, component_key: "look").members_choose?
      end

      def custom_offered?
        !colours[:background].casecmp?(WHITE)
      end

      private

      def saved_look(owner)
        LayoutChoice.new(person: owner, account: nil, component_key: "look").value.to_h["look"]
      end

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
