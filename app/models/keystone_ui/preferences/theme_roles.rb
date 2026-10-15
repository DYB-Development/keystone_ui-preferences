# frozen_string_literal: true

module KeystoneUi
  module Preferences
    module ThemeRoles
      ROLES = {
        "background" => { kind: :colour, variables: %w[--ks-color-page] },
        "foreground" => { kind: :colour, variables: %w[--ks-color-on-page] },
        "card" => { kind: :colour, variables: %w[--ks-color-surface] },
        "card-foreground" => { kind: :colour, variables: %w[--ks-color-on-surface] },
        "popover" => { kind: :colour, variables: %w[--ks-color-overlay] },
        "popover-foreground" => { kind: :colour, variables: %w[--ks-color-on-overlay --ks-color-on-overlay-muted] },
        "primary" => { kind: :colour, variables: %w[--ks-color-accent] },
        "primary-foreground" => { kind: :colour, variables: %w[--ks-color-on-accent] },
        "secondary" => { kind: :colour, variables: %w[--ks-color-neutral] },
        "secondary-foreground" => { kind: :colour, variables: %w[--ks-color-on-neutral] },
        "muted" => { kind: :colour, variables: %w[--ks-color-fill-muted] },
        "muted-foreground" => { kind: :colour, variables: %w[--ks-color-text-muted] },
        "accent" => { kind: :colour, variables: %w[--ks-color-hover] },
        "accent-foreground" => { kind: :colour, variables: %w[--ks-color-on-hover --ks-color-on-hover-muted] },
        "destructive" => { kind: :colour, variables: %w[--ks-color-danger] },
        "destructive-foreground" => { kind: :colour, variables: %w[--ks-color-on-danger] },
        "border" => { kind: :colour, variables: %w[--ks-color-border] },
        "input" => { kind: :colour, variables: %w[--ks-color-border-control] },
        "ring" => { kind: :colour, variables: %w[--ks-color-focus] },
        "chart-1" => { kind: :colour, variables: %w[--ks-color-chart-1] },
        "chart-2" => { kind: :colour, variables: %w[--ks-color-chart-2] },
        "chart-3" => { kind: :colour, variables: %w[--ks-color-chart-3] },
        "chart-4" => { kind: :colour, variables: %w[--ks-color-chart-4] },
        "chart-5" => { kind: :colour, variables: %w[--ks-color-chart-5] },
        "sidebar" => { kind: :colour, variables: %w[--ks-color-nav] },
        "sidebar-foreground" => { kind: :colour, variables: %w[--ks-color-nav-link --ks-color-nav-text] },
        "sidebar-primary" => { kind: :colour, variables: %w[--ks-color-nav-indicator --ks-color-nav-active] },
        "sidebar-primary-foreground" => { kind: :colour, variables: [] },
        "sidebar-accent" => { kind: :colour, variables: %w[--ks-color-nav-hover] },
        "sidebar-accent-foreground" => { kind: :colour, variables: %w[--ks-color-nav-text-hover] },
        "sidebar-border" => { kind: :colour, variables: %w[--ks-color-nav-border] },
        "sidebar-ring" => { kind: :colour, variables: [] }
      }.freeze

      def self.names
        ROLES.keys
      end
    end
  end
end
