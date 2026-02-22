import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const Color habeshaGold = Color(0xFFD4AF35);
  static const Color backgroundDark = Color(0xFF0A0A0A);
  
  final User? currentUser = FirebaseAuth.instance.currentUser;
  late final String uid;

  // Local state to handle smooth slider movement without waiting for DB round-trip
  double? _distance;
  RangeValues? _ageRange;
  bool? _notifications;

  @override
  void initState() {
    super.initState();
    uid = currentUser?.uid ?? "";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text("Settings", style: TextStyle(color: habeshaGold, fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && _distance == null) {
            return const Center(child: CircularProgressIndicator(color: habeshaGold));
          }

          if (snapshot.hasData && snapshot.data!.exists) {
            var data = snapshot.data!.data() as Map<String, dynamic>;
            
            // Only update local state if it hasn't been touched yet (to avoid slider jumping)
            _distance ??= (data['maxDistance'] ?? 50).toDouble();
            _ageRange ??= RangeValues(
              (data['minAge'] ?? 18).toDouble(),
              (data['maxAge'] ?? 35).toDouble()
            );
            _notifications ??= data['notificationsEnabled'] ?? true;

            final bool isVerified = data['isVerified'] ?? false;

            return ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                const SizedBox(height: 20),
                _buildSectionTitle("ACCOUNT SETTINGS"),
                _buildListTile(Icons.person, "Profile Information", onTap: () => context.push('/profile_edit')),
                _buildListTile(
                  Icons.email, 
                  "Email", 
                  subtitle: currentUser?.email ?? "Not set"
                ),

                const SizedBox(height: 30),
                _buildSectionTitle("DISCOVERY PREFERENCES"),
                
                _buildSliderHeader("Maximum Distance", "${_distance!.round()} km"),
                Slider(
                  value: _distance!,
                  min: 1, max: 100,
                  activeColor: Colors.green[800],
                  inactiveColor: Colors.white10,
                  onChanged: (val) => setState(() => _distance = val),
                  onChangeEnd: (val) => _save('maxDistance', val.round()),
                ),

                _buildSliderHeader("Age Range", "${_ageRange!.start.round()} - ${_ageRange!.end.round()}"),
                RangeSlider(
                  values: _ageRange!,
                  min: 18, max: 70,
                  activeColor: habeshaGold,
                  inactiveColor: Colors.white10,
                  onChanged: (val) => setState(() => _ageRange = val),
                  onChangeEnd: (val) => _saveMulti({
                    'minAge': val.start.round(),
                    'maxAge': val.end.round(),
                  }),
                ),

                const SizedBox(height: 30),
                _buildSectionTitle("SECURITY"),
                _buildSecurityTile(isVerified),

                const SizedBox(height: 30),
                _buildSectionTitle("APP PREFERENCES"),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  secondary: const Icon(Icons.notifications, color: Colors.white54),
                  title: const Text("Push Notifications", style: TextStyle(color: Colors.white)),
                  value: _notifications!,
                  activeThumbColor: Colors.white,
                  activeTrackColor: Colors.green[800],
                  onChanged: (val) {
                    setState(() => _notifications = val);
                    _save('notificationsEnabled', val);
                  },
                ),

                const SizedBox(height: 50),
                _buildLogoutButton(),
                const SizedBox(height: 20),
                Center(child: Text("Version 1.0.6 (2026)", style: const TextStyle(color: Colors.white24, fontSize: 12))),
                const SizedBox(height: 40),
              ],
            );
          }
          return const Center(child: Text("Error loading settings", style: TextStyle(color: Colors.white)));
        },
      ),
    );
  }

  // --- DATABASE HELPERS ---

  void _save(String key, dynamic value) {
    FirebaseFirestore.instance.collection('users').doc(uid).update({key: value});
  }

  void _saveMulti(Map<String, dynamic> data) {
    FirebaseFirestore.instance.collection('users').doc(uid).update(data);
  }

  // --- UI COMPONENTS ---

  Widget _buildSectionTitle(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(text, style: const TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
  );

  Widget _buildSliderHeader(String title, String value) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(title, style: const TextStyle(color: Colors.white, fontSize: 16)),
      Text(value, style: const TextStyle(color: habeshaGold, fontWeight: FontWeight.bold)),
    ],
  );

  Widget _buildListTile(IconData icon, String title, {String? subtitle, VoidCallback? onTap}) => ListTile(
    onTap: onTap,
    contentPadding: EdgeInsets.zero,
    leading: Icon(icon, color: Colors.white54),
    title: Text(title, style: const TextStyle(color: Colors.white)),
    trailing: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (subtitle != null) Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 12)),
        const Icon(Icons.chevron_right, color: Colors.white24),
      ],
    ),
  );

  Widget _buildSecurityTile(bool isVerified) {
    return InkWell(
      onTap: isVerified ? null : () => context.push('/verification'),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              isVerified ? Icons.verified_user : Icons.gpp_maybe, 
              color: isVerified ? Colors.green : habeshaGold
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Fayda ID Integration", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  Text(
                    isVerified ? "Identity verified successfully" : "Verification required for trust", 
                    style: TextStyle(color: isVerified ? Colors.green : Colors.white54, fontSize: 12)
                  ),
                ],
              ),
            ),
            if (!isVerified) 
              const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 14)
            else 
              const Icon(Icons.check_circle, color: Colors.green),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton() => SizedBox(
    width: double.infinity,
    child: ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF1A1A1A), 
        padding: const EdgeInsets.all(15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
      ),
      onPressed: () => FirebaseAuth.instance.signOut().then((_) => context.go('/')),
      child: const Text("Log Out", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 16)),
    ),
  );
}