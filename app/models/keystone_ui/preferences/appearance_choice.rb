# frozen_string_literal: true

module KeystoneUi
  module Preferences
    class AppearanceChoice
      def initialize(person:, account:)
        @person = person
        @account = account
      end

      def colours
        configuration = KeystoneUi::Preferences.configuration
        { accent: configuration.default_accent, surface: configuration.default_surface, background: configuration.default_background, text: configuration.default_text }
      end
    end
  end
end
