import 'package:cloud_firestore/cloud_firestore.dart';

class TimestampUtils {
  static DateTime toDateTime(Timestamp? timestamp) {
    return timestamp?.toDate() ?? DateTime.now();
  }

  static Timestamp fromDateTime(DateTime? dateTime) {
    return Timestamp.fromDate(dateTime ?? DateTime.now());
  }
}
