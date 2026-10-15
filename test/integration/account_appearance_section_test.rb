# frozen_string_literal: true

require "test_helper"

class AccountAppearanceSectionTest < ActionDispatch::IntegrationTest
  def admin
    @admin ||= User.create!(name: "Owner")
  end

  def member
    @member ||= User.create!(name: "Rep")
  end

  def account
    @account ||= Account.create!(name: "Acme")
  end

  def setup
    KeystoneUi::Preferences.configure { |config| config.current_account_method = :current_account }
    ApplicationController.signed_in_account = account
  end

  def teardown
    ApplicationController.signed_in_user = nil
    ApplicationController.signed_in_account = nil
    KeystoneUi::Preferences::ComponentPreference.delete_all
    KeystoneUi::Preferences.reset_configuration!
  end

  test "a member's next page is drawn in the template an admin saves for the account with members choosing turned off" do
    KeystoneUi::Preferences::ComponentPreference.create!(owner: member, component_key: "colours", value: { "template_name" => "ocean" })
    ApplicationController.signed_in_user = admin
    get "/settings/account_appearance"
    patch "/settings/account_appearance", params: { template_name: "forest", members_choose: "0" }
    follow_redirect!

    ApplicationController.signed_in_user = member
    get "/palette"

    assert_equal [ "--color-accent-500: #10b981;", "--color-surface-500: #78716c;", "--color-custom-background: #ecfdf5;", "--color-custom-text: #064e3b;" ], css_select("head style").text.lines.map(&:strip).grep(/-(500|background|text):/)
  end

  test "a member's next page sets the theme an admin pastes for the account with members choosing turned off" do
    KeystoneUi::Preferences::ComponentPreference.create!(owner: member, component_key: "colours", value: { "template_name" => "ocean" })
    ApplicationController.signed_in_user = admin
    get "/settings/account_appearance"
    patch "/settings/account_appearance", params: { template_name: "default", members_choose: "0", pasted_theme: ":root {\n  --background: oklch(1 0 0);\n}\n.dark {\n  --background: oklch(0.145 0 0);\n}\n" }
    follow_redirect!

    ApplicationController.signed_in_user = member
    get "/palette"

    assert_equal [ "--ks-color-page: oklch(1 0 0);", "--ks-color-page-dark: oklch(0.145 0 0);" ], css_select("head style").text.lines.map(&:strip).grep(/--ks-color-page/)
  end
end
