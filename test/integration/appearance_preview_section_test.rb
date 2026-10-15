# frozen_string_literal: true

require "test_helper"

class AppearancePreviewSectionTest < ActionDispatch::IntegrationTest
  def setup
    ApplicationController.signed_in_user = User.create!(name: "Rep")
  end

  def teardown
    ApplicationController.signed_in_user = nil
    KeystoneUi::Preferences::ComponentPreference.delete_all
  end

  test "a person who opens the appearance section through settings_hub finds the Edit and Preview tabs and the preview's components on both sides" do
    get "/settings/appearance"

    tabs = css_select("[data-tab-switcher-target='tab']").map { |tab| tab.text.strip }
    components = %w[light dark].map { |side| css_select("[data-theme-preview] [data-theme='#{side}'] .ks-card, [data-theme-preview] [data-theme='#{side}'] .ks-button, [data-theme-preview] [data-theme='#{side}'] .ks-form-field, [data-theme-preview] [data-theme='#{side}'] .ks-table, [data-theme-preview] [data-theme='#{side}'] [data-controller='line-chart'], [data-theme-preview] [data-theme='#{side}'] .ks-sidebar").size }

    assert_equal [ [ "Edit", "Preview" ], [ 9, 9 ] ], [ tabs, components ]
  end
end
