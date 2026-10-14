# frozen_string_literal: true

require "active_support/concern"

module KeystoneUi
  module Preferences
    module ComponentPreferences
      extend ActiveSupport::Concern

      included do
        helper_method :keystone_component_preference, :keystone_palette_style_tag, :keystone_theme_mode, :keystone_look if respond_to?(:helper_method)
      end

      class_methods do
        def keystone_host_colors
          before_action :keystone_keep_host_colours
        end
      end

      def keystone_component_preference(component_key)
        owner = send(KeystoneUi::Preferences.configuration.current_owner_method)
        return unless owner

        choice = keystone_layout_choice(component_key)
        {
          value: choice.value,
          save_url: (keystone_ui_preferences.component_preference_path(component_key: component_key) if choice.members_choose?)
        }
      end

      def keystone_palette_style_tag
        colours = keystone_appearance_choice.colours
        helpers.content_tag(:style, PaletteCss.new(**colours).to_s)
      end

      def keystone_theme_mode
        keystone_appearance_choice.mode
      end

      def keystone_look
        AppearanceChoice.new(person: send(KeystoneUi::Preferences.configuration.current_owner_method), account: keystone_preferences_account).look
      end

      def keystone_layout_choice(component_key)
        LayoutChoice.new(person: send(KeystoneUi::Preferences.configuration.current_owner_method), account: keystone_preferences_account, component_key: component_key)
      end

      def keystone_preferences_account
        method = KeystoneUi::Preferences.configuration.current_account_method
        send(method) if method
      end

      private

      def keystone_keep_host_colours
        @keystone_host_colours = true
      end

      def keystone_appearance_choice
        return AppearanceChoice.new(person: nil, account: nil) if @keystone_host_colours

        AppearanceChoice.new(person: send(KeystoneUi::Preferences.configuration.current_owner_method), account: keystone_preferences_account)
      end

      def after_settings_change(section:, **)
        cookies.delete(KeystoneUi::ThemeChoice::COOKIE) if section.runs.to_s == PickAppearance.name
      end
    end
  end
end
