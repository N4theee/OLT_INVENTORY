# OLT Inventory

Church inventory management system built with Flutter and Supabase.

## Features

- Dashboard with inventory statistics and department breakdown
- Full CRUD for inventory items with image upload (camera & gallery)
- Department-based organization
- Soft delete with restore and permanent delete
- Activity logging for all inventory actions
- Search, filter, and sort on inventory lists
- Gold and white Material 3 church-themed UI

## Setup

### 1. Supabase Project

1. Create a project at [supabase.com](https://supabase.com)
2. Run `supabase/schema.sql` in the SQL Editor
3. Create a Storage bucket named `inventory-images` (public)
4. Copy your project URL and anon key

### 2. Configure the App

Edit `lib/constants/app_constants.dart`:

```dart
static const String supabaseUrl = 'https://YOUR_PROJECT.supabase.co';
static const String supabaseAnonKey = 'YOUR_ANON_KEY';
```

### 3. Run

```bash
flutter pub get
flutter run
```

## Project Structure

```
lib/
├── constants/     # Theme, colors, app config
├── models/        # Data models
├── providers/     # Provider state management
├── screens/       # UI screens
├── services/      # Supabase & business logic
├── utils/         # Validators, formatters
└── widgets/       # Reusable UI components
```

## Future Versions

Planned features (not yet implemented):

- Authentication
- User Roles
- Borrowing System
- Reports
- Notifications
