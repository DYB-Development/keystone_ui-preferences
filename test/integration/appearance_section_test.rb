# frozen_string_literal: true

require "test_helper"

class AppearanceSectionTest < ActionDispatch::IntegrationTest
  def person
    @person ||= User.create!(name: "Rep")
  end

  def setup
    ApplicationController.signed_in_user = person
  end

  def teardown
    ApplicationController.signed_in_user = nil
    KeystoneUi::Preferences::ComponentPreference.delete_all
  end

  test "a person who saves a template in the appearance section sees the next page drawn in it" do
    get "/settings/appearance"
    patch "/settings/appearance", params: { template_name: "forest" }
    follow_redirect!
    get "/palette"

    assert_equal [ "--color-accent-500: #10b981;", "--color-surface-500: #78716c;", "--color-custom-background: #ecfdf5;", "--color-custom-text: #064e3b;" ], css_select("head style").text.lines.map(&:strip).grep(/-(500|background|text):/)
  end

  test "a person who saves Dark in the appearance section sees the next page marked dark" do
    get "/settings/appearance"
    patch "/settings/appearance", params: { template_name: "forest", mode: "dark" }
    follow_redirect!
    get "/palette"

    assert_equal "dark", css_select("html").first["data-theme"]
  end

  test "saving in the appearance section clears the theme toggle's choice in this browser" do
    cookies[KeystoneUi::ThemeChoice::COOKIE] = "light"

    patch "/settings/appearance", params: { template_name: "forest", mode: "dark" }

    assert_predicate cookies[KeystoneUi::ThemeChoice::COOKIE], :blank?
  end

  test "saving in another settings section leaves the theme toggle's choice in this browser" do
    cookies[KeystoneUi::ThemeChoice::COOKIE] = "light"

    patch "/settings/navigation_placement", params: { placement: "left" }

    assert_equal "light", cookies[KeystoneUi::ThemeChoice::COOKIE]
  end
end
