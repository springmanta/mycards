// app/javascript/controllers/toggle_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["content", "icon"]
  static values = { open: { type: Boolean, default: false } }

  connect() {
    // Auto-open if filters are active
    if (this.openValue) {
      this.open()
    }
  }

  toggle() {
    if (this.contentTarget.classList.contains('hidden')) {
      this.open()
    } else {
      this.close()
    }
  }

  open() {
    this.contentTarget.classList.remove('hidden')
    this.iconTarget.classList.add('rotate-180')
  }

  close() {
    this.contentTarget.classList.add('hidden')
    this.iconTarget.classList.remove('rotate-180')
  }
}
