import 'package:akop_mobile/features/reports/presentation/new_report/voice_input.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('söylenen metin mevcut açıklamanın sonuna boşlukla eklenir', () {
    expect(appendSpoken('', 'yolda çukur var'), 'yolda çukur var');
    expect(appendSpoken('Okul önü.  ', ' yolda çukur var '), 'Okul önü. yolda çukur var');
    expect(appendSpoken('Okul önü.', '  '), 'Okul önü.'); // boş sonuç metni değiştirmez
  });

  test('sınırı aşan kısım kesilir', () {
    expect(appendSpoken('abc', 'defgh', maxLength: 6), 'abc de');
  });
}
