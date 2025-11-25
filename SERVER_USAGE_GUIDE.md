# server.py Enhanced Features - Usage Guide

## What Changed

server.py now supports **all Parallax sampling parameters** and returns **usage metadata**. This allows your mobile app to:

1. **Control AI behavior** (creativity, randomness, repetition)
2. **Display statistics** (tokens used, response time, model name)
3. **Create presets** (e.g., "Creative Mode", "Precise Mode")

---

## API Request Format

### Basic Request (Same as Before)

```json
POST /chat
{
  "prompt": "Explain quantum computing"
}
```

### Advanced Request (With Parameters)

```json
POST /chat
{
  "prompt": "Write a creative story about space",
  "temperature": 1.2,
  "max_tokens": 1000,
  "repetition_penalty": 1.1,
  "top_p": 0.95
}
```

---

## All Available Parameters

### Required

- **`prompt`** (string): The user's message

### Optional Parameters

| Parameter | Type | Default | Range | Purpose |
|-----------|------|---------|-------|---------|
| `max_tokens` | int | 512 | 1-4096 | Max response length |
| `temperature` | float | 0.7 | 0.0-2.0 | Creativity/randomness |
| `top_p` | float | 0.9 | 0.0-1.0 | Nucleus sampling |
| `top_k` | int | -1 | -1 or 1-100 | Top-k sampling |
| `repetition_penalty` | float | 1.0 | 0.0-2.0 | Reduce repetition |
| `presence_penalty` | float | 0.0 | -2.0 to 2.0 | Topic diversity |
| `frequency_penalty` | float |0.0 | -2.0 to 2.0 | Word variety |
| `stop` | string[] | [] | - | Stop sequences |

---

## Response Format

### New Response Structure

```json
{
  "response": "The AI's actual response text...",
  "metadata": {
    "usage": {
      "prompt_tokens": 15,
      "completion_tokens": 127,
      "total_tokens": 142
    },
    "timing": {
      "duration_ms": 2340,
      "duration_seconds": 2.34
    },
    "model": "Qwen/Qwen3-0.6B"
  }
}
```

---

## Mobile App Integration Examples

### 1. Basic Dart Model

```dart
class ChatResponse {
  final String response;
  final ResponseMetadata? metadata;
  
  ChatResponse({
    required this.response,
    this.metadata,
  });
  
  factory ChatResponse.fromJson(Map<String, dynamic> json) {
    return ChatResponse(
      response: json['response'],
      metadata: json['metadata'] != null 
        ? ResponseMetadata.fromJson(json['metadata'])
        : null,
    );
  }
}

class ResponseMetadata {
  final TokenUsage usage;
  final ResponseTiming timing;
  final String model;
  
  ResponseMetadata({
    required this.usage,
    required this.timing,
    required this.model,
  });
  
  factory ResponseMetadata.fromJson(Map<String, dynamic> json) {
    return ResponseMetadata(
      usage: TokenUsage.fromJson(json['usage']),
      timing: ResponseTiming.fromJson(json['timing']),
      model: json['model'],
    );
  }
}

class TokenUsage {
  final int promptTokens;
  final int completionTokens;
  final int totalTokens;
  
  TokenUsage({
    required this.promptTokens,
    required this.completionTokens,
    required this.totalTokens,
  });
  
  factory TokenUsage.fromJson(Map<String, dynamic> json) {
    return TokenUsage(
      promptTokens: json['prompt_tokens'],
      completionTokens: json['completion_tokens'],
      totalTokens: json['total_tokens'],
    );
  }
}

class ResponseTiming {
  final int durationMs;
  final double durationSeconds;
  
  ResponseTiming({
    required this.durationMs,
    required this.durationSeconds,
  });
  
  factory ResponseTiming.fromJson(Map<String, dynamic> json) {
    return ResponseTiming(
      durationMs: json['duration_ms'],
      durationSeconds: json['duration_seconds'].toDouble(),
    );
  }
}
```

### 2. Settings Model

```dart
class AISettings {
  final double temperature;
  final double topP;
  final int topK;
  final double repetitionPenalty;
  final double presencePenalty;
  final double frequencyPenalty;
  final int maxTokens;
  final List<String> stopSequences;
  
  const AISettings({
    this.temperature = 0.7,
    this.topP = 0.9,
    this.topK = -1,
    this.repetitionPenalty = 1.0,
    this.presencePenalty = 0.0,
    this.frequencyPenalty = 0.0,
    this.maxTokens = 512,
    this.stopSequences = const [],
  });
  
  Map<String, dynamic> toJson() {
    return {
      'temperature': temperature,
      'top_p': topP,
      'top_k': topK,
      'repetition_penalty': repetitionPenalty,
      'presence_penalty': presencePenalty,
      'frequency_penalty': frequencyPenalty,
      'max_tokens': maxTokens,
      'stop': stopSequences,
    };
  }
}
```

### 3. Presets System

```dart
class AIPresets {
  static const creative = AISettings(
    temperature: 1.2,
    topP: 0.95,
    topK: 100,
    maxTokens: 1000,
    frequencyPenalty: 0.3,
  );
  
  static const balanced = AISettings(
    temperature: 0.7,
    topP: 0.9,
    topK: 50,
    maxTokens: 512,
  );
  
  static const precise = AISettings(
    temperature: 0.3,
    topP: 0.5,
    topK: 10,
    maxTokens: 256,
    repetitionPenalty: 1.15,
  );
  
  static const chatty = AISettings(
    temperature: 0.8,
    maxTokens: 800,
    presencePenalty: 0.6,  // Encourage diverse topics
  );
  
  static const focused = AISettings(
    temperature: 0.4,
    maxTokens: 300,
    presencePenalty: -0.5,  // Stay on topic
    repetitionPenalty: 1.2,
  );
}
```

### 4. API Call with Settings

```dart
Future<ChatResponse> sendMessageWithSettings(
  String prompt,
  AISettings settings,
) async {
  final payload = {
    'prompt': prompt,
    ...settings.toJson(),  // Spread all settings
  };
  
  final response = await dio.post(
    '$baseUrl/chat',
    data: payload,
    options: Options(headers: _buildPasswordHeader()),
  );
  
  return ChatResponse.fromJson(response.data);
}
```

### 5. Display Metadata in UI

```dart
class MessageBubble extends StatelessWidget {
  final Message message;
  
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Message content
        Text(message.content),
        
        // Metadata footer
        if (message.metadata != null)
          Padding(
            padding: EdgeInsets.only(top: 4),
            child: Row(
              children: [
                Icon(Icons.schedule, size: 12, color: Colors.grey),
                SizedBox(width: 4),
                Text(
                  '${message.metadata!.timing.durationSeconds}s',
                  style: TextStyle(fontSize: 10, color: Colors.grey),
                ),
                SizedBox(width: 12),
                Icon(Icons.grain, size: 12, color: Colors.grey),
                SizedBox(width: 4),
                Text(
                  '${message.metadata!.usage.totalTokens} tokens',
                  style: TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
```

### 6. Settings Screen UI

```dart
class AISettingsScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<AISettingsScreen> createState() => _AISettingsScreenState();
}

class _AISettingsScreenState extends ConsumerState<AISettingsScreen> {
  late AISettings _settings;
  
  @override
  void initState() {
    super.initState();
    _settings = ref.read(aiSettingsProvider);  // Load from provider
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('AI Settings')),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          // Preset Buttons
          Text('Quick Presets', style: Theme.of(context).textTheme.titleMedium),
          SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              ElevatedButton(
                onPressed: () => setState(() => _settings = AIPresets.creative),
                child: Text('Creative'),
              ),
              ElevatedButton(
                onPressed: () => setState(() => _settings = AIPresets.balanced),
                child: Text('Balanced'),
              ),
              ElevatedButton(
                onPressed: () => setState(() => _settings = AIPresets.precise),
                child: Text('Precise'),
              ),
            ],
          ),
          
          SizedBox(height: 24),
          Divider(),
          
          // Temperature Slider
          Text('Creativity (Temperature): ${_settings.temperature.toStringAsFixed(1)}'),
          Slider(
            value: _settings.temperature,
            min: 0.0,
            max: 2.0,
            divisions: 20,
            label: _settings.temperature.toStringAsFixed(1),
            onChanged: (value) {
              setState(() {
                _settings = AISettings(
                  temperature: value,
                  topP: _settings.topP,
                  maxTokens: _settings.maxTokens,
                  // ... copy other fields
                );
              });
            },
          ),
          
          // Max Tokens Slider
          Text('Max Response Length: ${_settings.maxTokens} tokens'),
          Slider(
            value: _settings.maxTokens.toDouble(),
            min: 50,
            max: 2048,
            divisions: 39,
            label: _settings.maxTokens.toString(),
            onChanged: (value) {
              setState(() {
                _settings = AISettings(
                  maxTokens: value.toInt(),
                  temperature: _settings.temperature,
                  // ... copy other fields
                );
              });
            },
          ),
          
          // Repetition Penalty
          Text('Repetition Penalty: ${_settings.repetitionPenalty.toStringAsFixed(2)}'),
          Slider(
            value: _settings.repetitionPenalty,
            min: 1.0,
            max: 1.5,
            divisions: 10,
            label: _settings.repetitionPenalty.toStringAsFixed(2),
            onChanged: (value) {
              setState(() {
                _settings = AISettings(
                  repetitionPenalty: value,
                  temperature: _settings.temperature,
                  maxTokens: _settings.maxTokens,
                  // ... copy other fields
                );
              });
            },
          ),
          
          // Save Button
          SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              ref.read(aiSettingsProvider.notifier).updateSettings(_settings);
              Navigator.pop(context);
            },
            child: Text('Save Settings'),
          ),
        ],
      ),
    );
  }
}
```

---

## Testing Examples

### Test with cURL

```powershell
# Basic request
curl -X POST http://localhost:8000/chat -H "Content-Type: application/json" -d "{\"prompt\":\"Hello\"}"

# With temperature
curl -X POST http://localhost:8000/chat -H "Content-Type: application/json" -d "{\"prompt\":\"Write a poem\",\"temperature\":1.5}"

# With all parameters
curl -X POST http://localhost:8000/chat -H "Content-Type: application/json" -d "{\"prompt\":\"Explain AI\",\"temperature\":0.7,\"max_tokens\":200,\"top_p\":0.9,\"repetition_penalty\":1.1}"

# With password
curl -X POST http://localhost:8000/chat -H "Content-Type: application/json" -H "x-password: YOUR_PASSWORD" -d "{\"prompt\":\"Test\"}"
```

---

## Parameter Usage Tips

### For Different Use Cases

**Code Generation**:

```dart
AISettings(
  temperature: 0.2,  // Very focused
  maxTokens: 1024,
  topK: 10,
)
```

**Creative Writing**:

```dart
AISettings(
  temperature: 1.3,  // Very creative
  maxTokens: 2000,
  topP: 0.95,
  presencePenalty: 0.5,  // Diverse topics
)
```

**Factual Q&A**:

```dart
AISettings(
  temperature: 0.3,  // Precise
  maxTokens: 300,
  repetitionPenalty: 1.15,
)
```

**Brainstorming**:

```dart
AISettings(
  temperature: 1.0,
  maxTokens: 800,
  presencePenalty: 0.8,  // New ideas
  frequencyPenalty: 0.5,  // Varied words
)
```

---

## Next Steps

1. **Update `chat_repository.dart`** to accept `AISettings`
2. **Create `AISettings` model** in your app
3. **Add settings screen** with sliders/presets
4. **Update message bubble** to show metadata
5. **Create settings provider** to persist preferences

The server is now ready - all these features work immediately!
