import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/station_model.dart';
import '../services/api_service.dart';

class FleetProvider with ChangeNotifier {
  List<StationModel> _stations = [];
  bool _isLoading = false;

  List<StationModel> get stations => _stations;
  bool get isLoading => _isLoading;

  Future<void> fetchStations() async {
    _isLoading = true;
    notifyListeners();

    try {
      final res = await ApiService.getStations();
      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        _stations = data.map((json) => StationModel.fromJson(json)).toList();
      }
    } catch (e) {
      debugPrint("Fetch stations error: $e");
    }

    _isLoading = false;
    notifyListeners();
  }
}
