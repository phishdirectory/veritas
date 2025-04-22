# Service Integration with Auth.P.D

## Authentication

Each service has two keys:
- **API Key**: Used for authenticating the service with Auth.P.D
- **Hash Key**: Used for encrypting sensitive data before transmission

Both keys must be kept secure and should never be exposed to clients or in client-side code.

## API Endpoints

### 1. Create User
- **URL**: `/api/v1/users`
- **Method**: `POST`
- **Headers**:
  - `X-Api-Key`: Your service API key
  - `Content-Type`: `application/json`
- **Body**:
  ```json
  {
    "hashed_data": "<base64-encoded-encrypted-user-data>"
  }
  ```
- **User data format (before hashing)**:
  ```json
  {
    "first_name": "John",
    "last_name": "Doe",
    "email": "john.doe@example.com",
    "password": "SecurePassword123",
    "password_confirmation": "SecurePassword123"
  }
  ```

### 2. Authenticate User
- **URL**: `/api/v1/auth/authenticate`
- **Method**: `POST`
- **Headers**:
  - `X-Api-Key`: Your service API key
  - `Content-Type`: `application/json`
- **Body**:
  ```json
  {
    "credentials": "<base64-encoded-encrypted-credentials>"
  }
  ```
- **Credentials format (before hashing)**:
  ```json
  {
    "email": "john.doe@example.com",
    "password": "SecurePassword123"
  }
  ```

### 3. Get User
- **URL**: `/api/v1/users/:pd_id`
- **Method**: `GET`
- **Headers**:
  - `X-Api-Key`: Your service API key

## Implementation Examples

### Ruby
```ruby
require 'net/http'
require 'openssl'
require 'base64'
require 'json'

class AuthClient
  def initialize(api_key, hash_key, base_url = 'https://auth.phish.directory')
    @api_key = api_key
    @hash_key = hash_key
    @base_url = base_url
  end
  
  def create_user(user_data)
    hashed_data = hash_data(user_data)
    
    uri = URI("/api/v1/users")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = uri.scheme == 'https'
    
    request = Net::HTTP::Post.new(uri.path)
    request['Content-Type'] = 'application/json'
    request['X-Api-Key'] = @api_key
    request.body = { hashed_data: hashed_data }.to_json
    
    response = http.request(request)
    JSON.parse(response.body)
  end
  
  private
  
  def hash_data(data)
    json_data = data.to_json
    
    cipher = OpenSSL::Cipher::AES.new(256, :CBC)
    cipher.encrypt
    
    key = Digest::SHA256.digest(@hash_key)[0...32]
    iv = @hash_key[0...16].ljust(16, '0')
    
    cipher.key = key
    cipher.iv = iv
    
    encrypted = cipher.update(json_data) + cipher.final
    
    Base64.strict_encode64(encrypted)
  end
end
```

### JavaScript
```javascript
class AuthClient {
  constructor(apiKey, hashKey, baseUrl = 'https://auth.phish.directory') {
    this.apiKey = apiKey;
    this.hashKey = hashKey;
    this.baseUrl = baseUrl;
  }
  
  async _getCryptoKey() {
    const encoder = new TextEncoder();
    const keyData = encoder.encode(this.hashKey);
    
    const importedKey = await window.crypto.subtle.importKey(
      'raw',
      keyData,
      { name: 'PBKDF2' },
      false,
      ['deriveBits', 'deriveKey']
    );
    
    return window.crypto.subtle.deriveKey(
      {
        name: 'PBKDF2',
        salt: encoder.encode(this.hashKey.substring(0, 16)),
        iterations: 100000,
        hash: 'SHA-256'
      },
      importedKey,
      { name: 'AES-CBC', length: 256 },
      false,
      ['encrypt']
    );
  }
  
  async hashData(data) {
    const encoder = new TextEncoder();
    const jsonData = JSON.stringify(data);
    const dataBuffer = encoder.encode(jsonData);
    
    const key = await this._getCryptoKey();
    const iv = encoder.encode(this.hashKey.substring(0, 16).padEnd(16, '0'));
    
    const encryptedBuffer = await window.crypto.subtle.encrypt(
      { name: 'AES-CBC', iv },
      key,
      dataBuffer
    );
    
    return btoa(String.fromCharCode(...new Uint8Array(encryptedBuffer)));
  }
  
  async createUser(userData) {
    const hashedData = await this.hashData(userData);
    
    const response = await fetch(`${this.baseUrl}/api/v1/users`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-Api-Key': this.apiKey
      },
      body: JSON.stringify({ hashed_data: hashedData })
    });
    
    return response.json();
  }
}
```
