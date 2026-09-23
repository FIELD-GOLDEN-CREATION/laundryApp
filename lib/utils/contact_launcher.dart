import 'package:url_launcher/url_launcher.dart';

/// Opens the device's phone dialer with [phone] pre-filled, ready to call.
/// Returns whether the dialer could be launched.
Future<bool> launchPhoneCall(String phone) async {
  final uri = Uri(scheme: 'tel', path: phone);
  return launchUrl(uri);
}

/// Opens WhatsApp straight to a chat with [phone], skipping the contact
/// picker. Only digits survive into the `wa.me` deep link — [phone] may
/// otherwise come formatted with spaces, dashes or a leading '+'.
/// Pass [message] to pre-fill the chat input (e.g. a package enquiry).
/// Returns whether WhatsApp (or its web fallback) could be launched.
Future<bool> launchWhatsAppChat(String phone, {String? message}) async {
  final digits = phone.replaceAll(RegExp(r'\D'), '');
  final uri = message != null && message.trim().isNotEmpty
      ? Uri.parse('https://wa.me/$digits?text=${Uri.encodeComponent(message.trim())}')
      : Uri.parse('https://wa.me/$digits');
  return launchUrl(uri, mode: LaunchMode.externalApplication);
}

/// Prefilled WhatsApp enquiry for a vendor package.
String packageWhatsAppMessage({
  required String shopName,
  required String packageName,
  required String priceLabel,
  required String detail,
}) =>
    'Hello $shopName! I am interested in your package "$packageName" ($priceLabel). $detail';
