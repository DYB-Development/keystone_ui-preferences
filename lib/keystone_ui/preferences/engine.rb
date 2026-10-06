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
    end
  end
end
