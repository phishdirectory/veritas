import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  validate() {
    const password = this.element.value
    
    // Check length
    const lengthReq = document.getElementById('req-length')
    this.updateRequirement(lengthReq, password.length >= 8)
    
    // Check uppercase
    const uppercaseReq = document.getElementById('req-uppercase')
    this.updateRequirement(uppercaseReq, /[A-Z]/.test(password))
    
    // Check lowercase
    const lowercaseReq = document.getElementById('req-lowercase')
    this.updateRequirement(lowercaseReq, /[a-z]/.test(password))
    
    // Check number
    const numberReq = document.getElementById('req-number')
    this.updateRequirement(numberReq, /\d/.test(password))
    
    // Check special character
    const specialReq = document.getElementById('req-special')
    this.updateRequirement(specialReq, /[!@#$%^&*()_+\-=\[\]{}|;:,.<>?]/.test(password))
  }
  
  updateRequirement(element, met) {
    const icon = element.querySelector('span')
    
    if (met) {
      element.className = 'flex items-center text-green-600'
      icon.textContent = '✓'
    } else {
      element.className = 'flex items-center text-red-600'
      icon.textContent = '✗'
    }
  }
}