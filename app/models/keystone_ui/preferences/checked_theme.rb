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
      PATTERNS = { colour: COLOUR, length: LENGTH, letter_spacing: Regexp.union(SIGNED_LENGTH, /\Anormal\z/), font_list: FONT_LIST }.freeze
      REASONS = {
        length: "is not a number followed by px, rem or em, or zero",
        letter_spacing: "is not normal or a number followed by px, rem or em, or zero",
        font_list: "is not a list of font names made of letters, digits, spaces and hyphens"
      }.freeze
      SIDES = %w[light dark].freeze

      def initialize(values)
        @values = values
      end

      def refusal
        kept.each do |name, sides|
          kind = ThemeRoles::ROLES.fetch(name)[:kind]
          sides.each do |side, value|
            return reason(kind, name, side) unless value.to_s.match?(PATTERNS.fetch(kind))
          end
        end
        nil
      end

      def value
        { "theme" => kept }
      end

      private

      def sides_of(name)
        ThemeRoles::ROLES.fetch(name)[:kind] == :colour ? SIDES : SIDES.first(1)
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
