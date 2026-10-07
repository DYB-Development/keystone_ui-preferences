# frozen_string_literal: true

module KeystoneUi
  module Preferences
    class LayoutChoice
      def initialize(person:, account:, component_key:)
        @person = person
        @account = account
        @component_key = component_key.to_s
      end

      def value
        return account_preference.value unless members_choose?

        (own_preference || account_preference)&.value
      end

      def members_choose?
        account_preference.nil? || account_preference.members_choose
      end

      private

      def own_preference
        preferences.find { |preference| preference.owned_by?(@person) }
      end

      def account_preference
        return nil unless @account

        preferences.find { |preference| preference.owned_by?(@account) }
      end

      def preferences
        @preferences ||= ComponentPreference.where(owner: [ @person, @account ].compact, component_key: @component_key).to_a
      end
    end
  end
end
