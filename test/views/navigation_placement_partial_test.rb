# frozen_string_literal: true

require "test_helper"

class NavigationPlacementPartialTest < ActionView::TestCase
  include KeystoneUiHelper

  def person
    @person ||= User.create!(name: "Rep")
  end

  def teardown
    KeystoneUi::Preferences::ComponentPreference.delete_all
  end

  def render_section(account: nil)
    render partial: "keystone_ui/preferences/settings/navigation_placement", locals: { person: person, account: account, submit_url: "/settings/navigation_placement" }
  end

  def account_setting_navigation
    Account.create!(name: "Acme").tap do |account|
      KeystoneUi::Preferences::ComponentPreference.create!(owner: account, component_key: "navigation", members_choose: false)
    end
  end

  test "the navigation section offers Top, Left and Right" do
    render_section

    assert_equal [ [ "top", "Top" ], [ "left", "Left" ], [ "right", "Right" ] ], css_select("label:has(input[type=radio][name=placement])").map { |option| [ option.at_css("input")["value"], option.text.strip ] }
  end

  test "the navigation section selects the placement the person saved" do
    KeystoneUi::Preferences::ComponentPreference.create!(owner: person, component_key: "navigation", value: { "placement" => "left" })

    render_section

    assert_equal [ "left" ], css_select("input[type=radio][name=placement][checked]").map { |option| option["value"] }
  end

  test "the navigation section selects Top for a person with nothing saved" do
    render_section

    assert_equal [ "top" ], css_select("input[type=radio][name=placement][checked]").map { |option| option["value"] }
  end

  test "the navigation section stacks its options one per row at phone width" do
    render_section

    assert_equal 3, css_select(".grid.grid-cols-1 > label:has(input[type=radio][name=placement])").size
  end

  test "the navigation section saves without any script the web view has to run" do
    render_section

    assert_empty css_select("[data-controller]")
  end

  test "the navigation section says the account sets the navigation when members may not choose their own" do
    render_section(account: account_setting_navigation)

    assert_includes rendered, "Your account sets the navigation for everyone."
  end

  test "the navigation section offers no save when the account sets the navigation" do
    render_section(account: account_setting_navigation)

    assert_empty css_select("form")
  end
end
