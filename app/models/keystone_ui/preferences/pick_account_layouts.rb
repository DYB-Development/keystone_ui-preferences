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
        preference = ComponentPreference.find_or_initialize_by(owner: @account, component_key: @values[:component_key])
        preference.update!(members_choose: @values[:members_choose] == "1")
      end
    end
  end
end
