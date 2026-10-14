# frozen_string_literal: true

Rails.application.routes.draw do
  get "/months", to: "months#index"
  get "/navigation", to: "navigations#show"
  get "/palette", to: "palettes#show"
  mount KeystoneUi::Preferences::Engine => "/keystone_ui_preferences"
  mount SettingsHub::Engine => "/settings"
end
