// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"

document.addEventListener('click', (event) => {
  const autocompleteElements = document.querySelectorAll('[data-controller~="autocomplete"]')
  autocompleteElements.forEach(element => {
    if (!element.contains(event.target)){
      const controller = Stimulus.getControllerForElementsAndIdentifier(element, 'autocomplete')
      if (controller) controller.hideResults()
    }
  })
})
