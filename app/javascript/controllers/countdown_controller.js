import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["timer", "progressBar", "button", "message"]
  static values = { 
    expiresAt: String,
    totalDuration: Number
  }

  connect() {
    if (this.expiresAtValue) {
      this.startCountdown()
      this.interval = setInterval(() => {
        this.updateCountdown()
      }, 1000)
    }
  }

  disconnect() {
    if (this.interval) {
      clearInterval(this.interval)
    }
  }

  startCountdown() {
    this.updateCountdown()
  }

  updateCountdown() {
    const now = new Date().getTime()
    const expiresAt = new Date(this.expiresAtValue).getTime()
    const timeLeft = expiresAt - now

    if (timeLeft <= 0) {
      this.enableResend()
      return
    }

    const minutes = Math.floor(timeLeft / (1000 * 60))
    const seconds = Math.floor((timeLeft % (1000 * 60)) / 1000)
    
    const timeString = `${minutes}:${seconds.toString().padStart(2, '0')}`
    this.timerTarget.textContent = timeString

    // Update progress bar
    const totalMs = this.totalDurationValue * 60 * 1000 // Convert minutes to milliseconds
    const elapsedMs = totalMs - timeLeft
    const progressPercentage = Math.min((elapsedMs / totalMs) * 100, 100)
    this.progressBarTarget.style.width = `${progressPercentage}%`

    // Update message
    this.messageTarget.textContent = `Please wait ${timeString} before requesting another confirmation email.`
  }

  enableResend() {
    if (this.interval) {
      clearInterval(this.interval)
    }
    
    // Hide countdown elements and show resend button
    this.element.innerHTML = `
      <div class="text-center">
        <p class="text-sm text-gray-500">
          Didn't receive the email? Check your spam folder or 
          <form action="/email_confirmation/resend" method="post" class="inline">
            <input type="hidden" name="authenticity_token" value="${document.querySelector('meta[name="csrf-token"]').content}">
            <input type="submit" value="resend confirmation email" class="font-medium text-indigo-600 hover:text-indigo-500 bg-transparent border-none underline cursor-pointer">
          </form>
        </p>
      </div>
    `
  }
}