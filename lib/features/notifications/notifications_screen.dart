import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  String _titleForType(String type) {
    switch (type) {
      case 'follow':
        return 'New follower';
      case 'chat':
        return 'New message';
      case 'match':
        return "It's a match!";
      default:
        return 'Notification';
    }
  }

  String _subtitleForType(String type, String fromName, Map<String, dynamic> data) {
    if (type == 'chat') {
      final msg = data['message'] ?? 'sent you a message';
      return "$fromName: $msg";
    }
    if (type == 'match') {
      return "$fromName matched with you";
    }
    if (type == 'follow') {
      return "$fromName started following you";
    }
    return data['message'] ?? "You have a new update";
  }

  Future<void> _markRead(String uid, String notifId) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .doc(notifId)
        .set({'isRead': true}, SetOptions(merge: true));
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("Not logged in")),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text("Notifications", style: Theme.of(context).appBarTheme.titleTextStyle),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('notifications')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: AppColors.gold));
          }

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(
              child: Text(
                "No notifications yet.",
                style: TextStyle(color: Colors.white54),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            itemCount: docs.length,
            separatorBuilder: (_, _) => const Divider(color: Colors.white10),
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final type = data['type'] ?? 'unknown';
              final from = data['from'] ?? '';
              final isRead = data['isRead'] == true;
              final createdAt = data['createdAt'];

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('users').doc(from).get(),
                builder: (context, userSnap) {
                  final fromData = userSnap.data?.data() as Map<String, dynamic>? ?? {};
                  final fromName = fromData['name'] ?? "User";
                  final fromPhoto = fromData['profileImageUrl'] ?? "";
                  final title = _titleForType(type);
                  final subtitle = _subtitleForType(type, fromName, (data['data'] as Map<String, dynamic>? ?? {}));

                  return ListTile(
                    onTap: () async {
                      await _markRead(user.uid, doc.id);
                      if (type == 'chat' || type == 'match') {
                        final chatId = (data['data'] as Map<String, dynamic>? ?? {})['chatId'];
                        if (chatId != null && chatId.toString().isNotEmpty) {
                          context.push('/chat_room/$chatId?name=$fromName');
                          return;
                        }
                      }
                      if (from.toString().isNotEmpty) {
                        context.push('/profile_details/$from');
                      }
                    },
                    leading: CircleAvatar(
                      radius: 24,
                      backgroundColor: AppColors.surface,
                      backgroundImage: fromPhoto.isNotEmpty ? NetworkImage(fromPhoto) : null,
                      child: fromPhoto.isEmpty
                          ? Text(
                              fromName.toString().isNotEmpty ? fromName[0] : 'U',
                              style: const TextStyle(color: Colors.white),
                            )
                          : null,
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: isRead ? FontWeight.w500 : FontWeight.bold,
                            ),
                          ),
                        ),
                        if (!isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.gold,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    subtitle: Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white54),
                    ),
                    trailing: Text(
                      _formatTime(createdAt),
                      style: const TextStyle(color: Colors.white30, fontSize: 11),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  String _formatTime(dynamic ts) {
    if (ts == null) return "";
    DateTime date = (ts as Timestamp).toDate();
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 1) return "now";
    if (diff.inMinutes < 60) return "${diff.inMinutes}m";
    if (diff.inHours < 24) return "${diff.inHours}h";
    return "${date.month}/${date.day}";
  }
}
