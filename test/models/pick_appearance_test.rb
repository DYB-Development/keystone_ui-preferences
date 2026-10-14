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
end
