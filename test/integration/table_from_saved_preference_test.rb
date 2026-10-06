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

  test "a person with nothing saved gets a Columns menu that saves to their save address" do
    get "/months"

    assert_equal [ "/keystone_ui_preferences/months" ], css_select("[data-controller=column-picker]").map { |picker| picker["data-column-picker-save-url-value"] }
  end

  test "another person viewing a table with the same key gets nothing from the first person's save" do
    patch "/keystone_ui_preferences/months", params: { hidden_columns: [ "pipeline" ] }, as: :json
    ApplicationController.signed_in_user = User.create!(name: "Teammate")

    get "/months"

    assert_equal [ "Month", "Pipeline" ], css_select("thead th").map { |header| header.text.strip }
  end

  test "a table viewed with nobody signed in shows no Columns menu" do
    ApplicationController.signed_in_user = nil

    get "/months"

    assert_empty css_select("[data-controller=column-picker]")
  end
end
