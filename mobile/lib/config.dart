/// App-wide configuration.
class AppConfig {
  // --- Supabase (auth + storage) ---
  // Supabase dashboard > Project Settings > API.
  static const String supabaseUrl = 'https://uzcnewzcxpertcntjvev.supabase.co';
  // The "publishable" key (older projects label this the "anon public" key).
  static const String supabaseKey = 'sb_publishable_t2iV--SFeRcvOwV0fthl6Q_in8jL7ZT';

  /// Supabase Storage bucket used for file uploads (create it in the dashboard).
  static const String storageBucket = 'uploads';

  // --- Laravel data API ---
  // Production: the deployed Laravel API on Render.
  static const String apiBaseUrl = 'https://pomodoro-api-wvct.onrender.com/api';
  //
  // For local development, swap apiBaseUrl above for the value that matches
  // where you run the app (and start the backend with `php artisan serve`):
  //   - Android emulator:            http://10.0.2.2:8000/api
  //   - iOS simulator / desktop:     http://127.0.0.1:8000/api
  //   - Web (flutter run -d chrome): http://127.0.0.1:8000/api
  //   - Physical device:             http://YOUR-COMPUTER-LAN-IP:8000/api
}
