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
        @preferences ||= begin
          owners = [ @person, @account ].compact
          cached = owners.map { |owner| Rails.cache.read(cache_key(owner)) }.compact
          missing = owners.reject { |owner| cached.any? { |preference| preference.owned_by?(owner) } }
          cached + read_and_cache(missing)
        end
      end

      def read_and_cache(owners)
        return [] if owners.empty?

        ComponentPreference.where(owner: owners, component_key: @component_key).to_a.each do |preference|
          Rails.cache.write(cache_key(preference.owner_type, preference.owner_id), preference)
        end
      end

      def cache_key(owner_or_type, id = nil)
        type, id = id ? [ owner_or_type, id ] : [ owner_or_type.class.base_class.name, owner_or_type.id ]
        [ "keystone_ui_preferences", type, id, @component_key ].join("/")
      end
    end
  end
end
