import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/ride_model.dart';
import '../services/api_service.dart';

class RideProvider with ChangeNotifier {
  RideModel? _activeRide;
  List<RideModel> _history = [];
  bool _isLoading = false;
  String? _errorMessage;

  RideModel? get activeRide => _activeRide;
  List<RideModel> get history => _history;
  bool get hasActiveRide => _activeRide != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> checkActiveRide(String token) async {
    try {
      final res = await ApiService.getActiveRide(token);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['active_ride'] != null) {
          _activeRide = RideModel.fromJson(data['active_ride']);
        } else {
          _activeRide = null;
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Active ride check error: $e");
    }
  }

  Future<bool> startRide(String token, String qrCode) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await ApiService.startRide(token, qrCode);
      final data = jsonDecode(res.body);

      if (res.statusCode == 201) {
        _activeRide = RideModel.fromJson(data['ride']);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = data['error'] ?? 'Failed to unlock cycle';
      }
    } catch (e) {
      _errorMessage = 'Network error: $e';
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> endRide(String token, String endStationId) async {
    if (_activeRide == null) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await ApiService.endRide(token, _activeRide!.id, endStationId);
      final data = jsonDecode(res.body);

      if (res.statusCode == 200) {
        _activeRide = null;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = data['error'] ?? 'Failed to end ride';
      }
    } catch (e) {
      _errorMessage = 'Network error: $e';
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<void> fetchHistory(String token) async {
    try {
      final res = await ApiService.getRideHistory(token);
      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        _history = data.map((json) => RideModel.fromJson(json)).toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Fetch history error: $e");
    }
  }
}
