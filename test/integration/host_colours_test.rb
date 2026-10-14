# frozen_string_literal: true

require "test_helper"

class HostColoursTest < ActionDispatch::IntegrationTest
  def person
    @person ||= User.create!(name: "Rep")
  end

  def setup
    ApplicationController.signed_in_user = person
  end

  def teardown
    ApplicationController.signed_in_user = nil
    ApplicationController.signed_in_account = nil
    KeystoneUi::Preferences.reset_configuration!
    KeystoneUi::Preferences::ComponentPreference.delete_all
  end

  def palette_lines
    css_select("head style").text.lines.map(&:strip)
  end

  test "a person with saved colours opening a page kept on the app's colours sees the app's default colours" do
    KeystoneUi::Preferences::ComponentPreference.create!(owner: person, component_key: "colours", value: { "template_name" => "forest" })

    get "/host_palette"

    assert_equal [ "--color-accent-500: #3b82f6;", "--color-surface-500: #71717a;", "--color-custom-background: #ffffff;", "--color-custom-text: #18181b;" ], palette_lines.grep(/-(500|background|text):/)
  end

  test "a person who saved Dark opening a page kept on the app's colours sees the app's default mode" do
    KeystoneUi::Preferences::ComponentPreference.create!(owner: person, component_key: "mode", value: { "mode" => "dark" })

    get "/host_palette"

    assert_equal "light", css_select("html").first["data-theme"]
  end

  test "a person who saved a look opening a page kept on the app's colours sees the app's default look" do
    KeystoneUi.configuration.default_look = "sharp"
    KeystoneUi::Preferences::ComponentPreference.create!(owner: person, component_key: "look", value: { "look" => "rounded" })

    get "/host_palette"

    assert_equal "sharp", css_select("html").first["data-look"]
  ensure
    KeystoneUi.configuration.default_look = nil
  end

  test "a member of an account with saved colours opening a page kept on the app's colours sees the app's default colours" do
    KeystoneUi::Preferences.configure { |config| config.current_account_method = :current_account }
    account = Account.create!(name: "Acme")
    ApplicationController.signed_in_account = account
    KeystoneUi::Preferences::ComponentPreference.create!(owner: account, component_key: "colours", value: { "template_name" => "forest" }, members_choose: false)

    get "/host_palette"

    assert_equal [ "--color-accent-500: #3b82f6;", "--color-surface-500: #71717a;", "--color-custom-background: #ffffff;", "--color-custom-text: #18181b;" ], palette_lines.grep(/-(500|background|text):/)
  end

  test "an action left out of the host colours declaration's only option draws the colours the person saved" do
    KeystoneUi::Preferences::ComponentPreference.create!(owner: person, component_key: "colours", value: { "template_name" => "forest" })

    get "/partly_kept_palettes"

    assert_includes palette_lines, "--color-accent-500: #10b981;"
  end
end
