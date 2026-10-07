# frozen_string_literal: true

Rails.application.configure do
  config.action_controller.allow_forgery_protection = false
  config.cache_store = :memory_store
end
