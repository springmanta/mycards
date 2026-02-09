import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["video", "canvas", "results", "status", "overlay"]
  static values = { matchUrl: String, scanning: Boolean }

  connect() {
    this.scanning = false
    this.lastResult = ""
    this.worker = null
    this.initCamera()
    this.initTesseract()
  }

  disconnect() {
    this.stopScanning()
    if (this.stream) {
      this.stream.getTracks().forEach(t => t.stop())
    }
    if (this.worker) {
      this.worker.terminate()
    }
  }

  async initCamera() {
    try {
      this.stream = await navigator.mediaDevices.getUserMedia({
        video: {
          facingMode: "environment",
          width: { ideal: 1280 },
          height: { ideal: 720 }
        }
      })
      this.videoTarget.srcObject = this.stream
      this.videoTarget.play()
      this.statusTarget.textContent = "Initializing OCR..."
    } catch (err) {
      this.statusTarget.textContent = "Camera access denied. Please allow camera access."
      console.error("Camera error:", err)
    }
  }

  async initTesseract() {
    try {
      this.worker = await Tesseract.createWorker("eng", 1, {
        logger: () => {}
      })
      await this.worker.setParameters({
        tessedit_char_whitelist: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz ',.-"
      })
      this.statusTarget.textContent = "Ready! Point camera at a card name."
      this.startScanning()
    } catch (err) {
      this.statusTarget.textContent = "OCR failed to load. Try refreshing."
      console.error("Tesseract error:", err)
    }
  }

  startScanning() {
    this.scanning = true
    this.scanLoop()
  }

  stopScanning() {
    this.scanning = false
  }

  async scanLoop() {
    if (!this.scanning) return

    await this.captureAndRecognize()

    // Scan every 1.5 seconds
    setTimeout(() => this.scanLoop(), 1500)
  }

  async captureAndRecognize() {
    const video = this.videoTarget
    const canvas = this.canvasTarget
    const ctx = canvas.getContext("2d")

    if (video.readyState !== video.HAVE_ENOUGH_DATA) return

    // Crop to top 20% of video (where card name is)
    const videoW = video.videoWidth
    const videoH = video.videoHeight

    // Title region: top portion, centered
    const cropX = videoW * 0.1
    const cropY = videoH * 0.05
    const cropW = videoW * 0.8
    const cropH = videoH * 0.15

    canvas.width = cropW
    canvas.height = cropH

    ctx.drawImage(video, cropX, cropY, cropW, cropH, 0, 0, cropW, cropH)

    // Increase contrast for better OCR
    ctx.filter = "contrast(1.5) brightness(1.1)"
    ctx.drawImage(canvas, 0, 0)
    ctx.filter = "none"

    try {
      const { data: { text, confidence } } = await this.worker.recognize(canvas)

      const cleaned = text.trim().split("\n")[0]?.trim()

      if (cleaned && cleaned.length >= 3 && confidence > 40 && cleaned !== this.lastResult) {
        this.lastResult = cleaned
        this.statusTarget.textContent = `Detected: "${cleaned}"`
        this.statusTarget.classList.add("text-goldenrod")
        this.searchCard(cleaned)
      }
    } catch (err) {
      console.error("OCR error:", err)
    }
  }

  async searchCard(name) {
    try {
      const response = await fetch(`${this.matchUrlValue}?name=${encodeURIComponent(name)}`)
      const data = await response.json()

      if (data.matches && data.matches.length > 0) {
        this.renderResults(data.matches)
      } else {
        this.resultsTarget.innerHTML = `
          <div class="text-center py-4 text-gray-500 text-sm">
            No matches for "${name}"
          </div>`
      }
    } catch (err) {
      console.error("Search error:", err)
    }
  }

  renderResults(matches) {
    this.resultsTarget.innerHTML = matches.map(card => `
      <a href="${card.url}" class="flex items-center gap-3 p-3 bg-white rounded-xl border-2 border-gray-200 hover:border-goldenrod transition-colors">
        ${card.image_uri
          ? `<img src="${card.image_uri}" alt="${card.name}" class="w-14 rounded-lg shadow" />`
          : '<div class="w-14 h-20 bg-gray-200 rounded-lg"></div>'
        }
        <div class="flex-1 min-w-0">
          <p class="font-bold text-gray-900 truncate">${card.name}</p>
          <p class="text-sm text-gray-500">${card.set_name || card.set_code.toUpperCase()} · ${card.rarity}</p>
        </div>
        <svg class="w-5 h-5 text-gray-400 shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7" />
        </svg>
      </a>
    `).join("")
  }
}
