# frozen_string_literal: true

module KeystoneUi
  module Preferences
    class CheckedTheme
      def initialize(values)
        @values = values
      end

      def value
        { "theme" => @values }
      end
    end
  end
end
