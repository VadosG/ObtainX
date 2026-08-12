import 'package:flutter_test/flutter_test.dart';
import 'package:obtainium/app_sources/uptodown.dart';

void main() {
  group('Uptodown Source Tests', () {
    final uptodown = Uptodown();

    test('parseUptodownDate parses standard English date formats', () {
      expect(parseUptodownDate('Aug 11, 2026'), equals(DateTime(2026, 8, 11)));
      expect(
        parseUptodownDate('August 11, 2026'),
        equals(DateTime(2026, 8, 11)),
      );
      expect(parseUptodownDate(null), isNull);
    });

    test('sourceSpecificStandardizeURL normalizes subdomains to .en.uptodown.', () {
      expect(
        uptodown.sourceSpecificStandardizeURL(
          'https://gamehub.br.uptodown.com/android',
        ),
        equals('https://gamehub.en.uptodown.com/android/download'),
      );
      expect(
        uptodown.sourceSpecificStandardizeURL(
          'https://vlc.es.uptodown.com/android/download',
        ),
        equals('https://vlc.en.uptodown.com/android/download'),
      );
      expect(
        uptodown.sourceSpecificStandardizeURL(
          'https://whatsapp-messenger.en.uptodown.com/android',
        ),
        equals('https://whatsapp-messenger.en.uptodown.com/android/download'),
      );
    });
  });
}
