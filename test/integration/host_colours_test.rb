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
end
