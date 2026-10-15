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

  test "an admin finds the preview and Reset in the account's section, and a member who may not choose sees the theme setting the admin changes and saves" do
    ApplicationController.signed_in_user = admin
    get "/settings/account_appearance"
    found = [ css_select("[data-theme-preview] [data-theme]").size, css_select("form button").map { |button| button.text.strip }.include?("Reset") ]
    patch "/settings/account_appearance", params: { template_name: "default", members_choose: "0", theme: { primary: { light: "#123456", dark: "#abcdef" } } }
    follow_redirect!

    ApplicationController.signed_in_user = member
    get "/palette"

    assert_equal [ [ 2, true ], [ "--ks-color-accent: #123456;", "--ks-color-accent-dark: #abcdef;" ] ], [ found, css_select("head style").text.lines.map(&:strip).grep(/--ks-color-accent(-dark)?:/) ]
  end

  test "an admin whose typed theme for the account is refused is told why, sees what they typed in the theme fields and under the refused one, and has nothing saved" do
    ApplicationController.signed_in_user = admin
    patch "/settings/account_appearance", params: { template_name: "default", members_choose: "1", theme: { primary: { light: "#123456", dark: "#abcdef" }, radius: { light: "big" } } }

    assert_equal [
      true,
      { "theme[primary][light]" => "#123456", "theme[primary][dark]" => "#abcdef", "theme[radius][light]" => "big" },
      [ "The --radius value is not a number followed by px, rem or em, or zero, so it was not saved." ],
      nil
    ], [
      response.body.include?("The --radius value is not a number followed by px, rem or em, or zero, so it was not saved."),
      css_select("form input[name='theme[primary][light]'], form input[name='theme[primary][dark]'], form input[name='theme[radius][light]']").to_h { |field| [ field["name"], field["value"] ] },
      css_select(".ks-form-field:has(> input[name='theme[radius][light]']) + p.ks-error").map { |error| error.text.strip },
      KeystoneUi::Preferences::ComponentPreference.find_by(owner: account, component_key: "colours")
    ]
  end
end
