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

  def render_section
    render partial: "keystone_ui/preferences/settings/navigation_placement", locals: { person: person, account: nil, submit_url: "/settings/navigation_placement" }
  end

  test "the navigation section offers Top, Left and Right" do
    render_section

    assert_equal [ [ "top", "Top" ], [ "left", "Left" ], [ "right", "Right" ] ], css_select("label:has(input[type=radio][name=placement])").map { |option| [ option.at_css("input")["value"], option.text.strip ] }
  end
end
