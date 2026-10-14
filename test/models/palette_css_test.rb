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
end
