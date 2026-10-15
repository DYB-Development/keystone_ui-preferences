# frozen_string_literal: true

require "test_helper"
require "minitest/mock"

class AppearanceChoiceTest < ActiveSupport::TestCase
  def person
    @person ||= User.create!(name: "Rep")
  end

  def account
    @account ||= Account.create!(name: "Acme")
  end

  def teardown
    KeystoneUi::Preferences.reset_configuration!
    KeystoneUi::Preferences::ComponentPreference.delete_all
  end

  def colours_for(person, account = nil)
    KeystoneUi::Preferences::AppearanceChoice.new(person: person, account: account).colours
  end

  test "a person with nothing saved gets the accent, surface, background and text the app configures" do
    KeystoneUi::Preferences.configure do |config|
      config.default_accent = "violet"
      config.default_surface = "stone"
      config.default_background = "#fefce8"
      config.default_text = "#422006"
    end

    assert_equal({ accent: "violet", surface: "stone", background: "#fefce8", text: "#422006" }, colours_for(person, account))
  end

  test "a person's saved custom colours draw as saved, with the custom surface as the background" do
    KeystoneUi::Preferences::ComponentPreference.create!(owner: person, component_key: "colours", value: { "accent" => "#e11d48", "surface" => "#f5e6c8", "text" => "#3b2f1e" })

    assert_equal({ accent: "#e11d48", surface: "#f5e6c8", background: "#f5e6c8", text: "#3b2f1e" }, colours_for(person, account))
  end

  test "a person's saved template draws that template's accent, surface, background and text" do
    KeystoneUi::Preferences::ComponentPreference.create!(owner: person, component_key: "colours", value: { "template_name" => "forest", "accent" => "rose", "surface" => "zinc", "text" => "#3b2f1e" })

    assert_equal({ accent: "emerald", surface: "stone", background: "#ecfdf5", text: "#064e3b" }, colours_for(person, account))
  end

  test "a person who saved the default template gets the accent, surface, background and text the app configures" do
    KeystoneUi::Preferences.configure { |config| config.default_accent = "violet" }
    KeystoneUi::Preferences::ComponentPreference.create!(owner: person, component_key: "colours", value: { "template_name" => "default", "accent" => "rose", "surface" => "#f5e6c8" })

    assert_equal({ accent: "violet", surface: "zinc", background: "#ffffff", text: "#18181b" }, colours_for(person, account))
  end

  test "a person whose account does not let members choose colours gets the account's colours" do
    KeystoneUi::Preferences::ComponentPreference.create!(owner: account, component_key: "colours", value: { "accent" => "rose", "surface" => "neutral" }, members_choose: false)
    KeystoneUi::Preferences::ComponentPreference.create!(owner: person, component_key: "colours", value: { "accent" => "cyan", "surface" => "gray" })

    assert_equal({ accent: "rose", surface: "neutral", background: "#ffffff", text: "#18181b" }, colours_for(person, account))
  end

  test "a visitor who is not signed in gets the accent, surface, background and text the app configures" do
    KeystoneUi::Preferences::ComponentPreference.create!(owner: person, component_key: "colours", value: { "accent" => "cyan", "surface" => "gray" })

    assert_equal({ accent: "blue", surface: "zinc", background: "#ffffff", text: "#18181b" }, colours_for(nil))
  end

  test "a saved accent that is neither a palette name nor a six-digit hex draws the app's default accent" do
    KeystoneUi::Preferences::ComponentPreference.create!(owner: person, component_key: "colours", value: { "accent" => "red;} body{display:none}" })

    assert_equal "blue", colours_for(person, account)[:accent]
  end

  test "a saved surface that is neither a palette name nor a six-digit hex draws the app's default surface and background" do
    KeystoneUi::Preferences::ComponentPreference.create!(owner: person, component_key: "colours", value: { "surface" => "#f5e6c8;} body{display:none}" })

    assert_equal [ "zinc", "#ffffff" ], colours_for(person, account).values_at(:surface, :background)
  end

  test "a saved text colour that is not a six-digit hex draws the app's default text colour" do
    KeystoneUi::Preferences::ComponentPreference.create!(owner: person, component_key: "colours", value: { "text" => "black" })

    assert_equal "#18181b", colours_for(person, account)[:text]
  end

  test "a person whose saved template the catalogue no longer has gets the account's colours" do
    KeystoneUi::Preferences::ComponentPreference.create!(owner: account, component_key: "colours", value: { "template_name" => "forest" })
    KeystoneUi::Preferences::ComponentPreference.create!(owner: person, component_key: "colours", value: { "template_name" => "retired" })

    assert_equal({ accent: "emerald", surface: "stone", background: "#ecfdf5", text: "#064e3b" }, colours_for(person, account))
  end

  test "a saved accent name the catalogue no longer has draws the app's default accent" do
    KeystoneUi::Preferences::ComponentPreference.create!(owner: person, component_key: "colours", value: { "accent" => "retired" })

    assert_equal "blue", colours_for(person, account)[:accent]
  end

  test "a saved surface name the catalogue no longer has draws the app's default surface" do
    KeystoneUi::Preferences::ComponentPreference.create!(owner: person, component_key: "colours", value: { "surface" => "retired" })

    assert_equal "zinc", colours_for(person, account)[:surface]
  end

  def warnings_from
    log = StringIO.new
    original = Rails.logger
    Rails.logger = ActiveSupport::Logger.new(log, level: :warn)
    yield
    log.string.lines.map(&:chomp)
  ensure
    Rails.logger = original
  end

  test "a person's saved template the catalogue no longer has writes one warning naming the person and the template" do
    KeystoneUi::Preferences::ComponentPreference.create!(owner: person, component_key: "colours", value: { "template_name" => "retired" })

    assert_equal [ "keystone_ui-preferences: User #{person.id} saved the template \"retired\", which keystone_ui-looks does not have" ], warnings_from { colours_for(person) }
  end

  test "an account's saved template the catalogue no longer has writes one warning naming the account and the template" do
    KeystoneUi::Preferences::ComponentPreference.create!(owner: account, component_key: "colours", value: { "template_name" => "retired" })

    assert_equal [ "keystone_ui-preferences: Account #{account.id} saved the template \"retired\", which keystone_ui-looks does not have" ], warnings_from { colours_for(person, account) }
  end

  test "a saved accent and surface the catalogue no longer has each write one warning naming the person and the name" do
    KeystoneUi::Preferences::ComponentPreference.create!(owner: person, component_key: "colours", value: { "accent" => "retired_accent", "surface" => "retired_surface" })

    assert_equal [ "keystone_ui-preferences: User #{person.id} saved the surface \"retired_surface\", which keystone_ui-looks does not have", "keystone_ui-preferences: User #{person.id} saved the accent \"retired_accent\", which keystone_ui-looks does not have" ], warnings_from { colours_for(person, account) }
  end

  test "a saved accent that is neither a palette name nor a six-digit hex writes no warning" do
    KeystoneUi::Preferences::ComponentPreference.create!(owner: person, component_key: "colours", value: { "accent" => "red;} body{display:none}" })

    assert_empty warnings_from { colours_for(person, account) }
  end

  def mode_for(person, account = nil)
    KeystoneUi::Preferences::AppearanceChoice.new(person: person, account: account).mode
  end

  test "a person who saved a mode gets that mode" do
    KeystoneUi::Preferences::ComponentPreference.create!(owner: person, component_key: "mode", value: { "mode" => "dark" })

    assert_equal "dark", mode_for(person, account)
  end

  test "a person with no mode saved gets the mode the app configures" do
    KeystoneUi::Preferences.configure { |config| config.default_mode = "system" }

    assert_equal "system", mode_for(person, account)
  end

  test "a person's saved mode applies when the account turns off members-choose" do
    KeystoneUi::Preferences::ComponentPreference.create!(owner: account, component_key: "colours", value: { "template_name" => "ocean" }, members_choose: false)
    KeystoneUi::Preferences::ComponentPreference.create!(owner: account, component_key: "mode", value: { "mode" => "light" }, members_choose: false)
    KeystoneUi::Preferences::ComponentPreference.create!(owner: person, component_key: "mode", value: { "mode" => "dark" })

    assert_equal "dark", mode_for(person, account)
  end

  def look_for(person, account = nil)
    KeystoneUi::Preferences::AppearanceChoice.new(person: person, account: account).look
  end

  def save_look(owner, look, members_choose: true)
    KeystoneUi::Preferences::ComponentPreference.create!(owner: owner, component_key: "look", value: { "look" => look }, members_choose: members_choose)
  end

  test "a person who saved a registered look gets that look" do
    save_look(person, "rounded")

    assert_equal "rounded", look_for(person, account)
  end

  test "a person whose saved look the app no longer registers gets the account's look" do
    save_look(account, "sharp")
    save_look(person, "retired")

    assert_equal "sharp", look_for(person, account)
  end

  test "a person's saved look is passed over for the app's default look when the app turns off a person's own looks" do
    KeystoneUi::Preferences.configure { |config| config.user_looks = false }
    save_look(person, "rounded")

    assert_nil look_for(person, account)
  end

  test "a visitor who is not signed in gets the app's default look" do
    save_look(account, "sharp")

    assert_nil look_for(nil, account)
  end

  test "a person gets the app's default colours when the app turns off account colours" do
    KeystoneUi::Preferences.configure { |config| config.account_colors = false }
    KeystoneUi::Preferences::ComponentPreference.create!(owner: person, component_key: "colours", value: { "template_name" => "forest" })

    assert_equal({ accent: "blue", surface: "zinc", background: "#ffffff", text: "#18181b" }, colours_for(person, account))
  end

  test "a person whose account turns off members choosing their own look gets the account's look" do
    save_look(account, "sharp", members_choose: false)
    save_look(person, "rounded")

    assert_equal "sharp", look_for(person, account)
  end

  test "a person with no look of their own gets the app's default look when the app turns off account looks" do
    KeystoneUi::Preferences.configure { |config| config.account_looks = false }
    save_look(account, "sharp")

    assert_nil look_for(person, account)
  end

  test "a person gets the app's default look when the app turns off account looks and the account turns off members choosing their own" do
    KeystoneUi::Preferences.configure { |config| config.account_looks = false }
    save_look(account, "sharp", members_choose: false)
    save_look(person, "rounded")

    assert_nil look_for(person, account)
  end

  test "a person who chose a look keeps it over the account's look while the account lets members choose" do
    save_look(account, "sharp")
    save_look(person, "rounded")

    assert_equal "rounded", look_for(person, account)
  end

  test "a person with no look of their own gets the account's look" do
    save_look(account, "sharp")

    assert_equal "sharp", look_for(person, account)
  end

  def theme_css_for(person, account = nil)
    KeystoneUi::Preferences::AppearanceChoice.new(person: person, account: account).theme_css
  end

  test "a person's saved theme is written as a theme rule" do
    theme = { "primary" => { "light" => "oklch(0.205 0 0)", "dark" => "oklch(0.922 0 0)" } }
    KeystoneUi::Preferences::ComponentPreference.create!(owner: person, component_key: "colours", value: { "theme" => theme })

    assert_equal KeystoneUi::Preferences::ThemeCss.new(theme).to_s, theme_css_for(person, account)
  end

  test "a saved theme holding a colour that fails the theme check is not written" do
    KeystoneUi::Preferences::ComponentPreference.create!(owner: person, component_key: "colours", value: { "theme" => { "primary" => { "light" => "#000;} body{display:none" } } })

    assert_nil theme_css_for(person, account)
  end

  test "a person's saved theme is not written when the app turns off account colours" do
    KeystoneUi::Preferences.configure { |config| config.account_colors = false }
    KeystoneUi::Preferences::ComponentPreference.create!(owner: person, component_key: "colours", value: { "theme" => { "primary" => { "light" => "#171717" } } })

    assert_nil theme_css_for(person, account)
  end

  test "a saved theme's written rule is kept in the Rails cache under the colours row's versioned cache key and whether the person saved a look" do
    row = KeystoneUi::Preferences::ComponentPreference.create!(owner: person, component_key: "colours", value: { "theme" => { "primary" => { "light" => "#171717" } } })

    css = theme_css_for(person, account)

    assert_equal css, Rails.cache.read([ row.cache_key_with_version, "theme_css", KeystoneUi::Preferences::ThemeCss::VERSION, false ])
  end

  test "a saved theme that is not a set of roles each holding light and dark colours is not written" do
    themes = [ "oklch(0.205 0 0)", { "primary" => "#171717" }, { "primary" => [ "#171717" ] } ]

    written = themes.map do |theme|
      KeystoneUi::Preferences::ComponentPreference.where(owner: person, component_key: "colours").delete_all
      Rails.cache.clear
      KeystoneUi::Preferences::ComponentPreference.create!(owner: person, component_key: "colours", value: { "theme" => theme })
      theme_css_for(person, account)
    end

    assert_equal [ nil, nil, nil ], written
  end

  test "a theme rule cached by another version of the writer is written again" do
    row = KeystoneUi::Preferences::ComponentPreference.create!(owner: person, component_key: "colours", value: { "theme" => { "primary" => { "light" => "#171717" } } })
    writer = KeystoneUi::Preferences::ThemeCss
    earlier = writer::VERSION
    Rails.cache.write([ row.cache_key_with_version, "theme_css", earlier ], "written by an earlier writer")
    writer.send(:remove_const, :VERSION)
    writer.const_set(:VERSION, "#{earlier}-next")

    css = theme_css_for(person, account)

    assert_equal writer.new(row.value["theme"]).to_s, css
  ensure
    writer.send(:remove_const, :VERSION)
    writer.const_set(:VERSION, earlier)
  end

  test "a person who saved a look of their own gets the theme's shape and type in a rule their look outranks" do
    theme = { "primary" => { "light" => "#171717" }, "radius" => { "light" => "0.5rem" } }
    KeystoneUi::Preferences::ComponentPreference.create!(owner: person, component_key: "colours", value: { "theme" => theme })
    save_look(account, "sharp")
    save_look(person, "rounded")

    assert_equal KeystoneUi::Preferences::ThemeCss.new(theme, own_look: true).to_s, theme_css_for(person, account)
  end

  test "a theme rule written before the person saved a look of their own is written again once they have" do
    theme = { "primary" => { "light" => "#171717" }, "radius" => { "light" => "0.5rem" } }
    KeystoneUi::Preferences::ComponentPreference.create!(owner: person, component_key: "colours", value: { "theme" => theme })
    theme_css_for(person, account)
    save_look(person, "rounded")

    assert_equal KeystoneUi::Preferences::ThemeCss.new(theme, own_look: true).to_s, theme_css_for(person, account)
  end

  test "a person's saved preset name is written as that preset's theme rule" do
    KeystoneUi::Preferences::ComponentPreference.create!(owner: person, component_key: "colours", value: { "preset_name" => "harbor" })

    assert_equal KeystoneUi::Preferences::ThemeCss.new(KeystoneUi::Looks::Themes[:harbor][:theme]).to_s, theme_css_for(person, account)
  end

  test "a preset's written rule is kept in the Rails cache under the preset's name, the keystone_ui-looks version and whether the person saved a look" do
    KeystoneUi::Preferences::ComponentPreference.create!(owner: person, component_key: "colours", value: { "preset_name" => "harbor" })

    css = theme_css_for(person, account)

    assert_equal css, Rails.cache.read([ "preset_css", "harbor", KeystoneUi::Looks::VERSION, KeystoneUi::Preferences::ThemeCss::VERSION, false ])
  end

  test "a preset changed in a later keystone_ui-looks release is drawn with the change for a person who picked it before" do
    KeystoneUi::Preferences::ComponentPreference.create!(owner: person, component_key: "colours", value: { "preset_name" => "harbor" })
    theme_css_for(person, account)
    changed = KeystoneUi::Looks::Themes[:harbor].merge(theme: KeystoneUi::Looks::Themes[:harbor][:theme].merge("primary" => { "light" => "#123456", "dark" => "#654321" }))
    looks = KeystoneUi::Looks
    released = looks::VERSION
    looks.send(:remove_const, :VERSION)
    looks.const_set(:VERSION, "#{released}-next")

    css = KeystoneUi::Looks::Themes.stub(:[], changed) { theme_css_for(person, account) }

    assert_equal KeystoneUi::Preferences::ThemeCss.new(changed[:theme]).to_s, css
  ensure
    looks.send(:remove_const, :VERSION)
    looks.const_set(:VERSION, released)
  end

  test "a saved preset name the catalogue no longer has writes no theme rule" do
    KeystoneUi::Preferences::ComponentPreference.create!(owner: person, component_key: "colours", value: { "preset_name" => "retired" })

    assert_nil theme_css_for(person, account)
  end

  test "a person's saved preset the catalogue no longer has writes one warning naming the person and the preset" do
    KeystoneUi::Preferences::ComponentPreference.create!(owner: person, component_key: "colours", value: { "preset_name" => "retired" })

    assert_equal [ "keystone_ui-preferences: User #{person.id} saved the preset \"retired\", which keystone_ui-looks does not have" ], warnings_from { theme_css_for(person, account) }
  end

  test "a person whose saved preset the catalogue no longer has gets the account's colours" do
    KeystoneUi::Preferences::ComponentPreference.create!(owner: person, component_key: "colours", value: { "preset_name" => "retired" })
    KeystoneUi::Preferences::ComponentPreference.create!(owner: account, component_key: "colours", value: { "template_name" => "forest" })

    assert_equal "emerald", colours_for(person, account)[:accent]
  end

  test "a person whose saved preset the catalogue no longer has gets the account's preset theme rule" do
    KeystoneUi::Preferences::ComponentPreference.create!(owner: person, component_key: "colours", value: { "preset_name" => "retired" })
    KeystoneUi::Preferences::ComponentPreference.create!(owner: account, component_key: "colours", value: { "preset_name" => "harbor" })

    assert_equal KeystoneUi::Preferences::ThemeCss.new(KeystoneUi::Looks::Themes[:harbor][:theme]).to_s, theme_css_for(person, account)
  end

  test "a member with no colours of their own gets the account's saved theme rule" do
    theme = { "primary" => { "light" => "#171717", "dark" => "#fafafa" } }
    KeystoneUi::Preferences::ComponentPreference.create!(owner: account, component_key: "colours", value: { "theme" => theme })

    assert_equal KeystoneUi::Preferences::ThemeCss.new(theme).to_s, theme_css_for(person, account)
  end
end
