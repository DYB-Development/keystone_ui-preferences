# frozen_string_literal: true

module KeystoneUi
  module Preferences
    class PickAccountLayouts
      def initialize(values:, person: nil, account: nil)
        @person = person
        @account = account
        @values = values
      end

      def call
        return Refusal.new("There is no account to save this layout on.") unless @account

        @values[:use_mine] == "1" ? share_mine : set_members_choose
      end

      private

      def share_mine
        mine = ComponentPreference.find_by(owner: @person, component_key: component_key)
        return Refusal.new("You have no saved layout for this table to share.") unless mine

        account_preference.update!(value: mine.value)
        Kept.new
      end

      def set_members_choose
        account_preference.update!(members_choose: @values[:members_choose] == "1")
        Kept.new
      end

      def account_preference
        @account_preference ||= ComponentPreference.find_or_initialize_by(owner: @account, component_key: component_key)
      end

      def component_key
        @values[:component_key]
      end
    end
  end
end
