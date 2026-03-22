# Firebase Architecture & Security

This document outlines the Cloud Firestore configuration, database schematics, and deployment instructions for the **Futeboladas** application.

---

## 🗄️ Database Schema

The database strictly uses **English** collection names and document keys to maintain consistency with the application's source code.

### Collection: `games`
Contains the core match information.
- `isActive` (boolean): Whether the game is visible/active.
- `title` (string): Title or name of the match.
- `location` (string): Full address or dynamic location string.
- `field` (string): Specific field name/type (e.g., "Relva Sintética").
- `date` (timestamp): The scheduled time and date of the match.
- `players` (int): Maximum player capacity.
- `price` (number): Entrance fee.
- `lat` & `lon` (float): Geographic coordinates for weather and map deep-linking.
- `createdBy` (string): UID of the game organizer.
- `createdAt` (timestamp): Record creation time.
- `createdByName` & `createdByPhoto` (string): Organizer metadata.

### Subcollection: `attendances` (inside `games/{id}/attendances/{uid}`)
Tracks attendance for a specific user in a specific game.
- `uid` (string): The attendee's Firebase Auth ID.
- `isGoing` (boolean): Opt-in status (`true` if attending).
- `name` & `photo` (string): Attendee metadata.
- `updatedAt` (timestamp): Last modified signature.

---

## 🔒 Security Rules

The application uses rigorous Security Rules to guarantee data integrity:

1. **Authentication**: Read and Write operations inside `games` require `request.auth != null`.
2. **Schema Validation**: Document creations and mutations are validated block-by-block. Only explicitly permitted keys (`length`, `type`, and `existence`) are permitted to be saved to avoid database pollution.
3. **Authorization**: Deleting or editing a match is rigidly restricted to `resource.data.createdBy == request.auth.uid`.
4. **Collection Group Queries**: There is a top-level rule allowing read capabilities for `attendances` across the entire database. This powers the "Games I'm Attending" filter on the dashboard.

---

## 🚀 Deployment

The project contains two critical configuration files:
- `firestore.rules`: Contains the security logic.
- `firestore.indexes.json`: Contains the composite indexes requires to evaluate `orderBy` queries in Cloud Firestore.

### How to deploy

Ensure you are authenticated in the Firebase CLI (`firebase login`) and execute the deployment script locally from the project root:

```bash
# This will push both the Rules and the Indexes to your Firebase Project
firebase deploy --only firestore
```

If you manage distinct environments (e.g. `futeboladas-dev` and `futeboladas-prod`), specify the target project:
```bash
firebase deploy --only firestore --project <alias_or_project_id>
```
