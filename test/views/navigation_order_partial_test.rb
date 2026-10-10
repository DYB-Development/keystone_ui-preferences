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
end
