# frozen_string_literal: true

require "keystone_ui/preferences/colors_check"

module KeystoneUi
  module Preferences
    class Engine < ::Rails::Engine
      isolate_namespace KeystoneUi::Preferences

      def self.check_colors
        KeystoneUi::Preferences::ColorsCheck.new(colors_loaded: KeystoneUi.const_defined?(:Colors, false)).call
      end

      config.after_initialize do
        KeystoneUi::Preferences::Engine.check_colors
      end

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

      initializer "keystone_ui.preferences.look" do
        KeystoneUi.configure do |config|
          config.look_supplier = ->(view) { view.keystone_look if view.respond_to?(:keystone_look) }
        end
      end
    end
  end
end
