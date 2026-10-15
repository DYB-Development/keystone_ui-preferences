# frozen_string_literal: true

module KeystoneUi
  module Preferences
    class ColorsCheck
      class Error < StandardError; end

      MESSAGE = "keystone_ui-preferences and keystone_ui-colors both save colours, modes and looks, so the app cannot load both. " \
        "Remove keystone_ui-colors from the Gemfile and change every KeystoneUi::Colors name the app uses first, " \
        "then run bin/rails generate keystone_ui:preferences:update, so the migration copying keystone_ui-colors' saved choices is in db/migrate, " \
        "and then run bin/rails db:migrate."

      def initialize(colors_loaded:)
        @colors_loaded = colors_loaded
      end

      def call
        raise Error, MESSAGE if @colors_loaded
      end
    end
  end
end
