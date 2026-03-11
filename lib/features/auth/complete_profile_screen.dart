import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/image_service.dart';

class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  static const Color habeshaGold = Color(0xFFD4AF35);
  static const Color backgroundDark = Color(0xFF0A0A0A);

  final TextEditingController nameController = TextEditingController();
  final TextEditingController bioController = TextEditingController();
  final TextEditingController ageController = TextEditingController();

  String? selectedReligion;
  String? selectedHeritage;
  String? selectedIntent;
  File? _imageFile;
  bool isLoading = false;

  final List<String> religions = [
    'Orthodox',
    'Muslim',
    'Protestant',
    'Catholic',
    'Other',
  ];
  final List<String> heritages = [
    'Addis Ababa',
    'Gonder',
    'Mekelle',
    'Jimma',
    'Bahir Dar',
    'Hawassa',
    'Diaspora',
  ];
  final List<String> intents = ['Marriage', 'Long-term', 'Friendship'];

  @override
  void dispose() {
    nameController.dispose();
    bioController.dispose();
    ageController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (pickedFile != null) {
      setState(() => _imageFile = File(pickedFile.path));
    }
  }

  Future<void> _saveProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (nameController.text.isEmpty ||
        ageController.text.isEmpty ||
        _imageFile == null ||
        selectedReligion == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please complete all fields and add a photo"),
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      // 1. Upload
      final fileName = 'profile_${user.uid}.jpg';
      String? downloadUrl = await ImageService.uploadImage(
        _imageFile!,
        fileName,
      );

      if (downloadUrl == null) throw Exception("Upload returned no URL");

      // 2. Save to Firestore
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'name': nameController.text.trim(),
        'age': int.tryParse(ageController.text.trim()) ?? 18,
        'bio': bioController.text.trim(),
        'religion': selectedReligion,
        'heritage': selectedHeritage,
        'intent': selectedIntent ?? 'Long-term',
        'profileImageUrl': downloadUrl,
        'phoneNumber': user.phoneNumber,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) context.go('/discovery');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Upload error. Please try again.")),
      );
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundDark,
      appBar: AppBar(
        title: const Text(
          "Complete Profile",
          style: TextStyle(color: habeshaGold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 60,
                backgroundColor: Colors.white10,
                backgroundImage: _imageFile != null
                    ? FileImage(_imageFile!)
                    : null,
                child: _imageFile == null
                    ? const Icon(Icons.camera_alt, color: habeshaGold, size: 40)
                    : null,
              ),
            ),
            const SizedBox(height: 30),
            _buildTextField(nameController, "Full Name", Icons.person),
            const SizedBox(height: 15),
            _buildTextField(
              ageController,
              "Age",
              Icons.calendar_today,
              isNumber: true,
            ),
            const SizedBox(height: 15),
            _buildDropdown(
              "Religion",
              religions,
              selectedReligion,
              (val) => setState(() => selectedReligion = val),
            ),
            const SizedBox(height: 15),
            _buildDropdown(
              "Heritage/Region",
              heritages,
              selectedHeritage,
              (val) => setState(() => selectedHeritage = val),
            ),
            const SizedBox(height: 15),
            _buildDropdown(
              "Intent",
              intents,
              selectedIntent,
              (val) => setState(() => selectedIntent = val),
            ),
            const SizedBox(height: 15),
            _buildTextField(bioController, "Bio", Icons.book, maxLines: 3),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: habeshaGold,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                onPressed: isLoading ? null : _saveProfile,
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.black)
                    : const Text(
                        "Save & Start Matching",
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool isNumber = false,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white60),
        prefixIcon: Icon(icon, color: habeshaGold),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildDropdown(
    String label,
    List<String> items,
    String? currentVal,
    Function(String?) onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(15),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: currentVal,
          hint: Text(label, style: const TextStyle(color: Colors.white60)),
          isExpanded: true,
          dropdownColor: const Color(0xFF1A1A1A),
          style: const TextStyle(color: Colors.white),
          items: items
              .map((val) => DropdownMenuItem(value: val, child: Text(val)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
