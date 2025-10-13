// app/javascript/controllers/mobile_menu_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["menu", "open", "close"]

  toggle() {
    this.menuTarget.classList.toggle("hidden")
    this.openTarget.classList.toggle("hidden")
    this.closeTarget.classList.toggle("hidden")
  }
}
