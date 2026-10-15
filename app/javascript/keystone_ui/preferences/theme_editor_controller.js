import { Controller } from "@hotwired/stimulus"

const THEME_FIELD = /^theme\[([^\]]+)\]\[(light|dark)\]$/

export default class extends Controller {
  apply({ target: { name, value } }) {
    const field = name.match(THEME_FIELD)
    if (!field || !CSS.supports("color", value)) return

    const [, role] = field
    const { variables, hover } = JSON.parse(this.element.dataset.themeRoles)[role]
    const style = this.element.ownerDocument.documentElement.style

    variables.forEach(variable => style.setProperty(variable, value))
    if (hover) style.setProperty(hover, `color-mix(in oklab, ${value} 85%, white)`)
  }
}
