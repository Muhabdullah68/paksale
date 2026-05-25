import 'package:flutter/material.dart';
import '../models/report_model.dart';
import '../repositories/report_repository.dart';
import '../repositories/product_repository.dart';
import '../repositories/user_repository.dart';

class ReportProvider extends ChangeNotifier {
  final ReportRepository _reportRepo = ReportRepository();
  final ProductRepository _productRepo = ProductRepository();
  final UserRepository _userRepo = UserRepository();
  
  List<ReportModel> _reports = [];
  bool _isLoading = false;

  List<ReportModel> get reports => _reports;
  bool get isLoading => _isLoading;

  void listenToReports({String? status}) {
    _isLoading = true;
    notifyListeners();
    _reportRepo.getReports(status: status).listen((reports) {
      _reports = reports;
      _isLoading = false;
      notifyListeners();
    });
  }

  Future<void> submitReport(ReportModel report) async {
    try {
      await _reportRepo.createReport(report);
    } catch (e) {
      debugPrint('Error submitting report: $e');
      if (e.toString().contains('suspended')) {
        throw Exception('Report service is currently unavailable due to project suspension.');
      }
      rethrow;
    }
  }

  Future<void> resolveReport(String reportId, String adminId) async {
    try {
      await _reportRepo.resolveReport(reportId, adminId);
    } catch (e) {
      debugPrint('Error resolving report: $e');
      rethrow;
    }
  }

  Future<void> blockProduct(String productId) async {
    try {
      await _productRepo.blockProduct(productId, true);
    } catch (e) {
      debugPrint('Error blocking product: $e');
      rethrow;
    }
  }

  Future<void> suspendUser(String userId) async {
    try {
      await _userRepo.suspendUser(userId, true);
    } catch (e) {
      debugPrint('Error suspending user: $e');
      rethrow;
    }
  }
}
