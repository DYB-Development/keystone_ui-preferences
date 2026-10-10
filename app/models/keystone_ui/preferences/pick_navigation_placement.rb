# frozen_string_literal: true

module KeystoneUi
  module Preferences
    class PickNavigationPlacement
      def initialize(values:, person: nil, account: nil)
        @person = person
        @account = account
        @values = values
      end

      def call
        preference = ComponentPreference.find_or_initialize_by(owner: @person, component_key: "navigation")
        preference.update!(value: { "placement" => @values[:placement] })
        Kept.new
      end
    end
  end
end
