# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include KeystoneUi::Preferences::ComponentPreferences

  cattr_accessor :signed_in_user

  def current_user
    signed_in_user
  end

  def authenticate_user!
    head :unauthorized unless current_user
  end
end
