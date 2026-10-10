# frozen_string_literal: true

require "test_helper"

class NavigationFromSavedOrderTest < ActionDispatch::IntegrationTest
  def person
    @person ||= User.create!(name: "Rep")
  end

  def setup
    ApplicationController.signed_in_user = person
    KeystoneUi.configuration.navigation_group("Sales") do |group|
      group.tab :orders, label: "Orders", href: "/orders", permitted: ->(_view) { true }
    end
    KeystoneUi.configuration.navigation_group("Admin") do |group|
      group.tab :users, label: "Users", href: "/users", permitted: ->(_view) { true }
    end
  end

  def teardown
    ApplicationController.signed_in_user = nil
    KeystoneUi.configuration.navigation_groups.clear
    KeystoneUi::Preferences::ComponentPreference.delete_all
  end

  test "the next page a person opens draws the navigation's groups in the order they saved" do
    KeystoneUi::Preferences::PickNavigationOrder.new(person: person, account: nil, values: { order: [ { "group" => "Admin" }, { "group" => "Sales" } ].to_json }).call

    get "/navigation"

    assert_equal [ "Admin", "Sales" ], css_select("[data-controller=dropdown] > button").map { |group| group.text.strip }
  end
end
