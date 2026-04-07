import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../../data/models/school_model.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/school_repository.dart';
import '../../core/utils/code_generator.dart';
import '../../routes/app_routes.dart';
import '../../core/services/account_deletion_service.dart';

class AdminController extends GetxController {
  final SchoolRepository _schoolRepo = SchoolRepository();
  final _firestore = FirebaseFirestore.instance;

  // Observables
  final _schoolsData = <SchoolModel>[].obs;
  List<SchoolModel> get schools => _schoolsData;

  final isLoading = true.obs;

  // Real-time user lists
  final allCoaches = <UserModel>[].obs;
  final allAthletes = <UserModel>[].obs;
  final List<StreamSubscription> _coachesSubs = [];
  final List<StreamSubscription> _athletesSubs = [];
  final Map<int, List<UserModel>> _coachesByChunk = {};
  final Map<int, List<UserModel>> _athletesByChunk = {};
  StreamSubscription? _schoolsSub;

  int get totalSchools => _schoolsData.length;
  int get totalCoaches => allCoaches.length;
  int get totalAthletes => allAthletes.length;

  // Form Controllers for Create School
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final expiryDate = Rx<DateTime?>(
    DateTime.now().add(const Duration(days: 365)),
  );

  final isCreating = false.obs;

  // Profile Observables
  final adminName = ''.obs;
  final adminEmail = ''.obs;
  final adminPhotoUrl = ''.obs;
  final isUpdatingPhoto = false.obs;
  final isUpdatingName = false.obs;

  // Image Picker
  final selectedSchoolLogo = Rxn<File>();
  final ImagePicker _picker = ImagePicker();

  // Generated Code State
  final generatedSchoolCode = ''.obs;

  @override
  void onInit() {
    super.onInit();
    generatedSchoolCode.value = '';
    loadSchools();
    _loadAdminProfile();
  }

  Future<void> _loadAdminProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      adminEmail.value = user.email ?? 'admin@scoreboardovr.com';
      adminPhotoUrl.value = user.photoURL ?? '';
      try {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (doc.exists) {
          final data = doc.data();
          adminName.value = data?['name'] ?? 'Super Admin';
          if (data?.containsKey('email') == true && data!['email'] != null) {
            adminEmail.value = data['email'];
          }
          final pic = data?['profilePicUrl'] as String?;
          if (pic != null && pic.isNotEmpty) {
            adminPhotoUrl.value = pic;
          }
        } else {
          adminName.value = 'Super Admin';
        }
      } catch (e) {
        adminName.value = 'Super Admin';
      }
    }
  }

  /// Pick image from gallery and set as admin avatar. Uploads to Storage and updates Firestore.
  Future<void> updateAdminPhoto() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      Get.snackbar('Error', 'Not signed in',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withValues(alpha: 0.8),
          colorText: Colors.white);
      return;
    }
    try {
      final XFile? picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 600,
      );
      if (picked == null) return;
      final file = File(picked.path);
      isUpdatingPhoto.value = true;
      final ref = FirebaseStorage.instance.ref().child('profile_pics').child('${user.uid}.jpg');
      await ref.putFile(file);
      final url = await ref.getDownloadURL();
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({'profilePicUrl': url});
      adminPhotoUrl.value = url;
      Get.snackbar('Done', 'Profile photo updated',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.withValues(alpha: 0.8),
          colorText: Colors.white);
    } catch (e) {
      Get.snackbar('Error', 'Failed to update photo: ${e.toString()}',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withValues(alpha: 0.8),
          colorText: Colors.white);
    } finally {
      isUpdatingPhoto.value = false;
    }
  }

  Future<void> updateAdminName(String rawName) async {
    final user = FirebaseAuth.instance.currentUser;
    final name = rawName.trim();
    if (user == null) {
      Get.snackbar('Error', 'Not signed in',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withValues(alpha: 0.8),
          colorText: Colors.white);
      return;
    }
    if (name.isEmpty) {
      Get.snackbar('Error', 'Name cannot be empty',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withValues(alpha: 0.8),
          colorText: Colors.white);
      return;
    }

    try {
      isUpdatingName.value = true;
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({'name': name});
      await user.updateDisplayName(name);
      adminName.value = name;
      Get.snackbar('Done', 'Name updated',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.withValues(alpha: 0.8),
          colorText: Colors.white);
    } catch (e) {
      Get.snackbar('Error', 'Failed to update name: ${e.toString()}',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withValues(alpha: 0.8),
          colorText: Colors.white);
    } finally {
      isUpdatingName.value = false;
    }
  }

  void loadSchools() {
    isLoading.value = true;
    _schoolsSub?.cancel();
    _schoolsSub = _schoolRepo.getSchoolsStream().listen((data) {
      _schoolsData.value = data;
      isLoading.value = false;
      final ids = data.map((s) => s.id).toList();
      _subscribeToUsers(ids);
    });
  }

  void _subscribeToUsers(List<String> schoolIds) {
    // Reset previous role subscriptions before wiring fresh streams.
    for (final s in _coachesSubs) {
      s.cancel();
    }
    for (final s in _athletesSubs) {
      s.cancel();
    }
    _coachesSubs.clear();
    _athletesSubs.clear();
    _coachesByChunk.clear();
    _athletesByChunk.clear();

    final ids = schoolIds.where((e) => e.trim().isNotEmpty).toList();
    if (ids.isEmpty) {
      allCoaches.clear();
      allAthletes.clear();
      return;
    }
    // Firestore whereIn supports up to 10 values, so we subscribe by chunks.
    for (int i = 0; i < ids.length; i += 10) {
      final chunkIndex = i ~/ 10;
      final chunkIds = ids.sublist(i, (i + 10) > ids.length ? ids.length : (i + 10));

      final coachSub = _firestore
          .collection('users')
          .where('role', whereIn: const ['coach', 'Head Coach', 'Assistant Coach'])
          .where('schoolId', whereIn: chunkIds)
          .snapshots()
          .listen((snap) {
        _coachesByChunk[chunkIndex] = snap.docs.map((d) {
          final data = Map<String, dynamic>.from(d.data());
          data['uid'] = d.id;
          return UserModel.fromJson(data);
        }).toList();
        final merged = <String, UserModel>{};
        for (final list in _coachesByChunk.values) {
          for (final u in list) {
            merged[u.uid] = u;
          }
        }
        allCoaches.value = merged.values.toList();
      });
      _coachesSubs.add(coachSub);

      final athleteSub = _firestore
          .collection('users')
          .where('role', isEqualTo: 'athlete')
          .where('schoolId', whereIn: chunkIds)
          .snapshots()
          .listen((snap) {
        _athletesByChunk[chunkIndex] = snap.docs.map((d) {
          final data = Map<String, dynamic>.from(d.data());
          data['uid'] = d.id;
          return UserModel.fromJson(data);
        }).toList();
        final merged = <String, UserModel>{};
        for (final list in _athletesByChunk.values) {
          for (final u in list) {
            merged[u.uid] = u;
          }
        }
        allAthletes.value = merged.values.toList();
      });
      _athletesSubs.add(athleteSub);
    }
  }

  @override
  void onClose() {
    _schoolsSub?.cancel();
    for (final s in _coachesSubs) {
      s.cancel();
    }
    for (final s in _athletesSubs) {
      s.cancel();
    }
    nameController.dispose();
    emailController.dispose();
    super.onClose();
  }

  Future<void> pickSchoolLogo() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
        maxWidth: 800,
      );
      if (image != null) {
        selectedSchoolLogo.value = File(image.path);
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to pick image: $e',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withValues(alpha: 0.8),
          colorText: Colors.white);
    }
  }

  Future<void> createSchool() async {
    final name = nameController.text.trim();
    final email = emailController.text.trim();

    if (name.isEmpty || email.isEmpty || expiryDate.value == null) {
      Get.snackbar(
        'Error',
        'Please fill all details.',
        backgroundColor: Colors.red.withValues(alpha: 0.8),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    isCreating.value = true;
    try {
      final code = CodeGenerator.generate(6);

      final docId = FirebaseFirestore.instance.collection('schools').doc().id;
      
      String? logoUrl;
      if (selectedSchoolLogo.value != null) {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('schools')
            .child(docId)
            .child('logo.jpg');
        
        await storageRef.putFile(selectedSchoolLogo.value!);
        logoUrl = await storageRef.getDownloadURL();
      }

      final school = SchoolModel(
        id: docId,
        name: name,
        email: email,
        inviteCode: code,
        isActive: true,
        expiryDate: expiryDate.value,
        createdAt: DateTime.now(),
        logoUrl: logoUrl,
      );

      await _schoolRepo.createSchool(school);

      nameController.clear();
      emailController.clear();
      selectedSchoolLogo.value = null;
      expiryDate.value = DateTime.now().add(const Duration(days: 365));

      generatedSchoolCode.value = code;
    } catch (e) {
      Get.snackbar(
        'Error',
        e.toString(),
        backgroundColor: Colors.red.withValues(alpha: 0.8),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isCreating.value = false;
    }
  }

  /// Resets Create School screen state so it can be used repeatedly.
  /// This controller is long-lived, so view state must be cleared manually.
  void resetCreateSchoolFlow() {
    isCreating.value = false;
    generatedSchoolCode.value = '';
    nameController.clear();
    emailController.clear();
    selectedSchoolLogo.value = null;
    expiryDate.value = DateTime.now().add(const Duration(days: 365));
  }

  Future<void> deleteSchool(SchoolModel school) async {
    try {
      final batch = _firestore.batch();

      final teamsSnap = await _firestore
          .collection('teams')
          .where('schoolId', isEqualTo: school.id)
          .get();
      for (final teamDoc in teamsSnap.docs) {
        batch.delete(teamDoc.reference);
      }

      final usersSnap = await _firestore
          .collection('users')
          .where('schoolId', isEqualTo: school.id)
          .get();
      for (final userDoc in usersSnap.docs) {
        batch.delete(userDoc.reference);
      }

      final seasonsSnap = await _firestore
          .collection('seasons')
          .where('schoolId', isEqualTo: school.id)
          .get();
      for (final doc in seasonsSnap.docs) {
        batch.delete(doc.reference);
      }

      final txSnap = await _firestore
          .collection('transactions')
          .where('schoolId', isEqualTo: school.id)
          .get();
      for (final doc in txSnap.docs) {
        batch.delete(doc.reference);
      }

      final feedSnap = await _firestore
          .collection('feeds')
          .where('schoolId', isEqualTo: school.id)
          .get();
      for (final doc in feedSnap.docs) {
        batch.delete(doc.reference);
      }

      batch.delete(_firestore.collection('schools').doc(school.id));

      await batch.commit();

      Get.snackbar(
        'Deleted',
        '${school.name} and all associated data removed.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.withValues(alpha: 0.8),
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to delete school: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withValues(alpha: 0.8),
        colorText: Colors.white,
      );
    }
  }

  Future<void> toggleSchool(SchoolModel school) async {
    try {
      await _schoolRepo.updateSchoolStatus(school.id, !school.isActive);
    } catch (e) {
      Get.snackbar(
        'Error updating status',
        e.toString(),
        backgroundColor: Colors.red.withValues(alpha: 0.8),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void logout() async {
    await FirebaseAuth.instance.signOut();
    Get.offAllNamed(Routes.AUTH);
  }

  Future<void> deleteAccount() async {
    await AccountDeletionService.confirmAndDeleteAccount(
      onSuccessCleanup: () async {},
      afterNavigation: () {
        if (Get.isRegistered<AdminController>()) {
          Get.delete<AdminController>(force: true);
        }
      },
    );
  }
}
