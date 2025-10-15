// app/javascript/controllers/set_autocomplete_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "results"]

  connect() {
    this.timeout = null
    document.addEventListener("click", this.handleClickOutside.bind(this))
  }

  disconnect() {
    document.removeEventListener("click", this.handleClickOutside.bind(this))
  }

  search() {
    clearTimeout(this.timeout)
    const query = this.inputTarget.value.trim()

    if (query.length < 2) {
      this.hideResults()
      return
    }

    this.timeout = setTimeout(() => this.fetchResults(query), 300)
  }

  async fetchResults(query) {
    try {
      const response = await fetch(`/sets/autocomplete?q=${encodeURIComponent(query)}`)
      const data = await response.json()
      this.displayResults(data.data || [])
    } catch (error) {
      console.error("Set autocomplete error:", error)
      this.hideResults()
    }
  }

  displayResults(sets) {
    if (sets.length === 0) {
      this.hideResults()
      return
    }

    this.resultsTarget.innerHTML = sets.map(set => `
      <a href="/sets/${set.code}"
         class="block px-4 py-2.5 text-sm text-gray-700 hover:bg-gray-50 border-b border-gray-100 last:border-b-0 no-underline">
        <div class="flex items-center gap-2">
          ${set.icon_svg_uri ? `<img src="${set.icon_svg_uri}" class="w-6 h-6" alt="">` : ''}
          <div class="flex-1">
            <span class="font-semibold">${set.name}</span>
            <span class="text-xs text-gray-500 ml-2">${set.code.toUpperCase()}</span>
          </div>
        </div>
      </a>
    `).join('')

    this.showResults()
  }

  showResults() {
    this.resultsTarget.classList.remove('hidden')
  }

  hideResults() {
    this.resultsTarget.classList.add('hidden')
  }

  handleClickOutside(event) {
    if (!this.element.contains(event.target)) {
      this.hideResults()
    }
  }
}
