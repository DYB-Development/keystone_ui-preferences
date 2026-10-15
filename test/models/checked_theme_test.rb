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

  test "a colour that is not hex, rgb(), hsl() or oklch() written with plain numbers is refused with a reason naming the role" do
    checked = check("border" => { "light" => "#e5e5e5" }, "primary" => { "light" => "#171717", "dark" => "red" })

    assert_equal "The dark --primary colour is not hex, rgb(), hsl() or oklch() written with plain numbers, so it was not saved.", checked.refusal&.message
  end

  test "a colour containing a semicolon, a brace, an angle bracket or a comment is refused" do
    colours = [ "#ffffff;", "oklch(0.5 0 0)}", "#fff</style>", "{", "#ffffff /* x */" ]

    assert_equal [ true ] * colours.size, colours.map { |colour| check("ring" => { "light" => colour }).refusal.is_a?(KeystoneUi::Preferences::Refusal) }
  end
end
