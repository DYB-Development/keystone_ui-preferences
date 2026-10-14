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
end
