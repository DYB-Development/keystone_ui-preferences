# frozen_string_literal: true

require "test_helper"

class ThemeSettingsPartialTest < ActionView::TestCase
  include KeystoneUiHelper

  def saved
    { "theme" => { "radius" => { "light" => "0.5rem" } } }
  end

  def render_settings(sent_theme: nil)
    render partial: "keystone_ui/preferences/settings/theme_settings", locals: { saved: saved, sent_theme: sent_theme }
  end

  test "a theme field shows the value the person sent, markup and all, in place of the saved one" do
    render_settings(sent_theme: { "radius" => { "light" => "big\"><b>bold</b>" } })

    assert_equal "big\"><b>bold</b>", css_select("input[name='theme[radius][light]']").first["value"]
  end
end
