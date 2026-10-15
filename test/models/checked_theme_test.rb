# frozen_string_literal: true

require "test_helper"

class CheckedThemeTest < ActiveSupport::TestCase
  def teardown
    KeystoneUi::Preferences.reset_configuration!
  end

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

  test "a font that is neither one the app offers nor a system font is dropped from the font list" do
    KeystoneUi::Preferences.configure { |config| config.theme_fonts = [ "Inter" ] }

    assert_equal({ "light" => "inter, \"Segoe UI\", sans-serif" }, check("font-sans" => { "light" => "inter, Comic Neue, \"Segoe UI\", 'Fancy', sans-serif" }).value["theme"]["font-sans"])
  end

  test "a font list naming no font the app offers and no system font is refused with a reason naming the setting" do
    assert_equal "The --font-mono value names no font this app offers, so it was not saved.", check("font-mono" => { "light" => "JetBrains Mono, Fira Code" }).refusal&.message
  end

  test "a kept font name of more than one word is written in double quotes and a one-word name is written bare" do
    KeystoneUi::Preferences.configure { |config| config.theme_fonts = [ "Source Serif 4" ] }

    assert_equal({ "light" => "\"Source Serif 4\", \"Segoe UI\", Georgia, serif" }, check("font-serif" => { "light" => "Source Serif 4, 'Segoe UI', \"Georgia\", serif" }).value["theme"]["font-serif"])
  end

  test "each shadow setting is checked as its own kind of value and refused with a reason naming the setting" do
    values = [
      [ "shadow-color", "oklch(0 0 0)" ], [ "shadow-color", "black" ],
      [ "shadow-opacity", "0.1" ], [ "shadow-opacity", "1.5" ],
      [ "shadow-blur", "3px" ], [ "shadow-blur", "-3px" ],
      [ "shadow-spread", "-1px" ], [ "shadow-spread", "1vh" ],
      [ "shadow-offset-x", "0" ], [ "shadow-offset-y", "2" ]
    ]
    length = "is not a number followed by px, rem or em, or zero, so it was not saved."

    assert_equal [
      nil, "The --shadow-color value is not hex, rgb(), hsl() or oklch() written with plain numbers, so it was not saved.",
      nil, "The --shadow-opacity value is not a number from 0 to 1, so it was not saved.",
      nil, "The --shadow-blur value #{length}",
      nil, "The --shadow-spread value #{length}",
      nil, "The --shadow-offset-y value #{length}"
    ], values.map { |name, value| check(name => { "light" => value }).refusal&.message }
  end
end
