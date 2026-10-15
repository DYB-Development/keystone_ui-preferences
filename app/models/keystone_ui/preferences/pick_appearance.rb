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
        return Refusal.new("Choose the app's own look or one of the looks it offers.") unless look_offered?
        return keep_mode_and_look unless @values.key?(:template_name) || pasting?
        return Refusal.new("This app sets the colours for everyone, so this was not saved.") unless KeystoneUi::Preferences.configuration.account_colors
        return Refusal.new("Your account sets the colours for everyone, so this was not saved.") unless members_choose?
        return keep_theme if pasting?
        return use_default if @values[:template_name] == AppearanceChoice::DEFAULT_TEMPLATE

        chosen = ChosenColours.new(@values)
        return chosen.refusal if chosen.refusal

        preference.update!(value: chosen.value)
        keep_mode_and_look
      end

      private

      def mode_offered?
        !@values.key?(:mode) || KeystoneUi::ThemeChoice::MODES.include?(@values[:mode])
      end

      def look_offered?
        !look_sent? || @values[:look].blank? || KeystoneUi.configuration.looks.key?(@values[:look])
      end

      def members_choose?
        LayoutChoice.new(person: @person, account: @account, component_key: "colours").members_choose?
      end

      def pasting?
        @values[:pasted_theme].present?
      end

      def keep_theme
        reader = ThemeReader.new(@values[:pasted_theme])
        return reader.refusal if reader.refusal

        checked = CheckedTheme.new(reader.values)
        return checked.refusal if checked.refusal

        preference.update!(value: checked.value)
        keep_mode_and_look
      end

      def use_default
        preference.destroy! if preference.persisted?
        keep_mode_and_look
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
        return unless look_sent?
        return look_preference.update!(value: { "look" => @values[:look] }) if @values[:look].present?

        look_preference.destroy! if look_preference.persisted?
      end

      def look_sent?
        @values.key?(:look) && AppearanceChoice.new(person: @person, account: @account).person_chooses_look?
      end

      def look_preference
        @look_preference ||= ComponentPreference.find_or_initialize_by(owner: @person, component_key: "look")
      end

      def preference
        @preference ||= ComponentPreference.find_or_initialize_by(owner: @person, component_key: "colours")
      end
    end
  end
end
