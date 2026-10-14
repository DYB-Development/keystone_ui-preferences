# frozen_string_literal: true

module KeystoneUi
  module Preferences
    class PickAccountAppearance
      def initialize(values:, person: nil, account: nil)
        @person = person
        @account = account
        @values = values
      end

      def call
        chosen = ChosenColours.new(@values)
        return chosen.refusal if chosen.refusal

        ComponentPreference.find_or_initialize_by(owner: @account, component_key: "colours").update!(value: chosen.value)
        Kept.new
      end
    end
  end
end
