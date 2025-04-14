
# AI4EDU

Final project for **CSDS 392 – App Development for iOS**  
**Team Members:** Ruilin Jin, Teddy Bryant

[AI4EDU](https://dashboard.ai4edu.io/) is an application designed to provide AI-powered educational assistance through interactive chat and customizable agent interactions. This project focuses on developing the iOS version, which offers basic chat functionality for students.

**IMPORTANT :**

To create a new workspace, please contact system admin or Professor Sining Wang at `sxw924@case.edu`.

To create or modify an agent, use the web-based version of the platform at the link above.

---

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
Requires **Xcode** and a device or simulator running iOS 15.0 or later.

## Q&A

1. **How can I test the APIs?**  
We've provided several API endpoints for testing. You can try them directly or import the OpenAPI JSON file into Postman.  
**Note:** Make sure to set the base URL `https://ai4edu-api.jerryang.org` before making any API calls.  

    - [API Documentation](https://ai4edu-api.jerryang.org/v1/dev/admin/docs)  
    - [OpenAPI JSON](https://ai4edu-api.jerryang.org/v1/dev/admin/openapi.json)

2. **Why can’t I call the API or why do some endpoints return no data?**  
Most API requests require an access token and are protected by an RBAC system.  
Every API call must include an authorization header in the format:  `Authorization: Bearer access={access_token}`
If you're testing in Postman, you’ll need to copy a valid token from the web application and add it to your request headers. Tokens are valid for 30 minutes.
