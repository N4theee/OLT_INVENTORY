import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:olt_inventory/constants/app_constants.dart';

class SupabaseService {
  SupabaseService._();

  static bool _initialized = false;

  static SupabaseClient get client => Supabase.instance.client;

  static bool get isConfigured =>
      AppConstants.supabaseUrl != 'YOUR_SUPABASE_URL' &&
      AppConstants.supabaseAnonKey != 'YOUR_SUPABASE_ANON_KEY';

  static Future<void> initialize() async {
    if (_initialized) return;

    if (!isConfigured) {
      throw Exception(
        'Supabase credentials not configured. Update AppConstants.',
      );
    }

    await Supabase.initialize(
      url: AppConstants.supabaseUrl,
      publishableKey: AppConstants.supabaseAnonKey,
    );
    _initialized = true;
  }
}
