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
        return Refusal.new("Your account sets the colours for everyone, so this was not saved.") unless members_choose?
        return use_default if @values[:template_name] == AppearanceChoice::DEFAULT_TEMPLATE
        return Refusal.new("Choose Default, one of the colour templates or Custom.") unless template_offered?

        preference.update!(value: chosen_colours)
        Kept.new
      end

      private

      def members_choose?
        LayoutChoice.new(person: @person, account: @account, component_key: "colours").members_choose?
      end

      def template_offered?
        @values[:template_name].blank? || KeystoneUi::Looks::Templates.names.map(&:to_s).include?(@values[:template_name])
      end

      def use_default
        preference.destroy! if preference.persisted?
        Kept.new
      end

      def chosen_colours
        return { "template_name" => @values[:template_name] } if @values[:template_name].present?

        { "accent" => @values[:accent], "surface" => @values[:surface], "text" => @values[:text] }
      end

      def preference
        @preference ||= ComponentPreference.find_or_initialize_by(owner: @person, component_key: "colours")
      end
    end
  end
end
