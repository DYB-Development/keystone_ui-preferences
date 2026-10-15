import { test } from "node:test"
import assert from "node:assert/strict"
import ThemeEditorController from "../../app/javascript/keystone_ui/preferences/theme_editor_controller.js"

const ROLES = {
  "primary": { kind: "colour", variables: ["--ks-color-accent"], hover: "--ks-color-accent-hover" },
  "popover-foreground": { kind: "colour", variables: ["--ks-color-on-overlay", "--ks-color-on-overlay-muted"] }
}

function pageRoot() {
  const variables = {}
  return {
    variables,
    style: {
      setProperty(name, value) { variables[name] = value },
      removeProperty(name) { delete variables[name] }
    }
  }
}

function editorOn(root) {
  const element = { ownerDocument: { documentElement: root }, dataset: { themeRoles: JSON.stringify(ROLES) } }
  return new ThemeEditorController({ scope: { element } })
}

function change(name, value) {
  return { target: { name, value } }
}

test("changing a colour's light value sets each of its role's variables on the page's root element", () => {
  const root = pageRoot()

  editorOn(root).apply(change("theme[popover-foreground][light]", "#1f5fbf"))

  assert.deepEqual(root.variables, { "--ks-color-on-overlay": "#1f5fbf", "--ks-color-on-overlay-muted": "#1f5fbf" })
})
