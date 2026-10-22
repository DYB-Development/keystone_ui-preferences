# frozen_string_literal: true

require "test_helper"

class ModeFromThemeToggleTest < ActionDispatch::IntegrationTest
  def person
    @person ||= User.create!(name: "Rep")
  end

  def teardown
    ApplicationController.signed_in_user = nil
    KeystoneUi::Preferences::ComponentPreference.delete_all
  end

  test "a person who saved Light and picked Dark on the theme toggle gets dark as the theme mode" do
    ApplicationController.signed_in_user = person
    KeystoneUi::Preferences::ComponentPreference.create!(owner: person, component_key: "mode", value: { "mode" => "light" })
    cookies[KeystoneUi::ThemeChoice::COOKIE] = "dark"

    get "/palette"

    assert_equal "dark", css_select("body").first["data-theme-preference-value"]
  end
end
