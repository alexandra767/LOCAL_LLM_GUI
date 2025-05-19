Seraph/
├── App/
│   ├── SeraphApp.swift      // Main app entry point
│   └── AppState.swift       // Global app state
├── Views/
│   ├── ContentView.swift    // Main container view
│   ├── Chat/                // Chat-related views
│   ├── Projects/            // Project-related views
│   ├── Settings/            // Settings views
│   └── Components/          // Reusable UI components
├── ViewModels/              // Business logic
├── Models/                  // Data models
├── Services/                // Business services (LLM, Speech)
├── Persistence/             // CoreData setup and controllers
└── Utilities/               // Helper functions and extensions
Visual Style Requirements

Dark Mode Interface

Charcoal/dark gray (#1E1E1E) background
Minimal, clean aesthetic with generous whitespace
Subtle border separations between major sections
Consistent spacing and alignment throughout


Core Layout Structure

Left sidebar navigation panel (fixed width, ~220px)
Main content area with centered elements
Optional right panel for contextual information
Consistent header area at top


Typography

Sans-serif font family (SF Pro or similar system font)
Text hierarchy with clear size differentiation:

Headers: 20-24px, light weight
Section titles: 16-18px, medium weight
Regular text: 14-16px, regular weight
Secondary info: 12-13px, light gray (#888888)

UI Components

Rounded input fields with subtle borders
Subtle hover effects on interactive elements
Minimal buttons with rounded corners
Project/item cards with consistent padding and rounded corners
Subtle separators between list items
Clear visual hierarchy for navigation and content areas


Color Palette

Primary background: Dark gray/charcoal (#1E1E1E)
Secondary background: Slightly lighter gray (#252525)
Accent color: Coral/orange (#FF643D)
Text colors: White/off-white for primary text (#FFFFFF, #F0F0F0)
Secondary text: Light gray (#AAAAAA)
Subtle borders: Dark gray (#333333)


Navigation Structure

Sidebar with sections for "New chat", "Chats", "Projects"
Starred/pinned items section
Recent items section
User profile section at bottom


Responsive Behaviors

Collapsible sidebar for smaller screens
Responsive text size adjustments
Proper handling of various screen sizes and orientations



LLM Integration Requirements

LLM Connection Architecture

Flexible adapter pattern to connect to any LLM (local or API-based)
Support for multiple models: Ollama-based models (DeepSeek, Llama, Mistral), OpenAI, Anthropic, etc.
Streaming text capabilities for real-time responses
Efficient token handling and context management
Proper error handling and recovery mechanisms


Core API Integration Components

Modular API client for different LLM providers
Authentication and API key management (secure storage)
Request/response serialization
Rate limiting and quota management
Caching mechanisms for efficiency


Local Model Integration

Ollama connection handling for local models
Terminal connection to the LLM
Support for quantized models (GGUF format)
Memory and performance optimization for mobile/desktop
Background processing to prevent UI freezing

Note: When implementing LLM service integrations:
- Always use OllamaService.shared to access the singleton instance
- Ensure proper initialization in SeraphApp's initializeApp() method
- Use consistent token counting and formatting across the app
- Implement proper cancellation support for streaming requests


Chat Interface Features

Message streaming with typing indicator
Markdown rendering with syntax highlighting
Code block formatting with copy functionality
Message threading and conversation history
Input/output token counting with formatted display (1.2k for 1200 tokens)
Token rate calculations (tokens per second)
Context window visualization
ESC key support for cancelling generation


Project Organization

Project-based conversation management
Knowledge file attachment system
Chat history persistence
Export/import functionality


Advanced Features

Function calling/tool use implementation
System prompt management and templates
Model parameter controls (temperature, top_p, etc.)
Response formatting controls
Multi-modal capabilities where supported



Image Resources

Images can be found at /Users/alexandratitus767/Developer/content_for_app
Image files: Claude1.png, Claude2.png, Claude3.png
