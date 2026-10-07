# frozen_string_literal: true

module KeystoneUi
  module Preferences
    class Refusal
      attr_reader :message

      def initialize(message)
        @message = message
      end

      def ok? = false
    end
  end
end
