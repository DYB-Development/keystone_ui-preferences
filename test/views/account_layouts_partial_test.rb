# frozen_string_literal: true

require "test_helper"

class AccountLayoutsPartialTest < ActionView::TestCase
  include KeystoneUiHelper

  def admin
    @admin ||= User.create!(name: "Owner")
  end

  def account
    @account ||= Account.create!(name: "Acme")
  end

  def teardown
    KeystoneUi::Preferences::ComponentPreference.delete_all
    KeystoneUi::Preferences.reset_configuration!
  end

  def saved(owner, key, value = { "hidden_columns" => [] }, members_choose: true)
    KeystoneUi::Preferences::ComponentPreference.create!(owner: owner, component_key: key, value: value, members_choose: members_choose)
  end

  def render_section
    render partial: "keystone_ui/preferences/settings/account_layouts", locals: { person: admin, account: account, submit_url: "/settings/account_layouts" }
  end

  test "the account section lists each key the admin or the account has a saved layout for and no other" do
    saved(admin, "months")
    saved(account, "jobs")
    saved(User.create!(name: "Teammate"), "leads")

    render_section

    assert_equal %w[jobs months], css_select("[data-component-key]").map { |section| section["data-component-key"] }
  end

  test "each key has a members-choose switch showing whether the account lets members choose" do
    saved(admin, "months")
    saved(account, "jobs", members_choose: false)

    render_section

    assert_equal({ "jobs" => false, "months" => true }, css_select("[data-component-key]").to_h { |section| [ section["data-component-key"], section.at_css("input[type=checkbox][name=members_choose][value=\"1\"]").key?("checked") ] })
  end

  test "a key the admin has a saved layout for has a button that makes it the account's layout" do
    saved(admin, "months")

    render_section

    assert_equal [ "months" ], css_select("form:has(input[name=use_mine])").map { |form| form.at_css("input[name=component_key]")["value"] }
  end

  test "a key the admin has no saved layout for has no button to make it the account's" do
    saved(account, "jobs")

    render_section

    assert_empty css_select("input[name=use_mine]")
  end

  test "the account section reads its saved layouts in one query however many keys it lists" do
    saved(admin, "months")
    saved(account, "jobs")
    queries = []
    counting = ->(*, payload) { queries << payload[:sql] if payload[:sql].include?("keystone_ui_preferences_component_preferences") }

    ActiveSupport::Notifications.subscribed(counting, "sql.active_record") { render_section }

    assert_equal 1, queries.size
  end

  test "the account section names a key by the name the host gives it" do
    KeystoneUi::Preferences.configure { |config| config.name_component(:months, "Revenue projection by month") }
    saved(admin, "months")

    render_section

    assert_equal [ "Revenue projection by month" ], css_select("[data-component-key] .ks-section-title").map { |title| title.text.strip }
  end

  test "the account section names a key the host has not named by the key in words" do
    saved(admin, "revenue_projection_months")

    render_section

    assert_equal [ "Revenue projection months" ], css_select("[data-component-key] .ks-section-title").map { |title| title.text.strip }
  end
end
