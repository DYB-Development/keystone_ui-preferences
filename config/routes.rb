KeystoneUi::Preferences::Engine.routes.draw do
  patch "/:component_key", to: "component_preferences#update", as: :component_preference
end
