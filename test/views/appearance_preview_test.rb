# frozen_string_literal: true

require "test_helper"

class AppearancePreviewTest < ActionView::TestCase
  include KeystoneUiHelper

  def person
    @person ||= User.create!(name: "Rep")
  end

  def teardown
    KeystoneUi::Preferences.reset_configuration!
    KeystoneUi::Preferences::ComponentPreference.delete_all
  end

  def render_section
    render partial: "keystone_ui/preferences/settings/appearance", locals: { person: person, account: nil, submit_url: "/settings/appearance" }
  end

  def preview
    css_select("[data-theme-preview] [data-theme='light']")
  end

  test "the appearance section's preview shows a keystone_ui card" do
    render_section

    assert_equal 1, preview.css(".#{Keystone::Ui::CardComponent::CARD_CLASSES}").size
  end

  test "the appearance section's preview shows a keystone_ui button in each style" do
    render_section

    assert_equal %w[ks-button-primary ks-button-secondary ks-button-danger], preview.css(".ks-button").map { |button| button["class"].split[1] }
  end

  test "the appearance section's preview shows a form of keystone_ui fields, a text field and a select" do
    render_section

    assert_equal %w[input select], preview.css(".#{Keystone::Ui::FormFieldComponent::WRAPPER_CLASSES}").map { |field| field.at_css("input, select").name }
  end

  test "the appearance section's preview shows a keystone_ui table headed Customer, Region and Total" do
    render_section

    assert_equal [ "Customer", "Region", "Total" ], preview.css(".ks-table thead th").map { |cell| cell.text.strip }
  end

  def chart_series
    preview.css("[data-controller='line-chart']").map { |chart| JSON.parse(chart["data-line-chart-data-value"])["datasets"] }
  end

  test "the appearance section's preview shows a keystone_ui line chart of two sample series" do
    render_section

    assert_equal [ [ "This year", "Last year" ] ], chart_series.map { |datasets| datasets.map { |dataset| dataset["label"] } }
  end

  test "the appearance section's preview shows a navigation list drawn as keystone_ui's sidebar" do
    render_section

    assert_equal [ "Dashboard", "Customers", "Reports" ], preview.css(".ks-sidebar .#{Keystone::Ui::NavigationComponent::SIDEBAR_TAB_CLASSES}").map(&:text)
  end

  test "the appearance section's preview draws the same components once on a light side and once on a dark side" do
    render_section

    sides = css_select("[data-theme-preview] [data-theme]")

    assert_equal [ %w[light dark], 1 ], [ sides.map { |side| side["data-theme"] }, sides.map(&:inner_html).uniq.size ]
  end

  test "the preview's chart series carry no colour of their own, so the chart draws them in the theme's chart colours" do
    render_section

    assert_equal [ [ [ "data", "label" ], [ "data", "label" ] ] ], chart_series.map { |datasets| datasets.map { |dataset| dataset.keys.sort } }
  end

  test "the appearance section offers an Edit tab and a Preview tab from keystone_ui's tab switcher" do
    render_section

    assert_equal [ "Edit", "Preview" ], css_select("[data-controller='tab-switcher'] [data-tab-switcher-target='tab']").map { |tab| tab.text.strip }
  end

  test "picking a tab hands its place to the theme settings script, which starts with the Edit panel shown" do
    render_section

    settings = css_select("[data-controller='keystone-ui--preferences--appearance-editor']").first
    panels = css_select("[data-editor-panel]")

    assert_equal [ "tab-switcher:change->keystone-ui--preferences--appearance-editor#showPanel", [ true, false ] ], [ settings&.[]("data-action").to_s.split.first, panels.map { |panel| panel.key?("data-shown") } ]
  end

  test "Turbo visits, page unloads and Save in the appearance section are handed to the appearance editor script, which asks before unsaved changes are lost" do
    render_section

    actions = css_select("[data-controller='keystone-ui--preferences--appearance-editor']").first&.[]("data-action").to_s.split

    assert_equal [ "submit->keystone-ui--preferences--appearance-editor#save", "turbo:before-visit@document->keystone-ui--preferences--appearance-editor#confirmLeave", "beforeunload@window->keystone-ui--preferences--appearance-editor#warnBeforeUnload" ], actions.drop(1)
  end

  test "the appearance section holds a hidden question on the page offering to leave without saving or to stay" do
    render_section

    question = css_select("[data-appearance-editor] [data-leave-question] [data-modal-target='backdrop'].hidden")
    choices = question.css("button").filter_map { |button| [ button.text.strip, button["data-action"] ] unless button["aria-label"] == "Close" }

    assert_equal [ [ "Leave without saving", "keystone-ui--preferences--appearance-editor#leave" ], [ "Stay", "modal#close" ] ], choices
  end

  test "the appearance section holds the question on leaving without saving when it offers no colours, so a changed Mode or Look still asks first" do
    KeystoneUi::Preferences.configure { |config| config.account_colors = false }
    render_section

    assert_equal 1, css_select("[data-appearance-editor] [data-leave-question] [data-modal-target='backdrop'].hidden").size
  end

  test "the question on leaving without saving says the changes are not saved, since a colour card, Mode or Look raises it as well as a theme field" do
    render_section

    assert_equal [ "Your changes are not saved yet." ], css_select("[data-leave-question] p").map { |line| line.text.strip }
  end

  def section_style
    css_select("[data-controller='keystone-ui--preferences--appearance-editor'] style").text.squish
  end

  test "below a wide screen the appearance section draws only the panel of the picked tab" do
    render_section

    assert_includes section_style, "[data-editor-panel]:not([data-shown]) { display: none; }"
  end

  test "the appearance section's tabs and panels sit in a wrapper that measures the width the section is given rather than the window" do
    render_section

    assert_equal [ 1, true ], [ css_select("[data-editor-space] [data-controller='tab-switcher'] [data-editor-panels]").size, section_style.include?("[data-editor-space] { container-type: inline-size; }") ]
  end

  test "in a section at least 32rem wide the appearance section shows the editor and the preview one under the other, no wider than the section, with no tabs" do
    render_section

    assert_includes section_style, "@container (min-width: 32rem) { [data-editor-space] .ks-tab-bar { display: none; } [data-editor-panels] { display: grid; grid-template-columns: minmax(0, 1fr); gap: 1.5rem; } [data-editor-panel]:not([data-shown]) { display: block; } }"
  end

  test "in a section at least 56rem wide the appearance section draws the editor and the preview side by side" do
    render_section

    assert_includes section_style, "@container (min-width: 56rem) { [data-editor-panels] { grid-template-columns: minmax(0, 3fr) minmax(0, 2fr); align-items: start; } }"
  end

  test "the preview names no font of its own and loads nothing from another site, so it draws in the theme's fonts" do
    render_section

    assert_empty css_select("[data-theme-preview]").to_html.scan(%r{https?://|//[a-z]|@import|url\(|font-family|<link|<script})
  end
end
