# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

### Added
- The person's Appearance section has a paste box in its Theme section that saves a theme in shadcn/ui's variable names as the person's colours, keeping the 32 shadcn colour roles from a `:root` block and a `.dark` block and ignoring every other declaration, selector and rule.
- A pasted colour is saved only when it is a hex colour or an `rgb()`, `hsl()` or `oklch()` colour written with plain numbers, and is otherwise refused with a message naming the role.
- A paste over 20,000 characters, a paste containing `url(` or `@import`, and a paste with no shadcn colour role are refused with a message, and nothing is saved.
- A pasted theme is saved as `{ "theme": { "<role>": { "light": ..., "dark": ... } } }` under the `colours` key, holding only the checked colours and never the pasted text.
- The Theme section says a pasted theme is the person's current choice and selects no template for it.

### Changed
- keystone_ui-styles 0.18.0 or later is required, since each theme role names the `--ks-*` variables it will set.

### Fixed
- The boot check's message and the README's steps for moving off keystone_ui-colors remove keystone_ui-colors before running the update generator, since the generator boots the app and the boot check refuses to boot while keystone_ui-colors is loaded.

## [0.7.0] - 2026-10-15

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
- The appearance section offers a look, with the same look as keystone_ui-colors' look control: the app's own look first under the new `app_look_label` setting, which defaults to "Classic", then every look registered with keystone_ui, with the person's saved look selected, saved under the `look` key.
- Saving the app's own look removes the person's saved look, so the account's look or the app's default look applies again.
- A saved look is read through the same person-then-account choice as the colours and given to keystone_ui through its look supplier, so every page the person opens is marked with it, and a saved look the app no longer registers is passed over for the account's look or the app's default look.
- A look name keystone_ui does not register is refused with a message, and nothing is saved.
- The new `user_looks` setting, true by default, turns off a person's own looks when false: the section offers no look, a save ignores a look sent with it, and a person's saved look is passed over for the account's look or the app's default look.
- The appearance section offers no look when the app registers none.
- A settings_hub account section, `keystone_ui/preferences/settings/account_appearance` with `KeystoneUi::Preferences::PickAccountAppearance`, lets an admin pick the account's template or custom colours and the account's look, with the same look as keystone_ui-colors' account picker, saved under the account's `colours` and `look` keys.
- The account section has a switch for whether members choose their own colours and a separate switch for whether members choose their own look, both on until an admin turns them off, saved in the `members_choose` column of the account's `colours` and `look` rows.
- The account section refuses, with a message and nothing saved, a template not in the catalogue, a Custom colour that is neither a six-digit hex nor a palette name, a look the app does not register, and a save with no account.
- While the account turns off members choosing their own look, every member sees the account's look, their appearance section offers no look, and a look they send is ignored.
- The new `account_colors` setting, true by default, turns off accounts' and members' colours when false: neither section offers colours, every page draws the configured defaults, and colours sent to either section are refused with a message.
- The new `account_looks` setting, true by default, turns off accounts' looks when false: the account section offers no look, a look sent to it is ignored, and a saved account look is not applied.
- A controller that declares `keystone_host_colors`, with the same name and the same `only:` and `except:` options as keystone_ui-colors' declaration, draws its pages in the app's default colours, mode and look whatever the signed-in person or their account saved, while a choice made with keystone_ui's theme toggle in that browser still sets light or dark there.
- `keystone_ui:preferences:update` copies a migration that copies every keystone_ui-colors theme preference into the `colours`, `mode` and `look` rows of the same owner, with the account's two members-choose switches, so every person and account keeps the colours, mode and look they saved.
- The copy keeps a row an owner already has for a key, does nothing in an app without keystone_ui-colors' table, changes nothing when run a second time or rolled back, and reads keystone_ui-colors' table in batches.
- A saved template keystone_ui-looks no longer has draws the account's colours, or the configured defaults, instead of raising an error, and the appearance section shows no template selected for it and still saves a new one.
- A saved accent or surface name keystone_ui-looks no longer has draws the configured default accent or surface instead of raising an error.
- Each of these fallbacks writes one warning to the app's log naming the owner's type and id and the missing name.
- An app that loads keystone_ui-colors beside keystone_ui-preferences stops at boot with `KeystoneUi::Preferences::ColorsCheck::Error`, whose message names keystone_ui-colors as the gem to remove and the update generator as the step to run first.

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
