import { Controller } from "@hotwired/stimulus"

const THEME_FIELD = /^theme\[([^\]]+)\]\[(light|dark)\]$/

export default class extends Controller {
  apply({ target: { name, value } }) {
    const field = name.match(THEME_FIELD)
    if (!field) return

    const [, role] = field
    const roles = JSON.parse(this.element.dataset.themeRoles)
    const style = this.element.ownerDocument.documentElement.style

    roles[role].variables.forEach(variable => style.setProperty(variable, value))
  }
}
