import 'dart:typed_data';
import 'dart:convert';
import 'dart:io' show File;

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:apotek/model/obat.dart';
import 'package:apotek/model/user.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  final String _baseUrl = 'http://127.0.0.1:8000';

  // TOKEN MANAGEMENT
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  Future<void> _removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }

  Future<List<Obat>> fetchData() async {
    final uri = Uri.parse('$_baseUrl/api/obat/');
    final token = await _getToken();
    if (token == null) return [];

    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> body = json.decode(response.body);
      final List list = body['data'] ?? [];
      return list.map((json) => Obat.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load items: ${response.statusCode}');
    }
  }

  /// Create a new Obat.
  /// Supports web by sending bytes and mobile by sending file from path.
  Future<bool> createObat({
    required String name,
    required String description,
    required int price,
    required int stock,
    XFile? image,
    Uint8List? imageBytes,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/api/obat/');
      final token = await _getToken();

      final request = http.MultipartRequest('POST', uri);
      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });
      request.fields['name'] = name;
      request.fields['description'] = description;
      request.fields['price'] = price.toString();
      request.fields['stock'] = stock.toString();

      // Attach image: prefer bytes (web) else file (mobile)
      if (imageBytes != null) {
        final filename = image?.name ?? 'upload.jpg';
        // send bytes without explicit contentType (server will infer)
        request.files.add(
          http.MultipartFile.fromBytes('image', imageBytes, filename: filename),
        );
      } else if (image != null && !kIsWeb) {
        final file = File(image.path);
        final filename =
            image.name.isNotEmpty ? image.name : image.path.split('/').last;
        // send file from path without explicit contentType
        request.files.add(
          await http.MultipartFile.fromPath(
            'image',
            file.path,
            filename: filename,
          ),
        );
      }

      final streamed = await request.send();
      final resp = await http.Response.fromStream(streamed);

      return resp.statusCode == 201 || resp.statusCode == 200;
    } catch (e) {
      // print('Error creating Obat: $e');
      return false;
    }
  }

  Future<bool> deleteObat(int id) async {
    final uri = Uri.parse('$_baseUrl/api/obat/$id/');
    final token = await _getToken();

    final response = await http.delete(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    return response.statusCode == 204 || response.statusCode == 200;
  }

  Future<bool> updateObat({
    required int id,
    required String name,
    required String description,
    required int price,
    required int stock,
    XFile? image,
    Uint8List? imageBytes,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/api/obat/$id/');
      final token = await _getToken();
      // Gunakan POST dengan _method=PUT untuk support multipart di Laravel
      final request = http.MultipartRequest('POST', uri);

      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });

      request.fields['_method'] = 'PUT';
      request.fields['name'] = name;
      request.fields['description'] = description;
      request.fields['price'] = price.toString();
      request.fields['stock'] = stock.toString();

      if (imageBytes != null) {
        final filename = image?.name ?? 'update.jpg';
        request.files.add(
          http.MultipartFile.fromBytes('image', imageBytes, filename: filename),
        );
      } else if (image != null && !kIsWeb) {
        final file = File(image.path);
        final filename =
            image.name.isNotEmpty ? image.name : image.path.split('/').last;
        request.files.add(
          await http.MultipartFile.fromPath(
            'image',
            file.path,
            filename: filename,
          ),
        );
      }

      final streamed = await request.send();
      final resp = await http.Response.fromStream(streamed);
      return resp.statusCode == 200;
    } catch (e) {
      print('Error updating Obat: $e');
      return false;
    }
  }

  // ---------------------------------------------------------------
  // USER LOGIN
  // ---------------------------------------------------------------
  Future<bool> registerUser(User user) async {
    final url = Uri.parse('$_baseUrl/api/register');
    try {
      final resp = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(user.toJson()),
      );

      if (resp.statusCode == 201 || resp.statusCode == 200) {
        final Map<String, dynamic> body = json.decode(resp.body);
        final token = body['data']['token'];
        if (token != null) {
          await _saveToken(token);
        }
        return true;
      } else {
        return false;
      }
    } catch (e) {
      print('Error registering user: $e');
      return false;
    }
  }

  Future<bool> loginUser(String email, String password) async {
    final url = Uri.parse('$_baseUrl/api/login');
    try {
      final resp = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (resp.statusCode == 200) {
        final Map<String, dynamic> body = json.decode(resp.body);
        print('Login response body: $body');
        final token = body['data']['token'];
        print('Received token: $token');
        if (token != null) {
          await _saveToken(token);
        }
        return true;
      } else {
        return false;
      }
    } catch (e) {
      print('Error logging in user: $e');
      return false;
    }
  }

  Future<bool> logoutUser() async {
    final url = Uri.parse('$_baseUrl/api/logout');
    try {
      final token = await _getToken();
      if (token == null) return false;

      final resp = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (resp.statusCode == 200) {
        await _removeToken();
        return true;
      } else {
        return false;
      }
    } catch (e) {
      print('Error logging out user: $e');
      return false;
    }
  }

  // User Get Profile
  Future<UserProfile?> getUserProfile() async {
    final url = Uri.parse('$_baseUrl/api/profile');
    try {
      final token = await _getToken();
      if (token == null) return null;

      final resp = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (resp.statusCode == 200) {
        final Map<String, dynamic> body = json.decode(resp.body);
        print('User profile response body: $body');
        return UserProfile.fromJson(body['data']);
      } else {
        return null;
      }
    } catch (e) {
      print('Error fetching user profile: $e');
      return null;
    }
  }

  // -----------------------------
  // ORDERS
  // -----------------------------
  /// Create an order with multiple items.
  /// items: List of maps {"obat_id": id, "quantity": qty}
  /// Create order and return detailed result map for better error handling.
  /// Returns {"success": bool, "statusCode": int, "body": dynamic, "message": String?}
  Future<Map<String, dynamic>> createOrder({
    required List<Map<String, dynamic>> items,
    String? shippingAddress,
    String? paymentMethod,
    Map<String, dynamic>? paymentDetails,
  }) async {
    final url = Uri.parse('$_baseUrl/api/orders');
    try {
      final token = await _getToken();
      if (token == null) return {"success": false, "statusCode": 401, "body": null, "message": "Unauthenticated"};

      Map<String, dynamic> body;

      // Always include modern 'items' array
      body = {
        'items': items,
        if (shippingAddress != null) 'shipping_address': shippingAddress,
        if (paymentMethod != null) 'payment_method': paymentMethod,
        if (paymentDetails != null) 'payment_details': paymentDetails,
      };

      // Backward compatible: if single item, also include top-level obat_id & quantity
      if (items.length == 1) {
        final single = items.first;
        if (single.containsKey('obat_id')) body['obat_id'] = single['obat_id'];
        if (single.containsKey('quantity')) body['quantity'] = single['quantity'];
      }

      // Log payload for debugging
      print('Create order payload: ${jsonEncode(body)}');

      final resp = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      dynamic parsed;
      try {
        parsed = json.decode(resp.body);
      } catch (_) {
        parsed = resp.body;
      }

      final success = resp.statusCode == 201 || resp.statusCode == 200;
      if (!success) {
        print('Create order failed: status=${resp.statusCode} body=${resp.body}');
      }

      // Additional debug log
      print('Create order response: status=${resp.statusCode} parsed=$parsed');

      return {"success": success, "statusCode": resp.statusCode, "body": parsed, "message": success ? null : parsed.toString()};
    } catch (e) {
      print('Error creating order: $e');
      return {"success": false, "statusCode": 500, "body": null, "message": e.toString()};
    }
  }

  /// Get list of orders for current user
  Future<List<dynamic>> getOrders() async {
    final url = Uri.parse('$_baseUrl/api/orders');
    final token = await _getToken();
    if (token == null) return [];

    try {
      final resp = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (resp.statusCode == 200) {
        final Map<String, dynamic> body = json.decode(resp.body);
        return body['data'] ?? [];
      }
      return [];
    } catch (e) {
      print('Error fetching orders: $e');
      return [];
    }
  }

  /// Attempt to get all orders (for admin/cashier). Tries '/api/orders/all' then falls back to '/api/orders'.
  Future<List<dynamic>> getAllOrders() async {
    final token = await _getToken();
    if (token == null) return [];

    final tryUrls = [
      Uri.parse('$_baseUrl/api/orders/all'),
      Uri.parse('$_baseUrl/api/orders'),
    ];

    for (final uri in tryUrls) {
      try {
        final resp = await http.get(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );

        if (resp.statusCode == 200) {
          final Map<String, dynamic> body = json.decode(resp.body);
          return body['data'] ?? [];
        }
      } catch (e) {
        // try next
      }
    }

    return [];
  }

  /// Get single order by id
  Future<Map<String, dynamic>?> getOrderById(int id) async {
    final url = Uri.parse('$_baseUrl/api/orders/$id');
    final token = await _getToken();
    if (token == null) return null;

    try {
      final resp = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (resp.statusCode == 200) {
        return json.decode(resp.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('Error fetching order $id: $e');
      return null;
    }
  }

  /// Get current authenticated user (may include role)
  Future<Map<String, dynamic>?> getCurrentUser() async {
    final url = Uri.parse('$_baseUrl/api/user');
    final token = await _getToken();
    if (token == null) return null;

    try {
      final resp = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (resp.statusCode == 200) {
        return json.decode(resp.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('Error fetching current user: $e');
      return null;
    }
  }

  /// Cashier confirm payment
  Future<bool> confirmPayment(int orderId) async {
    final url = Uri.parse('$_baseUrl/api/orders/$orderId/confirm-payment');
    final token = await _getToken();
    if (token == null) return false;

    try {
      final resp = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return resp.statusCode == 200;
    } catch (e) {
      print('Error confirming payment: $e');
      return false;
    }
  }

  /// Notify payment (owner or cashier) with simple JSON details. File upload not implemented here.
  /// Notify payment. If [image] or [imageBytes] provided, sends multipart/form-data with file field 'proof'.
  Future<bool> notifyPayment(int orderId, {String? paymentMethod, Map<String, dynamic>? paymentDetails, XFile? image, Uint8List? imageBytes}) async {
    final url = Uri.parse('$_baseUrl/api/orders/$orderId/notify-payment');
    final token = await _getToken();
    if (token == null) return false;

    // If image provided, use multipart
    if (image != null || imageBytes != null) {
      try {
        final req = http.MultipartRequest('POST', url);
        req.headers.addAll({
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        });

        if (paymentMethod != null) req.fields['payment_method'] = paymentMethod;
        if (paymentDetails != null) req.fields['payment_details'] = jsonEncode(paymentDetails);

        if (imageBytes != null) {
          final filename = image?.name ?? 'payment_proof.jpg';
          req.files.add(http.MultipartFile.fromBytes('payment_proof', imageBytes, filename: filename));
        } else if (image != null && !kIsWeb) {
          final file = File(image.path);
          final filename = image.name.isNotEmpty ? image.name : image.path.split('/').last;
          req.files.add(await http.MultipartFile.fromPath('payment_proof', file.path, filename: filename));
        } else if (image != null && kIsWeb) {
          // On web, imageBytes should be provided; fallback to name only (no bytes)
          // This may not work; prefer passing imageBytes when on web.
        }

        final streamed = await req.send();
        final resp = await http.Response.fromStream(streamed);
        return resp.statusCode == 200;
      } catch (e) {
        print('Error notifying payment with file: $e');
        return false;
      }
    }

    // Otherwise send JSON
    final body = {
      if (paymentMethod != null) 'payment_method': paymentMethod,
      if (paymentDetails != null) 'payment_details': paymentDetails,
    };

    try {
      final resp = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      return resp.statusCode == 200;
    } catch (e) {
      print('Error notifying payment: $e');
      return false;
    }
  }

  /// Cancel order (owner only)
  Future<bool> cancelOrder(int orderId) async {
    final url = Uri.parse('$_baseUrl/api/orders/$orderId/cancel');
    final token = await _getToken();
    if (token == null) return false;

    try {
      final resp = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return resp.statusCode == 200;
    } catch (e) {
      print('Error cancelling order: $e');
      return false;
    }
  }

  // =====================================================
  // CASHIER API ENDPOINTS
  // =====================================================

  /// [Cashier] Get all orders with optional filters
  /// Params: status, payment_status, user_id, per_page
  Future<Map<String, dynamic>> getCashierOrders({
    String? status,
    String? paymentStatus,
    int? userId,
    int? perPage,
    int? page,
  }) async {
    final token = await _getToken();
    if (token == null) return {'success': false, 'data': [], 'meta': null};

    final queryParams = <String, String>{};
    if (status != null) queryParams['status'] = status;
    if (paymentStatus != null) queryParams['payment_status'] = paymentStatus;
    if (userId != null) queryParams['user_id'] = userId.toString();
    if (perPage != null) queryParams['per_page'] = perPage.toString();
    if (page != null) queryParams['page'] = page.toString();

    final uri = Uri.parse('$_baseUrl/api/cashier/orders').replace(queryParameters: queryParams.isEmpty ? null : queryParams);

    try {
      final resp = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (resp.statusCode == 200) {
        final body = json.decode(resp.body);
        return {
          'success': true,
          'data': body['data'] ?? [],
          'meta': body['meta'],
        };
      }
      return {'success': false, 'data': [], 'meta': null};
    } catch (e) {
      print('Error fetching cashier orders: $e');
      return {'success': false, 'data': [], 'meta': null};
    }
  }

  /// [Cashier] Get pending payments list
  Future<List<dynamic>> getCashierPendingPayments() async {
    final url = Uri.parse('$_baseUrl/api/cashier/orders/pending-payments');
    final token = await _getToken();
    if (token == null) return [];

    try {
      final resp = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (resp.statusCode == 200) {
        final body = json.decode(resp.body);
        return body['data'] ?? [];
      }
      return [];
    } catch (e) {
      print('Error fetching pending payments: $e');
      return [];
    }
  }

  /// [Cashier] Get order detail by id (includes user info)
  Future<Map<String, dynamic>?> getCashierOrderById(int id) async {
    final url = Uri.parse('$_baseUrl/api/cashier/orders/$id');
    final token = await _getToken();
    if (token == null) return null;

    try {
      final resp = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (resp.statusCode == 200) {
        return json.decode(resp.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('Error fetching cashier order $id: $e');
      return null;
    }
  }

  /// [Cashier] Confirm payment for an order
  /// Returns { success: bool, statusCode: int, body: dynamic, message: String? }
  Future<Map<String, dynamic>> confirmPaymentCashier(int orderId) async {
    final url = Uri.parse('$_baseUrl/api/cashier/orders/$orderId/confirm-payment');
    final token = await _getToken();
    if (token == null) return {'success': false, 'statusCode': 401, 'body': null, 'message': 'Unauthenticated'};

    try {
      final resp = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      dynamic parsed;
      try {
        parsed = json.decode(resp.body);
      } catch (_) {
        parsed = resp.body;
      }

      final success = resp.statusCode == 200;
      return {'success': success, 'statusCode': resp.statusCode, 'body': parsed, 'message': success ? null : parsed.toString()};
    } catch (e) {
      print('Error confirming payment (cashier): $e');
      return {'success': false, 'statusCode': 500, 'body': null, 'message': e.toString()};
    }
  }
}
