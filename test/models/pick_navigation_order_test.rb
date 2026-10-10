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

  test "saving an order leaves the person's saved placement as it was" do
    KeystoneUi::Preferences::ComponentPreference.create!(owner: person, component_key: "navigation", value: { "placement" => "left" })

    pick(order: order.to_json)

    assert_equal "left", saved_value["placement"]
  end

  test "resetting removes the person's saved order and keeps their placement" do
    KeystoneUi::Preferences::ComponentPreference.create!(owner: person, component_key: "navigation", value: { "placement" => "left", "order" => order })

    pick(reset: "1")

    assert_equal({ "placement" => "left" }, saved_value)
  end

  test "an order larger than the largest value the gem accepts is refused with a reason" do
    oversized = [ { "group" => "x" * KeystoneUi::Preferences.configuration.max_value_bytes } ].to_json

    assert_equal "That navigation order is too large to save.", pick(order: oversized).message
  end
end
