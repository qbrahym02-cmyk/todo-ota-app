/// إعدادات ثابتة للتطبيق — غيّرها لو نقلت المستودع.
class AppConfig {
  static const githubOwner = 'qbrahym02-cmyk';
  static const githubRepo = 'todo-ota-app';
  static const branch = 'main';

  /// ملف الإعدادات عن بعد (عدّله على GitHub وسيصل للتطبيق فوراً)
  static const remoteConfigUrl =
      'https://raw.githubusercontent.com/$githubOwner/$githubRepo/$branch/remote/config.json';

  /// آخر إصدار APK من GitHub Releases
  static const latestReleaseApi =
      'https://api.github.com/repos/$githubOwner/$githubRepo/releases/latest';

  static const remoteRefreshInterval = Duration(minutes: 5);
}
