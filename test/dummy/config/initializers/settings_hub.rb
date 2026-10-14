# frozen_string_literal: true

Rails.application.config.to_prepare do
  SettingsHub.section :appearance, area: :user, title: "Appearance",
    renders: "keystone_ui/preferences/settings/appearance",
    runs: "KeystoneUi::Preferences::PickAppearance"
  SettingsHub.section :navigation_placement, area: :user, title: "Navigation",
    renders: "keystone_ui/preferences/settings/navigation_placement",
    runs: "KeystoneUi::Preferences::PickNavigationPlacement"
  SettingsHub.section :account_appearance, area: :account, title: "Appearance",
    renders: "keystone_ui/preferences/settings/account_appearance",
    runs: "KeystoneUi::Preferences::PickAccountAppearance"
end
