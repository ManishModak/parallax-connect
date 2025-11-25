# API Communication Flow

Detailed documentation of how messages flow from mobile app through server.py to Parallax.

## Architecture Overview

```
┌─────────────────┐         ┌─────────────────┐         ┌─────────────────┐
│   Mobile App    │         │   server.py     │         │    Parallax     │
│   (Flutter)    │◄───────►│   (FastAPI)     │◄───────►│   (Scheduler)   │
│                 │         │                 │         │                 │
│  Port: N/A      │         │  Port: 8000     │         │  Port: 3001     │
└─────────────────┘         └─────────────────┘         └─────────────────┘
     HTTP(S)                      HTTP                       HTTP
```

## Communication Endpoints

### Mobile App → server.py

**Base URL**: Configured by user in app (local or ngrok)

- Local: `http://192.168.1.X:8000`
- Cloud: `https://xxxx.ngrok-free.app`

**Endpoints Used:**

1. `GET /healthz` - Health check (no auth)
2. `GET /` - Server info (requires password)
3. `GET /status` - Detailed status including Parallax connectivity
4. `POST /chat` - Send chat message
5. `POST /vision` - Send image for analysis (future)

### server.py → Parallax

**Base URL**: `http://localhost:3001`

**Endpoint Used:**

- `POST /v1/chat/completions` - OpenAI-compatible chat API

## Message Flow: Chat Request

### Step 1: Mobile App → server.py

**Mobile App Code** (`chat_repository.dart`):

```dart
Future<String> generateText(String prompt) async {
  final baseUrl = _configStorage.getBaseUrl(); // User-configured URL
  
  final response = await _dio.post(
    '$baseUrl/chat',
    data: {'prompt': prompt},
    options: Options(headers: _buildPasswordHeader()),
  );
  
  return response.data['response'] as String;
}
```

**HTTP Request:**

```http
POST https://xxxx.ngrok-free.app/chat HTTP/1.1
Content-Type: application/json
x-password: YOUR_PASSWORD (if set)

{
  "prompt": "Hello, can you help me?"
}
```

**server.py Receives:**

```python
@app.post("/chat", dependencies=[Depends(check_password)])
async def chat_endpoint(request: ChatRequest):
    # request.prompt = "Hello, can you help me?"
```

### Step 2: server.py → Parallax

**server.py Code:**

```python
# Construct OpenAI-compatible payload
payload = {
    "model": "default",
    "messages": [{"role": "user", "content": request.prompt}],
    "stream": False,
}

# Forward to Parallax
resp = await client.post(
    PARALLAX_SERVICE_URL,  # http://localhost:3001/v1/chat/completions
    json=payload,
    timeout=60.0
)
```

**HTTP Request:**

```http
POST http://localhost:3001/v1/chat/completions HTTP/1.1
Content-Type: application/json

{
  "model": "default",
  "messages": [
    {
      "role": "user",
      "content": "Hello, can you help me?"
    }
  ],
  "stream": false
}
```

**Parallax Processes:**

- Receives OpenAI-compatible request
- Runs inference on configured model
- Returns OpenAI-compatible response

### Step 3: Parallax → server.py

**HTTP Response from Parallax:**

```http
HTTP/1.1 200 OK
Content-Type: application/json

{
  "id": "chatcmpl-xyz123",
  "object": "chat.completion",
  "created": 1700000000,
  "model": "Qwen/Qwen3-0.6B",
  "choices": [
    {
      "index": 0,
      "message": {
        "role": "assistant",
        "content": "Hello! I'd be happy to help you. What do you need assistance with?"
      },
      "finish_reason": "stop"
    }
  ],
  "usage": {
    "prompt_tokens": 10,
    "completion_tokens": 20,
    "total_tokens": 30
  }
}
```

**server.py Extracts:**

```python
data = resp.json()
content = data["choices"][0]["message"]["content"]
# content = "Hello! I'd be happy to help you..."
```

### Step 4: server.py → Mobile App

**HTTP Response:**

```http
HTTP/1.1 200 OK
Content-Type: application/json

{
  "response": "Hello! I'd be happy to help you. What do you need assistance with?"
}
```

**Mobile App Receives:**

```dart
final response = await _dio.post('$baseUrl/chat', ...);
return response.data['response'] as String;
// Returns the AI response to display in chat
```

## Mock Mode vs Proxy Mode

### Mock Mode (`SERVER_MODE = "MOCK"`)

**Flow:**

```
Mobile App → server.py → Returns dummy data
                         (No Parallax involved)
```

**Use Case:**

- UI development
- Testing without Parallax
- Demo mode

**Response:**

```json
{
  "response": "[MOCK] Server received: 'Hello'. This is a simulated response."
}
```

### Proxy Mode (`SERVER_MODE = "PROXY"`)

**Flow:**

```
Mobile App → server.py → Parallax → server.py → Mobile App
```

**Use Case:**

- Production
- Real AI responses
- Full system testing

**Response:**

- Real AI-generated content from Parallax

## Authentication

### Password Protection

**Setting Password:**

```python
# In server.py
PASSWORD = None  # Set during startup via prompt
```

**Client Header:**

```http
x-password: your_password_here
```

**Validation:**

```python
async def check_password(x_password: Optional[str] = Header(default=None)):
    if PASSWORD and x_password != PASSWORD:
        raise HTTPException(status_code=401, detail="Invalid password")
    return True
```

**Endpoints Protected:**

- `/` (home)
- `/status`
- `/chat`
- `/vision`

**Endpoints Public:**

- `/healthz` (no auth required)

## Error Handling

### Error Scenarios

#### 1. Mobile App Cannot Reach server.py

**Cause:**

- Wrong URL
- server.py not running
- Network issue
- Firewall blocking

**Mobile App Error:**

```dart
catch (e) {
  logger.e('Error generating text', error: e);
  rethrow; // DioError: Connection refused
}
```

**User Sees:**

```
No internet connection. Cloud mode requires an active connection.
```

#### 2. server.py Cannot Reach Parallax

**Cause:**

- Parallax not running
- Wrong port (3001 vs 3002 confusion)
- Parallax crashed

**server.py Logs:**

```
🔌 [ID] Cannot connect to Parallax: [Errno 111] Connection refused
```

**HTTP Response:**

```http
HTTP/1.1 503 Service Unavailable

{
  "detail": "Cannot connect to Parallax. Make sure it's running: parallax run"
}
```

#### 3. Parallax Timeout

**Cause:**

- Model taking too long
- Heavy computation
- Resource constraints

**server.py Logs:**

```
⏱️ [ID] Parallax request timeout: TimeoutException
```

**HTTP Response:**

```http
HTTP/1.1 504 Gateway Timeout

{
  "detail": "Parallax request timed out. The model might be processing a heavy request."
}
```

#### 4. Invalid Password

**server.py Response:**

```http
HTTP/1.1 401 Unauthorized

{
  "detail": "Invalid password"
}
```

**Mobile App:**
Shows error: "Invalid password"

## Request Logging

### server.py Logging

**Log Levels:**

- `INFO`: Normal operations
- `WARNING`: Non-critical issues
- `ERROR`: Failures
- `DEBUG`: Detailed debugging (not shown by default)

**Log Format:**

```
2025-11-25 10:55:30 [INFO] 📝 [20251125105530123456] Received chat request: Hello...
2025-11-25 10:55:30 [INFO] 🔄 [20251125105530123456] Forwarding to Parallax...
2025-11-25 10:55:32 [INFO] ✅ [20251125105530123456] Received response (2.34s)
```

**Request ID:**

- Format: `YYYYMMDDHHMMSSffffff`
- Tracks single request through entire flow
- Helps correlate logs across systems

## Testing Commands

### Test Each Layer

**1. Test Parallax Directly:**

```bash
curl http://localhost:3001/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"messages":[{"role":"user","content":"test"}],"stream":false}'
```

**2. Test server.py:**

```bash
curl -X POST http://localhost:8000/chat \
  -H "Content-Type: application/json" \
  -H "x-password: YOUR_PASSWORD" \
  -d '{"prompt":"test"}'
```

**3. Test Mobile App:**

- Use the actual app interface

### Verify Full Chain

**Send request from mobile app and check:**

1. **Mobile app logs** (if debugging):

   ```
   [dio] --> POST /chat
   [dio] <-- 200
   ```

2. **server.py logs**:

   ```
   📝 [ID] Received chat request
   🔄 [ID] Forwarding to Parallax
   ✅ [ID] Received response
   ```

3. **Parallax logs** (in Parallax terminal):

   ```
   Processing request...
   Generated response
   ```

## Performance Metrics

### Expected Latencies

**Local Network:**

- Mobile → server.py: 10-50ms
- server.py → Parallax: < 5ms
- Parallax processing: 1-30s (model dependent)
- Total: ~1-30s

**Cloud (ngrok):**

- Mobile → server.py: 50-200ms (via ngrok)
- server.py → Parallax: < 5ms
- Parallax processing: 1-30s
- Total: ~1-30s

### Bottlenecks

**Primary:** Parallax model inference (95% of time)
**Secondary:** Network latency (5% for cloud mode)
**Negligible:** server.py processing

## Data Formats Reference

### Mobile App Format

```typescript
// Request
{
  "prompt": string
}

// Response
{
  "response": string
}
```

### OpenAI Format (server.py ↔ Parallax)

```typescript
// Request
{
  "model": string,
  "messages": [
    {
      "role": "user" | "assistant" | "system",
      "content": string
    }
  ],
  "stream": boolean,
  "max_tokens"?: number
}

// Response
{
  "id": string,
  "object": "chat.completion",
  "created": number,
  "model": string,
  "choices": [
    {
      "index": number,
      "message": {
        "role": "assistant",
        "content": string
      },
      "finish_reason": string
    }
  ],
  "usage": {
    "prompt_tokens": number,
    "completion_tokens": number,
    "total_tokens": number
  }
}
```
