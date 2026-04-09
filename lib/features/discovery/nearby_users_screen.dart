import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/services/location_service.dart';
import '../../core/theme/app_theme.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';

class NearbyUsersScreen extends StatefulWidget {
  const NearbyUsersScreen({super.key});

  @override
  State<NearbyUsersScreen> createState() => _NearbyUsersScreenState();
}

class _NearbyUsersScreenState extends State<NearbyUsersScreen> {
  double? _myLat;
  double? _myLon;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchMyPosition();
  }

  Future<void> _fetchMyPosition() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (doc.exists && mounted) {
      final data = doc.data()!;
      setState(() {
        _myLat = data['latitude'];
        _myLon = data['longitude'];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        title: const Text("NEARBY USERS"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.gold),
            onPressed: () => _fetchMyPosition(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
          : _myLat == null
              ? _buildNoLocationState()
              : _buildNearbyList(),
    );
  }

  Widget _buildNoLocationState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.location_off, color: Colors.white24, size: 80),
          const SizedBox(height: 20),
          const Text("Location data not found.", style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () async {
              await LocationService.updateUserLocation();
              _fetchMyPosition();
            },
            child: const Text("Enable Location"),
          ),
        ],
      ),
    );
  }

  Widget _buildNearbyList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(color: AppColors.gold));
        }

        final currentUid = FirebaseAuth.instance.currentUser?.uid;
        final List<Map<String, dynamic>> usersWithDistance = [];

        for (var doc in snapshot.data!.docs) {
          if (doc.id == currentUid) continue;

          final data = doc.data() as Map<String, dynamic>;
          final uLat = data['latitude'] as double?;
          final uLon = data['longitude'] as double?;

          if (uLat != null && uLon != null) {
            final double dist = LocationService.calculateDistance(_myLat!, _myLon!, uLat, uLon);
            // Limit to users within 100km for "Nearby"
            if (dist <= 100.0) {
              usersWithDistance.add({...data, 'distance': dist, 'uid': doc.id});
            }
          }
        }

        // Sort by distance
        usersWithDistance.sort((a, b) => (a['distance'] as double).compareTo(b['distance'] as double));

        if (usersWithDistance.isEmpty) {
          return const Center(
            child: Text("No users found within 100km.", style: TextStyle(color: Colors.white54)),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.75,
          ),
          itemCount: usersWithDistance.length,
          itemBuilder: (context, index) {
            final user = usersWithDistance[index];
            return _buildUserCard(user);
          },
        );
      },
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    return GestureDetector(
      onTap: () => context.push('/profile_details/${user['uid']}'),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: CachedNetworkImage(
                  imageUrl: user['profileImageUrl'] ?? '',
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${user['name']}, ${user['age']}",
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.near_me, color: AppColors.gold, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        "${(user['distance'] as double).toStringAsFixed(1)} km away",
                        style: const TextStyle(color: AppColors.gold, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
