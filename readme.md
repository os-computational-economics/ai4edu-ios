
# AI4EDU

[AI4EDU](https://dashboard.ai4edu.io/) is an application designed to provide AI-powered educational assistance through interactive chat and customizable agent interactions. This project focuses on developing the iOS version, which offers basic chat functionality for students.

**IMPORTANT :**

To create a new workspace, please contact system admin or Professor Sining Wang at `sxw924@case.edu`.

To create or modify an agent, use the web-based version of the platform at the link above.

---
## System Architecture
![System Architecture](arch.png)


## Project Structure

```
├── Models/               # Data models and app state
├── Services/             # API integrations and chat services
├── Components/           # Reusable UI components
└── Views/                # Feature-specific views
    ├── Dashboard/        # Dashboard and roster
    ├── Login/            # User authentication screens
    ├── Chat/             # AI chat interface
    └── Agent/            # Agent configuration and management
    └── Main/             # Main interface
```

---

## Features

- User authentication via SSO
- AI chat interface for real-time interaction
- Custom AI agent management
- Code and Markdown support for rich content rendering
- Persistent thread and conversation history
- Course-specific educational tools and resources

---

## Development

Built using **SwiftUI** for iOS.  
Requires **Xcode** and a device or simulator running iOS 18.0 or later.

---

## Environment

Change the value in `Environment.swift` to switch between environments.