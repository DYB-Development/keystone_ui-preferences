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
        typed.any? && [ saved["theme"], preset_theme(saved["preset_name"]), preset_theme(@values[:template_name]) ].exclude?(typed)
      end

      def saved
        @saved ||= @saved_colours.call
      end

      def preset_theme(name)
        KeystoneUi::Looks::Themes[name][:theme] if KeystoneUi::Looks::Themes.names.map(&:to_s).include?(name.to_s)
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
