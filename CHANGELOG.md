# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

## [0.1.0] - 2026-10-06

### Added
- An install generator that copies a migration for one saved value per owner and component key, with a members-choose switch on by default.
- A save address for each component key that keeps the signed-in person's JSON object, replacing what they saved before.
- A lookup that hands keystone_ui the signed-in person's saved value and save address for a data table's key.
- `current_owner_method` and `authentication_method` settings naming the host's signed-in person and sign-in check.
