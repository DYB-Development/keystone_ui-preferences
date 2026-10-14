# frozen_string_literal: true

module KeystoneUi
  module Preferences
    class ChosenColours
      def initialize(values)
        @values = values
      end

      def refusal
        return Refusal.new("Choose Default, one of the colour templates or Custom.") unless template_offered?

        Refusal.new("Choose each colour as a six-digit hex value, such as #1d4ed8.") unless colours_offered?
      end

      def value
        return { "template_name" => @values[:template_name] } if @values[:template_name].present?

        { "accent" => @values[:accent], "surface" => @values[:surface], "text" => @values[:text] }
      end

      private

      def template_offered?
        @values[:template_name].blank? || [ AppearanceChoice::DEFAULT_TEMPLATE, *KeystoneUi::Looks::Templates.names.map(&:to_s) ].include?(@values[:template_name])
      end

      def colours_offered?
        return true if @values[:template_name].present?

        colour_offered?(@values[:accent], KeystoneUi::Looks::Palettes::ACCENTS) && colour_offered?(@values[:surface], KeystoneUi::Looks::Palettes::SURFACES) && colour_offered?(@values[:text], {})
      end

      def colour_offered?(colour, palettes)
        colour.to_s.match?(AppearanceChoice::HEX) || palettes.key?(colour.to_s.to_sym)
      end
    end
  end
end
