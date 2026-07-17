import 'package:cloud_firestore/cloud_firestore.dart';

class TimestampUtils {
  static DateTime toDateTime(Timestamp? timestamp) {
    return timestamp?.toDate() ?? DateTime.now();
  }

  static Timestamp fromDateTime(DateTime? dateTime) {
    return Timestamp.fromDate(dateTime ?? DateTime.now());
  }

  static String timeAgo(dynamic timestamp) {
    DateTime date;
    if (timestamp is Timestamp) {
      date = timestamp.toDate();
    } else if (timestamp is DateTime) {
      date = timestamp;
    } else {
      return '';
    }

    final difference = DateTime.now().difference(date);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()}y ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()}mo ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
