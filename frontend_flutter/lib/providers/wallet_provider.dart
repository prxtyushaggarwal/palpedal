import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/wallet_model.dart';
import '../services/api_service.dart';

class WalletProvider with ChangeNotifier {
  WalletModel? _wallet;
  bool _isLoading = false;

  WalletModel? get wallet => _wallet;
  double get balance => _wallet?.balance ?? 0.0;
  List<WalletTransactionModel> get transactions => _wallet?.transactions ?? [];
  bool get isLoading => _isLoading;

  Future<void> fetchWallet(String token) async {
    _isLoading = true;
    notifyListeners();

    try {
      final res = await ApiService.getWallet(token);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        _wallet = WalletModel.fromJson(data);
      }
    } catch (e) {
      debugPrint("Fetch wallet error: $e");
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> topUp(String token, double amount) async {
    _isLoading = true;
    notifyListeners();

    try {
      final res = await ApiService.topUpWallet(token, amount);
      if (res.statusCode == 200) {
        await fetchWallet(token);
        return true;
      }
    } catch (e) {
      debugPrint("Top-up error: $e");
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }
}
