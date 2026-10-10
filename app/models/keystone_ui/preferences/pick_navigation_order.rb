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
        preference = ComponentPreference.find_or_initialize_by(owner: @person, component_key: "navigation")
        preference.update!(value: { "order" => JSON.parse(@values[:order]) })
        Kept.new
      end
    end
  end
end
