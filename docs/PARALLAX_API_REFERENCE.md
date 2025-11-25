# Parallax API Capabilities Reference

## Scheduler API Endpoints (Port 3001)

### 1. `/v1/chat/completions` (POST)

**Purpose**: OpenAI-compatible chat completions API

**Request Format**:

```json
{
  "model": "model-name",
  "messages": [
    {"role": "user", "content": "your message"}
  ],
  "stream": true/false,
  "max_tokens": 1024,
  "sampling_params": {
    "top_k": 3
  }
}
```

**Response (Non-Stream)**:

```json
{
  "id": "uuid",
  "object": "chat.completion",
  "created": timestamp,
  "model": "model-name",
  "choices": [{
    "index": 0,
    "message": {
      "role": "assistant",
      "content": "AI response"
    },
    "finish_reason": "stop"
  }],
  "usage": {
    "prompt_tokens": 10,
    "completion_tokens": 20,
    "total_tokens": 30
  }
}
```

**Response (Stream Mode)**:

- `Content-Type: text/event-stream`
- Server-Sent Events (SSE) format
- Chunks sent as `data: {json}` lines
- Ends with `data: [DONE]`

**Features**:

- Supports both streaming and non-streaming
- Automatic request routing across cluster nodes
- Retry logic for busy pipelines (up to 20 attempts, 5s delay)
- Returns 429 if all pipelines are full
- Returns 503 if routing not ready

---

### 2. `/cluster/status` (GET)

**Purpose**: Real-time cluster status monitoring

**Response Format**:

```json
{
  "type": "cluster_status",
  "data": {
    "status": "available" | "waiting",
    "model_name": "Qwen/Qwen3-0.6B",
    "init_nodes_num": 2,
    "node_join_command": "parallax join -s PEER_ID",
    "node_list": [
      {
        "node_id": "node-123",
        "status": "available" | "waiting",
        "gpu_num": 1,
        "gpu_name": "NVIDIA RTX 3090",
        "gpu_memory": 24
      }
    ],
    "need_more_nodes": true/false
  }
}
```

**Special Features**:

- Streaming endpoint (Server-Sent Events)
- Updates every 1 second
- `Content-Type: application/x-ndjson`
- Each line is a complete JSON object

**Use Cases**:

- Monitor cluster health
- Check if more nodes needed
- See connected GPUs
- Track model loading status

---

### 3. `/model/list` (GET)

**Purpose**: Get available models

**Response**:

```json
{
  "type": "model_list",
  "data": [
    {
      "name": "Qwen/Qwen3-0.6B",
      "size": "0.6B",
      "provider": "Qwen"
    }
  ]
}
```

---

### 4. `/scheduler/init` (POST)

**Purpose**: Initialize cluster with model

**Request**:

```json
{
  "model_name": "Qwen/Qwen3-0.6B",
  "init_nodes_num": 2,
  "is_local_network": true
}
```

**Response**:

```json
{
  "type": "scheduler_init",
  "data": null
}
```

---

### 5. `/node/join/command` (GET)

**Purpose**: Get command for nodes to join cluster

**Response**:

```json
{
  "type": "node_join_command",
  "data": "parallax join -s 12D3KooW..."
}
```

---

### 6. `/` (GET)

**Purpose**: Serve web UI

**Returns**: Frontend HTML application

---

## Advanced Features Discovered

### 1. Request Routing Intelligence

- Automatic load balancing across nodes
- Pipeline capacity management
- Retry logic with exponential backoff
- Request queue management

### 2. Performance Metrics

- **TPS** (Tokens Per Second)
- **TTFT** (Time To First Token)
- Input/output token counts
- Request duration tracking

### 3. P2P Communication

- Uses Lattica library for node discovery
- NAT traversal support
- Relay server support for public networks
- DHT-based peer discovery

### 4. Cluster Management

- Dynamic node joining
- GPU detection and allocation
- Layer-wise model sharding
- Pipeline parallelism

---

## Integration Opportunities for Mobile App

### 1. Cluster Status Monitoring

Add to mobile app:

```dart
// Stream cluster status
Stream<ClusterStatus> watchClusterStatus() async* {
  final response = await dio.get('$baseUrl/cluster/status');
  // Parse SSE stream
}
```

### 2. Model Selection

```dart
// Get available models
Future<List<Model>> getAvailableModels() async {
  final response = await dio.get('$baseUrl/model/list');
  return parseModels(response.data['data']);
}
```

### 3. Streaming Chat

Currently using non-stream. Can add:

```dart
Stream<String> sendMessageStream(String prompt) async* {
  // Use SSE to get chunks in real-time
  // Show typing effect in UI
}
```

### 4. Performance Display

Show in UI:

- Tokens per second
- Time to first token
- Token counts
- Response time

---

## server.py Enhancement Opportunities

### 1. Add Streaming Support

```python
@app.post("/chat/stream")
async def chat_stream(request: ChatRequest):
    # Forward with stream=true
    # Return SSE stream to mobile
```

### 2. Add Cluster Info Endpoint

```python
@app.get("/cluster/info")
async def cluster_info():
    # Proxy /cluster/status from Parallax
    # Return simplified info for mobile
```

### 3. Add Model Selection

```python
@app.get("/models")
async def list_models():
    # Proxy /model/list from Parallax
```

### 4. Add Performance Metrics

```python
# Include TPS, TTFT in response metadata
{
  "response": "...",
  "metrics": {
    "tps": 45.2,
    "ttft_ms": 250,
    "tokens": 150
  }
}
```

---

## Testing Commands

```powershell
# Test streaming chat
curl http://localhost:3001/v1/chat/completions -H "Content-Type: application/json" -d "{\"messages\":[{\"role\":\"user\",\"content\":\"test\"}],\"stream\":true}"

# Monitor cluster status
curl http://localhost:3001/cluster/status

# Get available models
curl http://localhost:3001/model/list

# Get node join command
curl http://localhost:3001/node/join/command
```

---

## Status Codes

- **200**: Success
- **429**: Too many requests (all pipelines busy)
- **500**: Internal server error
- **503**: Service unavailable (routing not ready)

---

## Key Insights

1. **Parallax is production-ready** with sophisticated routing, retry logic, and error handling
2. **Streaming is fully supported** - can add real-time responses to mobile app
3. **Cluster monitoring** available for showing system health in app
4. **Performance metrics** can be displayed to users
5. **Model switching** possible at runtime
