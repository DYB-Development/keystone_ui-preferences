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

  test "the setting whose sent value the theme check refuses is followed by the refusal" do
    render_settings(sent_theme: { "primary" => { "light" => "#123456" }, "radius" => { "light" => "big" } })

    assert_equal [ "The --radius value is not a number followed by px, rem or em, or zero, so it was not saved." ], css_select(".ks-form-field:has(> input[name='theme[radius][light]']) + p.ks-error").map { |error| error.text.strip }
  end

  test "a sent colour the theme check refuses reaches no style attribute on the section" do
    render_settings(sent_theme: { "primary" => { "light" => "red; background:url(x)" } })

    assert_empty css_select("[style]").map { |element| element["style"] }.grep(/url\(x\)/)
  end
end
