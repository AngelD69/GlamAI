class AppConfig {
  // Change this to your machine's local IP when testing on a physical device.
  // Use 10.0.2.2 for Android emulator, 127.0.0.1 for iOS simulator.
  static const String baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'http://192.168.1.65:8000',
  );
}
