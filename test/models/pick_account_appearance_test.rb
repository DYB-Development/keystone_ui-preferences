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
    assert_equal "Choose Default, one of the colour templates or Custom.", pick(template_name: "sunset").message
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
end
