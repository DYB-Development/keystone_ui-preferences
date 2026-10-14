# frozen_string_literal: true

require "test_helper"

class ModeFromSavedModeTest < ActionDispatch::IntegrationTest
  def person
    @person ||= User.create!(name: "Rep")
  end

  def teardown
    ApplicationController.signed_in_user = nil
    ApplicationController.signed_in_account = nil
    KeystoneUi::Preferences.reset_configuration!
    KeystoneUi::Preferences::ComponentPreference.delete_all
  end

  def page_mode
    css_select("html").first["data-theme"]
  end

  test "a page opened by a person who saved Dark is marked dark" do
    ApplicationController.signed_in_user = person
    KeystoneUi::Preferences::ComponentPreference.create!(owner: person, component_key: "mode", value: { "mode" => "dark" })

    get "/palette"

    assert_equal "dark", page_mode
  end

  test "a page opened by a visitor who is not signed in is marked with the app's default mode" do
    KeystoneUi::Preferences.configure { |config| config.default_mode = "dark" }

    get "/palette"

    assert_equal "dark", page_mode
  end
end
