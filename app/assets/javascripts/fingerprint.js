document.addEventListener('DOMContentLoaded', async () => {
  try {
    // Use the globally loaded FingerprintJS
    if (window.FingerprintJS) {
      const fp = await window.FingerprintJS.load()
      const result = await fp.get()
      const visitorId = result.visitorId

      const fingerprintField = document.querySelector('#fingerprint')
      if (fingerprintField) {
        fingerprintField.value = visitorId
      }

      const deviceField = document.querySelector('#device_info')
      if (deviceField && window.UAParser) {
        const parser = new UAParser()
        const browser = parser.getBrowser()
        deviceField.value = `${browser.name} ${browser.version}`
      }

      const osField = document.querySelector('#os_info')
      if (osField && window.UAParser) {
        const parser = new UAParser()
        const os = parser.getOS()
        osField.value = `${os.name} ${os.version || ''}`
      }

      const timezoneField = document.querySelector('#timezone')
      if (timezoneField) {
        timezoneField.value = Intl.DateTimeFormat().resolvedOptions().timeZone
      }
    }
  } catch (error) {
    console.error('Error collecting fingerprint:', error)
  }
})
