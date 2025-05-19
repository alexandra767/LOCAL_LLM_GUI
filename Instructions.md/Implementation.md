Provide SwiftUI code that implements this design system, focusing specifically on the main layout structure and navigation components first. Include comments explaining key design decisions and how to customize various aspects of the interface.You are an expert AI integration specialist with deep knowledge of LLM implementation in Swift applications. Help me integrate any large language model into my app with an elegant Claude-like interface. I need a complete solution that handles:

1. LLM Connection Architecture:
   - Flexible adapter pattern to connect to any LLM (local or API-based)
   - Support for multiple models: Ollama-based models (on my system)
   - Streaming text capabilities for real-time responses
   - Efficient token handling and context management
   - Proper error handling and recovery mechanisms

2. Core API Integration Components:
   - Modular API client for different LLM providers
   - Authentication and API key management (secure storage)
   - Request/response serialization
   - Rate limiting and quota management
   - Caching mechanisms for efficiency

3. Local Model Integration:
   - Ollama connection handling for local models
   -Use A Terminal connection to the LLM
   - Support for quantized models (GGUF format)
   - Memory and performance optimization for mobile/desktop
   - Background processing to prevent UI freezing

4. Chat Interface Features:
   - Message streaming with typing indicator
   - Markdown rendering with syntax highlighting
   - Code block formatting with copy functionality useing best choice with Swift6.1 to format code blocks indentation and syntax highlighting
   - Message threading and conversation history
   - Input/output token counting
   - Context window visualization

5. Project Organization:
   - Project-based conversation management
   - Knowledge file attachment system
   - Chat history persistence
   - Export/import functionality

6. Advanced Features:
   - Function calling/tool use implementation
   - System prompt management and templates
   - Model parameter controls (temperature, top_p, etc.)
   - Response formatting controls
   - Multi-modal capabilities where supported

Provide a comprehensive Swift implementation focusing on the core architecture that would allow me to easily swap between different LLMs while maintaining the clean Claude-like interface seen in the screenshots. Include code for the main components and explain how they connect together.