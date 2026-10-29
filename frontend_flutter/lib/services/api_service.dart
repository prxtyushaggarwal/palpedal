import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // Configurable base URL: 10.0.2.2 for Android emulator, localhost for web/desktop, or custom LAN IP
  static const String baseUrl = 'http://10.0.2.2:8000/api';

  static Map<String, String> getHeaders({String? token}) {
    final Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Token $token';
    }
    return headers;
  }

  // Auth
  static Future<http.Response> login(String username, String password) async {
    final url = Uri.parse('$baseUrl/auth/login/');
    return await http.post(
      url,
      headers: getHeaders(),
      body: jsonEncode({'username': username, 'password': password}),
    );
  }

  static Future<http.Response> register({
    required String username,
    required String email,
    required String password,
    String? firstName,
    String? lastName,
  }) async {
    final url = Uri.parse('$baseUrl/auth/register/');
    return await http.post(
      url,
      headers: getHeaders(),
      body: jsonEncode({
        'username': username,
        'email': email,
        'password': password,
        'first_name': firstName ?? '',
        'last_name': lastName ?? '',
      }),
    );
  }

  // Fleet
  static Future<http.Response> getStations() async {
    final url = Uri.parse('$baseUrl/stations/');
    return await http.get(url, headers: getHeaders());
  }

  // Wallet
  static Future<http.Response> getWallet(String token) async {
    final url = Uri.parse('$baseUrl/wallet/');
    return await http.get(url, headers: getHeaders(token: token));
  }

  static Future<http.Response> topUpWallet(String token, double amount) async {
    final url = Uri.parse('$baseUrl/wallet/topup/');
    return await http.post(
      url,
      headers: getHeaders(token: token),
      body: jsonEncode({
        'amount': amount,
        'payment_method': 'In-App Payment / UPI'
      }),
    );
  }

  // Rides
  static Future<http.Response> startRide(String token, String qrCode) async {
    final url = Uri.parse('$baseUrl/rides/start/');
    return await http.post(
      url,
      headers: getHeaders(token: token),
      body: jsonEncode({'qr_code': qrCode}),
    );
  }

  static Future<http.Response> endRide(String token, String rideId, String endStationId) async {
    final url = Uri.parse('$baseUrl/rides/end/');
    return await http.post(
      url,
      headers: getHeaders(token: token),
      body: jsonEncode({'ride_id': rideId, 'end_station_id': endStationId}),
    );
  }

  static Future<http.Response> getActiveRide(String token) async {
    final url = Uri.parse('$baseUrl/rides/active/');
    return await http.get(url, headers: getHeaders(token: token));
  }

  static Future<http.Response> getRideHistory(String token) async {
    final url = Uri.parse('$baseUrl/rides/history/');
    return await http.get(url, headers: getHeaders(token: token));
  }
}
