# frozen_string_literal: true

require "test_helper"

class NavigationOrderPartialTest < ActionView::TestCase
  include KeystoneUiHelper

  def setup
    KeystoneUi.configuration.navigation_group("Sales") do |group|
      group.tab :orders, label: "Orders", href: "/orders", permitted: ->(_view) { true }
      group.tab :quotes, label: "Quotes", href: "/quotes", permitted: ->(_view) { true }
    end
    KeystoneUi.configuration.navigation_group("Admin") do |group|
      group.tab :users, label: "Users", href: "/users", permitted: ->(_view) { true }
    end
  end

  def teardown
    KeystoneUi.configuration.navigation_groups.clear
    KeystoneUi::Preferences::ComponentPreference.delete_all
  end

  def person
    @person ||= User.create!(name: "Rep")
  end

  def render_section
    render partial: "keystone_ui/preferences/settings/navigation_order", locals: { person: person, account: nil, submit_url: "/settings/navigation_order" }
  end

  def listed
    css_select("[data-navigation-group]").map do |group|
      [ group.at_css("[data-group-label]").text.strip, group.css("[data-navigation-tab]").map { |tab| tab.at_css("[data-tab-label]").text.strip } ]
    end
  end

  def group_moves(direction)
    css_select("[data-navigation-group]").to_h do |group|
      order = group.at_css("form[data-group-move=#{direction}] input[name=order]")
      [ group["data-navigation-group"], order && JSON.parse(order["value"]) ]
    end
  end

  def tab_moves(direction)
    css_select("[data-navigation-tab]").to_h do |tab|
      order = tab.at_css("form[data-tab-move=#{direction}] input[name=order]")
      [ tab["data-navigation-tab"], order && JSON.parse(order["value"]) ]
    end
  end

  test "the tab order section lists each group with its tabs in the declared order when nothing is saved" do
    render_section

    assert_equal [ [ "Sales", [ "Orders", "Quotes" ] ], [ "Admin", [ "Users" ] ] ], listed
  end

  test "the tab order section leaves out a tab the person may not see" do
    KeystoneUi.configuration.navigation_groups.first.tab :refunds, label: "Refunds", href: "/refunds", permitted: ->(_view) { false }

    render_section

    assert_equal [ [ "Sales", [ "Orders", "Quotes" ] ], [ "Admin", [ "Users" ] ] ], listed
  end

  test "the tab order section leaves out a group with no tab the person may see" do
    KeystoneUi.configuration.navigation_group("Billing") do |group|
      group.tab :invoices, label: "Invoices", href: "/invoices", permitted: ->(_view) { false }
    end

    render_section

    assert_equal [ "Sales", "Admin" ], listed.map(&:first)
  end

  test "the tab order section lists the groups and tabs in the order the person saved" do
    KeystoneUi::Preferences::ComponentPreference.create!(owner: person, component_key: "navigation", value: { "order" => [ { "group" => "Admin" }, { "group" => "Sales", "tabs" => [ "quotes", "orders" ] } ] })

    render_section

    assert_equal [ [ "Admin", [ "Users" ] ], [ "Sales", [ "Quotes", "Orders" ] ] ], listed
  end

  test "every group but the first has an Up button that saves the order with that group moved above the one before it" do
    render_section

    assert_equal({ "Sales" => nil, "Admin" => [ { "group" => "Admin", "tabs" => [ "users" ] }, { "group" => "Sales", "tabs" => [ "orders", "quotes" ] } ] }, group_moves("up"))
  end

  test "every group but the last has a Down button that saves the order with that group moved below the one after it" do
    render_section

    assert_equal({ "Sales" => [ { "group" => "Admin", "tabs" => [ "users" ] }, { "group" => "Sales", "tabs" => [ "orders", "quotes" ] } ], "Admin" => nil }, group_moves("down"))
  end

  test "every tab but the first in its group has an Up button that saves the order with that tab moved above the one before it" do
    render_section

    assert_equal({ "orders" => nil, "quotes" => [ { "group" => "Sales", "tabs" => [ "quotes", "orders" ] }, { "group" => "Admin", "tabs" => [ "users" ] } ], "users" => nil }, tab_moves("up"))
  end
end
