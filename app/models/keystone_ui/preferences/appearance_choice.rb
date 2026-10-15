# frozen_string_literal: true

module KeystoneUi
  module Preferences
    class AppearanceChoice
      DEFAULT_TEMPLATE = "default"
      HEX = /\A#\h{6}\z/
      PALETTE_NAME = /\A[a-z][a-z0-9_]*\z/
      WHITE = "#ffffff"

      def initialize(person:, account:, own_look: nil)
        @person = person
        @account = account
        @own_look = own_look
      end

      def colours
        @colours ||= chosen_colours
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

      def theme_css
        return unless configuration.account_colors
        return preset_css if saved.key?("preset_name")
        return unless saved.key?("theme")
        return refused_theme_css if refused_setting

        Rails.cache.fetch([ colours_choice.preference.cache_key_with_version, "theme_css", ThemeCss::VERSION, own_look? ]) { written_theme }
      end

      private

      def chosen_colours
        return default_colours unless configuration.account_colors
        return default_colours if saved["template_name"] == DEFAULT_TEMPLATE
        return template_colours if template_offered?
        return fallback_colours if saved["template_name"].present?
        return account_colours if saved["preset_name"].present? && !preset_offered?
        return account_colours if refused_setting

        surface = catalogue_colour("surface", KeystoneUi::Looks::Palettes::SURFACES) || configuration.default_surface
        {
          accent: catalogue_colour("accent", KeystoneUi::Looks::Palettes::ACCENTS) || configuration.default_accent,
          surface: surface,
          background: surface.start_with?("#") ? surface : configuration.default_background,
          text: (saved["text"] if saved["text"].to_s.match?(HEX)) || configuration.default_text
        }
      end

      def preset_css
        unless preset_offered?
          warn_missing("preset", saved["preset_name"])
          return account_theme_css
        end

        Rails.cache.fetch([ "preset_css", saved["preset_name"], KeystoneUi::Looks::VERSION, ThemeCss::VERSION, own_look? ]) { written(KeystoneUi::Looks::Themes[saved["preset_name"]][:theme]) }
      end

      def preset_offered?
        KeystoneUi::Looks::Themes.names.map(&:to_s).include?(saved["preset_name"].to_s)
      end

      def refused_theme_css
        row = colours_choice.preference
        Rails.logger.warn("keystone_ui-preferences: #{row.owner_type} #{row.owner_id} saved a theme whose --#{refused_setting} setting fails the theme check")
        account_theme_css
      end

      def refused_setting
        @refused_setting ||= CheckedTheme.new(saved["theme"]).failing_setting if theme_shaped?(saved["theme"])
      end

      def written_theme
        written(saved["theme"]) if theme_shaped?(saved["theme"])
      end

      def written(theme)
        checked = CheckedTheme.new(theme)
        ThemeCss.new(checked.value["theme"], own_look: own_look?).to_s unless checked.refusal
      end

      def own_look?
        return @own_look unless @own_look.nil?

        @person.present? && person_chooses_look? && KeystoneUi.configuration.looks.key?(saved_look(@person))
      end

      def theme_shaped?(theme)
        theme.is_a?(Hash) && theme.values.all?(Hash)
      end

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
        account_colours
      end

      def account_theme_css
        AppearanceChoice.new(person: @account, account: nil, own_look: own_look?).theme_css unless @account.nil? || colours_choice.preference.owned_by?(@account)
      end

      def account_colours
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
