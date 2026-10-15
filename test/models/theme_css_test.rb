# frozen_string_literal: true

require "test_helper"

class ThemeCssTest < ActiveSupport::TestCase
  def css_for(theme)
    KeystoneUi::Preferences::ThemeCss.new(theme).to_s
  end

  def declarations(css)
    css.lines.map(&:strip).grep(/\A--/)
  end

  test "a role's light value is written to every variable the role maps to, and a role with no variable writes nothing" do
    css = css_for("popover-foreground" => { "light" => "#0a0a0a" }, "sidebar-ring" => { "light" => "#a1a1a1" })

    assert_equal [ "--ks-color-on-overlay: #0a0a0a;", "--ks-color-on-overlay-muted: #0a0a0a;" ], declarations(css)
  end

  test "a role's dark value is written to the dark partner of every variable the role maps to" do
    css = css_for("sidebar-foreground" => { "light" => "#3f3f46", "dark" => "oklch(0.985 0 0)" })

    assert_equal [ "--ks-color-nav-link: #3f3f46;", "--ks-color-nav-link-dark: oklch(0.985 0 0);", "--ks-color-nav-text: #3f3f46;", "--ks-color-nav-text-dark: oklch(0.985 0 0);" ], declarations(css)
  end
end
