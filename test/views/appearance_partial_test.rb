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

  test "the appearance section selects Default for a person with no colours saved" do
    render_section

    assert_equal [ "default" ], selected_template
  end

  test "the appearance section selects Custom for a person who saved their own colours" do
    save_colours("accent" => "#e11d48", "surface" => "#f5e6c8", "text" => "#3b2f1e")

    render_section

    assert_equal [ "" ], selected_template
  end

  def picker_value(name)
    css_select("input[type=hidden][name=#{name}]").map { |input| input["value"] }
  end

  test "the appearance section's accent picker shows the accent drawn for the person" do
    save_colours("template_name" => "forest")

    render_section

    assert_equal [ "#10b981" ], picker_value("accent")
  end

  test "the appearance section's surface picker shows the surface drawn for the person" do
    save_colours("template_name" => "forest")

    render_section

    assert_equal [ "#78716c" ], picker_value("surface")
  end

  test "the appearance section's text colour picker shows the text colour drawn for the person" do
    save_colours("template_name" => "forest")

    render_section

    assert_equal [ "#064e3b" ], picker_value("text")
  end

  def account_setting_colours
    Account.create!(name: "Acme").tap do |account|
      KeystoneUi::Preferences::ComponentPreference.create!(owner: account, component_key: "colours", value: { "template_name" => "ocean" }, members_choose: false)
    end
  end

  test "the appearance section says the account sets the colours when members may not choose their own" do
    render_section(account: account_setting_colours)

    assert_includes rendered, "Your account sets the colours for everyone."
  end

  test "the appearance section's form runs the template picker script" do
    render_section

    assert_equal [ "keystone-ui--preferences--theme-settings" ], css_select("form[data-controller]").map { |form| form["data-controller"] }
  end
end
