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
        ComponentPreference.find_or_initialize_by(owner: @account, component_key: "colours").update!(value: chosen_colours)
        Kept.new
      end

      private

      def chosen_colours
        return { "template_name" => @values[:template_name] } if @values[:template_name].present?

        { "accent" => @values[:accent], "surface" => @values[:surface], "text" => @values[:text] }
      end
    end
  end
end
