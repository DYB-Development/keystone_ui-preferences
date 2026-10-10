# frozen_string_literal: true

require "test_helper"

class PickNavigationPlacementTest < ActiveSupport::TestCase
  def person
    @person ||= User.create!(name: "Rep")
  end

  def teardown
    KeystoneUi::Preferences::ComponentPreference.delete_all
  end

  def pick(values, who = person, account = nil)
    KeystoneUi::Preferences::PickNavigationPlacement.new(person: who, account: account, values: values).call
  end

  def account_setting_navigation
    Account.create!(name: "Acme").tap do |account|
      KeystoneUi::Preferences::ComponentPreference.create!(owner: account, component_key: "navigation", members_choose: false)
    end
  end

  def saved_value(who = person)
    KeystoneUi::Preferences::ComponentPreference.find_by(owner: who, component_key: "navigation")&.value
  end

  test "saving a placement keeps it as the person's navigation value" do
    pick(placement: "left")

    assert_equal({ "placement" => "left" }, saved_value)
  end

  test "saving a placement leaves another person's placement as it was" do
    teammate = User.create!(name: "Teammate")
    pick({ placement: "right" }, teammate)

    pick(placement: "left")

    assert_equal({ "placement" => "right" }, saved_value(teammate))
  end

  test "a placement other than Top, Left or Right is refused with a reason" do
    assert_equal "Choose Top, Left or Right for the navigation.", pick(placement: "bottom").message
  end

  test "a refused placement leaves the person's saved placement as it was" do
    pick(placement: "left")

    pick(placement: "bottom")

    assert_equal({ "placement" => "left" }, saved_value)
  end

  test "saving a placement leaves the person's saved navigation order as it was" do
    KeystoneUi::Preferences::ComponentPreference.create!(owner: person, component_key: "navigation", value: { "order" => [ { "group" => "Admin" } ] })

    pick(placement: "left")

    assert_equal [ { "group" => "Admin" } ], saved_value["order"]
  end

  test "a placement is refused with a reason when the account sets the navigation for everyone" do
    assert_equal "Your account sets the navigation for everyone, so this was not saved.", pick({ placement: "left" }, person, account_setting_navigation).message
  end

  test "a placement refused because the account sets the navigation saves nothing for the person" do
    pick({ placement: "left" }, person, account_setting_navigation)

    assert_nil saved_value
  end
end
