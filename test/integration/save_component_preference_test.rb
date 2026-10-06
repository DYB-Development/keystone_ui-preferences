# frozen_string_literal: true

require "test_helper"

class SaveComponentPreferenceTest < ActionDispatch::IntegrationTest
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

  test "saves the JSON object a signed-in person sends as their value for the key" do
    patch "/keystone_ui_preferences/months", params: { hidden_columns: [ "pipeline" ] }, as: :json

    assert_equal({ "hidden_columns" => [ "pipeline" ] }, KeystoneUi::Preferences::ComponentPreference.find_by(owner: person, component_key: "months").value)
  end

  test "a second save for the same person and key replaces the first value" do
    patch "/keystone_ui_preferences/months", params: { hidden_columns: [ "pipeline" ] }, as: :json
    patch "/keystone_ui_preferences/months", params: { hidden_columns: [ "outreach" ] }, as: :json

    assert_equal [ { "hidden_columns" => [ "outreach" ] } ], KeystoneUi::Preferences::ComponentPreference.where(owner: person, component_key: "months").map(&:value)
  end

  test "a save with nobody signed in is refused by the host's sign-in check" do
    ApplicationController.signed_in_user = nil

    patch "/keystone_ui_preferences/months", params: { hidden_columns: [ "pipeline" ] }, as: :json

    assert_response :unauthorized
  end
end
