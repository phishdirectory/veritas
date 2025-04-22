# lib/tasks/api_docs.rake
namespace :api do
  desc "Generate API documentation for service integration"
  task generate_docs: :environment do
    puts "Generating API documentation for service integration..."

    docs_dir = Rails.root.join('docs', 'api')
    FileUtils.mkdir_p(docs_dir)

    # Generate documentation file
    File.open(docs_dir.join('service_integration.md'), 'w') do |f|
      f.puts "# Service Integration with Auth.P.D"
      f.puts
      f.puts "## Authentication"
      f.puts
      f.puts "Each service has two keys:"
      f.puts "- **API Key**: Used for authenticating the service with Auth.P.D"
      f.puts "- **Hash Key**: Used for encrypting sensitive data before transmission"
      f.puts
      f.puts "Both keys must be kept secure and should never be exposed to clients or in client-side code."
      f.puts
      f.puts "## API Endpoints"
      f.puts
      f.puts "### 1. Create User"
      f.puts "- **URL**: `/api/v1/users`"
      f.puts "- **Method**: `POST`"
      f.puts "- **Headers**:"
      f.puts "  - `X-Api-Key`: Your service API key"
      f.puts "  - `Content-Type`: `application/json`"
      f.puts "- **Body**:"
      f.puts "  ```json"
      f.puts "  {"
      f.puts "    \"hashed_data\": \"<base64-encoded-encrypted-user-data>\""
      f.puts "  }"
      f.puts "  ```"
      f.puts "- **User data format (before hashing)**:"
      f.puts "  ```json"
      f.puts "  {"
      f.puts "    \"first_name\": \"John\","
      f.puts "    \"last_name\": \"Doe\","
      f.puts "    \"email\": \"john.doe@example.com\","
      f.puts "    \"password\": \"SecurePassword123\","
      f.puts "    \"password_confirmation\": \"SecurePassword123\""
      f.puts "  }"
      f.puts "  ```"
      f.puts
      f.puts "### 2. Authenticate User"
      f.puts "- **URL**: `/api/v1/auth/authenticate`"
      f.puts "- **Method**: `POST`"
      f.puts "- **Headers**:"
      f.puts "  - `X-Api-Key`: Your service API key"
      f.puts "  - `Content-Type`: `application/json`"
      f.puts "- **Body**:"
      f.puts "  ```json"
      f.puts "  {"
      f.puts "    \"credentials\": \"<base64-encoded-encrypted-credentials>\""
      f.puts "  }"
      f.puts "  ```"
      f.puts "- **Credentials format (before hashing)**:"
      f.puts "  ```json"
      f.puts "  {"
      f.puts "    \"email\": \"john.doe@example.com\","
      f.puts "    \"password\": \"SecurePassword123\""
      f.puts "  }"
      f.puts "  ```"
      f.puts
      f.puts "### 3. Get User"
      f.puts "- **URL**: `/api/v1/users/:pd_id`"
      f.puts "- **Method**: `GET`"
      f.puts "- **Headers**:"
      f.puts "  - `X-Api-Key`: Your service API key"
      f.puts
      f.puts "## Implementation Examples"
      f.puts
      f.puts "### Ruby"
      f.puts "```ruby"
      f.puts "require 'net/http'"
      f.puts "require 'openssl'"
      f.puts "require 'base64'"
      f.puts "require 'json'"
      f.puts
      f.puts "class AuthClient"
      f.puts "  def initialize(api_key, hash_key, base_url = 'https://auth.phish.directory')"
      f.puts "    @api_key = api_key"
      f.puts "    @hash_key = hash_key"
      f.puts "    @base_url = base_url"
      f.puts "  end"
      f.puts "  "
      f.puts "  def create_user(user_data)"
      f.puts "    hashed_data = hash_data(user_data)"
      f.puts "    "
      f.puts "    uri = URI(\"#{@base_url}/api/v1/users\")"
      f.puts "    http = Net::HTTP.new(uri.host, uri.port)"
      f.puts "    http.use_ssl = uri.scheme == 'https'"
      f.puts "    "
      f.puts "    request = Net::HTTP::Post.new(uri.path)"
      f.puts "    request['Content-Type'] = 'application/json'"
      f.puts "    request['X-Api-Key'] = @api_key"
      f.puts "    request.body = { hashed_data: hashed_data }.to_json"
      f.puts "    "
      f.puts "    response = http.request(request)"
      f.puts "    JSON.parse(response.body)"
      f.puts "  end"
      f.puts "  "
      f.puts "  private"
      f.puts "  "
      f.puts "  def hash_data(data)"
      f.puts "    json_data = data.to_json"
      f.puts "    "
      f.puts "    cipher = OpenSSL::Cipher::AES.new(256, :CBC)"
      f.puts "    cipher.encrypt"
      f.puts "    "
      f.puts "    key = Digest::SHA256.digest(@hash_key)[0...32]"
      f.puts "    iv = @hash_key[0...16].ljust(16, '0')"
      f.puts "    "
      f.puts "    cipher.key = key"
      f.puts "    cipher.iv = iv"
      f.puts "    "
      f.puts "    encrypted = cipher.update(json_data) + cipher.final"
      f.puts "    "
      f.puts "    Base64.strict_encode64(encrypted)"
      f.puts "  end"
      f.puts "end"
      f.puts "```"
      f.puts
      f.puts "### JavaScript"
      f.puts "```javascript"
      f.puts "class AuthClient {"
      f.puts "  constructor(apiKey, hashKey, baseUrl = 'https://auth.phish.directory') {"
      f.puts "    this.apiKey = apiKey;"
      f.puts "    this.hashKey = hashKey;"
      f.puts "    this.baseUrl = baseUrl;"
      f.puts "  }"
      f.puts "  "
      f.puts "  async _getCryptoKey() {"
      f.puts "    const encoder = new TextEncoder();"
      f.puts "    const keyData = encoder.encode(this.hashKey);"
      f.puts "    "
      f.puts "    const importedKey = await window.crypto.subtle.importKey("
      f.puts "      'raw',"
      f.puts "      keyData,"
      f.puts "      { name: 'PBKDF2' },"
      f.puts "      false,"
      f.puts "      ['deriveBits', 'deriveKey']"
      f.puts "    );"
      f.puts "    "
      f.puts "    return window.crypto.subtle.deriveKey("
      f.puts "      {"
      f.puts "        name: 'PBKDF2',"
      f.puts "        salt: encoder.encode(this.hashKey.substring(0, 16)),"
      f.puts "        iterations: 100000,"
      f.puts "        hash: 'SHA-256'"
      f.puts "      },"
      f.puts "      importedKey,"
      f.puts "      { name: 'AES-CBC', length: 256 },"
      f.puts "      false,"
      f.puts "      ['encrypt']"
      f.puts "    );"
      f.puts "  }"
      f.puts "  "
      f.puts "  async hashData(data) {"
      f.puts "    const encoder = new TextEncoder();"
      f.puts "    const jsonData = JSON.stringify(data);"
      f.puts "    const dataBuffer = encoder.encode(jsonData);"
      f.puts "    "
      f.puts "    const key = await this._getCryptoKey();"
      f.puts "    const iv = encoder.encode(this.hashKey.substring(0, 16).padEnd(16, '0'));"
      f.puts "    "
      f.puts "    const encryptedBuffer = await window.crypto.subtle.encrypt("
      f.puts "      { name: 'AES-CBC', iv },"
      f.puts "      key,"
      f.puts "      dataBuffer"
      f.puts "    );"
      f.puts "    "
      f.puts "    return btoa(String.fromCharCode(...new Uint8Array(encryptedBuffer)));"
      f.puts "  }"
      f.puts "  "
      f.puts "  async createUser(userData) {"
      f.puts "    const hashedData = await this.hashData(userData);"
      f.puts "    "
      f.puts "    const response = await fetch(`${this.baseUrl}/api/v1/users`, {"
      f.puts "      method: 'POST',"
      f.puts "      headers: {"
      f.puts "        'Content-Type': 'application/json',"
      f.puts "        'X-Api-Key': this.apiKey"
      f.puts "      },"
      f.puts "      body: JSON.stringify({ hashed_data: hashedData })"
      f.puts "    });"
      f.puts "    "
      f.puts "    return response.json();"
      f.puts "  }"
      f.puts "}"
      f.puts "```"
    end

    puts "Documentation generated at #{docs_dir.join('service_integration.md')}"

    # Generate example for a service if one exists
    if (service = Service.first) && (key = service.current_key)
      puts "\nExample for service '#{service.name}':"
      puts "API Key: #{key.api_key}"
      puts "Hash Key: #{key.hash_key}"

      # Create an example curl command
      user_data = {
        first_name: 'Test',
        last_name: 'User',
        email: "test_#{Time.now.to_i}@example.com",
        password: 'Password123!',
        password_confirmation: 'Password123!'
      }

      # Create a temporary object to use for hashing
      temp_hasher = Object.new
      def temp_hasher.hash_data(data, hash_key)
        json_data = data.to_json

        cipher = OpenSSL::Cipher::AES.new(256, :CBC)
        cipher.encrypt

        key = Digest::SHA256.digest(hash_key)[0...32]
        iv = hash_key[0...16].ljust(16, '0')

        cipher.key = key
        cipher.iv = iv

        encrypted = cipher.update(json_data) + cipher.final

        Base64.strict_encode64(encrypted)
      end

      hashed_data = temp_hasher.hash_data(user_data, key.hash_key)

      puts "\nExample curl command:"
      puts "curl -X POST \\"
      puts "  -H 'Content-Type: application/json' \\"
      puts "  -H 'X-Api-Key: #{key.api_key}' \\"
      puts "  -d '{\"hashed_data\":\"#{hashed_data}\"}' \\"
      puts "  http://localhost:3000/api/v1/users"
    else
      puts "No service found for example. Create a service with: Service.create_with_key('test_service')"
    end
  end
end
