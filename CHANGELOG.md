# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

### Added
- `keystone_palette_style_tag` writes the accent and surface shades and the custom background and text colours for the signed-in person as a `<style>` tag, with the CSS variable names keystone_ui-colors writes, so a layout that calls it keeps working unchanged.
- Colours are read from the `colours` key through the same person-then-account choice and `Rails.cache` entries as a table's layout, so a second page view reads no colour rows.
- A saved accent or surface that is not a palette name or a six-digit hex, and a saved text colour that is not a six-digit hex, draws the configured default for that colour, so a saved value cannot add CSS rules to a page.
- `default_accent`, `default_surface`, `default_background` and `default_text` settings give the colours a person with nothing saved and a visitor who is not signed in see, and the `default` template is built from them.
- A settings_hub section, `keystone_ui/preferences/settings/appearance` with `KeystoneUi::Preferences::PickAppearance`, lets a person pick Default, one of the five colour templates or Custom with an accent, a surface and a text colour, saved under the `colours` key, with the same look and behaviour as keystone_ui-colors' colour settings.
- Saving Default in the appearance section removes the person's saved colours, so the account's colours or the app's defaults apply again.
- The appearance section refuses, with a message and nothing saved, a template not in the catalogue, a Custom colour that is neither a six-digit hex nor a palette name, and any save of colours while the account sets the colours for everyone, when it also says so instead of offering the colours.
- `keystone_ui:preferences:install` copies the template picker script, which sets the colour pickers as soon as a template is picked, into `app/javascript/controllers/keystone_ui/preferences/theme_settings_controller.js`.
- `keystone_ui:preferences:update` copies the template picker script into an app that installed an earlier version, and leaves the file alone when the app already has it.
- The appearance section offers Light, Dark and System, and Custom to a person who may choose their own colours or whose colours draw a background other than white, with the same look as keystone_ui-colors' mode control, and saves the mode under the `mode` key.
- A saved mode is read only from the person's own row and given to keystone_ui through its theme mode supplier, so every page the person opens is marked with it whether or not their account lets members choose colours, and a visitor who is not signed in gets the new `default_mode` setting.
- A mode other than Light, Dark, System or Custom is refused with a message, and nothing is saved.
- Saving in the appearance section clears keystone_ui's theme toggle cookie through settings_hub's `after_settings_change` hook, which the `ComponentPreferences` concern now defines, so the saved mode shows on the next page.

### Changed
- Requires keystone_ui-looks 0.3.0 or later, which supplies the colour palettes, the shade generator and the named colour templates.

## [0.6.0] - 2026-10-13

### Changed
- Requires keystone_ui 0.41.0 or later, the first release that can declare a tab outside any group.

### Fixed
- The tab order section lists a tab declared with keystone_ui's `navigation_tab` as one row among the groups, with the group Up and Down buttons, instead of as a group label with a single tab row under it.
- Moving a tab declared outside any group saves it in the order by its label alone, with no list of tabs.

## [0.5.0] - 2026-10-10

### Added
- A settings_hub section, `keystone_ui/preferences/settings/navigation_placement` with `KeystoneUi::Preferences::PickNavigationPlacement`, lets a person choose Top, Left or Right for the desktop navigation, saved under the `navigation` key, and refuses any other placement with a message.
- A settings_hub section, `keystone_ui/preferences/settings/navigation_order` with `KeystoneUi::Preferences::PickNavigationOrder`, lists the navigation's groups and the tabs a person may see in their current order, moves a group or tab up or down with buttons that save at once, and resets to the declared order.

### Changed
- Requires keystone_ui 0.38.0 or later, the first release with navigation groups and a saved navigation order.
- Saving a navigation placement keeps the person's saved tab order, and saving a tab order keeps their placement.
- When the account turns off members-choose for the `navigation` key, the placement and tab order sections say the account sets the navigation and offer no save, and a placement, tab order or reset sent anyway is refused with a message and saves nothing.

## [0.4.1] - 2026-10-07

### Fixed
- The install migration no longer adds an owner index that the owner and component key index already covers, and `keystone_ui:preferences:update` copies a migration that drops it from an app that installed an earlier version.

## [0.4.0] - 2026-10-07

### Added
- The layout lookup keeps each owner's row for a component key, or the fact that there is none, in `Rails.cache`, so a second view of a page makes no query for it, and a row clears its entry when it is saved.
- The save address refuses a body that is not a JSON object, a body larger than `max_value_bytes` (10,000 by default), and a component key that is not 1 to 64 letters, digits and underscores, answering 422 and saving nothing.

## [0.3.0] - 2026-10-07

### Added
- `config.name_component(key, name)` gives a component key the name the account layouts settings section shows for it, which otherwise shows the key in words.

## [0.2.0] - 2026-10-07

### Added
- With `current_account_method` set, an account can keep its own layout for a component key and a members-choose switch, and a table shows the person's own layout when the account lets members choose, otherwise the account's, otherwise its default.
- A person whose account does not let members choose sees no Columns menu, and their saves are refused.
- A settings_hub account section, `keystone_ui/preferences/settings/account_layouts` with `KeystoneUi::Preferences::PickAccountLayouts`, sets each key's members-choose switch and makes the admin's layout the account's.

## [0.1.0] - 2026-10-06

### Added
- An install generator that copies a migration for one saved value per owner and component key, with a members-choose switch on by default.
- A save address for each component key that keeps the signed-in person's JSON object, replacing what they saved before.
- A lookup that hands keystone_ui the signed-in person's saved value and save address for a data table's key.
- `current_owner_method` and `authentication_method` settings naming the host's signed-in person and sign-in check.
