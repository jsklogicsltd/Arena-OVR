import "package:flutter/material.dart";
import "package:get/get.dart";
import '../../data/repositories/auth_repository.dart' as import_repo;
import "admin_controller.dart";
import '../../core/widgets/stadium_background.dart';

class AdminView extends GetView<AdminController> {
  const AdminView({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              // Sign out logic for testing
              final repo = Get.put(import_repo.AuthRepository());
              await repo.signOut();
              Get.offAllNamed('/auth');
            },
          ),
        ],
      ),
      body: StadiumBackground(
        child: Stack(
          fit: StackFit.expand,
          children: const [
            Center(
              child: Text("AdminView", style: TextStyle(fontSize: 24, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
