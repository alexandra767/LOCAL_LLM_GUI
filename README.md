# Seraph - Local LLM Assistant

A macOS application for interacting with local language models (LLMs) using Ollama or other LLM services.

## Features

### Project Management
- Display projects as cards with descriptions
- Star/unstar favorite projects
- Delete projects with confirmation
- View project details and associated chats

### Chat Interface
- Create and manage chat conversations
- Support for different chat models
- Delete chats with confirmation
- Star/unstar favorite chats

### Profile Management
- Customizable user profile with profile picture
- Display connection status to LLM

## Screenshots

Here's what the application looks like:

**Projects View**
```
+------------------+    +--------------------------------------------------+
|                  |    |                                                  |
| Seraph           |    | Projects                                     +   |
|                  |    |                                                  |
| LLM Assistant    |    | +------------------+  +-------------------+      |
|                  |    | | Project One      |  | Project Two      ★ 🗑️   |
|                  |    | | Description...   |  | Description...          |
| + New chat       |    | | 0 Chats          |  | 0 Chats                 |
|                  |    | | Updated today    |  | Updated today           |
| • Chat 1         |    | +------------------+  +-------------------+      |
| • Chat 2         |    |                                                  |
| • Chat 3         |    | +------------------+                             |
|                  |    | | New Project      |                             |
| Settings         |    | | Add description  |                             |
| Files            |    | | No chats yet     |                             |
| Projects         |    | | Created just now |                             |
|                  |    | +------------------+                             |
| ⭐ STARRED       |    |                                                  |
|                  |    |                                                  |
| 🕒 RECENTS       |    |                                                  |
|                  |    |                                                  |
|                  |    |                                                  |
|                  |    |                                                  |
| +------------+   |    |                                                  |
| | AT    ✅    |   |    |                                                  |
| +------------+   |    |                                                  |
+------------------+    +--------------------------------------------------+
```

**Chat View**
```
+------------------+    +--------------------------------------------------+
|                  |    |                                                  |
| Seraph           |    | Recent Chats                                 +   |
|                  |    |                                                  |
| LLM Assistant    |    | +--------------------------------------------------+
|                  |    | | Understanding LLMs                         🗑️  |
| + New chat       |    | | user: What are LLMs?                           |
|                  |    | | 2 days ago                                     |
| • Understanding  |    | +--------------------------------------------------+
| • Coding Project |    | | Coding Project ★                           🗑️  |
| • Data Analysis  |    | | user: Help me with a Swift project             |
|                  |    | | 1 day ago                                      |
| Settings         |    | +--------------------------------------------------+
| Files            |    | | Data Analysis                              🗑️  |
| Projects         |    | | user: How do I analyze this dataset?           |
|                  |    | | 5 hours ago                                    |
| ⭐ STARRED       |    | +--------------------------------------------------+
|                  |    |                                                  |
| 🕒 RECENTS       |    |                                                  |
|                  |    |                                                  |
|                  |    |                                                  |
|                  |    |                                                  |
| +------------+   |    |                                                  |
| | AT    ✅    |   |    |                                                  |
| +------------+   |    |                                                  |
+------------------+    +--------------------------------------------------+
```

**Profile**
```
+------------------+
|                  |
| +------------+   |
| | AT    ✅    |   |
| +------------+   |
| Alexandra T.     |
| Connected • llama|
+------------------+
```

## Running the Application

Build and run the app using Swift:

```bash
swift run
```

## Requirements

- macOS 13 or later
- Xcode 14 or later
- Swift 5.8 or later