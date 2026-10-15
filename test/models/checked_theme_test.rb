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

  test "names that are not theme roles and sides other than light and dark are left out of the theme" do
    checked = check("ring" => { "light" => "#a1a1a1", "hover" => "#000000" }, "shadow-2xl" => { "light" => "#ffffff" })

    assert_equal({ "theme" => { "ring" => { "light" => "#a1a1a1" } } }, checked.value)
  end

  test "a length that is not a number followed by px, rem or em, or zero, is refused with a reason naming the setting" do
    lengths = [ "1vh", "10%", "calc(1px)", "-1px", "1 rem", "0.5", "var(--x)", "1px;" ]

    assert_equal [ "The --radius value is not a number followed by px, rem or em, or zero, so it was not saved." ] * lengths.size, lengths.map { |length| check("radius" => { "light" => length }).refusal&.message }
  end

  test "a shape or type setting keeps only its light value" do
    checked = check("radius" => { "light" => "0", "dark" => "1rem" })

    assert_equal({ "theme" => { "radius" => { "light" => "0" } } }, checked.value)
  end

  test "a letter spacing is kept only as normal or a length that may be negative, and is otherwise refused with a reason naming the setting" do
    spacings = [ "normal", "-0.025em", "0", "0.5px", "wide", "-1vh", "--1px" ]
    refused = "The --letter-spacing value is not normal or a number followed by px, rem or em, or zero, so it was not saved."

    assert_equal [ nil, nil, nil, nil, refused, refused, refused ], spacings.map { |spacing| check("letter-spacing" => { "light" => spacing }).refusal&.message }
  end

  test "a font list is kept only as comma-separated names of letters, digits, spaces and hyphens, each optionally quoted, and is otherwise refused with a reason naming the setting" do
    lists = [ "Inter, sans-serif", "\"Segoe UI\", Roboto, -apple-system", "'JetBrains Mono', monospace", "Inter; color: red", "Inter,", "\"Inter", "Comic_Sans", "", "Inter!" ]
    refused = "The --font-sans value is not a list of font names made of letters, digits, spaces and hyphens, so it was not saved."

    assert_equal [ nil, nil, nil, refused, refused, refused, refused, refused, refused ], lists.map { |list| check("font-sans" => { "light" => list }).refusal&.message }
  end
end
