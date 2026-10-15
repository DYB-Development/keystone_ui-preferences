import { test } from "node:test"
import assert from "node:assert/strict"
import ThemeEditorController from "../../app/javascript/keystone_ui/preferences/theme_editor_controller.js"

const ROLES = {
  "primary": { kind: "colour", variables: ["--ks-color-accent"], hover: "--ks-color-accent-hover" },
  "popover-foreground": { kind: "colour", variables: ["--ks-color-on-overlay", "--ks-color-on-overlay-muted"] },
  "radius": { kind: "length", variables: ["--ks-radius-control", "--ks-radius-surface"] },
  "letter-spacing": { kind: "letter_spacing", variables: ["--ks-letter-spacing"] },
  "font-mono": { kind: "font_list", variables: ["--ks-font-mono", "--default-mono-font-family"] },
  "font-weight-strong": { kind: "weight", variables: ["--ks-font-weight-strong"] }
}

const DRAWABLE = {
  "color": ["#1f5fbf"],
  "width": ["0.5rem"],
  "letter-spacing": ["-0.02em"],
  "font-family": ["Menlo, monospace"],
  "font-weight": ["600"]
}

globalThis.CSS = { supports: (property, value) => (DRAWABLE[property] ?? []).includes(value) }

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

test("changing a field that is not a theme setting sets nothing on the page's root element", () => {
  const root = pageRoot()

  editorOn(root).apply(change("", "#1f5fbf"))

  assert.deepEqual(root.variables, {})
})

test("changing a colour to one the browser cannot draw leaves the page's root element as it was", () => {
  const root = pageRoot()

  editorOn(root).apply(change("theme[popover-foreground][light]", "not a colour"))

  assert.deepEqual(root.variables, {})
})

test("changing a colour whose role has a hover colour also sets the hover colour the theme writer derives from it", () => {
  const root = pageRoot()

  editorOn(root).apply(change("theme[primary][light]", "#1f5fbf"))

  assert.equal(root.variables["--ks-color-accent-hover"], "color-mix(in oklab, #1f5fbf 85%, white)")
})

test("changing a radius, spacing or border width sets each of its role's variables on the page's root element", () => {
  const root = pageRoot()

  editorOn(root).apply(change("theme[radius][light]", "0.5rem"))

  assert.deepEqual(root.variables, { "--ks-radius-control": "0.5rem", "--ks-radius-surface": "0.5rem" })
})

test("changing the letter spacing sets its variable on the page's root element", () => {
  const root = pageRoot()

  editorOn(root).apply(change("theme[letter-spacing][light]", "-0.02em"))

  assert.deepEqual(root.variables, { "--ks-letter-spacing": "-0.02em" })
})

test("changing a font sets each of its role's variables on the page's root element", () => {
  const root = pageRoot()

  editorOn(root).apply(change("theme[font-mono][light]", "Menlo, monospace"))

  assert.deepEqual(root.variables, { "--ks-font-mono": "Menlo, monospace", "--default-mono-font-family": "Menlo, monospace" })
})

test("changing a font weight sets its variable on the page's root element", () => {
  const root = pageRoot()

  editorOn(root).apply(change("theme[font-weight-strong][light]", "600"))

  assert.deepEqual(root.variables, { "--ks-font-weight-strong": "600" })
})

test("changing a colour's dark value sets only the dark variables, and the dark hover colour, on the page's root element", () => {
  const root = pageRoot()

  editorOn(root).apply(change("theme[primary][dark]", "#1f5fbf"))

  assert.deepEqual(root.variables, { "--ks-color-accent-dark": "#1f5fbf", "--ks-color-accent-hover-dark": "color-mix(in oklab, #1f5fbf 85%, white)" })
})

test("leaving the theme fields removes every variable the editor set, so the next page is drawn in the saved theme", () => {
  const root = pageRoot()
  const editor = editorOn(root)
  editor.apply(change("theme[primary][light]", "#1f5fbf"))
  editor.apply(change("theme[radius][light]", "0.5rem"))

  editor.disconnect()

  assert.deepEqual(root.variables, {})
})
