import { Controller } from "@hotwired/stimulus"

const THEME_FIELD = /^theme\[([^\]]+)\]\[(light|dark)\]$/
const PROPERTY_FOR_KIND = { colour: "color", length: "width", letter_spacing: "letter-spacing", font_list: "font-family", weight: "font-weight" }

export default class extends Controller {
  #setVariables = new Set()

  apply({ target: { name, value } }) {
    const field = name.match(THEME_FIELD)
    if (!field) return

    const [, role, side] = field
    const { kind, variables, hover } = JSON.parse(this.element.dataset.themeRoles)[role]
    if (!CSS.supports(PROPERTY_FOR_KIND[kind], value)) return

    const suffix = side === "dark" ? "-dark" : ""
    variables.forEach(variable => this.#set(`${variable}${suffix}`, value))
    if (hover) this.#set(`${hover}${suffix}`, `color-mix(in oklab, ${value} 85%, white)`)
  }

  disconnect() {
    this.#setVariables.forEach(variable => this.#rootStyle().removeProperty(variable))
    this.#setVariables.clear()
  }

  #set(variable, value) {
    this.#rootStyle().setProperty(variable, value)
    this.#setVariables.add(variable)
  }

  #rootStyle() {
    return this.element.ownerDocument.documentElement.style
  }
}
