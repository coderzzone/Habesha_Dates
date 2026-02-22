import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  static const Color habeshaGold = Color(0xFFD4AF35);
  static const Color backgroundDark = Color(0xFF0A0A0A);
  static const Color cardGrey = Color(0xFF1A1A1A);

  String get currentUserId => FirebaseAuth.instance.currentUser?.uid ?? "";

  Future<void> _deleteChat(String partnerId) async {
    try {
      final batch = FirebaseFirestore.instance.batch();
      List<String> ids = [currentUserId, partnerId];
      ids.sort();
      String chatId = ids.join("_");

      batch.delete(FirebaseFirestore.instance.collection('chats').doc(chatId));
      batch.delete(FirebaseFirestore.instance.collection('likes').doc('${currentUserId}_$partnerId'));
      batch.delete(FirebaseFirestore.instance.collection('likes').doc('${partnerId}_$currentUserId'));

      await batch.commit();
    } catch (e) {
      debugPrint("Delete error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundDark,
      // Use Column + Expanded to prevent RenderFlex overflows
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            _buildSearchBar(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildSectionTitle("NEW MATCHES"),
                  _buildNewMatchesRow(),
                  const SizedBox(height: 25),
                  _buildSectionTitle("ACTIVE CONVERSATIONS"),
                  _buildActiveChatsList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text("Messages", style: TextStyle(color: habeshaGold, fontSize: 32, fontWeight: FontWeight.bold)),
          _langToggleRow(),
        ],
      ),
    );
  }

  Widget _langToggleRow() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: cardGrey, borderRadius: BorderRadius.circular(20)),
      child: Row(
        children: [
          _langToggleItem("EN", true),
          _langToggleItem("አማ", false),
        ],
      ),
    );
  }

  Widget _langToggleItem(String label, bool active) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: active ? Colors.white24 : Colors.transparent, borderRadius: BorderRadius.circular(15)),
      child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: "Search matches",
          prefixIcon: const Icon(Icons.search, color: Colors.white38),
          filled: true,
          fillColor: cardGrey,
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(title, style: const TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildNewMatchesRow() {
    return SizedBox(
      height: 100,
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').limit(8).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const SizedBox.shrink();
          final users = snapshot.data!.docs.where((d) => d.id != currentUserId).toList();
          return ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index].data() as Map<String, dynamic>;
              return Padding(
                padding: const EdgeInsets.only(right: 15),
                child: Column(
                  children: [
                    CircleAvatar(radius: 30, backgroundImage: NetworkImage(user['profileImageUrl'] ?? "")),
                    const SizedBox(height: 5),
                    Text(user['name'] ?? "", style: const TextStyle(color: Colors.white, fontSize: 11)),
                  ],
                ),
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

        return ListView.builder(
          shrinkWrap: true, // Crucial for nested lists
          physics: const NeverScrollableScrollPhysics(),
          itemCount: chatDocs.length,
          itemBuilder: (context, index) {
            final chatData = chatDocs[index].data() as Map<String, dynamic>;
            final String partnerId = (chatData['users'] as List).firstWhere((id) => id != currentUserId, orElse: () => "");

            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('users').doc(partnerId).get(),
              builder: (context, userSnap) {
                if (!userSnap.hasData || !userSnap.data!.exists) return const SizedBox.shrink();
                final partner = userSnap.data!.data() as Map<String, dynamic>;
                
                // Safety check for isRead
                final bool isRead = chatData['lastSenderId'] == currentUserId || (chatData['isRead'] ?? true);

                return Dismissible(
                  key: Key(chatDocs[index].id),
                  direction: DismissDirection.endToStart,
                  onDismissed: (_) => _deleteChat(partnerId),
                  background: Container(
                    color: Colors.red, 
                    alignment: Alignment.centerRight, 
                    padding: const EdgeInsets.only(right: 20),
                    child: const Icon(Icons.delete, color: Colors.white)
                  ),
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    onTap: () => context.push('/chat_room/${chatDocs[index].id}?name=${partner['name']}'),
                    leading: CircleAvatar(radius: 28, backgroundImage: NetworkImage(partner['profileImageUrl'] ?? "")),
                    title: Text("${partner['name'] ?? 'User'}, ${partner['age'] ?? ''}", 
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    subtitle: Text(chatData['lastMessage'] ?? "Start chatting...", 
                      maxLines: 1, 
                      style: TextStyle(
                        color: isRead ? Colors.white54 : Colors.white, 
                        fontWeight: isRead ? FontWeight.normal : FontWeight.bold
                      )),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(_formatTime(chatData['timestamp']), style: const TextStyle(color: Colors.white38, fontSize: 10)),
                        if (!isRead) const Padding(padding: EdgeInsets.only(top: 5), child: CircleAvatar(radius: 4, backgroundColor: habeshaGold)),
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
    return DateFormat.jm().format((ts as Timestamp).toDate());
  }
}