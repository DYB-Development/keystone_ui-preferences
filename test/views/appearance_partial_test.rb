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

  test "picking a template hands the template picker script that template's accent, surface and text colour" do
    render_section

    forest = css_select("input[type=radio][name=template_name][value=forest]").first

    assert_equal [ "keystone-ui--preferences--theme-settings#selectTemplate", "#10b981", "#78716c", "#064e3b" ], %w[data-action data-accent-hex data-surface-hex data-text-hex].map { |attribute| forest[attribute] }
  end

  test "the template picker script finds the accent, surface and text colour pickers" do
    render_section

    targets = %w[accentPicker surfacePicker textPicker].map { |target| css_select("[data-keystone-ui--preferences--theme-settings-target=#{target}] input[type=hidden]").map { |input| input["name"] } }

    assert_equal [ [ "accent" ], [ "surface" ], [ "text" ] ], targets
  end

  test "the template picker script finds each template's option and the Custom option to highlight" do
    render_section

    assert_equal %w[default ocean forest twilight coral arctic custom], css_select("label[data-keystone-ui--preferences--theme-settings-target=templateLabel]").map { |label| label["data-template"] }
  end

  test "the template picker script finds the Custom option to select when a colour picker changes" do
    render_section

    assert_equal [ "" ], css_select("input[data-keystone-ui--preferences--theme-settings-target=customRadio]").map { |input| input["value"] }
  end

  test "the appearance section saves with a full page load, as the other sections do in a Hotwire Native web view" do
    render_section

    assert_equal [ "false" ], css_select("form").map { |form| form["data-turbo"] }
  end

  def mode_options
    css_select("input[type=radio][name=mode]").map { |option| option["value"] }
  end

  test "the appearance section offers Light, Dark, System and Custom to a person who may choose their own colours" do
    render_section

    assert_equal %w[light dark system custom], mode_options
  end

  def selected_mode
    css_select("input[type=radio][name=mode][checked]").map { |option| option["value"] }
  end

  test "the appearance section selects the mode the person saved" do
    KeystoneUi::Preferences::ComponentPreference.create!(owner: person, component_key: "mode", value: { "mode" => "dark" })

    render_section

    assert_equal [ "dark" ], selected_mode
  end
end
