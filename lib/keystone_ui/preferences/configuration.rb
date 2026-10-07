# frozen_string_literal: true

module KeystoneUi
  module Preferences
    class Configuration
      attr_accessor :current_owner_method, :authentication_method, :current_account_method

      def initialize
        @current_owner_method = :current_user
        @authentication_method = :authenticate_user!
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
