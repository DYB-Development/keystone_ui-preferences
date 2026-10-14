# frozen_string_literal: true

require "test_helper"

class PaletteFromSavedColoursTest < ActionDispatch::IntegrationTest
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

  def palette_lines
    css_select("head style").text.lines.map(&:strip)
  end

  test "a layout that calls the palette style tag draws the page in the colours the signed-in person saved" do
    KeystoneUi::Preferences::ComponentPreference.create!(owner: person, component_key: "colours", value: { "template_name" => "forest" })

    get "/palette"

    assert_equal [ "--color-accent-500: #10b981;", "--color-surface-500: #78716c;", "--color-custom-background: #ecfdf5;", "--color-custom-text: #064e3b;" ], palette_lines.grep(/-(500|background|text):/)
  end
end
