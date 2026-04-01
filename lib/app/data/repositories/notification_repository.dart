import '../providers/firebase_provider.dart';
import '../models/notification_model.dart';

class NotificationRepository {
  final FirebaseProvider _provider = FirebaseProvider();

  Future<List<NotificationModel>> getNotifications(String userId) async {
    final snapshot = await _provider.firestore.collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = data['id'] ?? doc.id;
      return NotificationModel.fromJson(data);
    }).toList();
  }

  Future<void> markAsRead(String id) async {
    await _provider.firestore.collection('notifications').doc(id).update({'isRead': true});
  }

  Future<void> markAllAsRead(String userId) async {
    final snapshot = await _provider.firestore.collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();
    if (snapshot.docs.isEmpty) return;
    final batch = _provider.firestore.batch();
    for (var doc in snapshot.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  Future<int> getUnreadCount(String userId) async {
    final snapshot = await _provider.firestore.collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();
    return snapshot.docs.length;
  }

  Future<void> createNotification(NotificationModel notification) async {
    await _provider.firestore.collection('notifications').doc(notification.id).set(notification.toJson());
  }
}