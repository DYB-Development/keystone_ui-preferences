# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

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
