# frozen_string_literal: true

Rails.application.routes.draw do
  mount KeystoneUi::Preferences::Engine => "/keystone_ui_preferences"
end
