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
        return Refusal.new("There is no account to save this appearance on.") unless @account

        chosen = ChosenColours.new(@values)
        return chosen.refusal if chosen.refusal

        ComponentPreference.find_or_initialize_by(owner: @account, component_key: "colours").update!(value: chosen.value, **switch(:members_choose))
        Kept.new
      end

      private

      def switch(name)
        @values.key?(name) ? { members_choose: @values[name] == "1" } : {}
      end
    end
  end
end
