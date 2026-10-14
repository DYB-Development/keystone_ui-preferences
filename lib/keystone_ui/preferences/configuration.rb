# frozen_string_literal: true

module KeystoneUi
  module Preferences
    class Configuration
      attr_accessor :current_owner_method, :authentication_method, :current_account_method, :max_value_bytes, :default_accent, :default_surface, :default_background, :default_text, :default_mode, :user_looks, :app_look_label, :account_colors

      def initialize
        @current_owner_method = :current_user
        @authentication_method = :authenticate_user!
        @component_names = {}
        @max_value_bytes = 10_000
        @default_accent = "blue"
        @default_surface = "zinc"
        @default_background = "#ffffff"
        @default_text = "#18181b"
        @default_mode = "light"
        @user_looks = true
        @app_look_label = "Classic"
        @account_colors = true
      end

      def name_component(component_key, name)
        @component_names[component_key.to_s] = name
      end

      def component_name(component_key)
        @component_names.fetch(component_key.to_s) { component_key.to_s.humanize }
      end
    end

    def self.configuration
      @configuration ||= Configuration.new
    end

    def self.configure
      yield(configuration)
    end

    def self.reset_configuration!
      @configuration = Configuration.new
    end
  end
end
