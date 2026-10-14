# frozen_string_literal: true

module KeystoneUi
  module Preferences
    class PickAppearance
      def initialize(values:, person: nil, account: nil)
        @person = person
        @account = account
        @values = values
      end

      def call
        preference.update!(value: { "template_name" => @values[:template_name] })
        Kept.new
      end

      private

      def preference
        @preference ||= ComponentPreference.find_or_initialize_by(owner: @person, component_key: "colours")
      end
    end
  end
end
