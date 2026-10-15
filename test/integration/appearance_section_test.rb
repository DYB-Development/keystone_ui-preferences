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
    KeystoneUi::Preferences.reset_configuration!
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

  test "a person who saves a look in the appearance section sees the next page marked with it" do
    get "/settings/appearance"
    patch "/settings/appearance", params: { template_name: "forest", look: "rounded" }
    follow_redirect!
    get "/palette"

    assert_equal "rounded", css_select("html").first["data-look"]
  end

  test "a person who pastes a :root block and a .dark block in the appearance section has their checked colour roles saved" do
    get "/settings/appearance"
    patch "/settings/appearance", params: { pasted_theme: ":root {\n  --shadow-2xl: 0 1px 3px 0px hsl(0 0% 0% / 0.05);\n  --primary: oklch(0.205 0 0);\n}\n.dark {\n  --primary: oklch(0.922 0 0);\n}\n" }

    assert_equal({ "theme" => { "primary" => { "light" => "oklch(0.205 0 0)", "dark" => "oklch(0.922 0 0)" } } }, KeystoneUi::Preferences::ComponentPreference.find_by(owner: person, component_key: "colours").value)
  end

  test "a person who pastes a theme in the appearance section sees every page set the theme's light and dark values" do
    patch "/settings/appearance", params: { pasted_theme: ":root {\n  --background: oklch(1 0 0);\n}\n.dark {\n  --background: oklch(0.145 0 0);\n}\n" }
    get "/palette"

    assert_equal [ "--ks-color-page: oklch(1 0 0);", "--ks-color-page-dark: oklch(0.145 0 0);" ], css_select("head style").text.lines.map(&:strip).grep(/--ks-color-page/)
  end

  test "a person who pastes a theme with a radius and a font the app offers sees every page set them" do
    KeystoneUi::Preferences.configure { |config| config.theme_fonts = [ "Inter" ] }

    patch "/settings/appearance", params: { pasted_theme: ":root {\n  --primary: oklch(0.205 0 0);\n  --radius: 0.5rem;\n  --font-sans: Inter, Comic Neue, sans-serif;\n}\n" }
    get "/palette"

    assert_equal [ "--ks-radius-control: 0.5rem;", "--ks-radius-surface: 0.5rem;", "--ks-font-body: Inter, sans-serif;" ], css_select("head style").text.lines.map(&:strip).grep(/--ks-(radius|font)/)
  end

  test "a person who changes one theme field in the appearance section has only that setting changed, on the next page too" do
    patch "/settings/appearance", params: { pasted_theme: ":root {\n  --primary: oklch(0.205 0 0);\n  --radius: 0.5rem;\n}\n.dark {\n  --primary: oklch(0.922 0 0);\n}\n" }
    get "/settings/appearance"
    fields = css_select("form input[name^='theme[']").map { |field| [ field["name"], field["value"].to_s ] }
    fields = fields.map { |name, value| [ name, name == "theme[radius][light]" ? "0.75rem" : value ] }

    patch "/settings/appearance", params: URI.encode_www_form(fields)
    get "/palette"

    assert_equal [
      { "theme" => { "primary" => { "light" => "oklch(0.205 0 0)", "dark" => "oklch(0.922 0 0)" }, "radius" => { "light" => "0.75rem" } } },
      [ "--ks-color-accent: oklch(0.205 0 0);", "--ks-color-accent-dark: oklch(0.922 0 0);", "--ks-radius-control: 0.75rem;", "--ks-radius-surface: 0.75rem;" ]
    ], [ KeystoneUi::Preferences::ComponentPreference.find_by(owner: person, component_key: "colours").value, css_select("head style").text.lines.map(&:strip).grep(/--ks-(color-accent(-dark)?|radius-[a-z]+):/) ]
  end
end
