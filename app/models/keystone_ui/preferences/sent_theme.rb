# frozen_string_literal: true

module KeystoneUi
  module Preferences
    class SentTheme
      def initialize(values, &saved_colours)
        @values = values
        @saved_colours = saved_colours
      end

      def sent?
        pasting? || editing?
      end

      def checked
        return pasted if pasting?

        CheckedTheme.new(typed)
      end

      private

      def pasting?
        @values[:pasted_theme].present?
      end

      def editing?
        typed.any? && [ saved["theme"], *preset_themes ].exclude?(typed)
      end

      def preset_themes
        KeystoneUi::Looks::Themes.names.map { |name| KeystoneUi::Looks::Themes[name][:theme] }
      end

      def saved
        @saved ||= @saved_colours.call
      end

      def typed
        @typed ||= @values[:theme].to_h.to_h { |name, sides| [ name.to_s, sides.to_h.to_h { |side, value| [ side.to_s, value.to_s.strip ] }.compact_blank ] }.compact_blank
      end

      def pasted
        reader = ThemeReader.new(@values[:pasted_theme])
        reader.refusal ? reader : CheckedTheme.new(reader.values)
      end
    end
  end
end
