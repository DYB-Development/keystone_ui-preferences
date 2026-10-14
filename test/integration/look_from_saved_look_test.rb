# frozen_string_literal: true

require "test_helper"

class LookFromSavedLookTest < ActionDispatch::IntegrationTest
  def person
    @person ||= User.create!(name: "Rep")
  end

  def teardown
    ApplicationController.signed_in_user = nil
    KeystoneUi::Preferences::ComponentPreference.delete_all
  end

  test "a page opened by a person who saved a look is marked with that look" do
    ApplicationController.signed_in_user = person
    KeystoneUi::Preferences::ComponentPreference.create!(owner: person, component_key: "look", value: { "look" => "rounded" })

    get "/palette"

    assert_equal "rounded", css_select("html").first["data-look"]
  end
end
