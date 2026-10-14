# frozen_string_literal: true

require "test_helper"

class PickAppearanceTest < ActiveSupport::TestCase
  def person
    @person ||= User.create!(name: "Rep")
  end

  def teardown
    KeystoneUi::Preferences::ComponentPreference.delete_all
  end

  def pick(values, account = nil)
    KeystoneUi::Preferences::PickAppearance.new(person: person, account: account, values: values).call
  end

  def saved_value
    KeystoneUi::Preferences::ComponentPreference.find_by(owner: person, component_key: "colours")&.value
  end

  test "saving a template keeps its name as the person's colours" do
    pick(template_name: "forest")

    assert_equal({ "template_name" => "forest" }, saved_value)
  end

  test "saving Custom keeps the accent, surface and text colour as the person's colours" do
    pick(template_name: "", accent: "#e11d48", surface: "#f5e6c8", text: "#3b2f1e")

    assert_equal({ "accent" => "#e11d48", "surface" => "#f5e6c8", "text" => "#3b2f1e" }, saved_value)
  end

  test "saving Default removes the person's saved colours" do
    pick(template_name: "forest")

    pick(template_name: "default")

    assert_nil saved_value
  end

  def account_setting_colours
    Account.create!(name: "Acme").tap do |account|
      KeystoneUi::Preferences::ComponentPreference.create!(owner: account, component_key: "colours", value: { "template_name" => "ocean" }, members_choose: false)
    end
  end

  test "a save is refused with a reason when the account sets the colours for everyone" do
    assert_equal "Your account sets the colours for everyone, so this was not saved.", pick({ template_name: "forest" }, account_setting_colours).message
  end

  test "a save refused because the account sets the colours saves nothing for the person" do
    pick({ template_name: "forest" }, account_setting_colours)

    assert_nil saved_value
  end

  test "a template that is not in the catalogue is refused with a reason" do
    assert_equal "Choose Default, one of the colour templates or Custom.", pick(template_name: "jungle").message
  end

  test "a refused template leaves the person's saved colours as they were" do
    pick(template_name: "forest")

    pick(template_name: "jungle")

    assert_equal({ "template_name" => "forest" }, saved_value)
  end

  def custom(accent: "#e11d48", surface: "#f5e6c8", text: "#3b2f1e")
    pick(template_name: "", accent: accent, surface: surface, text: text)
  end

  test "a Custom accent that is neither a six-digit hex nor a catalogue accent is refused with a reason" do
    assert_equal "Choose each colour as a six-digit hex value, such as #1d4ed8.", custom(accent: "red; } body { display: none").message
  end
end
