# frozen_string_literal: true

module KeystoneUi
  module Preferences
    class ThemeCss
      def initialize(theme)
        @theme = theme
      end

      def to_s
        ":root {\n#{lines.join("\n")}\n}"
      end

      private

      def lines
        @theme.flat_map do |role, sides|
          ThemeRoles::ROLES.fetch(role)[:variables].map { |variable| "  #{variable}: #{sides["light"]};" }
        end
      end
    end
  end
end
