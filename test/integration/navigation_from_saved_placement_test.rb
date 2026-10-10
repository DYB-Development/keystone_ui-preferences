# frozen_string_literal: true

require "test_helper"

class NavigationFromSavedPlacementTest < ActionDispatch::IntegrationTest
  def person
    @person ||= User.create!(name: "Rep")
  end

  def setup
    ApplicationController.signed_in_user = person
  end

  def teardown
    ApplicationController.signed_in_user = nil
    KeystoneUi::Preferences::ComponentPreference.delete_all
  end

  test "the next page a person opens hands keystone_ui the placement they saved for the navigation" do
    KeystoneUi::Preferences::PickNavigationPlacement.new(person: person, account: nil, values: { placement: "right" }).call

    get "/navigation"

    assert_equal [ "right" ], css_select("[data-placement]").map { |navigation| navigation["data-placement"] }
  end
end
