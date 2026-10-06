# frozen_string_literal: true

module KeystoneUi
  module Preferences
    class ApplicationRecord < ActiveRecord::Base
      self.abstract_class = true
    end
  end
end
