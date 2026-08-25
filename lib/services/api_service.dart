import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// ---------------------------------------------------------------------------
// Custom exceptions
// ---------------------------------------------------------------------------

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode, this.body});
  final String message;
  final int? statusCode;
  final dynamic body;

  @override
  String toString() => 'ApiException($statusCode): $message';
}

class AuthException extends ApiException {
  AuthException(super.message, {super.statusCode, super.body});
}

class NotFoundException extends ApiException {
  NotFoundException(super.message, {super.statusCode, super.body});
}

class ValidationException extends ApiException {
  ValidationException(super.message, {super.statusCode, super.body, this.errors});
  final Map<String, dynamic>? errors;
}

// ---------------------------------------------------------------------------
// API Service
// ---------------------------------------------------------------------------

class ApiService {
  ApiService._();
  static final ApiService instance = ApiService._();

  static const String baseUrl = 'https://freshfold.qecure.online/api';
  static const String imagebbKey = 'cc1bcb51a356dc45e4f3566e8dbb55c2';

  String? _token;

  // -- Token persistence ---------------------------------------------------

  Future<void> _loadToken() async {
    if (_token != null) return;
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
  }

  Future<void> _saveToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  Future<void> clearToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  Future<void> setToken(String? token) async {
    _token = token;
    if (token == null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
    }
  }

  // -- Headers & HTTP helpers ----------------------------------------------

  Future<Map<String, String>> _headers() async {
    await _loadToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (_token != null) 'Authorization': 'Bearer $_token',
    };
  }

  Uri _uri(String path, [Map<String, String>? query]) {
    if (query != null && query.isNotEmpty) {
      return Uri.parse('$baseUrl$path').replace(queryParameters: query);
    }
    return Uri.parse('$baseUrl$path');
  }

  Map<String, dynamic> _decode(http.Response response) {
    if (response.statusCode == 204) return {};
    final body = utf8.decode(response.bodyBytes);
    if (body.isEmpty) return {};
    return jsonDecode(body) as Map<String, dynamic>;
  }

  Never _handleError(http.Response response) {
    final data = _decode(response);
    final message = data['message'] as String? ?? 'Request failed (${response.statusCode})';

    switch (response.statusCode) {
      case 401:
        throw AuthException(message, statusCode: 401, body: data);
      case 404:
        throw NotFoundException(message, statusCode: 404, body: data);
      case 422:
        throw ValidationException(
          message,
          statusCode: 422,
          body: data,
          errors: data['errors'] as Map<String, dynamic>?,
        );
      default:
        throw ApiException(message, statusCode: response.statusCode, body: data);
    }
  }

  Future<Map<String, dynamic>> get(String path, {Map<String, String>? query}) async {
    final headers = await _headers();
    final response = await http.get(_uri(path, query), headers: headers).timeout(const Duration(seconds: 15));
    if (response.statusCode >= 200 && response.statusCode < 300) return _decode(response);
    _handleError(response);
  }

  Future<Map<String, dynamic>> post(String path, {Map<String, dynamic>? body}) async {
    final headers = await _headers();
    final response = await http.post(
      _uri(path),
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    ).timeout(const Duration(seconds: 15));
    if (response.statusCode >= 200 && response.statusCode < 300) return _decode(response);
    _handleError(response);
  }

  Future<Map<String, dynamic>> put(String path, {Map<String, dynamic>? body}) async {
    final headers = await _headers();
    final response = await http.put(
      _uri(path),
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    ).timeout(const Duration(seconds: 15));
    if (response.statusCode >= 200 && response.statusCode < 300) return _decode(response);
    _handleError(response);
  }

  Future<Map<String, dynamic>> patch(String path, {Map<String, dynamic>? body}) async {
    final headers = await _headers();
    final response = await http.patch(
      _uri(path),
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    ).timeout(const Duration(seconds: 15));
    if (response.statusCode >= 200 && response.statusCode < 300) return _decode(response);
    _handleError(response);
  }

  Future<Map<String, dynamic>> delete(String path) async {
    final headers = await _headers();
    final response = await http.delete(_uri(path), headers: headers).timeout(const Duration(seconds: 15));
    if (response.statusCode >= 200 && response.statusCode < 300) return _decode(response);
    _handleError(response);
  }

  // -- Multipart upload ---------------------------------------------------

  Future<String> uploadMultipart(String path, File file, {String? fieldName}) async {
    await _loadToken();
    final uri = _uri(path);
    final request = http.MultipartRequest('POST', uri);
    if (_token != null) request.headers['Authorization'] = 'Bearer $_token';
    request.headers['Accept'] = 'application/json';
    final stream = http.ByteStream(file.openRead());
    final length = await file.length();
    final multipartFile = http.MultipartFile(
      fieldName ?? 'file',
      stream,
      length,
      filename: file.path.split(Platform.pathSeparator).last,
    );
    request.files.add(multipartFile);
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = _decode(response);
      return data['url'] as String? ?? data['data']?['url'] as String? ?? '';
    }
    _handleError(response);
  }

  // =========================================================================
  // AUTH
  // =========================================================================

  Future<Map<String, dynamic>> login(String idToken) async {
    final data = await post('/auth/login', body: {'id_token': idToken});
    if (data['success'] == true && data['token'] != null) {
      await _saveToken(data['token'] as String);
    }
    return data;
  }

  Future<Map<String, dynamic>> register(String idToken, {String? phone}) async {
    final data = await post('/auth/register', body: {
      'id_token': idToken,
      if (phone != null) 'phone': phone,
    });
    if (data['success'] == true && data['token'] != null) {
      await _saveToken(data['token'] as String);
    }
    return data;
  }

  Future<Map<String, dynamic>> getProfile() => get('/auth/profile');

  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> body) =>
      put('/auth/profile', body: body);

  // =========================================================================
  // SHOPS
  // =========================================================================

  Future<List<Map<String, dynamic>>> getShops({Map<String, String>? query}) async {
    final data = await get('/shops', query: query);
    return (data['data'] as List?)?.cast<Map<String, dynamic>>() ?? [];
  }

  Future<Map<String, dynamic>> getShop(String slug) => get('/shops/$slug');

  // =========================================================================
  // CATEGORIES
  // =========================================================================

  Future<List<Map<String, dynamic>>> getCategories() async {
    final data = await get('/categories');
    return (data['data'] as List?)?.cast<Map<String, dynamic>>() ?? [];
  }

  Future<Map<String, dynamic>> getCategory(String id) => get('/categories/$id');

  // =========================================================================
  // ITEMS
  // =========================================================================

  Future<List<Map<String, dynamic>>> getItems(String categoryId) async {
    final data = await get('/items', query: {'category_id': categoryId});
    return (data['data'] as List?)?.cast<Map<String, dynamic>>() ?? [];
  }

  /// Per-shop offers (price + vendor) for one item, cheapest first.
  Future<Map<String, dynamic>> getItemOffers(String itemId) =>
      get('/items/$itemId/offers');

  // =========================================================================
  // PACKAGES
  // =========================================================================

  /// All active packages across vendors (home carousel).
  Future<List<Map<String, dynamic>>> getAllPackages() async {
    final data = await get('/packages');
    return (data['data'] as List?)?.cast<Map<String, dynamic>>() ?? [];
  }

  Future<List<Map<String, dynamic>>> getPackages(String shopId) async {
    final data = await get('/packages', query: {'shop_id': shopId});
    return (data['data'] as List?)?.cast<Map<String, dynamic>>() ?? [];
  }

  // =========================================================================
  // REVIEWS (public)
  // =========================================================================

  Future<List<Map<String, dynamic>>> getReviews({String? shopId}) async {
    final data = await get('/reviews', query: {if (shopId != null) 'shop_id': shopId});
    return (data['data'] as List?)?.cast<Map<String, dynamic>>() ?? [];
  }

  // =========================================================================
  // ORDERS (Customer)
  // =========================================================================

  Future<List<Map<String, dynamic>>> getOrders({String? status}) async {
    final data = await get('/orders', query: {if (status != null) 'status': status});
    return (data['data'] as List?)?.cast<Map<String, dynamic>>() ?? [];
  }

  Future<Map<String, dynamic>> createOrder(Map<String, dynamic> body) =>
      post('/orders', body: body);

  Future<Map<String, dynamic>> getOrder(String id) => get('/orders/$id');

  Future<Map<String, dynamic>> cancelOrder(String id) => post('/orders/$id/cancel');

  // =========================================================================
  // VENDOR ORDERS
  // =========================================================================

  Future<List<Map<String, dynamic>>> getVendorOrders({String? stage}) async {
    final data = await get('/vendor/orders', query: {if (stage != null) 'stage': stage});
    return (data['data'] as List?)?.cast<Map<String, dynamic>>() ?? [];
  }

  Future<Map<String, dynamic>> acceptOrder(String orderId, {int? deliveryFeeTzs}) =>
      post('/vendor/orders/$orderId/accept', body: {
        if (deliveryFeeTzs != null) 'delivery_fee': deliveryFeeTzs,
      });

  Future<Map<String, dynamic>> rejectOrder(String orderId) =>
      post('/vendor/orders/$orderId/reject');

  Future<Map<String, dynamic>> updateOrderStatus(String orderId, String status) =>
      patch('/vendor/orders/$orderId/status', body: {'status': status});

  Future<Map<String, dynamic>> getVendorOrderDetail(String orderId) =>
      get('/vendor/orders/$orderId');

  // =========================================================================
  // VENDOR SHOP
  // =========================================================================

  Future<Map<String, dynamic>> getVendorShop() => get('/vendor/shop');

  Future<Map<String, dynamic>> updateVendorShop(Map<String, dynamic> body) =>
      put('/vendor/shop', body: body);

  Future<Map<String, dynamic>> updateVendorShopPartial(Map<String, dynamic> body) =>
      patch('/vendor/shop', body: body);

  // =========================================================================
  // VENDOR CATALOG
  // =========================================================================

  /// Per-vendor categories + items with `vendor_price`/`vendor_available`
  /// overlays on the global catalog rows.
  Future<List<Map<String, dynamic>>> getVendorCatalog() async {
    final data = await get('/vendor/catalog');
    return (data['data'] as List?)?.cast<Map<String, dynamic>>() ?? [];
  }

  Future<Map<String, dynamic>> updateVendorCatalog(Map<String, dynamic> body) =>
      put('/vendor/catalog', body: body);

  // =========================================================================
  // VENDOR APPLICATION
  // =========================================================================

  Future<Map<String, dynamic>> submitVendorApplication({
    required String officeName,
    required String plan,
    String? officeLocation,
    String? contactPhone,
    String? contactWhatsapp,
    String? businessDescription,
  }) =>
      post('/vendor/apply', body: {
        'office_name': officeName,
        'plan': plan,
        if (officeLocation != null) 'office_location': officeLocation,
        if (contactPhone != null) 'contact_phone': contactPhone,
        if (contactWhatsapp != null) 'contact_whatsapp': contactWhatsapp,
        if (businessDescription != null) 'business_description': businessDescription,
      });

  // =========================================================================
  // VENDOR ADDONS CRUD
  // =========================================================================

  Future<List<Map<String, dynamic>>> getVendorAddons() async {
    final data = await get('/vendor/addons');
    return (data['data'] as List?)?.cast<Map<String, dynamic>>() ?? [];
  }

  Future<Map<String, dynamic>> createVendorAddon(Map<String, dynamic> body) =>
      post('/vendor/addons', body: body);

  Future<Map<String, dynamic>> updateVendorAddon(String id, Map<String, dynamic> body) =>
      put('/vendor/addons/$id', body: body);

  Future<Map<String, dynamic>> deleteVendorAddon(String id) =>
      delete('/vendor/addons/$id');

  // =========================================================================
  // VENDOR PACKAGES CRUD
  // =========================================================================

  Future<List<Map<String, dynamic>>> getVendorPackages() async {
    final data = await get('/vendor/packages');
    return (data['data'] as List?)?.cast<Map<String, dynamic>>() ?? [];
  }

  Future<Map<String, dynamic>> createVendorPackage(Map<String, dynamic> body) =>
      post('/vendor/packages', body: body);

  Future<Map<String, dynamic>> updateVendorPackage(String id, Map<String, dynamic> body) =>
      put('/vendor/packages/$id', body: body);

  Future<Map<String, dynamic>> deleteVendorPackage(String id) =>
      delete('/vendor/packages/$id');

  // =========================================================================
  // VENDOR PROMOS
  // =========================================================================

  Future<List<Map<String, dynamic>>> getVendorPromos() async {
    final data = await get('/vendor/promos');
    return (data['data'] as List?)?.cast<Map<String, dynamic>>() ?? [];
  }

  Future<Map<String, dynamic>> createVendorPromo(Map<String, dynamic> body) =>
      post('/vendor/promos', body: body);

  Future<Map<String, dynamic>> updateVendorPromo(String id, Map<String, dynamic> body) =>
      put('/vendor/promos/$id', body: body);

  Future<Map<String, dynamic>> deleteVendorPromo(String id) =>
      delete('/vendor/promos/$id');

  Future<Map<String, dynamic>> toggleVendorPromo(String id) =>
      patch('/vendor/promos/$id/toggle');

  // =========================================================================
  // REVIEWS
  // =========================================================================

  Future<List<Map<String, dynamic>>> getShopReviews(String shopId, {int? page}) async {
    final data = await get('/reviews', query: {
      'shop_id': shopId,
      if (page != null) 'page': page.toString(),
    });
    return (data['data'] as List?)?.cast<Map<String, dynamic>>() ?? [];
  }

  Future<Map<String, dynamic>> createReview(
    String orderId, {
    required int rating,
    String? comment,
  }) =>
      post('/orders/$orderId/review', body: {
        'rating': rating,
        if (comment != null && comment.isNotEmpty) 'comment': comment,
      });

  // =========================================================================
  // PROMOS (Customer-facing)
  // =========================================================================

  Future<List<Map<String, dynamic>>> getPromos() async {
    final data = await get('/promos');
    return (data['data'] as List?)?.cast<Map<String, dynamic>>() ?? [];
  }

  Future<Map<String, dynamic>> validatePromo(
    String code,
    String shopId,
    double subtotal,
  ) =>
      post('/promos/validate', body: {
        'code': code,
        'shop_id': shopId,
        'subtotal': subtotal,
      });

  // =========================================================================
  // CHAT
  // =========================================================================

  Future<List<Map<String, dynamic>>> getChatThreads() async {
    final data = await get('/chat/threads');
    return (data['data'] as List?)?.cast<Map<String, dynamic>>() ?? [];
  }

  Future<List<Map<String, dynamic>>> getChatMessages(String threadId, {int? page}) async {
    final data = await get('/chat/threads/$threadId/messages', query: {
      if (page != null) 'page': page.toString(),
    });
    return (data['data'] as List?)?.cast<Map<String, dynamic>>() ?? [];
  }

  Future<Map<String, dynamic>> sendChatMessage(String threadId, String text) =>
      post('/chat/threads/$threadId/messages', body: {'text': text});

  Future<Map<String, dynamic>> createChatThread(String orderId) =>
      post('/chat/threads', body: {'order_id': orderId});

  // =========================================================================
  // NOTIFICATIONS
  // =========================================================================

  Future<List<Map<String, dynamic>>> getNotifications({int? page}) async {
    final data = await get('/notifications', query: {
      if (page != null) 'page': page.toString(),
    });
    return (data['data'] as List?)?.cast<Map<String, dynamic>>() ?? [];
  }

  Future<Map<String, dynamic>> markNotificationRead(String id) =>
      patch('/notifications/$id/read');

  Future<Map<String, dynamic>> markAllNotificationsRead() =>
      patch('/notifications/read-all');

  // =========================================================================
  // SUBSCRIPTIONS
  // =========================================================================

  Future<List<Map<String, dynamic>>> getSubscriptionPlans() async {
    final data = await get('/subscriptions/plans');
    return (data['data'] as List?)?.cast<Map<String, dynamic>>() ?? [];
  }

  Future<Map<String, dynamic>> getVendorSubscription() =>
      get('/vendor/subscription');

  Future<Map<String, dynamic>> subscribe(String planId) =>
      post('/subscriptions/subscribe', body: {'plan_id': planId});

  Future<Map<String, dynamic>> cancelSubscription() =>
      post('/subscriptions/cancel');

  // =========================================================================
  // EARNINGS (Vendor)
  // =========================================================================

  Future<Map<String, dynamic>> getEarnings({String? period}) =>
      get('/vendor/earnings', query: {if (period != null) 'period': period});

  Future<List<Map<String, dynamic>>> getPayouts({int? page}) async {
    final data = await get('/vendor/payouts', query: {
      if (page != null) 'page': page.toString(),
    });
    return (data['data'] as List?)?.cast<Map<String, dynamic>>() ?? [];
  }

  // =========================================================================
  // VENDOR DASHBOARD
  // =========================================================================

  Future<Map<String, dynamic>> getVendorDashboard() => get('/vendor/dashboard');

  // =========================================================================
  // IMAGE UPLOAD (ImageBB)
  // =========================================================================

  Future<String> uploadImage(File file) async {
    final uri = Uri.parse('https://api.imgbb.com/1/upload');
    final request = http.MultipartRequest('POST', uri);
    request.fields['key'] = imagebbKey;
    final stream = http.ByteStream(file.openRead());
    final length = await file.length();
    request.files.add(http.MultipartFile(
      'image',
      stream,
      length,
      filename: file.path.split(Platform.pathSeparator).last,
    ));
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['data']?['url'] as String? ?? '';
    }
    throw ApiException('Image upload failed', statusCode: response.statusCode);
  }

  // =========================================================================
  // CUSTOMER ADDRESSES
  // =========================================================================

  Future<List<Map<String, dynamic>>> getAddresses() async {
    final data = await get('/customer/addresses');
    return (data['data'] as List?)?.cast<Map<String, dynamic>>() ?? [];
  }

  Future<Map<String, dynamic>> createAddress(Map<String, dynamic> body) =>
      post('/customer/addresses', body: body);

  Future<Map<String, dynamic>> updateAddress(String id, Map<String, dynamic> body) =>
      put('/customer/addresses/$id', body: body);

  Future<Map<String, dynamic>> deleteAddress(String id) =>
      delete('/customer/addresses/$id');

  // =========================================================================
  // CUSTOMER CARDS
  // =========================================================================

  Future<List<Map<String, dynamic>>> getCards() async {
    final data = await get('/customer/cards');
    return (data['data'] as List?)?.cast<Map<String, dynamic>>() ?? [];
  }

  Future<Map<String, dynamic>> addCard(Map<String, dynamic> body) =>
      post('/customer/cards', body: body);

  Future<Map<String, dynamic>> deleteCard(String id) =>
      delete('/customer/cards/$id');

  Future<Map<String, dynamic>> setDefaultCard(String id) =>
      patch('/customer/cards/$id/default');

  // =========================================================================
  // CUSTOMER FAVORITES
  // =========================================================================

  Future<List<Map<String, dynamic>>> getFavorites() async {
    final data = await get('/customer/favorites');
    return (data['data'] as List?)?.cast<Map<String, dynamic>>() ?? [];
  }

  Future<Map<String, dynamic>> toggleFavorite(String shopId) =>
      post('/customer/favorites/$shopId/toggle');

  // =========================================================================
  // VENDOR MACHINES
  // =========================================================================

  Future<List<Map<String, dynamic>>> getVendorMachines() async {
    final data = await get('/vendor/machines');
    return (data['data'] as List?)?.cast<Map<String, dynamic>>() ?? [];
  }

  // =========================================================================
  // SEARCH
  // =========================================================================

  Future<List<Map<String, dynamic>>> searchShops(String query) async {
    final data = await get('/search', query: {'q': query});
    return (data['data'] as List?)?.cast<Map<String, dynamic>>() ?? [];
  }

  // =========================================================================
  // CART / CHECKOUT
  // =========================================================================

  Future<Map<String, dynamic>> getDeliveryFee(String shopId, String address) =>
      post('/checkout/delivery-fee', body: {'shop_id': shopId, 'address': address});

  Future<Map<String, dynamic>> createPaymentIntent(Map<String, dynamic> body) =>
      post('/checkout/payment-intent', body: body);
}

// Global singleton
final api = ApiService.instance;
