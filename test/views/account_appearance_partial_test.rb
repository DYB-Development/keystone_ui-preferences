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

  test "the account's section offers Default, the five colour templates and Custom" do
    render_section

    assert_equal [ "default", "ocean", "forest", "twilight", "coral", "arctic", "" ], template_options
  end
end
