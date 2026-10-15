import { Controller } from "@hotwired/stimulus"

const THEME_FIELD = /^theme\[([^\]]+)\]\[(light|dark)\]$/
const ENDS_DECLARATION = /[;{}]/
const PROPERTY_FOR_KIND = { colour: "color", length: "width", letter_spacing: "letter-spacing", font_list: "font-family", weight: "font-weight" }

export default class extends Controller {
  #setVariables = new Set()

  connect() {
    this.#writeExport()
  }

  apply({ target: { name, value } }) {
    this.#writeExport()
    const field = name.match(THEME_FIELD)
    if (!field) return

    const [, role, side] = field
    const { kind, variables, hover } = JSON.parse(this.element.dataset.themeRoles)[role]
    const suffix = side === "dark" ? "-dark" : ""
    if (value === "") {
      [...variables, hover].filter(Boolean).forEach(variable => this.#remove(`${variable}${suffix}`))
      return
    }
    if (!CSS.supports(PROPERTY_FOR_KIND[kind], value)) return

    variables.forEach(variable => this.#set(`${variable}${suffix}`, value))
    if (hover) this.#set(`${hover}${suffix}`, `color-mix(in oklab, ${value} 85%, white)`)
  }

  disconnect() {
    this.#setVariables.forEach(variable => this.#rootStyle().removeProperty(variable))
    this.#setVariables.clear()
  }

  #writeExport() {
    const roles = Object.keys(JSON.parse(this.element.dataset.themeRoles))
    const block = side => roles.flatMap(role => {
      const field = this.element.querySelector(`[name="theme[${role}][${side}]"]`)
      return field?.value && !ENDS_DECLARATION.test(field.value) ? [`  --${role}: ${field.value};\n`] : []
    }).join("")
    this.element.querySelector("[data-theme-export]").value = `:root {\n${block("light")}}\n\n.dark {\n${block("dark")}}\n`
  }

  #set(variable, value) {
    this.#rootStyle().setProperty(variable, value)
    this.#setVariables.add(variable)
  }

  #remove(variable) {
    this.#rootStyle().removeProperty(variable)
    this.#setVariables.delete(variable)
  }

  #rootStyle() {
    return this.element.ownerDocument.documentElement.style
  }
}
