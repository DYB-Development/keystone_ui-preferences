# frozen_string_literal: true

require "test_helper"

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
end
