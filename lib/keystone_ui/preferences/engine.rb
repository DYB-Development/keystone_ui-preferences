# frozen_string_literal: true

module KeystoneUi
  module Preferences
    class Engine < ::Rails::Engine
      isolate_namespace KeystoneUi::Preferences
    end
  end
end
