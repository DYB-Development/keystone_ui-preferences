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

  test "a theme's border width and heading font are written to keystone_ui-styles' border width and heading font" do
    css = css_for("border-width" => { "light" => "2px" }, "font-heading" => { "light" => "Georgia, serif" })

    assert_equal [ "--ks-border-width: 2px;", "--ks-font-heading: Georgia, serif;" ], declarations(css)
  end

  SHADOW = {
    "shadow-color" => { "light" => "oklch(0 0 0)" }, "shadow-opacity" => { "light" => "0.1" }, "shadow-blur" => { "light" => "3px" },
    "shadow-spread" => { "light" => "-1px" }, "shadow-offset-x" => { "light" => "0" }, "shadow-offset-y" => { "light" => "1px" }
  }.freeze

  test "a theme's six shadow settings are written as one shadow on surfaces, overlays and menus" do
    shadow = "0 1px 3px -1px color-mix(in srgb, oklch(0 0 0) calc(0.1 * 100%), transparent)"

    assert_equal [ "--ks-shadow-surface: #{shadow};", "--ks-shadow-overlay: #{shadow};", "--ks-shadow-menu: #{shadow};" ], declarations(css_for(SHADOW))
  end

  test "a theme missing any of the six shadow settings writes no shadow" do
    assert_empty declarations(css_for(SHADOW.except("shadow-blur")))
  end

  test "for a person who saved a look of their own, the theme's shape and type go in a rule a look outranks while its colours still outrank the look" do
    css = KeystoneUi::Preferences::ThemeCss.new({ "primary" => { "light" => "#171717" }, "radius" => { "light" => "0.5rem" } }, own_look: true).to_s

    assert_equal ":root, html:root[data-look] {\n  --ks-color-accent: #171717;\n  --ks-color-accent-hover: color-mix(in oklab, #171717 85%, white);\n}\n:root {\n  --ks-radius-control: 0.5rem;\n  --ks-radius-surface: 0.5rem;\n}", css
  end

  def palette_css_for(accent: "blue", surface: "zinc", background: "#ffffff", text: "#18181b")
    KeystoneUi::Preferences::ThemeCss.new(palette: { accent: accent, surface: surface, background: background, text: text }).to_s
  end

  test "a named accent is written as its eleven shades under keystone_ui-colors' accent variable names" do
    accent_lines = palette_css_for(accent: "emerald").lines.grep(/--color-accent-/).map(&:strip)

    assert_equal [ "--color-accent-50: #ecfdf5;", "--color-accent-100: #d1fae5;", "--color-accent-200: #a7f3d0;", "--color-accent-300: #6ee7b7;", "--color-accent-400: #34d399;", "--color-accent-500: #10b981;", "--color-accent-600: #059669;", "--color-accent-700: #047857;", "--color-accent-800: #065f46;", "--color-accent-900: #064e3b;", "--color-accent-950: #022c22;" ], accent_lines
  end

  test "a named surface is written as its eleven shades under keystone_ui-colors' surface variable names" do
    surface_lines = palette_css_for(surface: "stone").lines.grep(/--color-surface-/).map(&:strip)

    assert_equal [ "--color-surface-50: #fafaf9;", "--color-surface-100: #f5f5f4;", "--color-surface-200: #e7e5e4;", "--color-surface-300: #d6d3d1;", "--color-surface-400: #a8a29e;", "--color-surface-500: #78716c;", "--color-surface-600: #57534e;", "--color-surface-700: #44403c;", "--color-surface-800: #292524;", "--color-surface-900: #1c1917;", "--color-surface-950: #0c0a09;" ], surface_lines
  end

  test "a hex accent and a hex surface are each written as shades generated from that colour" do
    shade_lines = palette_css_for(accent: "#e11d48", surface: "#f5e6c8").lines.grep(/--color-(accent|surface)-/).map(&:strip)

    assert_equal [
      "--color-accent-50: #fef4f6;", "--color-accent-100: #fce8ed;", "--color-accent-200: #f9d2da;", "--color-accent-300: #f6bbc8;", "--color-accent-400: #f3a5b6;", "--color-accent-500: #e11d48;",
      "--color-accent-600: #bf193d;", "--color-accent-700: #9e1432;", "--color-accent-800: #7c1028;", "--color-accent-900: #5a0c1d;", "--color-accent-950: #380712;",
      "--color-surface-50: #fffefc;", "--color-surface-100: #fefdfa;", "--color-surface-200: #fdfaf4;", "--color-surface-300: #fcf8ef;", "--color-surface-400: #fbf5e9;", "--color-surface-500: #f5e6c8;",
      "--color-surface-600: #d0c4aa;", "--color-surface-700: #aca18c;", "--color-surface-800: #877f6e;", "--color-surface-900: #625c50;", "--color-surface-950: #3d3a32;"
    ], shade_lines
  end

  test "the background and text are written as keystone_ui-colors' custom colour variables at the end of the palette" do
    css = palette_css_for(background: "#ecfdf5", text: "#064e3b")

    assert_equal [ "  --color-custom-background: #ecfdf5;\n", "  --color-custom-text: #064e3b;\n", "}" ], css.lines.last(3)
  end
end
