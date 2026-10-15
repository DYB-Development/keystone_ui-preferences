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

  def specificity(selector)
    [ selector.scan(/#[\w-]+/).size, selector.scan(/\[[^\]]*\]|:[\w-]+|\.[\w-]+/).size, selector.scan(/(?:\A|[\s>+~])[a-z][\w-]*/).size ]
  end

  test "the theme rule outranks a look's rule on a page that has a look" do
    selectors = css_for("primary" => { "light" => "#171717" }).lines.first.delete_suffix(" {\n").split(", ")

    assert_equal 1, specificity(selectors.last) <=> specificity(':root[data-look="compact"]')
  end

  test "the accent, neutral and danger hover colours are derived from the theme's primary, secondary and destructive fills" do
    css = css_for("primary" => { "light" => "#171717", "dark" => "#e5e5e5" }, "secondary" => { "light" => "#f5f5f5" }, "destructive" => { "dark" => "oklch(0.704 0.191 22.216)" })

    assert_equal [
      "--ks-color-accent-hover: color-mix(in oklab, #171717 85%, white);",
      "--ks-color-accent-hover-dark: color-mix(in oklab, #e5e5e5 85%, white);",
      "--ks-color-neutral-hover: color-mix(in oklab, #f5f5f5 85%, white);",
      "--ks-color-danger-hover-dark: color-mix(in oklab, oklch(0.704 0.191 22.216) 85%, white);"
    ], declarations(css).grep(/-hover/)
  end

  test "a theme's radius is written to the corner radius of controls and of surfaces" do
    assert_equal [ "--ks-radius-control: 0.5rem;", "--ks-radius-surface: 0.5rem;" ], declarations(css_for("radius" => { "light" => "0.5rem" }))
  end

  test "a theme's spacing, letter spacing and sans font are written to keystone_ui-styles' spacing, letter spacing and body font" do
    css = css_for("spacing" => { "light" => "0.25rem" }, "letter-spacing" => { "light" => "-0.025em" }, "font-sans" => { "light" => "\"Segoe UI\", sans-serif" })

    assert_equal [ "--ks-spacing: 0.25rem;", "--ks-letter-spacing: -0.025em;", "--ks-font-body: \"Segoe UI\", sans-serif;" ], declarations(css)
  end

  test "a theme's mono font is written to the mono font variable and to Tailwind's default mono font, which code reads" do
    assert_equal [ "--ks-font-mono: Menlo, monospace;", "--default-mono-font-family: Menlo, monospace;" ], declarations(css_for("font-mono" => { "light" => "Menlo, monospace" }))
  end

  test "a theme's font weights are written to keystone_ui-styles' normal, medium, strong and heading weights" do
    css = css_for(%w[normal medium strong heading].to_h { |weight| [ "font-weight-#{weight}", { "light" => "500" } ] })

    assert_equal [ "--ks-font-weight-normal: 500;", "--ks-font-weight-medium: 500;", "--ks-font-weight-strong: 500;", "--ks-font-weight-heading: 500;" ], declarations(css)
  end
end
