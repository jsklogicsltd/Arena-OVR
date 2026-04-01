import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/firebase_provider.dart';
import '../models/user_model.dart';

class AuthRepository {
  final FirebaseProvider _provider = FirebaseProvider();

  Future<UserCredential> signUp(String email, String password) async {
    return await _provider.auth.createUserWithEmailAndPassword(email: email, password: password);
  }

  Future<UserCredential> signIn(String email, String password) async {
    return await _provider.auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> signOut() async {
    await _provider.auth.signOut();
  }

  Future<void> resetPassword(String email) async {
    await _provider.auth.sendPasswordResetEmail(email: email);
  }

  Future<void> deleteAccount() async {
    await _provider.auth.currentUser?.delete();
  }

  User? getCurrentUser() {
    return _provider.auth.currentUser;
  }

  Future<void> updateProfile(String uid, Map<String, dynamic> data) async {
    await _provider.firestore.collection('users').doc(uid).update(data);
  }

  Future<String> uploadProfilePic(String uid, File imageFile) async {
    final ref = _provider.storage.ref().child('profile_pics').child('$uid.jpg');
    final uploadTask = await ref.putFile(imageFile);
    final url = await uploadTask.ref.getDownloadURL();
    
    final userDoc = await _provider.firestore.collection('users').doc(uid).get();
    if (userDoc.exists && userDoc.data() != null) {
      final userData = userDoc.data()!;
      if (userData['hasUploadedPic'] != true) {
        List<dynamic> badges = userData['badges'] ?? [];
        if (!badges.contains('First Step')) {
          badges.add('First Step');
        }
        
        Map<String, dynamic> rating = userData['currentRating'] != null 
          ? Map<String, dynamic>.from(userData['currentRating']) 
          : {};
        
        rating['Standard'] = (rating['Standard'] ?? 0) + 1.0;

        await _provider.firestore.collection('users').doc(uid).update({
          'profilePicUrl': url,
          'hasUploadedPic': true,
          'badges': badges,
          'currentRating': rating,
        });

        if (userData['teamId'] != null) {
           final teamDoc = await _provider.firestore.collection('teams').doc(userData['teamId']).get();
           String? seasonId;
           if (teamDoc.exists && teamDoc.data() != null) {
             seasonId = teamDoc.data()!['currentSeasonId'];
           }
           
           final txRef = _provider.firestore.collection('transactions').doc();
           await txRef.set({
             'id': txRef.id,
             'athleteId': uid,
             'teamId': userData['teamId'],
             'seasonId': seasonId,
             'awardedBy': 'SYSTEM',
             'category': 'Standard',
             'value': 1,
             'note': 'Profile picture uploaded.',
             'createdAt': FieldValue.serverTimestamp(),
             'isArchived': false,
           });
           
           final feedRef = _provider.firestore.collection('feed').doc();
           await feedRef.set({
              'id': feedRef.id,
              'teamId': userData['teamId'],
              'type': 'RATING',
              'title': '+1 Standard',
              'content': 'Earned the First Step badge for uploading a profile picture.',
              'targetId': uid,
              'createdAt': FieldValue.serverTimestamp(),
           });
        }
      } else {
        await _provider.firestore.collection('users').doc(uid).update({
          'profilePicUrl': url,
        });
      }
    }
    return url;
  }

  Future<void> updateFcmToken(String uid, String token) async {
    await _provider.firestore.collection('users').doc(uid).update({'fcmToken': token});
  }

  Stream<UserModel?> userStream(String uid) {
    return _provider.firestore.collection('users').doc(uid).snapshots().map((doc) {
      if (doc.exists && doc.data() != null) return UserModel.fromJson(doc.data()!);
      return null;
    });
  }
}