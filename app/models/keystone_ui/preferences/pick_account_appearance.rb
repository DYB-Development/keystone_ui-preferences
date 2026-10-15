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
        return Refusal.new("There is no account to save this appearance on.") unless @account
        return Refusal.new("Choose the app's own look or one of the looks it offers.") unless look_offered?

        return Refusal.new("This app does not let accounts choose their colours.") if colours_sent? && !KeystoneUi::Preferences.configuration.account_colors

        chosen = chosen_colours
        return chosen.refusal if chosen&.refusal

        keep("colours", (chosen ? { value: chosen.value } : {}).merge(switch(:members_choose)))
        keep_look
        Kept.new
      end

      private

      def colours_sent?
        @values.key?(:template_name) || sent_theme.sent?
      end

      def chosen_colours
        return sent_theme.checked if sent_theme.sent?

        ChosenColours.new(@values) if colours_sent?
      end

      def sent_theme
        @sent_theme ||= SentTheme.new(@values) { ComponentPreference.find_by(owner: @account, component_key: "colours")&.value.to_h }
      end

      def look_offered?
        !look_sent? || @values[:look].blank? || KeystoneUi.configuration.looks.key?(@values[:look])
      end

      def keep_look
        chosen = look_sent? ? { value: { "look" => @values[:look].presence }.compact } : {}
        keep("look", chosen.merge(switch(:members_choose_look)))
      end

      def look_sent?
        @values.key?(:look) && KeystoneUi::Preferences.configuration.account_looks
      end

      def keep(component_key, changes)
        ComponentPreference.find_or_initialize_by(owner: @account, component_key: component_key).update!(changes) if changes.any?
      end

      def switch(name)
        @values.key?(name) ? { members_choose: @values[name] == "1" } : {}
      end
    end
  end
end
