# frozen_string_literal: true

require "test_helper"

class MissingCatalogueNameTest < ActionDispatch::IntegrationTest
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

  test "a person whose saved template the catalogue no longer has opens a page drawn in the app's default colours" do
    KeystoneUi::Preferences::ComponentPreference.create!(owner: person, component_key: "colours", value: { "template_name" => "retired" })

    get "/palette"

    assert_equal [ "--color-accent-500: #3b82f6;", "--color-surface-500: #71717a;", "--color-custom-background: #ffffff;", "--color-custom-text: #18181b;" ], css_select("head style").text.lines.map(&:strip).grep(/-(500|background|text):/)
  end
end
