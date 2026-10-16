import { test } from "node:test"
import assert from "node:assert/strict"
import { readFileSync } from "node:fs"
import AppearanceEditorController from "../../app/javascript/keystone_ui/preferences/appearance_editor_controller.js"

const { roles, presets } = JSON.parse(readFileSync(new URL("../fixtures/drawn/presets.json", import.meta.url), "utf8"))

globalThis.CSS = { supports: () => true }

function drawn(theme) {
  const variables = {}
  const fields = Object.fromEntries(Object.entries(theme).flatMap(([role, sides]) => Object.entries(sides).map(([side, value]) => [`[name="theme[${role}][${side}]"]`, { name: `theme[${role}][${side}]`, value }])))
  const parts = { ...fields, "[data-theme-roles]": { dataset: { themeRoles: JSON.stringify(roles) } } }
  const root = { style: { setProperty(name, value) { variables[name] = value }, removeProperty(name) { delete variables[name] } } }
  const element = { ownerDocument: { documentElement: root }, querySelector: selector => parts[selector] ?? null, querySelectorAll: () => [] }
  const editor = new AppearanceEditorController({ scope: { element } })

  Object.values(fields).forEach(field => editor.apply({ target: field }))
  return variables
}

test("choosing each preset theme draws the same variables, hover colours and shadow the theme writer writes for it", () => {
  const expected = Object.fromEntries(Object.entries(presets).map(([name, { variables }]) => [name, variables]))

  assert.deepEqual(Object.fromEntries(Object.entries(presets).map(([name, { theme }]) => [name, drawn(theme)])), expected)
})
