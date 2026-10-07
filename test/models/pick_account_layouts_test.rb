# frozen_string_literal: true

require "test_helper"

class PickAccountLayoutsTest < ActiveSupport::TestCase
  def admin
    @admin ||= User.create!(name: "Owner")
  end

  def account
    @account ||= Account.create!(name: "Acme")
  end

  def teardown
    KeystoneUi::Preferences::ComponentPreference.delete_all
  end

  def pick(values)
    KeystoneUi::Preferences::PickAccountLayouts.new(person: admin, account: account, values: values).call
  end

  def account_preference(key = "months")
    KeystoneUi::Preferences::ComponentPreference.find_by(owner: account, component_key: key)
  end

  test "turning the members-choose switch off keeps the account's members from choosing for that key" do
    pick(component_key: "months", members_choose: "0")

    assert_equal false, account_preference.members_choose
  end

  test "using my layout for everyone copies the admin's saved layout to the account" do
    KeystoneUi::Preferences::ComponentPreference.create!(owner: admin, component_key: "months", value: { "hidden_columns" => [ "pipeline" ] })

    pick(component_key: "months", use_mine: "1")

    assert_equal({ "hidden_columns" => [ "pipeline" ] }, account_preference.value)
  end

  test "using my layout for everyone leaves the members-choose switch as it was" do
    KeystoneUi::Preferences::ComponentPreference.create!(owner: admin, component_key: "months", value: { "hidden_columns" => [] })
    KeystoneUi::Preferences::ComponentPreference.create!(owner: account, component_key: "months", members_choose: false)

    pick(component_key: "months", use_mine: "1")

    assert_equal false, account_preference.members_choose
  end

  test "a saved change answers that it was kept" do
    assert_equal true, pick(component_key: "months", members_choose: "1").ok?
  end

  test "a change with no account to save it on is refused with a reason" do
    result = KeystoneUi::Preferences::PickAccountLayouts.new(person: admin, account: nil, values: { component_key: "months", members_choose: "0" }).call

    assert_equal "There is no account to save this layout on.", result.message
  end

  test "using my layout for everyone with no saved layout of my own is refused with a reason" do
    assert_equal "You have no saved layout for this table to share.", pick(component_key: "months", use_mine: "1").message
  end
end
