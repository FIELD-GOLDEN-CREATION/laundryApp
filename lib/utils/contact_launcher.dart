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
/// Returns whether WhatsApp (or its web fallback) could be launched.
Future<bool> launchWhatsAppChat(String phone) async {
  final digits = phone.replaceAll(RegExp(r'\D'), '');
  final uri = Uri.parse('https://wa.me/$digits');
  return launchUrl(uri, mode: LaunchMode.externalApplication);
}
