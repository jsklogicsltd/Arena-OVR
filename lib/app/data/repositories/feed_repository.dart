import '../providers/firebase_provider.dart';
import '../models/feed_model.dart';

class FeedRepository {
  final FirebaseProvider _provider = FirebaseProvider();

  Future<List<FeedModel>> getFeed(String teamId) async {
    final snapshot = await _provider.firestore.collection('feeds')
        .where('teamId', isEqualTo: teamId)
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs.map((doc) => FeedModel.fromJson(doc.data())).toList();
  }

  Future<void> createAnnouncement(FeedModel feed) async {
    await _provider.firestore.collection('feeds').doc(feed.id).set(feed.toJson());
  }

  Future<void> addFeedEntry(FeedModel feed) async {
    await _provider.firestore.collection('feeds').doc(feed.id).set(feed.toJson());
  }
}