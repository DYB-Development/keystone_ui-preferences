# frozen_string_literal: true

module KeystoneUi
  module Preferences
    class ThemeReader
      BLOCK = /(?:\A|[\s};])(:root|\.dark)\s*\{([^{}]*)\}/
      DECLARATION = /--([a-z0-9-]+)\s*:\s*([^;]*)/
      SIDES = { ":root" => "light", ".dark" => "dark" }.freeze

      def initialize(text)
        @text = text.to_s
      end

      def values
        @values ||= @text.scan(BLOCK).each_with_object({}) do |(selector, body), values|
          body.scan(DECLARATION).each do |name, value|
            (values[name] ||= {})[SIDES.fetch(selector)] = value.strip
          end
        end
      end
    end
  end
end
