import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class FirebaseProvider {
  static final FirebaseProvider _instance = FirebaseProvider._internal();
  factory FirebaseProvider() => _instance;
  FirebaseProvider._internal();

  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseStorage storage = FirebaseStorage.instance;

  Future<String> generateInviteCode() async {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    
    for (int i = 0; i < 5; i++) {
      final code = String.fromCharCodes(Iterable.generate(
          6, (_) => chars.codeUnitAt(random.nextInt(chars.length))));
      
      final schoolDoc = await firestore.collection('schools').where('schoolCode', isEqualTo: code).get();
      final teamDoc = await firestore.collection('teams').where('teamCode', isEqualTo: code).get();
      
      if (schoolDoc.docs.isEmpty && teamDoc.docs.isEmpty) {
        return code;
      }
    }
    throw Exception('Failed to generate unique invite code after 5 attempts');
  }
}