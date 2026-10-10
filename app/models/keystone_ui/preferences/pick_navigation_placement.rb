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
        return Refusal.new("Your account sets the navigation for everyone, so this was not saved.") unless members_choose?
        return Refusal.new("Choose Top, Left or Right for the navigation.") unless PLACEMENTS.include?(@values[:placement])

        preference = ComponentPreference.find_or_initialize_by(owner: @person, component_key: "navigation")
        preference.update!(value: preference.value.to_h.merge("placement" => @values[:placement]))
        Kept.new
      end

      private

      def members_choose?
        LayoutChoice.new(person: @person, account: @account, component_key: "navigation").members_choose?
      end
    end
  end
end
