# frozen_string_literal: true

require "test_helper"

class PickNavigationPlacementTest < ActiveSupport::TestCase
  def person
    @person ||= User.create!(name: "Rep")
  end

  def teardown
    KeystoneUi::Preferences::ComponentPreference.delete_all
  end

  def pick(values, who = person)
    KeystoneUi::Preferences::PickNavigationPlacement.new(person: who, account: nil, values: values).call
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
end
