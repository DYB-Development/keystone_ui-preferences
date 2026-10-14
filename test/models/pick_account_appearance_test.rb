# frozen_string_literal: true

require "test_helper"

class PickAccountAppearanceTest < ActiveSupport::TestCase
  def admin
    @admin ||= User.create!(name: "Owner")
  end

  def account
    @account ||= Account.create!(name: "Acme")
  end

  def teardown
    KeystoneUi::Preferences.reset_configuration!
    KeystoneUi::Preferences::ComponentPreference.delete_all
  end

  def pick(values)
    KeystoneUi::Preferences::PickAccountAppearance.new(person: admin, account: account, values: values).call
  end

  def account_preference(key)
    KeystoneUi::Preferences::ComponentPreference.find_by(owner: account, component_key: key)
  end

  test "saving a template keeps its name as the account's colours" do
    pick(template_name: "forest")

    assert_equal({ "template_name" => "forest" }, account_preference("colours").value)
  end
end
