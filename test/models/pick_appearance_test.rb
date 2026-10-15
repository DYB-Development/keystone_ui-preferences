# frozen_string_literal: true

require "test_helper"

class PickAppearanceTest < ActiveSupport::TestCase
  def person
    @person ||= User.create!(name: "Rep")
  end

  def teardown
    KeystoneUi::Preferences.reset_configuration!
    KeystoneUi::Preferences::ComponentPreference.delete_all
  end

  def pick(values, account = nil)
    KeystoneUi::Preferences::PickAppearance.new(person: person, account: account, values: values).call
  end

  def saved_value
    KeystoneUi::Preferences::ComponentPreference.find_by(owner: person, component_key: "colours")&.value
  end

  test "saving a template keeps its name as the person's colours" do
    pick(template_name: "forest")

    assert_equal({ "template_name" => "forest" }, saved_value)
  end

  test "saving Custom keeps the accent, surface and text colour as the person's colours" do
    pick(template_name: "", accent: "#e11d48", surface: "#f5e6c8", text: "#3b2f1e")

    assert_equal({ "accent" => "#e11d48", "surface" => "#f5e6c8", "text" => "#3b2f1e" }, saved_value)
  end

  test "saving Default removes the person's saved colours" do
    pick(template_name: "forest")

    pick(template_name: "default")

    assert_nil saved_value
  end

  def account_setting_colours
    Account.create!(name: "Acme").tap do |account|
      KeystoneUi::Preferences::ComponentPreference.create!(owner: account, component_key: "colours", value: { "template_name" => "ocean" }, members_choose: false)
    end
  end

  test "a save is refused with a reason when the account sets the colours for everyone" do
    assert_equal "Your account sets the colours for everyone, so this was not saved.", pick({ template_name: "forest" }, account_setting_colours).message
  end

  test "a save refused because the account sets the colours saves nothing for the person" do
    pick({ template_name: "forest" }, account_setting_colours)

    assert_nil saved_value
  end

  test "a template that is not in the catalogue is refused with a reason" do
    assert_equal "Choose Default, one of the colour templates or Custom.", pick(template_name: "jungle").message
  end

  test "a refused template leaves the person's saved colours as they were" do
    pick(template_name: "forest")

    pick(template_name: "jungle")

    assert_equal({ "template_name" => "forest" }, saved_value)
  end

  def custom(accent: "#e11d48", surface: "#f5e6c8", text: "#3b2f1e")
    pick(template_name: "", accent: accent, surface: surface, text: text)
  end

  test "a Custom accent that is neither a six-digit hex nor a catalogue accent is refused with a reason" do
    assert_equal "Choose each colour as a six-digit hex value, such as #1d4ed8.", custom(accent: "red; } body { display: none").message
  end

  test "a Custom surface that is neither a six-digit hex nor a catalogue surface is refused with a reason" do
    assert_equal "Choose each colour as a six-digit hex value, such as #1d4ed8.", custom(surface: "blue").message
  end

  test "a Custom text colour that is not a six-digit hex is refused with a reason" do
    assert_equal "Choose each colour as a six-digit hex value, such as #1d4ed8.", custom(text: "zinc").message
  end

  test "a refused Custom colour leaves the person's saved colours as they were" do
    pick(template_name: "forest")

    custom(accent: "not a colour")

    assert_equal({ "template_name" => "forest" }, saved_value)
  end

  test "saving Custom with a catalogue accent and surface keeps their names" do
    custom(accent: "emerald", surface: "stone")

    assert_equal({ "accent" => "emerald", "surface" => "stone", "text" => "#3b2f1e" }, saved_value)
  end

  def saved_mode
    KeystoneUi::Preferences::ComponentPreference.find_by(owner: person, component_key: "mode")&.value
  end

  test "saving a mode keeps it as the person's mode" do
    pick(template_name: "forest", mode: "dark")

    assert_equal({ "mode" => "dark" }, saved_mode)
  end

  test "saving Default with a mode keeps the mode as the person's mode" do
    pick(template_name: "default", mode: "system")

    assert_equal({ "mode" => "system" }, saved_mode)
  end

  test "a mode other than Light, Dark, System or Custom is refused with a reason" do
    assert_equal "Choose Light, Dark, System or Custom for the mode.", pick(template_name: "forest", mode: "sepia").message
  end

  test "a refused mode leaves the person's saved colours and mode as they were" do
    pick(template_name: "forest", mode: "dark")

    pick(template_name: "ocean", mode: "sepia")

    assert_equal [ { "template_name" => "forest" }, { "mode" => "dark" } ], [ saved_value, saved_mode ]
  end

  test "a save that sends no mode leaves the person's saved mode as it was" do
    pick(template_name: "forest", mode: "dark")

    pick(template_name: "ocean")

    assert_equal({ "mode" => "dark" }, saved_mode)
  end

  test "a mode saves while the account sets the colours for everyone" do
    pick({ mode: "dark" }, account_setting_colours)

    assert_equal({ "mode" => "dark" }, saved_mode)
  end

  def saved_look
    KeystoneUi::Preferences::ComponentPreference.find_by(owner: person, component_key: "look")&.value
  end

  test "saving a look keeps it as the person's look" do
    pick(template_name: "forest", look: "rounded")

    assert_equal({ "look" => "rounded" }, saved_look)
  end

  test "saving the app's own look removes the person's saved look" do
    pick(template_name: "forest", look: "rounded")

    pick(template_name: "forest", look: "")

    assert_nil saved_look
  end

  test "a look the app does not register is refused with a reason" do
    assert_equal "Choose the app's own look or one of the looks it offers.", pick(template_name: "forest", look: "retired").message
  end

  test "a refused look leaves the person's saved colours, mode and look as they were" do
    pick(template_name: "forest", mode: "dark", look: "rounded")

    pick(template_name: "ocean", mode: "light", look: "retired")

    assert_equal [ { "template_name" => "forest" }, { "mode" => "dark" }, { "look" => "rounded" } ], [ saved_value, saved_mode, saved_look ]
  end

  test "a look sent with a save is ignored when the app turns off a person's own looks" do
    KeystoneUi::Preferences.configure { |config| config.user_looks = false }

    pick(template_name: "forest", look: "rounded")

    assert_nil saved_look
  end

  test "a look the app does not register is not refused when the app turns off a person's own looks" do
    KeystoneUi::Preferences.configure { |config| config.user_looks = false }

    assert_predicate pick(template_name: "forest", look: "retired"), :ok?
  end

  test "colours are refused with a reason when the app turns off account colours" do
    KeystoneUi::Preferences.configure { |config| config.account_colors = false }

    assert_equal "This app sets the colours for everyone, so this was not saved.", pick(template_name: "forest").message
  end

  test "a look sent with a save is ignored when the account turns off members choosing their own look" do
    account = Account.create!(name: "Acme")
    KeystoneUi::Preferences::ComponentPreference.create!(owner: account, component_key: "look", value: { "look" => "sharp" }, members_choose: false)

    pick({ template_name: "forest", look: "rounded" }, account)

    assert_nil saved_look
  end

  PASTED_THEME = <<~CSS
    :root {
      --radius: 0.625rem;
      --background: oklch(1 0 0);
      --primary: oklch(0.205 0 0);
    }

    .dark {
      --background: oklch(0.145 0 0);
      --primary: oklch(0.922 0 0);
    }
  CSS

  test "saving a pasted :root block and .dark block keeps every colour role in them as the person's colours" do
    pick(template_name: "", pasted_theme: PASTED_THEME)

    assert_equal({ "theme" => { "background" => { "light" => "oklch(1 0 0)", "dark" => "oklch(0.145 0 0)" }, "primary" => { "light" => "oklch(0.205 0 0)", "dark" => "oklch(0.922 0 0)" } } }, saved_value)
  end

  test "a pasted theme saves when the save sends no template" do
    pick(pasted_theme: ":root { --ring: #a1a1a1; }")

    assert_equal({ "theme" => { "ring" => { "light" => "#a1a1a1" } } }, saved_value)
  end

  test "a pasted theme is refused with the existing reason when the account sets the colours for everyone" do
    assert_equal "Your account sets the colours for everyone, so this was not saved.", pick({ pasted_theme: PASTED_THEME }, account_setting_colours).message
  end
end
