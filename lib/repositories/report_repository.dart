import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/report_model.dart';
import '../core/constants/firestore_paths.dart';

class ReportRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _reportsRef => _firestore.collection(FirestorePaths.reports);

  Future<void> createReport(ReportModel report) async {
    await _reportsRef.add(report.toFirestore());
  }

  Stream<List<ReportModel>> getReports({String? status}) {
    Query query = _reportsRef;
    if (status != null) {
      query = query.where('status', isEqualTo: status);
    }
    return query.snapshots().map((snapshot) {
      final reports = snapshot.docs
          .map((doc) => ReportModel.fromFirestore(doc))
          .toList();
      
      // In-memory sorting as per admin panel insight to avoid missing reports with missing timestamp
      reports.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return reports;
    });
  }

  Future<void> resolveReport(String reportId, String adminId) async {
    await _reportsRef.doc(reportId).update({
      'status': 'resolved',
      'resolvedBy': adminId,
      'resolvedAt': Timestamp.fromDate(DateTime.now()),
    });
  }
}
