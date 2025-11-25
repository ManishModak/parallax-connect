# Parallax Advanced Features & Configuration Reference

## Command Line Interface (CLI)

### Commands Available

#### 1. `parallax run` - Start Scheduler

```powershell
# With frontend (setup UI + chat)
parallax run

# Without frontend (headless)
parallax run -m Qwen/Qwen3-0.6B -n 2

# With custom port
parallax run --port 3001

# With relay servers (for public/remote mode)
parallax run -r

# Skip version reporting
parallax run -u
```

**Default Port**: 3001

#### 2. `parallax join` - Join as Worker Node

```powershell
# Auto-discover on local network
parallax join

# Join specific scheduler
parall join -s 12D3KooWLX7MWuzi1Txa5LyZS4eTQ2tPaJijheH8faHggB9SxnBu

# With relay (remote mode)
parallax join -s PEER_ID -r

# Skip version reporting
parallax join -u
```

**Default Configurations**:

- `max-num-tokens-per-batch`: 4096
- `max-sequence-length`: 2048
- `max-batch-size`: 8
- `kv-block-size`: 1024

#### 3. `parallax chat` - Standalone Chat Client

```powershell
# Auto-discover scheduler
parallax chat

# Connect to specific scheduler
parallax chat -s 12D3KooW...

# With relay
parallax chat -r
```

---

## Public Infrastructure

### Relay Servers (Gradient Network)

Used for NAT traversal and remote mode connections:

```
relay-lattica.gradient.network (US)
relay-lattica-us.gradient.network
relay-lattica-eu.gradient.network (EU)
```

### Bootstrap Peers (DHT)

For peer discovery:

```
bootstrap-lattica.gradient.network
bootstrap-lattica-us.gradient.network
bootstrap-lattica-eu.gradient.network
```

---

## Sampling Parameters (Advanced AI Control)

### Available Parameters

```json
{
  "messages": [...],
  "max_tokens": 128,        // Max new tokens to generate
  "temperature": 1.0,       // Randomness (0.0-2.0)
  "top_p": 1.0,            // Nucleus sampling (0.0-1.0)
  "top_k": -1,             // Top-k sampling (-1 = off)
  "min_p": 0.0,            // Minimum probability (0.0-1.0)
  "repetition_penalty": 1.0,  // Penalize repetition (0.0-2.0)
  "presence_penalty": 0.0,    // Encourage diversity (-2.0 to 2.0)
  "frequency_penalty": 0.0,   // Penalize frequent tokens (-2.0 to 2.0)
  "stop": ["###", "\n\n"],   // Stop sequences
  "ignore_eos": false,        // Ignore EOS token
  "json_schema": "{...}"      // Force JSON output format
}
```

### Parameter Details

**temperature** (0.0 - 2.0)

- 0.0: Deterministic (greedy)
- 0.7: Balanced
- 1.0: Default
- 1.5+: Very creative/random

**top_p** (0.0 - 1.0)

- Nucleus sampling
- 0.9: Common setting
- 1.0: No filtering

**top_k** (integer)

- Sample from top-k tokens
- -1: Disabled
- 50: Common setting

**repetition_penalty** (0.0 - 2.0)

- 1.0: No penalty
- 1.1-1.2: Recommended
- \u003e1.5: Strong penalty

**presence_penalty** (-2.0 to 2.0)

- Positive: Encourage new topics
- Negative: Stay on topic
- 0.0: Neutral

**frequency_penalty** (-2.0 to 2.0)

- Positive: Reduce repetitive words
- Negative: Allow repetition
- 0.0: Neutral

---

## Request Lifecycle & States

### Request Status Flow

```
PREFILLING → DECODING → FINISHED_EOS / FINISHED_MAX_LENGTH
                    ↓
                  ERROR / CANCELLED
```

**States**:

- `PREFILLING`: Processing initial prompt
- `DECODING`: Generating tokens
- `FINISHED_EOS`: Completed (hit EOS token)
- `FINISHED_MAX_LENGTH`: Hit max token limit
- `ERROR`: Request failed
- `CANCELLED`: User cancelled

### Request Types

**InitialRequest** (First Node)

- Full request state
- Has prompt, input_ids, output_ids
- Manages tokenization/detokenization
- Tracks sampling parameters

**IntermediateRequest** (Pipeline Nodes)

- Lightweight data packet
- Contains request_id, hidden_states
- Passed between nodes
- No tokenizer needed

---

## Performance Metrics

### Tracked Metrics

```python
{
  "current_requests": 0,      // Active requests
  "layer_latency_ms": 25.5,   // Per-layer latency (EWMA)
  "_last_update_ts": 1700000000.0
}
```

**Metrics Publisher**:

- Thread-safe updates
- EWMA smoothing (alpha=0.2)
- Optional callback for pushing to backend

---

## Configuration Parameters

### Memory Management

```
--param-mem-ratio 0.65      # GPU memory for parameters
--kvcache-mem-ratio 0.25    # GPU memory for KV cache
--kv-cache-memory-fraction 0.8
--kv-block-size 64          # Block size for KV cache
```

### Batch Processing

```
--max-batch-size 8
--max-num-tokens-per-batch 1024
--max-sequence-length 2048
--micro-batch-ratio 2
```

### Layer Sharding

```
--start-layer 0             # Starting layer (inclusive)
--end-layer 14              # Ending layer (exclusive)
```

### GPU Backend

```
--gpu-backend sglang        # or vllm
--attention-backend flashinfer  # torch_native, triton, fa3
--moe-runner-backend auto   # For MoE models
--tp-size 1                 # Tensor parallel size
```

### Timeouts & Scheduling

```
--request-timeout-s 600     # Per-request timeout
--scheduler-wait-ms 500     # Scheduler polling interval
--prefill-priority 0        # Priority (0 or 1)
```

### Debugging

```
--log-level INFO            # DEBUG, INFO, WARNING, ERROR
--verbose                   # Enable verbose logging
```

---

## Mobile App Integration Ideas

### 1. Advanced Settings Screen

```dart
class AISettings {
  double temperature = 0.7;
  double topP = 0.9;
  int topK = 50;
  double repetitionPenalty = 1.1;
  int maxTokens = 512;
  List<String> stopSequences = [];
}
```

### 2. Request with Custom Parameters

```dart
Future<String> sendMessageWithSettings(String prompt, AISettings settings) {
  final payload = {
    'messages': [{'role': 'user', 'content': prompt}],
    'max_tokens': settings.maxTokens,
    'temperature': settings.temperature,
    'top_p': settings.topP,
    'top_k': settings.topK,
    'repetition_penalty': settings.repetitionPenalty,
    'stop': settings.stopSequences,
  };
  
  return dio.post('$baseUrl/chat', data: payload);
}
```

### 3. Presets System

```dart
final presets = {
  'creative': AISettings(
    temperature: 1.5,
    topP: 0.95,
    topK: 100,
  ),
  'balanced': AISettings(
    temperature: 0.7,
    topP: 0.9,
    topK: 50,
  ),
  'precise': AISettings(
    temperature: 0.3,
    topP: 0.5,
    topK: 10,
  ),
};
```

### 4. JSON Mode for Structured Output

```dart
Future<Map<String, dynamic>> getStructuredResponse(String prompt) {
  final schema = {
    'type': 'object',
    'properties': {
      'answer': {'type': 'string'},
      'confidence': {'type': 'number'}
    }
  };
  
  final payload = {
    'messages': [{'role': 'user', 'content': prompt}],
    'json_schema': jsonEncode(schema),
  };
  
  return dio.post('$baseUrl/chat', data: payload);
}
```

---

## server.py Enhancements

### Add Sampling Parameters Support

```python
class ChatRequest(BaseModel):
    prompt: str
    max_tokens: int = 128
    temperature: float = 0.7
    top_p: float = 0.9
    top_k: int = -1
    repetition_penalty: float = 1.0
    stop: List[str] = []

@app.post("/chat")
async def chat_endpoint(request: ChatRequest):
    payload = {
        "model": "default",
        "messages": [{"role": "user", "content": request.prompt}],
        "max_tokens": request.max_tokens,
        "temperature": request.temperature,
        "top_p": request.top_p,
        "top_k": request.top_k,
        "repetition_penalty": request.repetition_penalty,
        "stop": request.stop,
        "stream": False,
    }
    
    # Forward to Parallax...
```

---

## Network Modes Explained

### Local Mode

- No relay servers
- Same network discovery
- Faster, no external dependencies

### Remote Mode (`-r` flag)

- Uses Gradient relay servers
- NAT traversal
- Works across different networks
- IP reported to relay for connection setup

### Symmetric NAT Check

- Parallax checks NAT type
- Symmetric NAT incompatible with relay
- Exits with error if detected

---

## Python Version Requirement

**Required**: Python 3.11+, \u003c 3.14

Checked automatically by CLI on startup.

---

## Summary: What You Can Do Now

✅ **Expose in Mobile App**:

1. Temperature slider (0.0-2.0)
2. Top-p/Top-k controls
3. Max tokens setting
4. Repetition penalty
5. Preset modes (Creative/Balanced/Precise)
6. Stop sequences input

✅ **For Windows Setup**:

1. Use `parallax run` (starts on 3001)
2. Add `-r` for remote mode
3. Configure batch size, memory ratios
4. Set log levels for debugging

✅ **Advanced Features**:

1. JSON mode for structured output
2. Custom sampling per message
3. Request cancellation
4. Performance metric tracking
