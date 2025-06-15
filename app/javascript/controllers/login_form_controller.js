import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="login-form"
export default class extends Controller {
  static targets = ["email", "password", "passwordContainer", "submitButton", "loadingIndicator"]

  connect() {
    this.emailCheckTimeout = null
    this.lastCheckedEmail = ""
    this.passwordLoginEnabled = false
  }

  disconnect() {
    if (this.emailCheckTimeout) {
      clearTimeout(this.emailCheckTimeout)
    }
  }

  emailChanged() {
    const email = this.emailTarget.value.trim()
    
    // Clear previous timeout
    if (this.emailCheckTimeout) {
      clearTimeout(this.emailCheckTimeout)
    }

    // Hide password field and disable submit while checking
    this.hidePasswordField()
    this.submitButtonTarget.disabled = true
    this.submitButtonTarget.textContent = "Continue"

    if (email === "") {
      this.hideLoadingIndicator()
      return
    }

    if (email === this.lastCheckedEmail) {
      return
    }

    // Show loading indicator
    this.showLoadingIndicator()

    // Debounce email checking
    this.emailCheckTimeout = setTimeout(() => {
      this.checkPasswordLoginEnabled(email)
    }, 800)
  }

  async checkPasswordLoginEnabled(email) {
    this.lastCheckedEmail = email

    try {
      const response = await fetch('/auth/check_password_login', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').getAttribute('content')
        },
        body: JSON.stringify({ email: email })
      })

      const data = await response.json()

      this.hideLoadingIndicator()

      if (data.password_login_enabled) {
        this.showPasswordField()
        this.submitButtonTarget.textContent = "Sign In"
        this.passwordLoginEnabled = true
      } else {
        this.hidePasswordField()
        this.submitButtonTarget.textContent = "Send Magic Link"
        this.passwordLoginEnabled = false
      }

      this.submitButtonTarget.disabled = false

    } catch (error) {
      console.error('Error checking password login status:', error)
      this.hideLoadingIndicator()
      // Default to magic link on error
      this.hidePasswordField()
      this.submitButtonTarget.textContent = "Send Magic Link"
      this.passwordLoginEnabled = false
      this.submitButtonTarget.disabled = false
    }
  }

  showPasswordField() {
    this.passwordContainerTarget.style.display = "block"
    this.passwordTarget.required = true
    
    // Add smooth transition
    this.passwordContainerTarget.style.opacity = "0"
    this.passwordContainerTarget.style.transform = "translateY(-10px)"
    
    setTimeout(() => {
      this.passwordContainerTarget.style.transition = "all 0.3s ease"
      this.passwordContainerTarget.style.opacity = "1"
      this.passwordContainerTarget.style.transform = "translateY(0)"
    }, 10)
  }

  hidePasswordField() {
    this.passwordContainerTarget.style.display = "none"
    this.passwordTarget.required = false
    this.passwordTarget.value = ""
  }

  showLoadingIndicator() {
    this.loadingIndicatorTarget.style.display = "block"
  }

  hideLoadingIndicator() {
    this.loadingIndicatorTarget.style.display = "none"
  }

  // Handle form submission
  submitForm(event) {
    // If password login is not enabled, clear password field
    // so the backend knows to send magic link
    if (!this.passwordLoginEnabled) {
      this.passwordTarget.value = ""
    }
  }
}