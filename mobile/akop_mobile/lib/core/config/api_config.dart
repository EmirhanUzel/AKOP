/// Backend adresi. Emülatörde bilgisayara `10.0.2.2` ile ulaşılır.
/// Değiştirmek için: `flutter run --dart-define=API_BASE_URL=http://192.168.1.20:5101`
const apiBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'http://10.0.2.2:5101');
