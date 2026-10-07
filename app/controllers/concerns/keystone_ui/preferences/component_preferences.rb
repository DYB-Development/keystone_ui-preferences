# frozen_string_literal: true

require "active_support/concern"

module KeystoneUi
  module Preferences
    module ComponentPreferences
      extend ActiveSupport::Concern

      included do
        helper_method :keystone_component_preference if respond_to?(:helper_method)
      end

      def keystone_component_preference(component_key)
        owner = send(KeystoneUi::Preferences.configuration.current_owner_method)
        return unless owner

        choice = LayoutChoice.new(person: owner, account: keystone_preferences_account, component_key: component_key)
        {
          value: choice.value,
          save_url: keystone_ui_preferences.component_preference_path(component_key: component_key)
        }
      end

      def keystone_preferences_account
        method = KeystoneUi::Preferences.configuration.current_account_method
        send(method) if method
      end
    end
  end
end
