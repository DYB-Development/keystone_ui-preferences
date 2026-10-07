# frozen_string_literal: true

module KeystoneUi
  module Preferences
    class Configuration
      attr_accessor :current_owner_method, :authentication_method, :current_account_method, :max_value_bytes

      def initialize
        @current_owner_method = :current_user
        @authentication_method = :authenticate_user!
        @component_names = {}
        @max_value_bytes = 10_000
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
