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
        return Refusal.new("Choose Light, Dark, System or Custom for the mode.") unless mode_offered?
        return keep_mode_and_look unless @values.key?(:template_name)
        return Refusal.new("Your account sets the colours for everyone, so this was not saved.") unless members_choose?
        return use_default if @values[:template_name] == AppearanceChoice::DEFAULT_TEMPLATE
        return Refusal.new("Choose Default, one of the colour templates or Custom.") unless template_offered?
        return Refusal.new("Choose each colour as a six-digit hex value, such as #1d4ed8.") unless colours_offered?

        preference.update!(value: chosen_colours)
        keep_mode_and_look
      end

      private

      def mode_offered?
        !@values.key?(:mode) || KeystoneUi::ThemeChoice::MODES.include?(@values[:mode])
      end

      def members_choose?
        LayoutChoice.new(person: @person, account: @account, component_key: "colours").members_choose?
      end

      def template_offered?
        @values[:template_name].blank? || KeystoneUi::Looks::Templates.names.map(&:to_s).include?(@values[:template_name])
      end

      def colours_offered?
        return true if @values[:template_name].present?

        colour_offered?(@values[:accent], KeystoneUi::Looks::Palettes::ACCENTS) && colour_offered?(@values[:surface], KeystoneUi::Looks::Palettes::SURFACES) && colour_offered?(@values[:text], {})
      end

      def colour_offered?(colour, palettes)
        colour.to_s.match?(AppearanceChoice::HEX) || palettes.key?(colour.to_s.to_sym)
      end

      def use_default
        preference.destroy! if preference.persisted?
        keep_mode_and_look
      end

      def chosen_colours
        return { "template_name" => @values[:template_name] } if @values[:template_name].present?

        { "accent" => @values[:accent], "surface" => @values[:surface], "text" => @values[:text] }
      end

      def keep_mode_and_look
        keep_mode
        keep_look
        Kept.new
      end

      def keep_mode
        return unless @values.key?(:mode)

        ComponentPreference.find_or_initialize_by(owner: @person, component_key: "mode").update!(value: { "mode" => @values[:mode] })
      end

      def keep_look
        return unless @values.key?(:look)

        ComponentPreference.find_or_initialize_by(owner: @person, component_key: "look").update!(value: { "look" => @values[:look] })
      end

      def preference
        @preference ||= ComponentPreference.find_or_initialize_by(owner: @person, component_key: "colours")
      end
    end
  end
end
