# frozen_string_literal: true

require "test_helper"
require "minitest/mock"

class AppearancePartialTest < ActionView::TestCase
  include KeystoneUiHelper

  def person
    @person ||= User.create!(name: "Rep")
  end

  def teardown
    KeystoneUi::Preferences.reset_configuration!
    KeystoneUi::Preferences::ComponentPreference.delete_all
  end

  def render_section(account: nil)
    render partial: "keystone_ui/preferences/settings/appearance", locals: { person: person, account: account, submit_url: "/settings/appearance" }
  end

  def template_options
    css_select("input[type=radio][name=template_name]")
  end

  test "the appearance section offers Default, the five colour templates, the six preset themes and Custom" do
    render_section

    assert_equal [ "default", "ocean", "forest", "twilight", "coral", "arctic", "graphite", "harbor", "fern", "terracotta", "heather", "ledger", "" ], template_options.map { |option| option["value"] }
  end

  def selected_template
    css_select("input[type=radio][name=template_name][checked]").map { |option| option["value"] }
  end

  def save_colours(value, owner = person)
    KeystoneUi::Preferences::ComponentPreference.create!(owner: owner, component_key: "colours", value: value)
  end

  test "the appearance section selects the template the person saved" do
    save_colours("template_name" => "forest")

    render_section

    assert_equal [ "forest" ], selected_template
  end

  test "the appearance section selects no template for a person whose saved template the catalogue no longer has" do
    save_colours("template_name" => "retired")

    render_section

    assert_empty selected_template
  end

  test "the appearance section writes one warning for an account's saved template the catalogue no longer has" do
    account = Account.create!(name: "Acme")
    KeystoneUi::Preferences::ComponentPreference.create!(owner: account, component_key: "colours", value: { "template_name" => "retired" }, members_choose: false)
    log = StringIO.new
    original = Rails.logger
    Rails.logger = ActiveSupport::Logger.new(log, level: :warn)

    render_section(account: account)

    assert_equal 1, log.string.lines.count
  ensure
    Rails.logger = original
  end

  test "the appearance section selects Default for a person with no colours saved" do
    render_section

    assert_equal [ "default" ], selected_template
  end

  test "the appearance section selects Custom for a person who saved their own colours" do
    save_colours("accent" => "#e11d48", "surface" => "#f5e6c8", "text" => "#3b2f1e")

    render_section

    assert_equal [ "" ], selected_template
  end

  def picker_value(name)
    css_select("input[type=hidden][name=#{name}]").map { |input| input["value"] }
  end

  test "the appearance section's accent picker shows the accent drawn for the person" do
    save_colours("template_name" => "forest")

    render_section

    assert_equal [ "#10b981" ], picker_value("accent")
  end

  test "the appearance section's surface picker shows the surface drawn for the person" do
    save_colours("template_name" => "forest")

    render_section

    assert_equal [ "#78716c" ], picker_value("surface")
  end

  test "the appearance section's text colour picker shows the text colour drawn for the person" do
    save_colours("template_name" => "forest")

    render_section

    assert_equal [ "#064e3b" ], picker_value("text")
  end

  def account_setting_colours
    Account.create!(name: "Acme").tap do |account|
      KeystoneUi::Preferences::ComponentPreference.create!(owner: account, component_key: "colours", value: { "template_name" => "ocean" }, members_choose: false)
    end
  end

  test "the appearance section says the account sets the colours when members may not choose their own" do
    render_section(account: account_setting_colours)

    assert_includes rendered, "Your account sets the colours for everyone."
  end

  test "the appearance section's form sits inside the template picker script" do
    render_section

    assert_equal 1, css_select("[data-controller='keystone-ui--preferences--theme-settings'] form").size
  end

  test "picking a template hands the template picker script that template's accent, surface and text colour" do
    render_section

    forest = css_select("input[type=radio][name=template_name][value=forest]").first

    assert_equal [ "keystone-ui--preferences--theme-settings#selectTemplate", "#10b981", "#78716c", "#064e3b" ], %w[data-action data-accent-hex data-surface-hex data-text-hex].map { |attribute| forest[attribute] }
  end

  test "the template picker script finds the accent, surface and text colour pickers" do
    render_section

    targets = %w[accentPicker surfacePicker textPicker].map { |target| css_select("[data-keystone-ui--preferences--theme-settings-target=#{target}] input[type=hidden]").map { |input| input["name"] } }

    assert_equal [ [ "accent" ], [ "surface" ], [ "text" ] ], targets
  end

  test "the template picker script finds each template's option, each preset theme's option and the Custom option to highlight" do
    render_section

    assert_equal %w[default ocean forest twilight coral arctic graphite harbor fern terracotta heather ledger custom], css_select("label[data-keystone-ui--preferences--theme-settings-target=templateLabel]").map { |label| label["data-template"] }
  end

  test "the template picker script finds the Custom option to select when a colour picker changes" do
    render_section

    assert_equal [ "" ], css_select("input[data-keystone-ui--preferences--theme-settings-target=customRadio]").map { |input| input["value"] }
  end

  test "the appearance section saves with a full page load, as the other sections do in a Hotwire Native web view" do
    render_section

    assert_equal [ "false" ], css_select("form").map { |form| form["data-turbo"] }
  end

  def mode_options
    css_select("input[type=radio][name=mode]").map { |option| option["value"] }
  end

  test "the appearance section offers Light, Dark, System and Custom to a person who may choose their own colours" do
    render_section

    assert_equal %w[light dark system custom], mode_options
  end

  def selected_mode
    css_select("input[type=radio][name=mode][checked]").map { |option| option["value"] }
  end

  test "the appearance section selects the mode the person saved" do
    KeystoneUi::Preferences::ComponentPreference.create!(owner: person, component_key: "mode", value: { "mode" => "dark" })

    render_section

    assert_equal [ "dark" ], selected_mode
  end

  test "the appearance section selects the app's default mode for a person with no mode saved" do
    KeystoneUi::Preferences.configure { |config| config.default_mode = "system" }

    render_section

    assert_equal [ "system" ], selected_mode
  end

  test "the appearance section offers the modes while the account sets the colours for everyone" do
    render_section(account: account_setting_colours)

    assert_equal %w[light dark system custom], mode_options
  end

  test "the appearance section leaves out Custom when the account sets colours drawn on a white background" do
    account = Account.create!(name: "Acme")
    KeystoneUi::Preferences::ComponentPreference.create!(owner: account, component_key: "colours", value: { "accent" => "rose", "surface" => "neutral" }, members_choose: false)

    render_section(account: account)

    assert_equal %w[light dark system], mode_options
  end

  def look_options
    css_select("input[type=radio][name=look]").map { |option| option["value"] }
  end

  test "the appearance section offers the app's own look first and then every registered look" do
    render_section

    assert_equal [ "", "brutalist", "compact", "rounded", "sharp", "soft" ], look_options
  end

  test "the appearance section labels the app's own look as the app configures and each registered look by its name" do
    KeystoneUi::Preferences.configure { |config| config.app_look_label = "House" }

    render_section

    assert_equal [ "House", "Brutalist", "Compact", "Rounded", "Sharp", "Soft" ], css_select("label:has(input[name=look]) .ks-radio-card-label").map(&:text)
  end

  def selected_look
    css_select("input[type=radio][name=look][checked]").map { |option| option["value"] }
  end

  test "the appearance section selects the look the person saved" do
    KeystoneUi::Preferences::ComponentPreference.create!(owner: person, component_key: "look", value: { "look" => "rounded" })

    render_section

    assert_equal [ "rounded" ], selected_look
  end

  test "the appearance section selects the app's own look for a person with no look saved" do
    render_section

    assert_equal [ "" ], selected_look
  end

  test "the appearance section offers no look when the app turns off a person's own looks" do
    KeystoneUi::Preferences.configure { |config| config.user_looks = false }

    render_section

    assert_empty look_options
  end

  test "the appearance section offers no look when the app registers none" do
    KeystoneUi.configuration.stub(:looks, {}) { render_section }

    assert_empty look_options
  end

  test "the appearance section offers no look when the account turns off members choosing their own look" do
    account = Account.create!(name: "Acme")
    KeystoneUi::Preferences::ComponentPreference.create!(owner: account, component_key: "look", value: { "look" => "sharp" }, members_choose: false)

    render_section(account: account)

    assert_empty look_options
  end

  test "the appearance section offers no colours when the app turns off account colours" do
    KeystoneUi::Preferences.configure { |config| config.account_colors = false }

    render_section

    assert_empty template_options
  end

  test "the appearance section leaves out Custom when the app turns off account colours" do
    KeystoneUi::Preferences.configure { |config| config.account_colors = false }

    render_section

    assert_equal %w[light dark system], mode_options
  end

  test "the appearance section does not say the account sets the colours when the app turns off account colours" do
    KeystoneUi::Preferences.configure { |config| config.account_colors = false }

    render_section(account: account_setting_colours)

    assert_not_includes rendered, "Your account sets the colours for everyone."
  end

  test "the appearance section offers no colours while the account sets the colours for everyone" do
    render_section(account: account_setting_colours)

    assert_empty template_options
  end

  def theme_section
    css_select("h2").find { |title| title.text.strip == "Theme" }.ancestors("div")[2]
  end

  test "the appearance section's Theme section has a box to paste a theme into" do
    render_section

    assert_equal [ "pasted_theme" ], theme_section.css("textarea").map { |box| box["name"] }
  end

  test "the Theme section says the current choice is the person's own theme when they saved one" do
    save_colours("theme" => { "primary" => { "light" => "#171717" } })

    render_section

    assert_includes theme_section.text, "Your current choice is your own theme."
  end

  test "the appearance section selects no template for a person whose colours are a pasted theme" do
    save_colours("theme" => { "primary" => { "light" => "#171717" } })

    render_section

    assert_empty selected_template
  end

  test "the appearance section offers Light, Dark and System to a person with a saved theme" do
    save_colours("theme" => { "primary" => { "light" => "#171717", "dark" => "#e5e5e5" } })

    render_section

    assert_empty %w[light dark system] - mode_options
  end

  test "the appearance section shows the templates and presets, then Look, then Mode, then the theme settings" do
    render_section

    order = css_select("input[name=template_name], input[name=look], input[name=mode], input[name^='theme[']").map { |input| input["name"][/\A[a-z_]+/] }

    assert_equal %w[template_name look mode theme], order.chunk_while { |a, b| a == b }.map(&:first)
  end

  def theme_settings
    css_select("[data-controller='keystone-ui--preferences--theme-editor']").first
  end

  def theme_field_names
    css_select("input[name^='theme[']").map { |field| field["name"] }
  end

  def roles_in_group_order
    KeystoneUi::Preferences::ThemeRoles::GROUPS.values.flat_map(&:values).flatten.to_h { |name| [ name, KeystoneUi::Preferences::ThemeRoles::ROLES.fetch(name) ] }
  end

  test "the Theme section has a field for every theme setting, with a light and a dark field for each colour role" do
    render_section

    expected = roles_in_group_order.flat_map { |name, role| (role[:kind] == :colour ? %w[light dark] : %w[light]).map { |side| "theme[#{name}][#{side}]" } }

    assert_equal expected, theme_field_names
  end

  test "the theme settings are under three groups, Colors, Typography and Other" do
    render_section

    assert_equal %w[Colors Typography Other], theme_settings.css("h2").map { |title| title.text.strip }
  end

  def theme_group(title)
    theme_settings.css("h2").find { |heading| heading.text.strip == title }.ancestors(".ks-section-sm").first
  end

  def settings_by_set(group)
    theme_group(group).css("fieldset").map { |set| [ set.at_css("legend").text.strip, set.css("input[name^='theme[']").map { |field| field["name"][/\Atheme\[([^\]]+)\]/, 1] }.uniq ] }
  end

  test "Colors lists each colour role beside its foreground, set by set" do
    render_section

    expected = [
      [ "Page", %w[background foreground] ],
      [ "Primary", %w[primary primary-foreground] ],
      [ "Secondary", %w[secondary secondary-foreground] ],
      [ "Accent", %w[accent accent-foreground] ],
      [ "Muted", %w[muted muted-foreground] ],
      [ "Card", %w[card card-foreground] ],
      [ "Popover", %w[popover popover-foreground] ],
      [ "Destructive", %w[destructive destructive-foreground] ],
      [ "Border, input and ring", %w[border input ring] ],
      [ "Chart", %w[chart-1 chart-2 chart-3 chart-4 chart-5] ],
      [ "Sidebar", %w[sidebar sidebar-foreground sidebar-primary sidebar-primary-foreground sidebar-accent sidebar-accent-foreground sidebar-border sidebar-ring] ]
    ]

    assert_equal expected, settings_by_set("Colors")
  end

  test "each colour in Colors has its light value and its dark value side by side" do
    render_section

    rows = theme_group("Colors").css("[role=group]").map { |row| [ row["aria-label"], row.css("input[type=hidden][name^='theme[']").map { |field| field["name"] } ] }

    expected = KeystoneUi::Preferences::ThemeRoles::GROUPS["Colors"].values.flatten.map { |name| [ "--#{name}", [ "theme[#{name}][light]", "theme[#{name}][dark]" ] ] }

    assert_equal expected, rows
  end

  test "Typography offers the four fonts, the four font weights and the letter spacing" do
    render_section

    expected = [
      [ "Fonts", %w[font-sans font-serif font-mono font-heading] ],
      [ "Font weights", %w[font-weight-normal font-weight-medium font-weight-strong font-weight-heading] ],
      [ "Letter spacing", %w[letter-spacing] ]
    ]

    assert_equal expected, settings_by_set("Typography")
  end

  test "Other offers the radius, the spacing, the border width and the six shadow settings" do
    render_section

    expected = [
      [ "Shape", %w[radius spacing border-width] ],
      [ "Shadow", %w[shadow-color shadow-opacity shadow-blur shadow-spread shadow-offset-x shadow-offset-y] ]
    ]

    assert_equal expected, settings_by_set("Other")
  end

  test "each font setting suggests the app's theme fonts and then the system fonts the gem offers" do
    KeystoneUi::Preferences.configure { |config| config.theme_fonts = [ "Inter", "Source Serif 4" ] }

    render_section

    suggestions = %w[font-sans font-serif font-mono font-heading].map do |name|
      list = theme_settings.at_css("[id='#{theme_settings.at_css("input[name='theme[#{name}][light]']")["list"]}']")
      list ? list.css("option").map { |option| option["value"] } : []
    end

    expected = [ "Inter", "Source Serif 4" ] + KeystoneUi::Preferences::CheckedTheme::SYSTEM_FONTS

    assert_equal [ expected ] * 4, suggestions
  end

  test "the theme settings are shown with no closed disclosure around them" do
    render_section

    assert_empty css_select("details:not([open]) input[name^='theme[']")
  end

  test "the Theme section edits each colour role and the shadow colour with a colour picker that takes a typed colour" do
    render_section

    expected = roles_in_group_order.flat_map { |name, role| { colour: %w[light dark], shadow_colour: %w[light] }.fetch(role[:kind], []).map { |side| "theme[#{name}][#{side}]" } }

    assert_equal expected, theme_settings.css("[data-controller=color-picker]:has(input[data-color-picker-target=text]) input[type=hidden]").map { |field| field["name"] }
  end

  test "the theme fields show the values of the person's saved theme" do
    save_colours("theme" => { "primary" => { "light" => "oklch(0.205 0 0)", "dark" => "oklch(0.922 0 0)" }, "radius" => { "light" => "0.5rem" } })

    render_section

    assert_equal [ "oklch(0.205 0 0)", "oklch(0.922 0 0)", "0.5rem" ], [ "theme[primary][light]", "theme[primary][dark]", "theme[radius][light]" ].map { |field| theme_settings.at_css("input[name='#{field}']")["value"] }
  end

  test "the theme fields hand the template picker script the person's saved theme to reset to" do
    saved_theme = { "primary" => { "light" => "oklch(0.205 0 0)", "dark" => "oklch(0.922 0 0)" }, "radius" => { "light" => "0.5rem" } }
    save_colours("theme" => saved_theme)

    render_section

    assert_equal [ saved_theme ], css_select("[data-saved-theme]").map { |element| JSON.parse(element["data-saved-theme"]) }
  end

  test "the appearance section's Reset button resets the theme fields through the template picker script without saving" do
    render_section

    assert_equal [ [ "button", "keystone-ui--preferences--theme-settings#reset" ] ], css_select("form button").select { |button| button.text.strip == "Reset" }.map { |button| [ button["type"], button["data-action"] ] }
  end

  test "each preset theme's card shows its light primary and secondary colours as swatches, as a template's card shows its accent and surface" do
    render_section

    swatches = css_select("label:has(input[name=template_name][value=harbor]) span[style*=background-color]").map { |swatch| swatch["style"][/background-color: ([^;]+);/, 1] }

    assert_equal [ "#1f5fbf", "#e3ebf6" ], swatches
  end

  test "the appearance section selects only the preset theme the person saved" do
    save_colours("preset_name" => "harbor")

    render_section

    assert_equal [ "harbor" ], selected_template
  end

  test "the theme fields show the values of the preset theme the person saved" do
    save_colours("preset_name" => "harbor")

    render_section

    assert_equal [ "#1f5fbf", "#6aa3f0", "0.625rem" ], [ "theme[primary][light]", "theme[primary][dark]", "theme[radius][light]" ].map { |field| theme_settings.at_css("input[name='#{field}']")["value"] }
  end

  test "picking a preset theme hands the template picker script that preset's theme values to fill the theme fields with" do
    render_section

    harbor = css_select("input[type=radio][name=template_name][value=harbor]").first

    assert_equal [ "keystone-ui--preferences--theme-settings#selectPreset", KeystoneUi::Looks::Themes[:harbor][:theme] ], [ harbor["data-action"], JSON.parse(harbor["data-theme"].to_s) ]
  end

  test "every template card and preset card hands the template picker script the same values as before the writers were joined" do
    render_section

    cards = template_options.map { |option| %w[value data-action data-accent-hex data-surface-hex data-text-hex data-theme].to_h { |attribute| [ attribute, option[attribute] ] } }

    assert_equal JSON.parse(File.read(File.expand_path("../fixtures/pinned/cards.json", __dir__))), cards
  end

  def labelled_controls(scope)
    scope.css("label[for]").filter_map do |label|
      control = scope.at_css("[id='#{label["for"]}']")
      [ label.text.strip, control["name"] ] if control
    end
  end

  test "each theme setting typed as text is labelled with its setting name" do
    render_section

    expected = roles_in_group_order.reject { |_name, role| %i[colour shadow_colour].include?(role[:kind]) }.map { |name, _role| [ "--#{name}", "theme[#{name}][light]" ] }

    assert_equal expected, labelled_controls(theme_settings).select { |_label, name| name.to_s.start_with?("theme[") }
  end

  test "the paste box is labelled 'Paste a theme'" do
    render_section

    assert_equal [ [ "Paste a theme", "pasted_theme" ] ], labelled_controls(theme_section).select { |_label, name| name == "pasted_theme" }
  end

  test "every theme field sits inside the theme editor script, which redraws the page on each change and each keystroke" do
    render_section

    editor = theme_settings

    fields = editor ? editor.css("input[name^='theme[']").map { |field| field["name"] } : []

    assert_equal [ "change->keystone-ui--preferences--theme-editor#apply input->keystone-ui--preferences--theme-editor#apply", theme_field_names ], [ editor&.[]("data-action"), fields ]
  end

  test "the theme editor script is handed each theme setting's kind and variables and the hover variable the theme writer derives from it" do
    render_section

    expected = KeystoneUi::Preferences::ThemeRoles::ROLES.to_h do |name, role|
      [ name, { "kind" => role[:kind].to_s, "variables" => role[:variables], "hover" => KeystoneUi::Preferences::ThemeCss::HOVERS[name] }.compact ]
    end

    assert_equal expected, JSON.parse(theme_settings["data-theme-roles"].to_s)
  end

  test "the theme editor writes its export into a read-only text area labelled Export that has no name, so Save does not send it" do
    render_section

    exports = theme_settings.css("textarea[data-theme-export]").map { |area| [ theme_settings.at_css("label[for='#{area["id"]}']")&.text&.strip, area.key?("readonly"), area["name"] ] }

    assert_equal [ [ "Export", true, nil ] ], exports
  end
end
