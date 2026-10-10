# frozen_string_literal: true

require "test_helper"

class NavigationArrangementTest < ActiveSupport::TestCase
  def group(label, *keys)
    navigation_group = KeystoneUi::NavigationGroup.new(label)
    keys.each { |key| navigation_group.tab key, label: key.to_s.humanize, href: "/#{key}", permitted: ->(_view) { true } }
    [ navigation_group, navigation_group.tabs ]
  end

  def arrangement
    KeystoneUi::Preferences::NavigationArrangement.new([ group("Sales", :orders, :quotes), group("Admin", :users) ])
  end

  test "moving a group up puts it above the group before it" do
    assert_equal [ { "group" => "Admin", "tabs" => [ "users" ] }, { "group" => "Sales", "tabs" => [ "orders", "quotes" ] } ], arrangement.group_moved(1, -1)
  end

  test "moving a tab down puts it below the tab after it in its group" do
    assert_equal [ { "group" => "Sales", "tabs" => [ "quotes", "orders" ] }, { "group" => "Admin", "tabs" => [ "users" ] } ], arrangement.tab_moved(0, 0, 1)
  end
end
