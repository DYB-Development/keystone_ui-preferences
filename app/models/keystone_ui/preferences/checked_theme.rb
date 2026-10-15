# frozen_string_literal: true

module KeystoneUi
  module Preferences
    class CheckedTheme
      NUMBER = '-?(?:\d+(?:\.\d+)?|\.\d+)%?'
      GAP = '(?:\s*,\s*|\s+)'
      HEX = /\A#(?:\h{3}|\h{4}|\h{6}|\h{8})\z/
      FUNCTION = /\A(?:rgba?|hsla?|oklch)\(\s*#{NUMBER}#{GAP}#{NUMBER}#{GAP}#{NUMBER}(?:\s*[\/,]\s*#{NUMBER})?\s*\)\z/
      COLOUR = Regexp.union(HEX, FUNCTION)

      def initialize(values)
        @values = values
      end

      def refusal
        @values.each do |name, sides|
          sides.each do |side, colour|
            return Refusal.new("The #{side} --#{name} colour is not hex, rgb(), hsl() or oklch() written with plain numbers, so it was not saved.") unless colour.to_s.match?(COLOUR)
          end
        end
        nil
      end

      def value
        { "theme" => @values }
      end
    end
  end
end
