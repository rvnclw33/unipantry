# 📦 Unipantry

Unipantry is a cross-platform Flutter application designed to help households track pantry items, manage grocery lists, and monitor product expiry dates.  
The system integrates barcode scanning, manual item entry, household collaboration, and scheduled notifications through Firebase and a custom notification service.

The app aims to reduce food waste, streamline grocery planning, and provide a shared pantry for multiple household members.

---

## 🧭 Overview

Unipantry provides:
- A shared pantry inventory for household members  
- Grocery list creation and management  
- Barcode scanning (OpenFoodAPI) and manual entry  
- Automatic expiry reminders via scheduled notifications  
- Firebase authentication, Firestore syncing, and real-time updates  

The project follows a modular, provider-based architecture that separates UI, state management, models, and services.

---

## 🏛 Architectural Notes

- **State Management:** Riverpod providers  
- **Database:** Firebase Firestore (real-time sync)  
- **Auth:** Firebase Authentication  
- **Notifications:** Local scheduled reminders for expiry dates  
- **API Integration:** OpenFoodAPI for barcode lookups  
- **UI:** Multi-screen Flutter application with reusable widgets  

The architecture separates:
- UI layer (Screens & Widgets)  
- Logic layer (Providers)  
- Data/Services layer (Firestore, NotificationService, APIs)

---

## 📌 Status

Actively developed — more screens and improvements will be added.
