# DBMS Documentation & Integration Guide

## 1. Initialization

Initialize `SyncManager` once at application startup or user authentication:

```dart
bool ok = await SyncManager.instance.initialize(
  backendBaseUrl: 'https://dementia-care-yne7.onrender.com', // no trailing slash
  email: 'user@example.com',
  password: 'password123',
);
```

- **Parameters:**
  - `backendBaseUrl` (`String`): Base URL for the remote server (without trailing slash).
  - `email` (`String`): User authentication email.
  - `password` (`String`): User authentication password.
- **Returns:** `Future<bool>` — `true` if initialization and authentication succeed, otherwise `false`.

---

## 2. CRUD Methods (`localRepo`)

### Create Reminder

Creates a new reminder entry locally.

```dart
int id = await localRepo.createReminder(
  message: 'Water',
  time: '08:00',
);
```

- **Parameters:**
  - `message` (`String`): Content or label for the reminder.
  - `time` (`String`): Scheduled time formatted as a string (e.g., `'08:00'`).
- **Returns:** `Future<int>` — Local database ID of the created record.

---

### Get Reminders

Fetches all reminders or retrieves a specific reminder by its ID.

```dart
List<dynamic> all = await localRepo.getReminder();     // Get all reminders
List<dynamic> one = await localRepo.getReminder(id);   // Get reminder by ID
```

- **Parameters:**
  - `id` (`int?`, optional): Specific record ID to query. Omit to fetch all entries.
- **Returns:** `Future<List<dynamic>>` — A list of reminder records matching the query.

---

### Create Game Session

Records a completed or ongoing game session locally.

```dart
int id = await localRepo.createGameSession(
  gameType: 'reaction',
  gameData: '{"score": 10}',
);
```

- **Parameters:**
  - `gameType` (`String`): Type or identifier of the game (e.g., `'reaction'`).
  - `gameData` (`String`): Serialized JSON payload containing session data/metrics.
- **Returns:** `Future<int>` — Local database ID of the created record.

---

## 3. Manual Sync

Forces an immediate data synchronization between the local repository and the backend.

```dart
bool ok = await SyncManager.instance.forceSyncNow();
```

- **Parameters:** None.
- **Returns:** `Future<bool>` — `true` if sync execution completes successfully, otherwise `false`.

---

## 4. Record Fields Reference

Common metadata fields present on local entity records:

| Field | Type | Description |
| :--- | :--- | :--- |
| `record.id` | `int` | Unique primary key in the local database. |
| `record.globalId` | `int?` | Corresponding remote server ID (`null` if pending initial sync). |
| `record.isSynced` | `bool` | Sync status flag (`true` if synchronized; `false` if pending upload). |