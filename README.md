# Unipantry

Unipantry is a cross-platform Flutter application designed to support household-level food inventory management, grocery list organization, and expiry tracking. The system integrates barcode scanning, manual item entry, household collaboration, and scheduled notifications using Firebase and a custom notification service. The goal of the application is to provide a unified, synchronized, and efficient approach to pantry management while reducing food waste.

---

## Overview

Unipantry provides the following capabilities:

- Shared pantry inventory accessible by all members of a household  
- Creation and management of grocery lists  
- Barcode-based item retrieval through OpenFoodAPI  
- Manual item entry with validation  
- Automatic scheduling of expiry reminders  
- Real-time synchronization via Firebase Firestore  
- User authentication and household membership management through Firebase Authentication  

The project follows a modular software architecture that separates UI components, state management, business logic, and data access layers.

---

## Architectural Notes

- **State Management:** Implemented using Riverpod to ensure predictable state flow and separation of concerns.  
- **Data Persistence:** Firebase Firestore is used for real-time data synchronization across all household members.  
- **Authentication:** Firebase Authentication manages user identity and access control.  
- **Notification Scheduling:** A custom notification service schedules and dispatches expiry reminders locally.  
- **API Integration:** OpenFoodAPI is utilized for barcode-based item metadata retrieval.  
- **UI Layer:** Structured as a multi-screen Flutter application with reusable components, maintaining clear separation between UI and business logic.

The system architecture is organized into three major layers:

1. **Presentation Layer** – Flutter screens and widgets  
2. **Logic/State Layer** – Riverpod providers handling domain logic  
3. **Data/Service Layer** – Firestore, Authentication, NotificationService, and external API integrations
