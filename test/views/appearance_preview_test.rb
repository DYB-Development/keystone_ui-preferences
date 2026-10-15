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
    css_select("[data-theme-preview]")
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
end
