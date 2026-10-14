/// Build-time configuration. Override with --dart-define, e.g.
/// flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8000
class AppConfig {
  static const apiBaseUrl ='https://clipflow-production-bbea.up.railway.app';
     
  static const googleClientId = '927667129590-r6mj0f907mp66gi5672lcq1b2fiv0a3e.apps.googleusercontent.com';
  

  // AdSense. While these contain "XXXX" the app shows a neutral placeholder
  // instead of a live ad unit, so nothing breaks before approval.
  static const adsenseClient =
      String.fromEnvironment('ADSENSE_CLIENT', defaultValue: 'ca-pub-XXXXXXXXXXXXXXXX');
  static const adSlotSidebar =
      String.fromEnvironment('ADSENSE_SLOT_SIDEBAR', defaultValue: 'XXXXXXXXXX');
  static const adSlotResults =
      String.fromEnvironment('ADSENSE_SLOT_RESULTS', defaultValue: 'XXXXXXXXXX');
}
