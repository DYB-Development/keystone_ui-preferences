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

        preference = ComponentPreference.find_or_initialize_by(owner: @account, component_key: @values[:component_key])
        if @values[:use_mine] == "1"
          preference.update!(value: ComponentPreference.find_by!(owner: @person, component_key: @values[:component_key]).value)
        else
          preference.update!(members_choose: @values[:members_choose] == "1")
        end
        Kept.new
      end
    end
  end
end
