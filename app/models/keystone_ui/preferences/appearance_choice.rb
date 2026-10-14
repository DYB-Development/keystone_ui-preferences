# frozen_string_literal: true

module KeystoneUi
  module Preferences
    class AppearanceChoice
      def initialize(person:, account:)
        @person = person
        @account = account
      end

      def colours
        surface = saved["surface"] || configuration.default_surface
        {
          accent: saved["accent"] || configuration.default_accent,
          surface: surface,
          background: surface.start_with?("#") ? surface : configuration.default_background,
          text: saved["text"].presence || configuration.default_text
        }
      end

      private

      def saved
        @saved ||= LayoutChoice.new(person: @person, account: @account, component_key: "colours").value.to_h
      end

      def configuration
        KeystoneUi::Preferences.configuration
      end
    end
  end
end
