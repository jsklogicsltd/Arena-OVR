import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/school_model.dart';

class SchoolRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<SchoolModel?> validateInviteCode(String code) async {
    final query = await _firestore
        .collection('schools')
        .where('inviteCode', isEqualTo: code.toUpperCase())
        .limit(1)
        .get();

    if (query.docs.isEmpty) {
      return null;
    }
    return SchoolModel.fromJson(query.docs.first.data());
  }

  Stream<List<SchoolModel>> getSchoolsStream() {
    return _firestore
        .collection('schools')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) {
            // Ensure model id always matches document id (even for older docs).
            final data = Map<String, dynamic>.from(doc.data());
            data['id'] = doc.id;
            return SchoolModel.fromJson(data);
          })
          .toList();
    });
  }

  Future<void> createSchool(SchoolModel school) async {
    await _firestore.collection('schools').doc(school.id).set(school.toJson());
  }

  Future<void> updateSchoolStatus(String schoolId, bool isActive) async {
    await _firestore.collection('schools').doc(schoolId).update({'isActive': isActive});
  }
}