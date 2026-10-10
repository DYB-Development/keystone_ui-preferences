# frozen_string_literal: true

require "test_helper"

class PickNavigationOrderTest < ActiveSupport::TestCase
  def person
    @person ||= User.create!(name: "Rep")
  end

  def teardown
    KeystoneUi::Preferences::ComponentPreference.delete_all
  end

  def pick(values, who = person)
    KeystoneUi::Preferences::PickNavigationOrder.new(person: who, account: nil, values: values).call
  end

  def saved_value(who = person)
    KeystoneUi::Preferences::ComponentPreference.find_by(owner: who, component_key: "navigation")&.value
  end

  def order
    [ { "group" => "Admin" }, { "group" => "Sales", "tabs" => [ "quotes", "orders" ] } ]
  end

  test "saving an order keeps it as the person's navigation order" do
    pick(order: order.to_json)

    assert_equal({ "order" => order }, saved_value)
  end

  test "an order that is not a list of groups is refused with a reason" do
    assert_equal "Choose an order for the navigation's groups and tabs.", pick(order: "Sales first").message
  end
end
