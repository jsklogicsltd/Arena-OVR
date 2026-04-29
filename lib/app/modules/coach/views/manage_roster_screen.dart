import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/stadium_background.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/fire_sparks_background.dart';
import '../../../core/components/animated_glowing_border.dart';
import '../../../data/models/user_model.dart';
import '../../../data/models/team_model.dart';

class ManageRosterScreen extends StatelessWidget {
  final String teamId;

  const ManageRosterScreen({super.key, required this.teamId});

  static const List<String> _positionGroups = [
    'OFFENSE',
    'DEFENSE',
    'SPECIAL TEAMS',
  ];

  Stream<List<UserModel>> _athletesStream() {
    return FirebaseFirestore.instance
        .collection('users')
        .where('teamId', isEqualTo: teamId)
        .where('role', isEqualTo: 'athlete')
        .snapshots()
        .map((snap) {
      final list = snap.docs.map((d) {
        final data = d.data();
        data['uid'] = d.id;
        return UserModel.fromJson(data);
      }).toList();
      list.sort((a, b) => a.name.trim().toLowerCase().compareTo(
            b.name.trim().toLowerCase(),
          ));
      return list;
    });
  }

  Future<void> _openAssignmentsSheet(BuildContext context, UserModel athlete) async {
    final pos = (athlete.positionGroup ?? '').trim().toUpperCase();
    String selectedPos = _positionGroups.contains(pos) ? pos : _positionGroups.first;
    final tagCtrl = TextEditingController(text: athlete.customTag ?? '');
    final baseOvrCtrl = TextEditingController(
      text: athlete.individualBaseOvrOverride?.toString() ?? '',
    );
    bool isSaving = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            Future<void> save() async {
              final tag = tagCtrl.text.trim();
              final baseRaw = baseOvrCtrl.text.trim();
              int? baseOverride;
              if (baseRaw.isNotEmpty) {
                final parsed = int.tryParse(baseRaw);
                if (parsed == null || parsed < 0 || parsed > 90) {
                  Get.snackbar(
                    'Invalid Base OVR',
                    'Custom Starting OVR must be a number between 0 and 90.',
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: Colors.red.withValues(alpha: 0.85),
                    colorText: Colors.white,
                  );
                  return;
                }
                baseOverride = parsed;
              }
              setModalState(() => isSaving = true);
              try {
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(athlete.uid)
                    .update({
                  'positionGroup': selectedPos,
                  'customTag': tag.isEmpty ? FieldValue.delete() : tag,
                  'individualBaseOvrOverride':
                      baseOverride ?? FieldValue.delete(),
                });
                if (tag.isNotEmpty) {
                  await FirebaseFirestore.instance
                      .collection('teams')
                      .doc(teamId)
                      .update({
                    'customTags': FieldValue.arrayUnion([tag]),
                  });
                }
                Get.back(closeOverlays: true);
                Get.snackbar(
                  'Saved',
                  'Assignments updated for ${athlete.name}',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.green.withValues(alpha: 0.85),
                  colorText: Colors.white,
                );
              } catch (e) {
                setModalState(() => isSaving = false);
                Get.snackbar(
                  'Error',
                  'Failed to save: $e',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.red.withValues(alpha: 0.85),
                  colorText: Colors.white,
                );
              }
            }

            Widget tagChips() {
              return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('teams')
                    .doc(teamId)
                    .snapshots(),
                builder: (context, snap) {
                  final data = snap.data?.data();
                  final team = (data != null)
                      ? TeamModel.fromJson({
                          ...data,
                          'id': snap.data!.id,
                        })
                      : null;
                  final tags = (team?.customTags ?? const <String>[])
                      .map((e) => e.trim())
                      .where((e) => e.isNotEmpty)
                      .toList();

                  if (tags.isEmpty) return const SizedBox.shrink();

                  final current = tagCtrl.text.trim().toLowerCase();
                  return Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: tags.map((t) {
                      final selected = current.isNotEmpty &&
                          current == t.trim().toLowerCase();
                      return FilterChip(
                        label: Text(
                          t,
                          style: GoogleFonts.spaceGrotesk(
                            color: Colors.white,
                            fontWeight:
                                selected ? FontWeight.w900 : FontWeight.w800,
                          ),
                        ),
                        selected: selected,
                        onSelected: isSaving
                            ? null
                            : (_) {
                                setModalState(() {
                                  tagCtrl.text = t;
                                  tagCtrl.selection = TextSelection.fromPosition(
                                    TextPosition(offset: tagCtrl.text.length),
                                  );
                                });
                              },
                        backgroundColor: Colors.white.withValues(alpha: 0.06),
                        selectedColor:
                            const Color(0xFF00A1FF).withValues(alpha: 0.20),
                        checkmarkColor: Colors.white,
                        side: BorderSide(
                          color: selected
                              ? const Color(0xFF00A1FF).withValues(alpha: 0.55)
                              : Colors.white.withValues(alpha: 0.14),
                          width: 1,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      );
                    }).toList(),
                  );
                },
              );
            }

            Future<void> removeFromTeam() async {
              final confirmed = await Get.dialog<bool>(
                AlertDialog(
                  backgroundColor: const Color(0xFF101A24),
                  title: Text(
                    'Remove athlete?',
                    style: GoogleFonts.spaceGrotesk(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  content: Text(
                    'This will remove ${athlete.name} from the team.',
                    style: GoogleFonts.inter(color: Colors.white70),
                  ),
                  actions: [
                    TextButton(onPressed: () => Get.back(result: false), child: const Text('Cancel')),
                    TextButton(
                      onPressed: () => Get.back(result: true),
                      child: Text('Remove', style: GoogleFonts.inter(color: Colors.redAccent)),
                    ),
                  ],
                ),
              );
              if (confirmed != true) return;

              setModalState(() => isSaving = true);
              try {
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(athlete.uid)
                    .update({
                  'teamId': FieldValue.delete(),
                  'positionGroup': FieldValue.delete(),
                  'customTag': FieldValue.delete(),
                });
                Get.back(closeOverlays: true);
                Get.snackbar(
                  'Removed',
                  '${athlete.name} removed from team',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.green.withValues(alpha: 0.85),
                  colorText: Colors.white,
                );
              } catch (e) {
                setModalState(() => isSaving = false);
                Get.snackbar(
                  'Error',
                  'Failed to remove: $e',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.red.withValues(alpha: 0.85),
                  colorText: Colors.white,
                );
              }
            }

            final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(bottom: bottomInset),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.08), width: 1),
                  ),
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              athlete.name,
                              style: GoogleFonts.spaceGrotesk(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Get.back(),
                            icon: const Icon(Icons.close_rounded, color: Colors.white54),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'POSITION GROUP',
                        style: GoogleFonts.spaceGrotesk(
                          color: Colors.white54,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: selectedPos,
                            isExpanded: true,
                            dropdownColor: const Color(0xFF0F172A),
                            items: _positionGroups
                                .map(
                                  (p) => DropdownMenuItem<String>(
                                    value: p,
                                    child: Text(
                                      p,
                                      style: GoogleFonts.inter(color: Colors.white),
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: isSaving
                                ? null
                                : (v) {
                                    if (v == null) return;
                                    setModalState(() => selectedPos = v);
                                  },
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'CUSTOM TAG (optional)',
                        style: GoogleFonts.spaceGrotesk(
                          color: Colors.white54,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: tagCtrl,
                        enabled: !isSaving,
                        style: GoogleFonts.inter(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'e.g. Seniors, JV',
                          hintStyle: GoogleFonts.inter(color: Colors.white38),
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.06),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.primary),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      tagChips(),
                      const SizedBox(height: 18),

                      // ── Custom Starting OVR (per-athlete override) ──────
                      Row(
                        children: [
                          Text(
                            'CUSTOM STARTING OVR',
                            style: GoogleFonts.spaceGrotesk(
                              color: Colors.white54,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.edit,
                              size: 12, color: Colors.white38),
                          const Spacer(),
                          Text(
                            'Team default: ${athlete.individualBaseOvrOverride == null ? 'in use' : 'overridden'}',
                            style: GoogleFonts.inter(
                              color: Colors.white38,
                              fontSize: 10,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: baseOvrCtrl,
                        enabled: !isSaving,
                        keyboardType: TextInputType.number,
                        style: GoogleFonts.inter(color: Colors.white),
                        decoration: InputDecoration(
                          hintText:
                              'Leave blank to use team default (0–90)',
                          hintStyle: GoogleFonts.inter(color: Colors.white38),
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.06),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                                color: Colors.white.withValues(alpha: 0.12)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                                color: Colors.white.withValues(alpha: 0.12)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: AppColors.primary),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Use for dual-sport athletes who arrive with a higher locked-in baseline. Leave blank to inherit the team\u2019s starting OVR.',
                        style: GoogleFonts.inter(
                          color: Colors.white38,
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(height: 16),

                      SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: isSaving ? null : save,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: isSaving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : Text(
                                  'Save Assignments',
                                  style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w800),
                                ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextButton(
                        onPressed: isSaving ? null : removeFromTeam,
                        child: Text(
                          'Remove Athlete',
                          style: GoogleFonts.inter(
                            color: Colors.redAccent,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    tagCtrl.dispose();
    baseOvrCtrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StadiumBackground(
      child: Stack(
        fit: StackFit.expand,
        children: [
          // const FireSparksBackground(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
          // App bar (custom, matches app style)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.06),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
                  ),
                  child: IconButton(
                    onPressed: () => Get.back(),
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'MANAGE ROSTER',
                    style: GoogleFonts.spaceGrotesk(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ).animate().fade(duration: 350.ms).slideY(begin: -0.15, curve: Curves.easeOutCubic),

          Expanded(
            child: StreamBuilder<List<UserModel>>(
              stream: _athletesStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2),
                  );
                }
                final athletes = snapshot.data ?? const <UserModel>[];
                if (athletes.isEmpty) {
                  return Center(
                    child: Text(
                      'No athletes found for this team.',
                      style: GoogleFonts.inter(color: Colors.white54),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
                  physics: const BouncingScrollPhysics(),
                  itemCount: athletes.length,
                  itemBuilder: (context, i) {
                    final a = athletes[i];
                    final group = (a.positionGroup ?? '').trim();
                    final tag = (a.customTag ?? '').trim();

                    final chips = <Widget>[];
                    if (group.isNotEmpty) {
                      chips.add(_pill(text: group, color: const Color(0xFF00A1FF)));
                    }
                    if (tag.isNotEmpty) {
                      chips.add(_pill(text: tag, color: AppColors.tierGold));
                    }
                    if (a.individualBaseOvrOverride != null) {
                      chips.add(_pill(
                        text: 'BASE ${a.individualBaseOvrOverride}',
                        color: const Color(0xFF22C55E),
                      ));
                    }

                    final card = GlassCard(
                      backgroundColor: Colors.white.withValues(alpha: 0.05),
                      borderRadius: 24,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      leftBorderColor: const Color(0xFF00A1FF).withValues(alpha: 0.6),
                      onTap: () => _openAssignmentsSheet(context, a),
                      child: Row(
                        children: [
                          AnimatedGlowingBorder(
                            // Preserve original avatar constraints: 46x46.
                            // Add a clean 3px glow gap around it.
                            diameter: 54,
                            borderWidth: 3,
                            duration: const Duration(seconds: 4),
                            child: SizedBox(
                              width: 46,
                              height: 46,
                              child: Container(
                                width: 46,
                                height: 46,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withValues(alpha: 0.08),
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                                ),
                                alignment: Alignment.center,
                                child: CircleAvatar(
                                  radius: 22,
                                  backgroundColor: Colors.transparent,
                                  backgroundImage: (a.profilePicUrl != null &&
                                          a.profilePicUrl!.trim().isNotEmpty)
                                      ? CachedNetworkImageProvider(a.profilePicUrl!.trim())
                                      : null,
                                  child: (a.profilePicUrl == null ||
                                          a.profilePicUrl!.trim().isEmpty)
                                      ? Text(
                                          a.name.isNotEmpty ? a.name[0].toUpperCase() : '?',
                                          style: GoogleFonts.spaceGrotesk(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        )
                                      : null,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  a.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.spaceGrotesk(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                if (chips.isEmpty)
                                  Text(
                                    'Tap to assign group & tag',
                                    style: GoogleFonts.inter(
                                      color: Colors.white54,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  )
                                else
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: chips,
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Icon(Icons.edit_rounded, color: Colors.white54),
                        ],
                      ),
                    );

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: card
                          .animate(delay: (80 + i * 45).ms)
                          .fade(duration: 350.ms, curve: Curves.easeOut)
                          .slideY(begin: 0.08, end: 0, curve: Curves.easeOutCubic),
                    );
                  },
                );
              },
            ),
          ),
            ],
          ),
        ],
      ),
    );
  }
}

Widget _pill({required String text, required Color color}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.18),
      borderRadius: BorderRadius.circular(9999),
      border: Border.all(color: color.withValues(alpha: 0.45), width: 1),
    ),
    child: Text(
      text,
      style: GoogleFonts.spaceGrotesk(
        color: Colors.white,
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.4,
      ),
    ),
  );
}

