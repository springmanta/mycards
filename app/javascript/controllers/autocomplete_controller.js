import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "results"]
  static values = { url: String }

  connect() {
    this.timeout = null
  }

  search() {
    clearTimeout(this.timeout)

    const query = this.inputTarget.value.trim()

    if (query.length < 2) {
      this.hideResults()
      return
    }

    // Timeout
    this.timeout = setTimeout(() => {
      this.fetchResults(query)
    }, 300);
  }

  async fetchResults(query) {
    try {
      const response = await fetch(`https://api.scryfall.com/cards/autocomplete?q=${encodeURIComponent(query)}`)
      const data = await response.json()

      this.displayResults(data.data || [])
    } catch (error) {
      console.error("Autocomplete error:", error)
      this.hideResults
    }
  }

displayResults(cards) {
  if (cards.length === 0) {
    this.hideResults()
    return
  }

  this.resultsTarget.innerHTML = cards.map(card => `
    <div class="block px-4 py-2.5 text-sm text-gray-700 hover:bg-gray-50 cursor-pointer border-b border-gray-100 last:border-b-0"
         data-action="click->autocomplete#selectCard"
         data-card-name="${card}">
      <span class="italic">${card}</span>
    </div>
  `).join('')

  this.showResults()
}

selectCard(event) {
  const cardName = event.currentTarget.dataset.cardName
  this.inputTarget.value = cardName
  this.hideResults()

  // Submit the form
  this.element.querySelector('form').submit()
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
