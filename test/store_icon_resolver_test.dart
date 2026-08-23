import 'package:flutter_test/flutter_test.dart';
import 'package:obtainium/services/store_icon_resolver.dart';

void main() {
  group('iconUrlFromStoreListingHtml', () {
    test('resolves F-Droid og:image against the listing URL', () {
      expect(
        iconUrlFromStoreListingHtml('''
<html><head>
<meta property="og:image" content="/repo/icons-640/org.example.app.png" />
</head></html>
''', 'https://f-droid.org/packages/org.example.app/'),
        'https://f-droid.org/repo/icons-640/org.example.app.png',
      );
    });

    test('prefers og:image over later img fallbacks', () {
      expect(
        iconUrlFromStoreListingHtml('''
<html><head>
<meta property="og:image" content="https://cdn.example.com/og.png" />
</head><body>
<img class="package-icon" src="https://cdn.example.com/fallback.png" />
</body></html>
''', 'https://f-droid.org/packages/org.example.app/'),
        'https://cdn.example.com/og.png',
      );
    });

    test('reads Play Store icon image when og:image is missing', () {
      expect(
        iconUrlFromStoreListingHtml('''
<html><body>
<img alt="Icon image" src="https://play-lh.googleusercontent.com/icon.png" />
</body></html>
''', 'https://play.google.com/store/apps/details?id=org.example.app'),
        'https://play-lh.googleusercontent.com/icon.png',
      );
    });

    test('returns null when the page has no icon', () {
      expect(
        iconUrlFromStoreListingHtml(
          '<html><body><p>No icon</p></body></html>',
          'https://apkpure.net/example/org.example.app',
        ),
        isNull,
      );
    });
  });

  group('resolveIconUrlFromOtherStores', () {
    test(
      'returns the APKMirror API icon without fetching listing pages',
      () async {
        final List<String> fetchedUrls = <String>[];
        final String? iconUrl = await resolveIconUrlFromOtherStores(
          apkMirrorIconUrl: ' https://www.apkmirror.com/icon.png ',
          apkMirrorListingUrl: 'https://www.apkmirror.com/apk/example/',
          fdroidListingUrl: 'https://f-droid.org/packages/org.example.app/',
          fetchListingIconUrl: (String listingUrl) async {
            fetchedUrls.add(listingUrl);
            return 'https://should-not-be-used.png';
          },
        );
        expect(iconUrl, 'https://www.apkmirror.com/icon.png');
        expect(fetchedUrls, isEmpty);
      },
    );

    test(
      'walks listing pages in preference order and stops at the first icon',
      () async {
        final List<String> fetchedUrls = <String>[];
        final String? iconUrl = await resolveIconUrlFromOtherStores(
          apkMirrorListingUrl: 'https://www.apkmirror.com/apk/example/',
          fdroidListingUrl: 'https://f-droid.org/packages/org.example.app/',
          apkPureListingUrl: 'https://apkpure.net/example/org.example.app',
          playStoreListingUrl:
              'https://play.google.com/store/apps/details?id=org.example.app',
          fetchListingIconUrl: (String listingUrl) async {
            fetchedUrls.add(listingUrl);
            if (listingUrl.contains('f-droid.org')) {
              return 'https://f-droid.org/repo/icons-640/org.example.app.png';
            }
            return null;
          },
        );
        expect(
          iconUrl,
          'https://f-droid.org/repo/icons-640/org.example.app.png',
        );
        expect(fetchedUrls, <String>[
          'https://www.apkmirror.com/apk/example/',
          'https://f-droid.org/packages/org.example.app/',
        ]);
      },
    );

    test('skips blank listing URLs', () async {
      final List<String> fetchedUrls = <String>[];
      final String? iconUrl = await resolveIconUrlFromOtherStores(
        apkMirrorListingUrl: '',
        fdroidListingUrl: '   ',
        apkPureListingUrl: 'https://apkpure.net/example/org.example.app',
        playStoreListingUrl: null,
        fetchListingIconUrl: (String listingUrl) async {
          fetchedUrls.add(listingUrl);
          return 'https://apkpure.net/icon.png';
        },
      );
      expect(iconUrl, 'https://apkpure.net/icon.png');
      expect(fetchedUrls, <String>[
        'https://apkpure.net/example/org.example.app',
      ]);
    });
  });
}
