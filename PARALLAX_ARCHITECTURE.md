# Parallax Complete Architecture Reference

## System Overview

Parallax has **3 different server types**:

1. **Scheduler (Port 3001)** - Main coordinator (`backend/main.py`)
2. **Node Worker (Port 3000)** - Model inference engine (`parallax/server/http_server.py`)
3. **Standalone Chat (Port 3002)** - Independent chat interface (`parallax/server/node_chat_http_server.py`)

---

## 1. Scheduler Server (Port 3001)

**Started by**: `parallax run`

### Endpoints

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/v1/chat/completions` | POST | OpenAI-compatible chat API |
| `/cluster/status` | GET | Real-time cluster monitoring (SSE stream) |
| `/model/list` | GET | Get available models |
| `/scheduler/init` | POST | Initialize cluster with model |
| `/node/join/command` | GET | Get command for nodes to join |
| `/` | GET | Web UI (setup + chat interface) |

### Key Features

- Request routing across nodes
- Load balancing with retry logic (20 attempts, 5s delay)
- Pipeline capacity management
- P2P node discovery via Lattica
- Performance metrics (TPS, TTFT)

---

## 2. Node Worker Server (Port 3000)

**Started by**: `parallax join`

### Endpoints

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/v1/chat/completions` | POST | Process inference requests |

### Architecture

- **IPC Communication**: Uses ZeroMQ for inter-process communication
- **Process Model**: HTTP server + Executor in separate processes
- **Tokenization**: Streaming detokenization for real-time responses
- **Request Lifecycle**:
  1. Receive HTTP request
  2. Forward to executor via ZMQ PUSH
  3. Executor processes (model inference)
  4. Results sent back via ZMQ PULL
  5. Stream or batch response to client

### Streaming Implementation

- Server-Sent Events (SSE)
- Token-by-token delivery
- Client disconnect handling with abort
- Queue-based buffering

### Error Handling

- Request-specific error tracking
- Graceful client disconnect detection
- Abort mechanism for cancelled requests
- Error status codes (400, 500, 503)

---

## 3. Standalone Chat Server (Port 3002)

**Started by**: `parallax chat`

### Endpoints

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/v1/chat/completions` | POST | Proxy to scheduler |
| `/cluster/status` | GET | Proxy cluster status |
| `/` | GET | Chat web UI |

### Purpose

- Provides chat interface without running full node
- Proxies requests to scheduler via P2P
- Useful for accessing cluster from non-node machines

---

## Communication Architecture

### Scheduler ↔ Nodes (P2P via Lattica)

```
┌─────────────┐     P2P/RPC      ┌─────────────┐
│  Scheduler  │◄────────────────►│ Node Worker │
│  Port 3001  │   (Lattica)      │  Port 3000  │
└─────────────┘                  └─────────────┘
```

- Uses Lattica library (libp2p-based)
- DHT for peer discovery
- NAT traversal support
- Relay servers for public networks

### Node Internal (IPC via ZeroMQ)

```
┌──────────────┐    ZMQ PUSH     ┌──────────────┐
│ HTTP Server  │───────────────►│  Executor    │
│              │◄───────────────│  (Model)     │
└──────────────┘    ZMQ PULL     └──────────────┘
```

- PUSH/PULL sockets for async communication
- Request queuing
- Abort signaling

---

## Advanced Features Discovered

### 1. Streaming Responses (SSE)

**Format**:

```
data: {"id":"uuid","object":"chat.completion.chunk","choices":[{"delta":{"content":"hello"}}]}

data: {"id":"uuid","object":"chat.completion.chunk","choices":[{"delta":{"content":" world"}}]}

data: [DONE]
```

**Features**:

- Token-by-token delivery
- First chunk includes role
- Last chunk includes finish_reason
- Usage stats in every chunk

### 2. Performance Metrics

Tracked per request:

- **TPS**: Tokens per second
- **TTFT**: Time to first token (ms)
- **Token counts**: Prompt + completion
- **Request duration**: End-to-end timing

### 3. Request Management

- Unique request IDs (UUID)
- Request state tracking
- Client disconnect detection
- Abort mechanism for cancelled requests
- Retry logic for busy pipelines

### 4. Model Support

Special handling for:

- MiniMax-M2 (thinking tokens)
- Qwen family (reasoning/thinking)
- GPT-OSS (analysis format)

### 5. Error Handling

**Status Codes**:

- 200: Success
- 400: Bad request
- 429: Too many requests (pipelines full)
- 500: Internal server error
- 503: Service unavailable

**Error Response Format**:

```json
{
  "object": "error",
  "message": "Error description",
  "type": "ErrorType",
  "code": 500
}
```

---

## server.py Integration Opportunities

### 1. Add Streaming Support ⭐

```python
@app.post("/chat/stream")
async def chat_stream(request: ChatRequest):
    payload = {
        "model": "default",
        "messages": [{"role": "user", "content": request.prompt}],
        "stream": True  # Enable streaming
    }
    
    async def stream_to_client():
        async with httpx.AsyncClient() as client:
            async with client.stream(
                "POST",
                PARALLAX_SERVICE_URL,
                json=payload,
                timeout=httpx.Timeout(60.0, connect=5.0)
            ) as response:
                async for line in response.aiter_lines():
                    if line.startswith("data: "):
                        yield f"{line}\n\n"
    
    return StreamingResponse(
        stream_to_client(),
        media_type="text/event-stream"
    )
```

### 2. Add Cluster Status Endpoint

```python
@app.get("/cluster/status", dependencies=[Depends(check_password)])
async def cluster_status():
    async with httpx.AsyncClient() as client:
        response = await client.get(
            "http://localhost:3001/cluster/status",
            timeout=10.0
        )
        # Parse and simplify for mobile
        data = response.json()
        return {
            "status": data["data"]["status"],
            "nodes": len(data["data"]["node_list"]),
            "model": data["data"]["model_name"]
        }
```

### 3. Add Performance Metrics

```python
# Extract from Parallax response and include in server response
{
  "response": "...",
  "metrics": {
    "prompt_tokens": 10,
    "completion_tokens": 50,
    "total_tokens": 60
  }
}
```

---

## Mobile App Enhancement Ideas

### 1. Streaming Chat UI

```dart  
Stream<String> sendMessageStream(String prompt) async* {
  final response = await dio.post(
    '$baseUrl/chat/stream',
    data: {'prompt': prompt},
    options: Options(
      responseType: ResponseType.stream,
      headers: _buildPasswordHeader(),
    ),
  );
  
  await for (final chunk in response.data.stream) {
    // Parse SSE format
    // Yield content tokens
  }
}
```

### 2. Cluster Health Widget

```dart
class ClusterStatusWidget extends StatelessWidget {
  Widget build(BuildContext context) {
    return FutureBuilder<ClusterStatus>(
      future: getClusterStatus(),
      builder: (context, snapshot) {
        return Card(
          child: Column(
            children: [
              Text('Status: ${snapshot.data?.status}'),
              Text('Nodes: ${snapshot.data?.nodes}'),
              Text('Model: ${snapshot.data?.model}'),
            ],
          ),
        );
      },
    );
  }
}
```

### 3. Performance Display

```dart
class MessageBubble extends StatelessWidget {
  final Message message;
  
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(message.content),
        if (message.metrics != null)
          Text(
            '${message.metrics.tokens} tokens • '
            '${message.metrics.durationMs}ms',
            style: TextStyle(fontSize: 10, color: Colors.grey),
          ),
      ],
    );
  }
}
```

---

## Testing Commands

### Scheduler

```powershell
# Streaming chat
curl http://localhost:3001/v1/chat/completions -H "Content-Type: application/json" -d "{\"messages\":[{\"role\":\"user\",\"content\":\"test\"}],\"stream\":true}"

# Cluster status
curl http://localhost:3001/cluster/status

# Models
curl http://localhost:3001/model/list
```

### Node Worker

```powershell
# Direct node request
curl http://localhost:3000/v1/chat/completions -H "Content-Type: application/json" -d "{\"rid\":\"test-123\",\"messages\":[{\"role\":\"user\",\"content\":\"hello\"}],\"stream\":false}"
```

### Standalone Chat

```powershell
# Via chat proxy
curl http://localhost:3002/v1/chat/completions -H "Content-Type: application/json" -d "{\"messages\":[{\"role\":\"user\",\"content\":\"test\"}]}"
```

---

## Summary: What We Can Use

✅ **Already Using**:

- Port 3001 scheduler
- `/v1/chat/completions` endpoint
- Non-streaming mode
- OpenAI-compatible format

🎯 **Can Add**:

- Streaming responses (real-time typing)
- Cluster status monitoring
- Performance metrics display
- Token usage tracking
- Better error messages

🔮 **Future Possibilities**:

- Model selection in app
- Multi-modal (vision) support
- Advanced sampling parameters
- Request priority/queuing

---

## Key Insights

1. **Parallax is production-grade** with sophisticated error handling, retry logic, and monitoring
2. **Three server modes** for different use cases (scheduler, worker, standalone chat)
3. **Streaming fully supported** via SSE - can add real-time responses
4. **Performance metrics available** - can show users token counts and speed
5. **Cluster management** - can display GPU info and node status
6. **P2P architecture** enables distributed inference across devices
