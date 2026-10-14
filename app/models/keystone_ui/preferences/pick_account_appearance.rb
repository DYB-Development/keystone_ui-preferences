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
        ComponentPreference.find_or_initialize_by(owner: @account, component_key: "colours").update!(value: { "template_name" => @values[:template_name] })
        Kept.new
      end
    end
  end
end
