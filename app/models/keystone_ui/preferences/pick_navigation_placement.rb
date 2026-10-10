# frozen_string_literal: true

module KeystoneUi
  module Preferences
    class PickNavigationPlacement
      PLACEMENTS = %w[top left right].freeze

      def initialize(values:, person: nil, account: nil)
        @person = person
        @account = account
        @values = values
      end

      def call
        return Refusal.new("Choose Top, Left or Right for the navigation.") unless PLACEMENTS.include?(@values[:placement])

        preference = ComponentPreference.find_or_initialize_by(owner: @person, component_key: "navigation")
        preference.update!(value: { "placement" => @values[:placement] })
        Kept.new
      end
    end
  end
end
