import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class ChatRoomScreen extends StatefulWidget {
  final String chatId;
  final String partnerName;

  const ChatRoomScreen({
    super.key,
    required this.chatId,
    required this.partnerName,
  });

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final TextEditingController _messageController = TextEditingController();
  final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? "";
  static const Color habeshaGold = Color(0xFFD4AF35);
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _markMessagesAsRead();
  }

  void _markMessagesAsRead() {
    FirebaseFirestore.instance.collection('chats').doc(widget.chatId).update({
      'isRead': true,
    });
  }

  void _setTypingStatus(bool typing) {
    FirebaseFirestore.instance.collection('chats').doc(widget.chatId).update({
      'typingStatus.$currentUserId': typing,
    });
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final text = _messageController.text.trim();
    _messageController.clear();
    _setTypingStatus(false);

    await FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages')
        .add({
      'senderId': currentUserId,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false,
    });

    await FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .update({
      'lastMessage': text,
      'lastSenderId': currentUserId,
      'isRead': false,
      'timestamp': FieldValue.serverTimestamp(),
    });

    final partnerId = await _resolvePartnerId();
    if (partnerId != null) {
      await _notifyUser(
        toUserId: partnerId,
        type: 'chat',
        data: {
          'chatId': widget.chatId,
          'message': text,
        },
      );
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      resizeToAvoidBottomInset: true,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(child: _buildMessageList()),
          _buildTypingIndicator(),
          _buildMessageInput(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.black,
      title: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('chats')
            .doc(widget.chatId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Text(widget.partnerName);
          }

          final List users = snapshot.data!['users'];
          final String partnerId = users.firstWhere(
            (id) => id != currentUserId,
          );

          return StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(partnerId)
                .snapshots(),
            builder: (context, userSnap) {
              String status = "Offline";
              if (userSnap.hasData && userSnap.data!.exists) {
                final data = userSnap.data!.data() as Map<String, dynamic>;
                bool online = data['isOnline'] ?? false;
                if (online) {
                  status = "Online";
                } else if (data['lastSeen'] != null) {
                  status = _formatLastSeen(data['lastSeen']);
                }
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.partnerName,
                    style: const TextStyle(color: habeshaGold, fontSize: 16),
                  ),
                  Text(
                    status,
                    style: const TextStyle(color: Colors.white54, fontSize: 10),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildMessageList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(
            child: Text(
              "Unable to load messages.",
              style: TextStyle(color: Colors.white54),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: habeshaGold),
          );
        }
        final messages = snapshot.data!.docs;
        if (messages.isEmpty) {
          return const Center(
            child: Text(
              "No messages yet. Say hello!",
              style: TextStyle(color: Colors.white54),
            ),
          );
        }
        return ListView.builder(
          reverse: true,
          padding: const EdgeInsets.all(15),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final msg = messages[index].data() as Map<String, dynamic>;
            bool isMe = msg['senderId'] == currentUserId;
            return _buildBubble(msg, isMe, messages[index].id);
          },
        );
      },
    );
  }

  Widget _buildBubble(Map<String, dynamic> msg, bool isMe, String id) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.all(12),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            decoration: BoxDecoration(
              color: isMe ? habeshaGold : const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(15),
                topRight: const Radius.circular(15),
                bottomLeft: Radius.circular(isMe ? 15 : 0),
                bottomRight: Radius.circular(isMe ? 0 : 15),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  msg['text'] ?? "",
                  style: TextStyle(
                    color: isMe ? Colors.black : Colors.white,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatMsgTime(msg['timestamp']),
                  style: TextStyle(
                    color: isMe ? Colors.black45 : Colors.white24,
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ),
          if (isMe)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Icon(
                Icons.done_all,
                size: 12,
                color: (msg['isRead'] ?? false) ? Colors.blue : Colors.white38,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          final typingData = data['typingStatus'] as Map<String, dynamic>?;
          final List users = data['users'];
          final String partnerId = users.firstWhere(
            (id) => id != currentUserId,
          );

          if (typingData != null && typingData[partnerId] == true) {
            return const Padding(
              padding: EdgeInsets.only(left: 20, bottom: 5),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Typing...",
                  style: TextStyle(
                    color: habeshaGold,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            );
          }
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 30),
      color: Colors.black,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              onChanged: (val) {
                if (!_isTyping && val.isNotEmpty) {
                  _isTyping = true;
                  _setTypingStatus(true);
                } else if (val.isEmpty) {
                  _isTyping = false;
                  _setTypingStatus(false);
                }
              },
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Write something...",
                fillColor: const Color(0xFF1A1A1A),
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _sendMessage,
            child: const CircleAvatar(
              backgroundColor: habeshaGold,
              child: Icon(Icons.send, color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }

  Future<String?> _resolvePartnerId() async {
    try {
      final chatDoc = await FirebaseFirestore.instance.collection('chats').doc(widget.chatId).get();
      if (!chatDoc.exists) return null;
      final data = chatDoc.data() as Map<String, dynamic>;
      final List users = data['users'] ?? [];
      return users.firstWhere((id) => id != currentUserId, orElse: () => null);
    } catch (_) {
      return null;
    }
  }

  Future<void> _notifyUser({
    required String toUserId,
    required String type,
    required Map<String, dynamic> data,
  }) async {
    if (currentUserId.isEmpty || toUserId.isEmpty) return;
    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(toUserId).get();
      final userData = userDoc.data() ?? {};
      if (userData['notificationsEnabled'] == false) return;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(toUserId)
          .collection('notifications')
          .add({
        'to': toUserId,
        'from': currentUserId,
        'type': type,
        'data': data,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint("Notification error: $e");
    }
  }

  String _formatMsgTime(dynamic ts) {
    if (ts == null) return "...";
    return DateFormat.jm().format((ts as Timestamp).toDate());
  }

  String _formatLastSeen(dynamic ts) {
    if (ts == null) return "Offline";
    DateTime date = (ts as Timestamp).toDate();
    DateTime now = DateTime.now();
    Duration diff = now.difference(date);

    if (diff.inMinutes < 1) return "Last seen just now";
    if (diff.inMinutes < 60) return "Last seen ${diff.inMinutes}m ago";
    if (diff.inHours < 24) return "Last seen ${diff.inHours}h ago";
    return "Last seen ${DateFormat.yMMMd().format(date)}";
  }
}
