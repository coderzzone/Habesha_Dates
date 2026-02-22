import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';

class LikesScreen extends StatelessWidget {
  const LikesScreen({super.key});

  static const Color habeshaGold = Color(0xFFD4AF35);

  @override
  Widget build(BuildContext context) {
    final String uid = FirebaseAuth.instance.currentUser?.uid ?? "";

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text("Who Likes You", style: TextStyle(color: habeshaGold, fontWeight: FontWeight.bold)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Query for likes where YOU are the target
        stream: FirebaseFirestore.instance
            .collection('likes')
            .where('likedUserId', isEqualTo: uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: habeshaGold));

          final likeDocs = snapshot.data!.docs;

          if (likeDocs.isEmpty) {
            return const Center(
              child: Text("No likes yet. Keep swiping!", style: TextStyle(color: Colors.white54)),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(15),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 15,
              mainAxisSpacing: 15,
              childAspectRatio: 0.75,
            ),
            itemCount: likeDocs.length,
            itemBuilder: (context, index) {
              final String admirerId = likeDocs[index]['userId'];

              // Fetch the admirer's user details
              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('users').doc(admirerId).get(),
                builder: (context, userSnap) {
                  if (!userSnap.hasData) return Container(color: Colors.white10);
                  
                  final userData = userSnap.data!.data() as Map<String, dynamic>;

                  return ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CachedNetworkImage(
                          imageUrl: userData['profileImageUrl'] ?? "",
                          fit: BoxFit.cover,
                          // Optional: Blur the image if you want to make it a premium feature
                          // imageBuilder: (context, imageProvider) => Container(
                          //   decoration: BoxDecoration(
                          //     image: DecorationImage(image: imageProvider, fit: BoxFit.cover),
                          //   ),
                          //   child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), child: Container(color: Colors.black.withOpacity(0.1))),
                          // ),
                        ),
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
                              ),
                            ),
                            child: Text(
                              userData['name'] ?? "Someone",
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
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
}