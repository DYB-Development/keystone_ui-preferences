# frozen_string_literal: true

class HostPalettesController < ApplicationController
  layout "palette"
  keystone_host_colors

  def show
  end
end
