# frozen_string_literal: true

require "test_helper"
require "minitest/mock"

class AccountAppearancePartialTest < ActionView::TestCase
  include KeystoneUiHelper

  def admin
    @admin ||= User.create!(name: "Owner")
  end

  def account
    @account ||= Account.create!(name: "Acme")
  end

  def teardown
    KeystoneUi::Preferences.reset_configuration!
    KeystoneUi::Preferences::ComponentPreference.delete_all
  end

  def render_section
    render partial: "keystone_ui/preferences/settings/account_appearance", locals: { person: admin, account: account, submit_url: "/settings/account_appearance" }
  end

  def template_options
    css_select("input[type=radio][name=template_name]").map { |option| option["value"] }
  end

  test "the account's section offers Default, the five colour templates, the six preset themes and Custom" do
    render_section

    assert_equal [ "default", "ocean", "forest", "twilight", "coral", "arctic", "graphite", "harbor", "fern", "terracotta", "heather", "ledger", "" ], template_options
  end

  def save(key, value, members_choose: true)
    KeystoneUi::Preferences::ComponentPreference.create!(owner: account, component_key: key, value: value, members_choose: members_choose)
  end

  test "the account's section selects the template the account saved" do
    save("colours", { "template_name" => "forest" })

    render_section

    assert_equal [ "forest" ], css_select("input[type=radio][name=template_name][checked]").map { |option| option["value"] }
  end

  test "the account's section's accent picker shows the accent drawn from the account's colours" do
    save("colours", { "template_name" => "forest" })

    render_section

    assert_equal [ "#10b981" ], css_select("input[type=hidden][name=accent]").map { |input| input["value"] }
  end

  def switch_on?(name)
    css_select("input[type=checkbox][name=#{name}][value=\"1\"]").map { |input| input.key?("checked") }
  end

  test "the account's section lets members choose their own colours until an admin turns it off" do
    render_section

    assert_equal [ true ], switch_on?("members_choose")
  end

  test "the account's section shows the colours switch off once an admin turns it off" do
    save("colours", { "template_name" => "forest" }, members_choose: false)

    render_section

    assert_equal [ false ], switch_on?("members_choose")
  end

  test "the account's section selects the look the account saved among the app's own look and every registered look" do
    save("look", { "look" => "sharp" })

    render_section

    assert_equal [ [ "", false ], [ "brutalist", false ], [ "compact", false ], [ "rounded", false ], [ "sharp", true ], [ "soft", false ] ], css_select("input[type=radio][name=look]").map { |option| [ option["value"], option.key?("checked") ] }
  end

  test "the account's section lets members choose their own look until an admin turns it off" do
    render_section

    assert_equal [ true ], switch_on?("members_choose_look")
  end

  test "the account's section shows the look switch off once an admin turns it off" do
    save("look", { "look" => "sharp" }, members_choose: false)

    render_section

    assert_equal [ false ], switch_on?("members_choose_look")
  end

  def look_options
    css_select("input[type=radio][name=look]")
  end

  test "the account's section offers no look when the app turns off account looks" do
    KeystoneUi::Preferences.configure { |config| config.account_looks = false }

    render_section

    assert_empty look_options
  end

  test "the account's section has no look switch when the app turns off account looks" do
    KeystoneUi::Preferences.configure { |config| config.account_looks = false }

    render_section

    assert_empty switch_on?("members_choose_look")
  end

  test "the account's section offers no look when the app registers none" do
    KeystoneUi.configuration.stub(:looks, {}) { render_section }

    assert_empty look_options
  end

  test "the account's section offers no colours when the app turns off account colours" do
    KeystoneUi::Preferences.configure { |config| config.account_colors = false }

    render_section

    assert_empty template_options
  end

  test "the account's section has no colours switch when the app turns off account colours" do
    KeystoneUi::Preferences.configure { |config| config.account_colors = false }

    render_section

    assert_empty switch_on?("members_choose")
  end

  test "the account's section offers nothing to save when the app turns off account colours and account looks" do
    KeystoneUi::Preferences.configure do |config|
      config.account_colors = false
      config.account_looks = false
    end

    render_section

    assert_equal [ [ "This app does not let accounts choose their colours or look." ], 0 ], [ css_select(".ks-alert-message").map { |message| message.text.strip }, css_select("form").size ]
  end

  test "the account's section shows the theme settings under Colors, Typography and Other after the Members switches" do
    render_section

    order = css_select("input[name=members_choose_look], [data-controller='keystone-ui--preferences--theme-editor'] h2").map { |node| node["name"] || node.text.strip }

    assert_equal %w[members_choose_look Colors Typography Other], order.uniq
  end

  test "the account's section has a box to paste a theme into" do
    render_section

    assert_equal 1, css_select("textarea[name=pasted_theme]").size
  end

  test "the account's theme fields show the values of the theme the account saved" do
    save("colours", { "theme" => { "primary" => { "light" => "oklch(0.205 0 0)", "dark" => "oklch(0.922 0 0)" }, "radius" => { "light" => "0.5rem" } } })

    render_section

    assert_equal [ "oklch(0.205 0 0)", "oklch(0.922 0 0)", "0.5rem" ], [ "theme[primary][light]", "theme[primary][dark]", "theme[radius][light]" ].map { |field| css_select("input[name='#{field}']").first&.[]("value") }
  end

  test "the account's Theme section says the current choice is the account's own theme when it saved one" do
    save("colours", { "theme" => { "primary" => { "light" => "#171717" } } })

    render_section

    assert_equal [ "The account's current choice is its own theme." ], css_select(".ks-hint").map { |hint| hint.text.strip }.grep(/current choice/)
  end

  test "the account's section and the person's section give no two fields the same id when shown on one page" do
    page = render(partial: "keystone_ui/preferences/settings/appearance", locals: { person: admin, account: account, submit_url: "/settings/appearance" }) + render_section

    ids = Nokogiri::HTML5.fragment(page).css("[id]").map { |element| element["id"] }

    assert_empty ids.select { |id| ids.count(id) > 1 }.uniq
  end

  test "the account's section offers the Edit and Preview tabs over the editor and the preview drawn on a light and a dark side" do
    render_section

    tabs = css_select("[data-controller='tab-switcher'] [data-tab-switcher-target='tab']").map { |tab| tab.text.strip }

    assert_equal [ [ "Edit", "Preview" ], %w[light dark] ], [ tabs, css_select("[data-theme-preview] [data-theme]").map { |side| side["data-theme"] } ]
  end
end
