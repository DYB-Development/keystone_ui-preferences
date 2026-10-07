# frozen_string_literal: true

require "test_helper"

class AccountLayoutTest < ActionDispatch::IntegrationTest
  def person
    @person ||= User.create!(name: "Rep")
  end

  def account
    @account ||= Account.create!(name: "Team")
  end

  def setup
    ApplicationController.signed_in_user = person
    ApplicationController.signed_in_account = account
    KeystoneUi::Preferences.configure { |config| config.current_account_method = :current_account }
  end

  def teardown
    ApplicationController.signed_in_user = nil
    ApplicationController.signed_in_account = nil
    KeystoneUi::Preferences::ComponentPreference.delete_all
    KeystoneUi::Preferences.reset_configuration!
  end

  def saved(owner, hidden, members_choose: true)
    KeystoneUi::Preferences::ComponentPreference.create!(owner: owner, component_key: "months", value: { "hidden_columns" => hidden }, members_choose: members_choose)
  end

  def headers
    css_select("thead th").map { |header| header.text.strip }
  end

  test "a table shows the account's layout when the account does not let members choose" do
    saved(person, [])
    saved(account, [ "pipeline" ], members_choose: false)

    get "/months"

    assert_equal [ "Month" ], headers
  end

  test "a table shows the person's own layout when the account lets members choose" do
    saved(person, [ "pipeline" ])
    saved(account, [])

    get "/months"

    assert_equal [ "Month" ], headers
  end

  test "a table shows the person's own layout when the account has no saved layout" do
    saved(person, [ "pipeline" ])

    get "/months"

    assert_equal [ "Month" ], headers
  end

  test "a table shows its default layout when neither the person nor the account has a saved layout" do
    get "/months"

    assert_equal [ "Month", "Pipeline" ], headers
  end

  test "with no account method named the account's layout is skipped" do
    KeystoneUi::Preferences.configure { |config| config.current_account_method = nil }
    saved(person, [])
    saved(account, [ "pipeline" ], members_choose: false)

    get "/months"

    assert_equal [ "Month", "Pipeline" ], headers
  end

  test "reading the layout that applies makes one query whether or not either row exists" do
    saved(account, [ "pipeline" ])
    queries = []
    counting = ->(*, payload) { queries << payload[:sql] if payload[:sql].include?("keystone_ui_preferences_component_preferences") }

    ActiveSupport::Notifications.subscribed(counting, "sql.active_record") { get "/months" }

    assert_equal 1, queries.size
  end

  test "a person whose account does not let members choose sees no Columns menu" do
    saved(account, [], members_choose: false)

    get "/months"

    assert_empty css_select("[data-controller=column-picker]")
  end
end
