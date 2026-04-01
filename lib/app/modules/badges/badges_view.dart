import "package:flutter/material.dart";
import "package:get/get.dart";
import "badges_controller.dart";

class BadgesView extends GetView<BadgesController> {
  const BadgesView({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text("BadgesView")),
    );
  }
}