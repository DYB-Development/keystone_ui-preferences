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
        return Refusal.new("Choose the app's own look or one of the looks it offers.") unless look_offered?

        chosen = ChosenColours.new(@values)
        return chosen.refusal if chosen.refusal

        ComponentPreference.find_or_initialize_by(owner: @account, component_key: "colours").update!(value: chosen.value, **switch(:members_choose))
        keep_look
        Kept.new
      end

      private

      def look_offered?
        @values[:look].blank? || KeystoneUi.configuration.looks.key?(@values[:look])
      end

      def keep_look
        chosen = @values.key?(:look) ? { value: { "look" => @values[:look].presence }.compact } : {}
        changes = chosen.merge(switch(:members_choose_look))
        ComponentPreference.find_or_initialize_by(owner: @account, component_key: "look").update!(changes) if changes.any?
      end

      def switch(name)
        @values.key?(name) ? { members_choose: @values[name] == "1" } : {}
      end
    end
  end
end
