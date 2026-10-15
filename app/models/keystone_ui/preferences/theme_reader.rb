# frozen_string_literal: true

module KeystoneUi
  module Preferences
    class ThemeReader
      BLOCK = %r{(?:\A|(?<=[\};])|(?<=\*/)|@layer\s+[\w-]+\s*\{)\s*(:root|\.dark)\s*\{([^\{\}]*)\}}
      DECLARATION = /--([a-z0-9-]+)\s*:\s*([^;]*)/
      LIMIT = 20_000
      FETCHES = /url\(|@import/i
      SIDES = { ":root" => "light", ".dark" => "dark" }.freeze

      def initialize(text)
        @text = text.to_s
      end

      def refusal
        return Refusal.new("The pasted theme is longer than 20,000 characters, so it was not saved.") if @text.length > LIMIT
        return Refusal.new("The pasted theme contains url( or @import, so it was not saved.") if @text.match?(FETCHES)

        Refusal.new("The pasted theme has no shadcn colour role in a :root or .dark block, so it was not saved.") if values.empty?
      end

      def values
        @values ||= @text.scan(BLOCK).each_with_object({}) do |(selector, body), values|
          body.scan(DECLARATION).each do |name, value|
            next unless ThemeRoles::ROLES.key?(name)

            (values[name] ||= {})[SIDES.fetch(selector)] = value.strip
          end
        end
      end
    end
  end
end
