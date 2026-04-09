import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  late final String uid;

  double? _distance;
  RangeValues? _ageRange;
  bool? _notifications;

  @override
  void initState() {
    super.initState();
    uid = currentUser?.uid ?? "";
  }

  Future<void> _sendEmailVerification() async {
    try {
      await currentUser?.sendEmailVerification();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Verification email sent! Please check your inbox.")),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to send: $e"), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) return const Scaffold(body: Center(child: Text("Not logged in")));

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text("Settings", style: Theme.of(context).appBarTheme.titleTextStyle),
        centerTitle: true,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && _distance == null) {
            return const Center(child: CircularProgressIndicator(color: AppColors.gold));
          }

          if (snapshot.hasData && snapshot.data!.exists) {
            var data = snapshot.data!.data() as Map<String, dynamic>;

            _distance ??= (data['maxDistance'] ?? 50).toDouble();
            _ageRange ??= RangeValues(
              (data['minAge'] ?? 18).toDouble(),
              (data['maxAge'] ?? 35).toDouble(),
            );
            _notifications ??= data['notificationsEnabled'] ?? true;

            final bool isVerified = data['isVerified'] ?? false;

            return ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              children: [
                _buildSection("Discovery Preferences", [
                  _buildSliderTile("Maximum Distance", "${_distance!.round()} km", _distance!, 1, 100, 
                    (val) => setState(() => _distance = val), (val) => _save('maxDistance', val.round())),
                  const Divider(color: Colors.white10),
                  _buildRangeSliderTile("Age Range", "${_ageRange!.start.round()} - ${_ageRange!.end.round()}", _ageRange!, 18, 70, 
                    (val) => setState(() => _ageRange = val), (val) => _saveMulti({'minAge': val.start.round(), 'maxAge': val.end.round()})),
                ]),

                const SizedBox(height: 25),
                _buildSection("Account & Security", [
                  _buildListTile(Icons.person_outline, "Edit Profile", subtitle: "Update photos and bio", 
                    onTap: () => context.push('/profile_edit')),
                  const Divider(color: Colors.white10),
                  _buildSecurityTile(isVerified),
                  const Divider(color: Colors.white10),
                  _buildEmailTile(),
                ]),

                const SizedBox(height: 25),
                _buildSection("Premium & Payments", [
                  _buildListTile(Icons.workspace_premium_outlined, "Premium Features",
                    subtitle: "Explore Gold membership benefits",
                    onTap: () => context.push('/premium')),
                  const Divider(color: Colors.white10),
                  _buildListTile(Icons.lock_outline, "Upgrade Now",
                    subtitle: "Open paywall options",
                    onTap: () => context.push('/paywall')),
                  const Divider(color: Colors.white10),
                  _buildListTile(Icons.receipt_long_outlined, "Pay with Telebirr",
                    subtitle: "Manual screenshot upload",
                    onTap: () => context.push('/telebirr?amount=600')),
                ]),

                const SizedBox(height: 25),
                _buildSection("App Settings", [
                  _buildListTile(Icons.notifications_active_outlined, "Notifications Inbox",
                    subtitle: "See follows, matches, and chats",
                    onTap: () => context.push('/notifications')),
                  const Divider(color: Colors.white10),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    secondary: const Icon(Icons.notifications_none_outlined, color: Colors.white70),
                    title: const Text("Push Notifications", style: TextStyle(color: Colors.white, fontSize: 16)),
                    value: _notifications!,
                    activeThumbColor: AppColors.gold,
                    onChanged: (val) {
                      setState(() => _notifications = val);
                      _save('notificationsEnabled', val);
                    },
                  ),
                ]),

                const SizedBox(height: 50),
                _buildLogoutButton(),
                const SizedBox(height: 40),
              ],
            );
          }
          return const Center(child: Text("Error loading settings"));
        },
      ),
    );
  }

  Future<void> _showEmailDialog() async {
    final TextEditingController emailController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text("Update Email", style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: emailController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: "Enter your email address",
            hintStyle: TextStyle(color: Colors.white30),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white10)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL", style: TextStyle(color: Colors.white54))),
          TextButton(
            onPressed: () async {
              try {
                final email = emailController.text.trim();
                if (email.isEmpty) return;
                
                // Use verifyBeforeUpdateEmail for modern security
                await currentUser?.verifyBeforeUpdateEmail(email);

                if (!mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Email updated and verification sent!")),
                );
                setState(() {}); // Refresh UI
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Error: $e"), backgroundColor: AppColors.error),
                  );
                }
              }
            },
            child: const Text("UPDATE & VERIFY", style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailTile() {
    final String? email = currentUser?.email;
    final bool hasEmail = email != null && email.isNotEmpty;
    final bool isEmailVerified = currentUser?.emailVerified ?? false;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.email_outlined, color: Colors.white70, size: 22),
      title: const Text("Email Address", style: TextStyle(color: Colors.white, fontSize: 16)),
      subtitle: Row(
        children: [
          Text(hasEmail ? (email ?? "") : "Not set", style: const TextStyle(color: Colors.white38, fontSize: 12)),
          const SizedBox(width: 8),
          if (hasEmail && isEmailVerified)
            const Icon(Icons.verified, color: Colors.blue, size: 14)
          else if (hasEmail)
            const Text(" (Unverified)", style: TextStyle(color: Colors.redAccent, fontSize: 12)),
        ],
      ),
      trailing: isEmailVerified 
          ? null 
          : TextButton(
              onPressed: hasEmail ? _sendEmailVerification : _showEmailDialog,
              child: Text(hasEmail ? "VERIFY" : "ADD EMAIL", 
                style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold, fontSize: 12)),
            ),
    );
  }

  void _save(String key, dynamic value) {
    FirebaseFirestore.instance.collection('users').doc(uid).update({key: value});
  }

  void _saveMulti(Map<String, dynamic> data) {
    FirebaseFirestore.instance.collection('users').doc(uid).update(data);
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 8),
          child: Text(title.toUpperCase(), style: const TextStyle(color: AppColors.gold, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white10)),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildSliderTile(String title, String value, double current, double min, double max, Function(double) onChanged, Function(double) onChangeEnd) {
    return Column(children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(title, style: const TextStyle(color: Colors.white, fontSize: 16)),
        Text(value, style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold)),
      ]),
      Slider(value: current, min: min, max: max, activeColor: AppColors.gold, inactiveColor: Colors.white10, onChanged: onChanged, onChangeEnd: onChangeEnd),
    ]);
  }

  Widget _buildRangeSliderTile(String title, String value, RangeValues current, double min, double max, Function(RangeValues) onChanged, Function(RangeValues) onChangeEnd) {
    return Column(children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(title, style: const TextStyle(color: Colors.white, fontSize: 16)),
        Text(value, style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold)),
      ]),
      RangeSlider(values: current, min: min, max: max, activeColor: AppColors.gold, inactiveColor: Colors.white10, onChanged: onChanged, onChangeEnd: onChangeEnd),
    ]);
  }

  Widget _buildListTile(IconData icon, String title, {String? subtitle, VoidCallback? onTap}) {
    return ListTile(onTap: onTap, contentPadding: EdgeInsets.zero, leading: Icon(icon, color: Colors.white70, size: 22), title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 16)), subtitle: subtitle != null ? Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 12)) : null, trailing: const Icon(Icons.chevron_right, color: Colors.white24, size: 20));
  }

  Widget _buildSecurityTile(bool isVerified) {
    return ListTile(
      onTap: isVerified ? null : () => context.push('/verification'),
      contentPadding: EdgeInsets.zero,
      leading: Icon(isVerified ? Icons.verified : Icons.gpp_maybe_outlined, color: isVerified ? Colors.blue : AppColors.gold, size: 22),
      title: const Text("Identity Verification", style: TextStyle(color: Colors.white, fontSize: 16)),
      subtitle: Text(isVerified ? "ID Verified" : "Action required", style: TextStyle(color: isVerified ? Colors.blue : Colors.white38, fontSize: 12)),
      trailing: isVerified ? const Icon(Icons.check_circle, color: Colors.blue, size: 20) : const Icon(Icons.chevron_right, color: Colors.white24, size: 20),
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red.withValues(alpha: 0.1),
          foregroundColor: Colors.redAccent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
            side: const BorderSide(color: Colors.redAccent, width: 0.5),
          ),
          elevation: 0,
        ),
        onPressed: () async {
          await FirebaseAuth.instance.signOut();
          if (!mounted) return;
          context.go('/');
        },
        child: const Text("Log Out", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ),
    );
  }
}
