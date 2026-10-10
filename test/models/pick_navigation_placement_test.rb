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
end
