import 'package:html/dom.dart';
import 'package:html/parser.dart' show parse;
import 'package:http/http.dart' as http;
import 'package:obtainium/services/html_parse_isolate.dart';

const Duration _storeListingIconFetchTimeout = Duration(seconds: 10);

const String _storeListingUserAgent =
    'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36';

/// Absolute raster icon URL from a store listing HTML document.
String? iconUrlFromStoreListingDocument(Document doc, String pageUrl) {
  final String? raw =
      doc.querySelector('meta[property="og:image"]')?.attributes['content'] ??
      doc.querySelector('meta[name="twitter:image"]')?.attributes['content'] ??
      doc
          .querySelector('meta[name="twitter:image:src"]')
          ?.attributes['content'] ??
      doc.querySelector('img.package-icon')?.attributes['src'] ??
      doc.querySelector('img[alt="Icon image"]')?.attributes['src'] ??
      doc.querySelector('img.icon')?.attributes['src'];
  if (raw == null || raw.trim().isEmpty) {
    return null;
  }
  return Uri.parse(pageUrl).resolveUri(Uri.parse(raw.trim())).toString();
}

/// Same as [iconUrlFromStoreListingDocument] for a raw HTML string.
String? iconUrlFromStoreListingHtml(String html, String pageUrl) {
  return iconUrlFromStoreListingDocument(parse(html), pageUrl);
}

Future<String?> iconUrlFromStoreListingHtmlOffIsolate(
  String html,
  String pageUrl,
) async {
  final Document doc = await parseHtmlOffIsolate(html);
  return iconUrlFromStoreListingDocument(doc, pageUrl);
}

/// Fetches [listingUrl] and extracts a raster icon URL from the page.
Future<String?> fetchIconUrlFromStoreListingPage(String listingUrl) async {
  try {
    final http.Response response = await http
        .get(
          Uri.parse(listingUrl),
          headers: {'User-Agent': _storeListingUserAgent},
        )
        .timeout(_storeListingIconFetchTimeout);
    if (response.statusCode != 200) {
      return null;
    }
    return await iconUrlFromStoreListingHtmlOffIsolate(
      response.body,
      listingUrl,
    );
  } catch (_) {
    return null;
  }
}

/// Resolves a missing-app icon from other-store metadata, in preference order:
/// APKMirror API icon, then listing pages APKMirror -> F-Droid -> APKPure ->
/// Play Store. Stops at the first URL that yields an icon.
Future<String?> resolveIconUrlFromOtherStores({
  String? apkMirrorIconUrl,
  String? apkMirrorListingUrl,
  String? fdroidListingUrl,
  String? apkPureListingUrl,
  String? playStoreListingUrl,
  Future<String?> Function(String listingUrl) fetchListingIconUrl =
      fetchIconUrlFromStoreListingPage,
}) async {
  final String? trimmedApkMirrorIcon = apkMirrorIconUrl?.trim();
  if (trimmedApkMirrorIcon != null && trimmedApkMirrorIcon.isNotEmpty) {
    return trimmedApkMirrorIcon;
  }
  for (final String? listingUrl in <String?>[
    apkMirrorListingUrl,
    fdroidListingUrl,
    apkPureListingUrl,
    playStoreListingUrl,
  ]) {
    final String? trimmedListingUrl = listingUrl?.trim();
    if (trimmedListingUrl == null || trimmedListingUrl.isEmpty) {
      continue;
    }
    final String? listingIconUrl = await fetchListingIconUrl(
      trimmedListingUrl,
    );
    if (listingIconUrl != null && listingIconUrl.trim().isNotEmpty) {
      return listingIconUrl.trim();
    }
  }
  return null;
}
