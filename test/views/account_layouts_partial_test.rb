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
end
