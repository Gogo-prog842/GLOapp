abstract final class AppConfig {
  static const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://cuclipnkrawodzcpzioi.supabase.co',
  );

  static const supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: 'sb_publishable_XgE-jZV70_yzEHZIVQ9uyw_cdyGRZ1L',
  );

  static const appName = 'GLO';
  static const fullName = 'Grudziądzka Liga Orlikowa';
}
