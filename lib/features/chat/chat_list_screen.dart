import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  String get currentUserId => FirebaseAuth.instance.currentUser?.uid ?? "";

  Future<void> _deleteChat(String partnerId) async {
    try {
      final batch = FirebaseFirestore.instance.batch();
      List<String> ids = [currentUserId, partnerId];
      ids.sort();
      String chatId = ids.join("_");

      batch.delete(FirebaseFirestore.instance.collection('chats').doc(chatId));
      batch.delete(
        FirebaseFirestore.instance
            .collection('likes')
            .doc('${currentUserId}_$partnerId'),
      );
      batch.delete(
        FirebaseFirestore.instance
            .collection('likes')
            .doc('${partnerId}_$currentUserId'),
      );

      await batch.commit();
    } catch (e) {
      debugPrint("Delete error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            _buildSearchBar(context),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildSectionTitle(context, "ONLINE & TALAK"),
                  _buildOnlineRow(),
                  const SizedBox(height: 32),
                  _buildSectionTitle(context, "ACTIVE CONVERSATIONS"),
                  _buildActiveChatsList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "Messages",
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: AppColors.gold,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          _langToggleRow(),
        ],
      ),
    );
  }

  Widget _langToggleRow() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [_langToggleItem("EN", true), _langToggleItem("አማ", false)],
      ),
    );
  }

  Widget _langToggleItem(String label, bool active) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: active ? Colors.white12 : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: active ? Colors.white : Colors.white38,
          fontSize: 13,
          fontWeight: active ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: TextField(
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: "Search matches",
          hintStyle: const TextStyle(color: Colors.white30),
          prefixIcon: const Icon(Icons.search, color: AppColors.gold, size: 20),
          filled: true,
          fillColor: AppColors.surface,
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.white10),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.white10),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: Colors.white38,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildOnlineRow() {
    return SizedBox(
      height: 110,
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('chats')
            .where('users', arrayContains: currentUserId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const SizedBox.shrink();

          final List<String> partnerIds = snapshot.data!.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final users = List<String>.from(data['users'] ?? []);
            return users.firstWhere((id) => id != currentUserId, orElse: () => "");
          }).where((id) => id.isNotEmpty).toList();

          if (partnerIds.isEmpty) return const SizedBox.shrink();

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .where(FieldPath.documentId, whereIn: partnerIds.take(10).toList())
                .where('isOnline', isEqualTo: true)
                .snapshots(),
            builder: (context, userSnap) {
              if (!userSnap.hasData) return const SizedBox.shrink();
              final users = userSnap.data!.docs;

              if (users.isEmpty) return const SizedBox.shrink();

              return ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final user = users[index].data() as Map<String, dynamic>;
                  return Padding(
                    padding: const EdgeInsets.only(right: 20),
                    child: Column(
                      children: [
                        Stack(
                          children: [
                            CircleAvatar(
                              radius: 32,
                              backgroundColor: AppColors.surface,
                              backgroundImage: NetworkImage(
                                user['profileImageUrl'] ?? "",
                              ),
                            ),
                            Positioned(
                              right: 2,
                              bottom: 2,
                              child: Container(
                                width: 14,
                                height: 14,
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: AppColors.darkBg, width: 2),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                          Text(
                            user['name'] ?? "",
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            "Online",
                            style: TextStyle(
                              color: Colors.greenAccent,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
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

  Widget _buildActiveChatsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('chats')
          .where('users', arrayContains: currentUserId)
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final chatDocs = snapshot.data!.docs;

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: chatDocs.length,
          separatorBuilder: (context, index) => const Divider(
            color: Colors.white10,
            height: 32,
          ),
          itemBuilder: (context, index) {
            final chatData = chatDocs[index].data() as Map<String, dynamic>;
            final String partnerId = (chatData['users'] as List).firstWhere(
              (id) => id != currentUserId,
              orElse: () => "",
            );

            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(partnerId)
                  .get(),
              builder: (context, userSnap) {
                if (!userSnap.hasData || !userSnap.data!.exists) {
                  return const SizedBox.shrink();
                }
                final partner = userSnap.data!.data() as Map<String, dynamic>;

                final bool isRead =
                    chatData['lastSenderId'] == currentUserId ||
                    (chatData['isRead'] ?? true);

                return Dismissible(
                  key: Key(chatDocs[index].id),
                  direction: DismissDirection.endToStart,
                  onDismissed: (_) => _deleteChat(partnerId),
                  background: Container(
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: const Icon(Icons.delete_outline, color: Colors.redAccent),
                  ),
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    onTap: () => context.push(
                      '/chat_room/${chatDocs[index].id}?name=${partner['name']}',
                    ),
                    leading: CircleAvatar(
                      radius: 30,
                      backgroundColor: AppColors.surface,
                      backgroundImage: NetworkImage(
                        partner['profileImageUrl'] ?? "",
                      ),
                    ),
                    title: Row(
                      children: [
                        Text(
                          "${partner['name'] ?? 'User'}, ${partner['age'] ?? ''}",
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: isRead ? FontWeight.w500 : FontWeight.bold,
                          ),
                        ),
                        if (partner['isVerified'] == true) ...[
                          const SizedBox(width: 6),
                          const Icon(Icons.verified, color: Colors.blue, size: 16),
                        ],
                      ],
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        chatData['lastMessage'] ?? "Start chatting...",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isRead ? Colors.white38 : Colors.white70,
                          fontWeight: isRead ? FontWeight.normal : FontWeight.w600,
                        ),
                      ),
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _formatTime(chatData['timestamp']),
                          style: const TextStyle(
                            color: Colors.white24,
                            fontSize: 11,
                          ),
                        ),
                        if (!isRead)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.gold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  String _formatTime(dynamic ts) {
    if (ts == null) return "";
    DateTime date = (ts as Timestamp).toDate();
    DateTime now = DateTime.now();

    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      return DateFormat.jm().format(date);
    } else if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day - 1) {
      return "Yesterday";
    } else {
      return DateFormat.yMMMd().format(date);
    }
  }
}
