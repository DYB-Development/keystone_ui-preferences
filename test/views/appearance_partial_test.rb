# frozen_string_literal: true

require "test_helper"

class AppearancePartialTest < ActionView::TestCase
  include KeystoneUiHelper

  def person
    @person ||= User.create!(name: "Rep")
  end

  def teardown
    KeystoneUi::Preferences::ComponentPreference.delete_all
  end

  def render_section(account: nil)
    render partial: "keystone_ui/preferences/settings/appearance", locals: { person: person, account: account, submit_url: "/settings/appearance" }
  end

  def template_options
    css_select("input[type=radio][name=template_name]")
  end

  test "the appearance section offers Default, the five colour templates and Custom" do
    render_section

    assert_equal [ "default", "ocean", "forest", "twilight", "coral", "arctic", "" ], template_options.map { |option| option["value"] }
  end

  def selected_template
    css_select("input[type=radio][name=template_name][checked]").map { |option| option["value"] }
  end

  def save_colours(value, owner = person)
    KeystoneUi::Preferences::ComponentPreference.create!(owner: owner, component_key: "colours", value: value)
  end

  test "the appearance section selects the template the person saved" do
    save_colours("template_name" => "forest")

    render_section

    assert_equal [ "forest" ], selected_template
  end
end
