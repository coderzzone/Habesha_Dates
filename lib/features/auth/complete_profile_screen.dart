import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/image_service.dart';
import '../../core/services/location_service.dart';

class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController bioController = TextEditingController();
  final TextEditingController ageController = TextEditingController();

  String? selectedGender;
  String? selectedReligion;
  String? selectedHeritage;
  String? selectedIntent;
  File? _imageFile;
  bool isLoading = false;

  final List<String> genders = ['Male', 'Female'];
  final List<String> religions = ['Orthodox', 'Muslim', 'Protestant', 'Catholic', 'Other'];
  final List<String> heritages = ['Addis Ababa', 'Gonder', 'Mekelle', 'Jimma', 'Bahir Dar', 'Hawassa', 'Diaspora'];
  final List<String> intents = ['Marriage', 'Long-term', 'Friendship'];

  @override
  void dispose() {
    nameController.dispose();
    bioController.dispose();
    ageController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );
      if (pickedFile != null) {
        setState(() => _imageFile = File(pickedFile.path));
      }
    } catch (e) {
      debugPrint("Image Pick Error: $e");
      _showSnackBar("Could not pick image. Please check permissions.");
    }
  }

  Future<void> _saveProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showSnackBar("User session lost. Please log in again.");
      return;
    }

    if (nameController.text.isEmpty ||
        ageController.text.isEmpty ||
        selectedGender == null ||
        _imageFile == null ||
        selectedReligion == null) {
      _showSnackBar("Please complete all sections and add a photo");
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

      if (downloadUrl == null) throw Exception("Image upload failed");

      // 2. Location (Best Effort)
      try {
        await LocationService.updateUserLocation();
      } catch (e) {
        debugPrint("Location update skipped during profile completion: $e");
      }

      // 3. Save to Firestore
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'name': nameController.text.trim(),
        'age': int.tryParse(ageController.text.trim()) ?? 18,
        'gender': selectedGender,
        'bio': bioController.text.trim(),
        'religion': selectedReligion,
        'heritage': selectedHeritage,
        'intent': selectedIntent ?? 'Long-term',
        'profileImageUrl': downloadUrl,
        'phoneNumber': user.phoneNumber,
        'email': user.email,
        'createdAt': FieldValue.serverTimestamp(),
        'isOnline': true,
        'lastSeen': FieldValue.serverTimestamp(),
      });

      if (mounted) context.go('/discovery');
    } catch (e) {
      debugPrint("Save Profile Error: $e");
      _showSnackBar("Error saving profile. Please try again.");
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Complete Profile"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.gold, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.gold.withValues(alpha: 0.2),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 70,
                      backgroundColor: AppColors.surface,
                      backgroundImage: _imageFile != null ? FileImage(_imageFile!) : null,
                      child: _imageFile == null
                          ? const Icon(Icons.add_a_photo_outlined, color: AppColors.gold, size: 40)
                          : null,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: AppColors.gold,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.edit, color: Colors.black, size: 20),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),
            _buildTextField(nameController, "Full Name", Icons.person_outline),
            const SizedBox(height: 16),
            _buildTextField(ageController, "Age", Icons.cake_outlined, isNumber: true),
            const SizedBox(height: 16),
            _buildDropdown("Gender", genders, selectedGender, (val) => setState(() => selectedGender = val), Icons.wc),
            const SizedBox(height: 16),
            _buildDropdown("Religion", religions, selectedReligion, (val) => setState(() => selectedReligion = val), Icons.church_outlined),
            const SizedBox(height: 16),
            _buildDropdown("Heritage/Region", heritages, selectedHeritage, (val) => setState(() => selectedHeritage = val), Icons.flag_outlined),
            const SizedBox(height: 16),
            _buildDropdown("Dating Intent", intents, selectedIntent, (val) => setState(() => selectedIntent = val), Icons.favorite_outline),
            const SizedBox(height: 16),
            _buildTextField(bioController, "About Me", Icons.notes_outlined, maxLines: 4),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: isLoading ? null : _saveProfile,
                child: isLoading
                    ? const SizedBox(height: 25, width: 25, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 3))
                    : const Text("Save & Start Matching"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool isNumber = false, int maxLines = 1}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: TextField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        maxLines: maxLines,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white38),
          prefixIcon: Icon(icon, color: AppColors.gold, size: 20),
          border: InputBorder.none,
          floatingLabelStyle: const TextStyle(color: AppColors.gold),
        ),
      ),
    );
  }

  Widget _buildDropdown(String label, List<String> items, String? currentVal, Function(String?) onChanged, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.gold, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: currentVal,
                hint: Text(label, style: const TextStyle(color: Colors.white38, fontSize: 16)),
                isExpanded: true,
                dropdownColor: AppColors.surface,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                items: items.map((val) => DropdownMenuItem(value: val, child: Text(val))).toList(),
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
