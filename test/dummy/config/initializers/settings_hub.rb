# frozen_string_literal: true

Rails.application.config.to_prepare do
  SettingsHub.section :appearance, area: :user, title: "Appearance",
    renders: "keystone_ui/preferences/settings/appearance",
    runs: "KeystoneUi::Preferences::PickAppearance"
end
