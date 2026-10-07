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
end
