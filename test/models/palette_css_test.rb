# frozen_string_literal: true

require "test_helper"

class PaletteCssTest < ActiveSupport::TestCase
  def css_for(accent: "blue", surface: "zinc", background: "#ffffff", text: "#18181b")
    KeystoneUi::Preferences::PaletteCss.new(accent: accent, surface: surface, background: background, text: text).to_s
  end

  test "a named accent is written as its eleven shades under keystone_ui-colors' accent variable names" do
    accent_lines = css_for(accent: "emerald").lines.grep(/--color-accent-/).map(&:strip)

    assert_equal [ "--color-accent-50: #ecfdf5;", "--color-accent-100: #d1fae5;", "--color-accent-200: #a7f3d0;", "--color-accent-300: #6ee7b7;", "--color-accent-400: #34d399;", "--color-accent-500: #10b981;", "--color-accent-600: #059669;", "--color-accent-700: #047857;", "--color-accent-800: #065f46;", "--color-accent-900: #064e3b;", "--color-accent-950: #022c22;" ], accent_lines
  end

  test "a named surface is written as its eleven shades under keystone_ui-colors' surface variable names" do
    surface_lines = css_for(surface: "stone").lines.grep(/--color-surface-/).map(&:strip)

    assert_equal [ "--color-surface-50: #fafaf9;", "--color-surface-100: #f5f5f4;", "--color-surface-200: #e7e5e4;", "--color-surface-300: #d6d3d1;", "--color-surface-400: #a8a29e;", "--color-surface-500: #78716c;", "--color-surface-600: #57534e;", "--color-surface-700: #44403c;", "--color-surface-800: #292524;", "--color-surface-900: #1c1917;", "--color-surface-950: #0c0a09;" ], surface_lines
  end

  test "a hex accent and a hex surface are each written as shades generated from that colour" do
    shade_lines = css_for(accent: "#e11d48", surface: "#f5e6c8").lines.grep(/--color-(accent|surface)-/).map(&:strip)

    assert_equal [
      "--color-accent-50: #fef4f6;", "--color-accent-100: #fce8ed;", "--color-accent-200: #f9d2da;", "--color-accent-300: #f6bbc8;", "--color-accent-400: #f3a5b6;", "--color-accent-500: #e11d48;",
      "--color-accent-600: #bf193d;", "--color-accent-700: #9e1432;", "--color-accent-800: #7c1028;", "--color-accent-900: #5a0c1d;", "--color-accent-950: #380712;",
      "--color-surface-50: #fffefc;", "--color-surface-100: #fefdfa;", "--color-surface-200: #fdfaf4;", "--color-surface-300: #fcf8ef;", "--color-surface-400: #fbf5e9;", "--color-surface-500: #f5e6c8;",
      "--color-surface-600: #d0c4aa;", "--color-surface-700: #aca18c;", "--color-surface-800: #877f6e;", "--color-surface-900: #625c50;", "--color-surface-950: #3d3a32;"
    ], shade_lines
  end

  test "the background and text are written as keystone_ui-colors' custom colour variables at the end of the palette" do
    css = css_for(background: "#ecfdf5", text: "#064e3b")

    assert_equal [ "  --color-custom-background: #ecfdf5;\n", "  --color-custom-text: #064e3b;\n", "}" ], css.lines.last(3)
  end
end
