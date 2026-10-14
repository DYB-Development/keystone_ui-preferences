# frozen_string_literal: true

module KeystoneUi
  module Preferences
    class AppearanceChoice
      DEFAULT_TEMPLATE = "default"
      HEX = /\A#\h{6}\z/
      PALETTE_NAME = /\A[a-z][a-z0-9_]*\z/
      WHITE = "#ffffff"

      def initialize(person:, account:)
        @person = person
        @account = account
      end

      def colours
        return default_colours unless configuration.account_colors
        return default_colours if saved["template_name"] == DEFAULT_TEMPLATE
        return template_colours if template_offered?
        return fallback_colours if saved["template_name"].present?

        surface = catalogue_colour("surface", KeystoneUi::Looks::Palettes::SURFACES) || configuration.default_surface
        {
          accent: catalogue_colour("accent", KeystoneUi::Looks::Palettes::ACCENTS) || configuration.default_accent,
          surface: surface,
          background: surface.start_with?("#") ? surface : configuration.default_background,
          text: (saved["text"] if saved["text"].to_s.match?(HEX)) || configuration.default_text
        }
      end

      def mode
        LayoutChoice.new(person: @person, account: nil, component_key: "mode").value.to_h["mode"] || configuration.default_mode
      end

      def look
        return nil unless @person

        [ (saved_look(@person) if person_chooses_look?), (saved_look(@account) if configuration.account_looks) ].find { |look| KeystoneUi.configuration.looks.key?(look) }
      end

      def person_chooses_look?
        configuration.user_looks && LayoutChoice.new(person: @person, account: @account, component_key: "look").members_choose?
      end

      def custom_offered?
        !colours[:background].casecmp?(WHITE)
      end

      private

      def saved_look(owner)
        LayoutChoice.new(person: owner, account: nil, component_key: "look").value.to_h["look"]
      end

      def catalogue_colour(kind, palettes)
        value = saved[kind].to_s
        return value if value.match?(HEX)
        return unless value.match?(PALETTE_NAME)
        return value if palettes.key?(value.to_sym)

        warn_missing(kind, value)
        nil
      end

      def default_colours
        { accent: configuration.default_accent, surface: configuration.default_surface, background: configuration.default_background, text: configuration.default_text }
      end

      def fallback_colours
        warn_missing("template", saved["template_name"])
        return default_colours if @account.nil? || colours_choice.preference.owned_by?(@account)

        AppearanceChoice.new(person: @account, account: nil).colours
      end

      def warn_missing(kind, name)
        row = colours_choice.preference
        Rails.logger.warn("keystone_ui-preferences: #{row.owner_type} #{row.owner_id} saved the #{kind} #{name.to_s.inspect}, which keystone_ui-looks does not have")
      end

      def template_offered?
        KeystoneUi::Looks::Templates.names.map(&:to_s).include?(saved["template_name"].to_s)
      end

      def template_colours
        template = KeystoneUi::Looks::Templates[saved["template_name"]]
        { accent: template[:accent].to_s, surface: template[:surface].to_s, background: template[:background], text: template[:text] }
      end

      def saved
        @saved ||= colours_choice.value.to_h
      end

      def colours_choice
        @colours_choice ||= LayoutChoice.new(person: @person, account: @account, component_key: "colours")
      end

      def configuration
        KeystoneUi::Preferences.configuration
      end
    end
  end
end
