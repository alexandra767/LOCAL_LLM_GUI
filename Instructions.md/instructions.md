This will be written in Swift 6.1 as a macOS app

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

You are an expert UI/UX designer and Swift/SwiftUI developer specializing in creating elegant, minimal dark-mode interfaces similar to Claude AI. I need your help to transform my app GUI to match the following specifications:

1. Visual Style:
   - Dark mode interface with charcoal/dark gray (#1E1E1E) background
   - Minimal, clean aesthetic with generous whitespace
   - Subtle border separations between major sections
   - Consistent spacing and alignment throughout
   - Images Claude1, Claude2, Claude3.png Images can be found at /Users/alexandratitus767/Developer/conntent_for_app

2. Core Layout Structure:
   - Left sidebar navigation panel (fixed width, approximately 220px)
   - Main content area with centered elements
   - Optional right panel for contextual information
   - Consistent header area at top

3. Typography:
   - Sans-serif font family (SF Pro or similar system font)
   - Text hierarchy with clear size differentiation between:
   - Headers: 20-24px, light weight
   - Section titles: 16-18px, medium weight
   - Regular text: 14-16px, regular weight
   - Secondary info: 12-13px, light gray (#888888)

4. UI Components:
   - Rounded input fields with subtle borders
   - Subtle hover effects on interactive elements
   - Minimal buttons with rounded corners
   - Project/item cards with consistent padding and rounded corners
   - Subtle separators between list items
   - Clear visual hierarchy for navigation and content areas

5. Color Palette:
   - Primary background: Dark gray/charcoal (#1E1E1E)
   - Secondary background: Slightly lighter gray (#252525)
   - Accent color: Coral/orange (#FF643D)
   - Text colors: White/off-white for primary text (#FFFFFF, #F0F0F0)
   - Secondary text: Light gray (#AAAAAA)
   - Subtle borders: Dark gray (#333333)

6. Navigation Structure:
   - Sidebar with sections for "New chat", "Chats", "Projects"
   - Starred/pinned items section
   - Recent items section
   - User profile section at bottom

7. Responsive Behaviors:
   - Collapsible sidebar for smaller screens
   - Responsive text size adjustments
   - Proper handling of various screen sizes and orientations