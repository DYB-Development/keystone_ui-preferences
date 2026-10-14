# frozen_string_literal: true

require "test_helper"
require "minitest/mock"

class AccountAppearancePartialTest < ActionView::TestCase
  include KeystoneUiHelper

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

  def render_section
    render partial: "keystone_ui/preferences/settings/account_appearance", locals: { person: admin, account: account, submit_url: "/settings/account_appearance" }
  end

  def template_options
    css_select("input[type=radio][name=template_name]").map { |option| option["value"] }
  end

  test "the account's section offers Default, the five colour templates and Custom" do
    render_section

    assert_equal [ "default", "ocean", "forest", "twilight", "coral", "arctic", "" ], template_options
  end

  def save(key, value, members_choose: true)
    KeystoneUi::Preferences::ComponentPreference.create!(owner: account, component_key: key, value: value, members_choose: members_choose)
  end

  test "the account's section selects the template the account saved" do
    save("colours", { "template_name" => "forest" })

    render_section

    assert_equal [ "forest" ], css_select("input[type=radio][name=template_name][checked]").map { |option| option["value"] }
  end

  test "the account's section's accent picker shows the accent drawn from the account's colours" do
    save("colours", { "template_name" => "forest" })

    render_section

    assert_equal [ "#10b981" ], css_select("input[type=hidden][name=accent]").map { |input| input["value"] }
  end

  def switch_on?(name)
    css_select("input[type=checkbox][name=#{name}][value=\"1\"]").map { |input| input.key?("checked") }
  end

  test "the account's section lets members choose their own colours until an admin turns it off" do
    render_section

    assert_equal [ true ], switch_on?("members_choose")
  end

  test "the account's section shows the colours switch off once an admin turns it off" do
    save("colours", { "template_name" => "forest" }, members_choose: false)

    render_section

    assert_equal [ false ], switch_on?("members_choose")
  end

  test "the account's section selects the look the account saved among the app's own look and every registered look" do
    save("look", { "look" => "sharp" })

    render_section

    assert_equal [ [ "", false ], [ "brutalist", false ], [ "compact", false ], [ "rounded", false ], [ "sharp", true ], [ "soft", false ] ], css_select("input[type=radio][name=look]").map { |option| [ option["value"], option.key?("checked") ] }
  end

  test "the account's section lets members choose their own look until an admin turns it off" do
    render_section

    assert_equal [ true ], switch_on?("members_choose_look")
  end

  test "the account's section shows the look switch off once an admin turns it off" do
    save("look", { "look" => "sharp" }, members_choose: false)

    render_section

    assert_equal [ false ], switch_on?("members_choose_look")
  end

  def look_options
    css_select("input[type=radio][name=look]")
  end

  test "the account's section offers no look when the app turns off account looks" do
    KeystoneUi::Preferences.configure { |config| config.account_looks = false }

    render_section

    assert_empty look_options
  end
end
