# frozen_string_literal: true

require "json"

module KeystoneUi
  module Preferences
    class PickNavigationOrder
      def initialize(values:, person: nil, account: nil)
        @person = person
        @account = account
        @values = values
      end

      def call
        order = submitted_order
        return Refusal.new("Choose an order for the navigation's groups and tabs.") unless order.is_a?(Array)

        preference = ComponentPreference.find_or_initialize_by(owner: @person, component_key: "navigation")
        preference.update!(value: preference.value.to_h.merge("order" => order))
        Kept.new
      end

      private

      def submitted_order
        JSON.parse(@values[:order].to_s)
      rescue JSON::ParserError
        nil
      end
    end
  end
end
