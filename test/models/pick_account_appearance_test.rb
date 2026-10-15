# frozen_string_literal: true

require "test_helper"

class PickAccountAppearanceTest < ActiveSupport::TestCase
  def admin
    @admin ||= User.create!(name: "Owner")
  end

  def account
    @account ||= Account.create!(name: "Acme")
  end

  def teardown
    KeystoneUi::Preferences.reset_configuration!
    KeystoneUi::Preferences::ComponentPreference.delete_all
  end

  def pick(values)
    KeystoneUi::Preferences::PickAccountAppearance.new(person: admin, account: account, values: values).call
  end

  def account_preference(key)
    KeystoneUi::Preferences::ComponentPreference.find_by(owner: account, component_key: key)
  end

  test "saving a template keeps its name as the account's colours" do
    pick(template_name: "forest")

    assert_equal({ "template_name" => "forest" }, account_preference("colours").value)
  end

  test "saving Custom keeps the accent, surface and text colour as the account's colours" do
    pick(template_name: "", accent: "#e11d48", surface: "#f5e6c8", text: "#3b2f1e")

    assert_equal({ "accent" => "#e11d48", "surface" => "#f5e6c8", "text" => "#3b2f1e" }, account_preference("colours").value)
  end

  test "a template that is not in the catalogue is refused with a reason" do
    assert_equal "Choose Default, one of the colour templates, one of the preset themes or Custom.", pick(template_name: "sunset").message
  end

  test "a save with no account to save it on is refused with a reason" do
    result = KeystoneUi::Preferences::PickAccountAppearance.new(person: admin, account: nil, values: { template_name: "forest" }).call

    assert_equal "There is no account to save this appearance on.", result.message
  end

  test "turning the colours switch off keeps the account's members from choosing their own colours" do
    pick(template_name: "forest", members_choose: "0")

    assert_equal false, account_preference("colours").members_choose
  end

  test "saving a look keeps it as the account's look" do
    pick(template_name: "forest", look: "rounded")

    assert_equal({ "look" => "rounded" }, account_preference("look").value)
  end

  test "saving the app's own look leaves the account with no look" do
    KeystoneUi::Preferences::ComponentPreference.create!(owner: account, component_key: "look", value: { "look" => "rounded" })

    pick(template_name: "forest", look: "")

    assert_equal({}, account_preference("look").value)
  end

  test "turning the look switch off keeps the account's members from choosing their own look" do
    pick(template_name: "forest", look: "rounded", members_choose_look: "0")

    assert_equal false, account_preference("look").members_choose
  end

  test "a look the app does not register is refused with a reason" do
    assert_equal "Choose the app's own look or one of the looks it offers.", pick(template_name: "forest", look: "retired").message
  end

  test "a save that sends a look and no colours keeps the look" do
    pick(look: "rounded")

    assert_equal({ "look" => "rounded" }, account_preference("look").value)
  end

  test "colours are refused with a reason when the app turns off account colours" do
    KeystoneUi::Preferences.configure { |config| config.account_colors = false }

    assert_equal "This app does not let accounts choose their colours.", pick(template_name: "forest").message
  end

  test "a look sent with a save is ignored when the app turns off account looks" do
    KeystoneUi::Preferences.configure { |config| config.account_looks = false }

    pick(template_name: "forest", look: "rounded")

    assert_nil account_preference("look")
  end

  PASTED_THEME = ":root {\n  --radius: 0.625rem;\n  --primary: oklch(0.205 0 0);\n}\n.dark {\n  --primary: oklch(0.922 0 0);\n}\n"

  test "saving a pasted theme keeps every checked theme setting in it as the account's colours" do
    pick(template_name: "default", pasted_theme: PASTED_THEME)

    assert_equal({ "theme" => { "primary" => { "light" => "oklch(0.205 0 0)", "dark" => "oklch(0.922 0 0)" }, "radius" => { "light" => "0.625rem" } } }, account_preference("colours").value)
  end

  test "a pasted theme is refused with a reason when the app turns off account colours" do
    KeystoneUi::Preferences.configure { |config| config.account_colors = false }

    assert_equal "This app does not let accounts choose their colours.", pick(pasted_theme: PASTED_THEME).message
  end

  test "a pasted theme containing url( is refused and leaves the account's colours as they were" do
    pick(template_name: "forest")

    pick(pasted_theme: "#{PASTED_THEME}\n.logo { background: url(x.png); }")

    assert_equal({ "template_name" => "forest" }, account_preference("colours").value)
  end

  test "a theme setting typed by hand is saved as the account's theme, leaving out the fields left blank" do
    pick(template_name: "default", theme: { "primary" => { "light" => "#171717", "dark" => "" }, "radius" => { "light" => "" } })

    assert_equal({ "theme" => { "primary" => { "light" => "#171717" } } }, account_preference("colours").value)
  end

  test "theme fields sent unchanged with a template save the template over the account's saved theme" do
    pick(template_name: "default", theme: { "primary" => { "light" => "#171717" } })

    pick(template_name: "forest", theme: { "primary" => { "light" => "#171717", "dark" => "" } })

    assert_equal({ "template_name" => "forest" }, account_preference("colours").value)
  end

  test "a preset saves its name as the account's colours when the theme fields hold that preset's values, as they do once its card is picked" do
    pick(template_name: "harbor", theme: KeystoneUi::Looks::Themes[:harbor][:theme])

    assert_equal({ "preset_name" => "harbor" }, account_preference("colours").value)
  end

  test "theme fields sent unchanged with a template save the template over the account's saved preset" do
    pick(template_name: "harbor")

    pick(template_name: "forest", theme: KeystoneUi::Looks::Themes[:harbor][:theme])

    assert_equal({ "template_name" => "forest" }, account_preference("colours").value)
  end
end
