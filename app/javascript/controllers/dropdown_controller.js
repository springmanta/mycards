// app/javascript/controllers/dropdown_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["menu"]

  connect() {
    this.boundHandleClickOutside = this.handleClickOutside.bind(this)
  }

  toggle(event) {
    event.stopPropagation()
    this.menuTarget.classList.toggle("hidden")

    if (!this.menuTarget.classList.contains("hidden")) {
      document.addEventListener("click", this.boundHandleClickOutside)
    } else {
      document.removeEventListener("click", this.boundHandleClickOutside)
    }
  }

  handleClickOutside(event) {
    if (!this.element.contains(event.target)) {
      this.menuTarget.classList.add("hidden")
      document.removeEventListener("click", this.boundHandleClickOutside)
    }
  }

  disconnect() {
    document.removeEventListener("click", this.boundHandleClickOutside)
  }
}
