# frozen_string_literal: true

module KeystoneUi
  module Preferences
    class CheckedTheme
      NUMBER = '-?(?:\d+(?:\.\d+)?|\.\d+)%?'
      GAP = '(?:\s*,\s*|\s+)'
      HEX = /\A#(?:\h{3}|\h{4}|\h{6}|\h{8})\z/
      FUNCTION = /\A(?:rgba?|hsla?|oklch)\(\s*#{NUMBER}#{GAP}#{NUMBER}#{GAP}#{NUMBER}(?:\s*[\/,]\s*#{NUMBER})?\s*\)\z/
      COLOUR = Regexp.union(HEX, FUNCTION)
      UNSIGNED_LENGTH = '(?:0|(?:\d+(?:\.\d+)?|\.\d+)(?:px|rem|em))'
      LENGTH = /\A#{UNSIGNED_LENGTH}\z/
      SIGNED_LENGTH = /\A-?#{UNSIGNED_LENGTH}\z/
      FONT_NAME = "[A-Za-z0-9-]+(?: [A-Za-z0-9-]+)*"
      FONT = "(?:#{FONT_NAME}|\"#{FONT_NAME}\"|'#{FONT_NAME}')"
      FONT_LIST = /\A#{FONT}(?:\s*,\s*#{FONT})*\z/
      WEIGHT = /\A[1-9]00\z/
      OPACITY = /\A(?:0(?:\.\d+)?|\.\d+|1(?:\.0+)?)\z/
      PATTERNS = {
        colour: COLOUR, shadow_colour: COLOUR, length: LENGTH, signed_length: SIGNED_LENGTH, opacity: OPACITY, weight: WEIGHT,
        letter_spacing: Regexp.union(SIGNED_LENGTH, /\Anormal\z/), font_list: FONT_LIST
      }.freeze
      REASONS = {
        shadow_colour: "is not hex, rgb(), hsl() or oklch() written with plain numbers",
        length: "is not a number followed by px, rem or em, or zero",
        signed_length: "is not a number followed by px, rem or em, or zero",
        opacity: "is not a number from 0 to 1",
        weight: "is not a font weight from 100 to 900 in hundreds",
        letter_spacing: "is not normal or a number followed by px, rem or em, or zero",
        font_list: "is not a list of font names made of letters, digits, spaces and hyphens"
      }.freeze
      SIDES = %w[light dark].freeze
      SYSTEM_FONTS = [
        "system-ui", "ui-sans-serif", "ui-serif", "ui-monospace", "ui-rounded", "sans-serif", "serif", "monospace", "cursive",
        "-apple-system", "BlinkMacSystemFont", "Segoe UI", "Roboto", "Helvetica", "Helvetica Neue", "Arial", "Georgia",
        "Times New Roman", "Menlo", "Monaco", "Consolas", "Courier New", "SFMono-Regular"
      ].freeze

      def initialize(values)
        @values = values
      end

      def refusal
        kept.each do |name, sides|
          kind = kind_of(name)
          sides.each do |side, value|
            return reason(kind, name, side) unless value.to_s.match?(PATTERNS.fetch(kind))
            return Refusal.new("The --#{name} value names no font this app offers, so it was not saved.") if kind == :font_list && offered_fonts(value).empty?
          end
        end
        nil
      end

      def value
        { "theme" => kept.to_h { |name, sides| [ name, kind_of(name) == :font_list ? sides.transform_values { |list| offered_fonts(list).map { |font| written_font(font) }.join(", ") } : sides ] } }
      end

      private

      def sides_of(name)
        kind_of(name) == :colour ? SIDES : SIDES.first(1)
      end

      def kind_of(name)
        ThemeRoles::ROLES.fetch(name)[:kind]
      end

      def offered_fonts(list)
        offered = (KeystoneUi::Preferences.configuration.theme_fonts + SYSTEM_FONTS).map(&:downcase)
        list.split(",").map { |font| font.strip.delete("\"'") }.select { |font| offered.include?(font.downcase) }
      end

      def written_font(font)
        font.include?(" ") ? "\"#{font}\"" : font
      end

      def reason(kind, name, side)
        return Refusal.new("The #{side} --#{name} colour is not hex, rgb(), hsl() or oklch() written with plain numbers, so it was not saved.") if kind == :colour

        Refusal.new("The --#{name} value #{REASONS.fetch(kind)}, so it was not saved.")
      end

      def kept
        @kept ||= ThemeRoles.names.each_with_object({}) do |name, kept|
          sides = @values.to_h[name].to_h.slice(*sides_of(name))
          kept[name] = sides if sides.any?
        end
      end
    end
  end
end
