# frozen_string_literal: true

module KeystoneUi
  module Preferences
    class ApplicationController < ::ApplicationController
      before_action { send(KeystoneUi::Preferences.configuration.authentication_method) }

      private

      def current_owner
        send(KeystoneUi::Preferences.configuration.current_owner_method)
      end
    end
  end
end
