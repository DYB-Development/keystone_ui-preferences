# frozen_string_literal: true

require "test_helper"

class TableFromSavedPreferenceTest < ActionDispatch::IntegrationTest
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

  test "a table with a key renders from the value the signed-in person saved for it" do
    patch "/keystone_ui_preferences/months", params: { hidden_columns: [ "pipeline" ] }, as: :json

    get "/months"

    assert_equal [ "Month" ], css_select("thead th").map { |header| header.text.strip }
  end
end
