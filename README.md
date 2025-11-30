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

---

System is divided into three layers:
1. Presentation Layer – Flutter screens and widgets  
2. Logic/State Layer – Riverpod providers handling domain logic  
3. Data/Service Layer – Firestore, Authentication, NotificationService, and external API integrations
