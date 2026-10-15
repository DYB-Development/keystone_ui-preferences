# frozen_string_literal: true

require "test_helper"

class CheckedThemeTest < ActiveSupport::TestCase
  def check(values)
    KeystoneUi::Preferences::CheckedTheme.new(values)
  end

  test "hex, rgb(), hsl() and oklch() colours written with plain numbers are kept as the theme" do
    values = {
      "background" => { "light" => "#fff", "dark" => "#0a0a0aff" },
      "primary" => { "light" => "rgb(23, 23, 23)", "dark" => "rgb(250 250 250 / 0.9)" },
      "secondary" => { "light" => "hsl(240 4.8% 95.9%)", "dark" => "hsla(240, 3.7%, 15.9%, 1)" },
      "border" => { "light" => "oklch(0.922 0 0)", "dark" => "oklch(1 0 0 / 10%)" }
    }

    assert_equal({ "theme" => values }, check(values).value)
  end
end
