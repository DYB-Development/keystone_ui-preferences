# frozen_string_literal: true

module KeystoneUi
  module Preferences
    class Engine < ::Rails::Engine
      isolate_namespace KeystoneUi::Preferences

      initializer "keystone_ui.preferences.supplier" do
        KeystoneUi.configure do |config|
          config.preference_supplier = lambda do |view, component_key|
            view.keystone_component_preference(component_key) if view.respond_to?(:keystone_component_preference)
          end
        end
      end

      initializer "keystone_ui.preferences.theme_mode" do
        KeystoneUi.configure do |config|
          config.theme_mode_supplier = lambda do |view|
            view.respond_to?(:keystone_theme_mode) ? view.keystone_theme_mode : KeystoneUi::Preferences.configuration.default_mode
          end
        end
      end
    end
  end
end
