import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'dart:convert';

class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  static const Color habeshaGold = Color(0xFFD4AF35);
  static const Color backgroundDark = Color(0xFF0A0A0A);

  // --- IMAGEKIT CONFIG ---
  // Ensure "Allow unsigned upload" is ON in ImageKit Settings > Security
  final String _ikPublicKey = "public_328gQi1XhxJ5oKR75qD9BTiT7LA="; // REPLACE THIS
  final String _ikEndpoint = "https://ik.imagekit.io/ddw3thfez"; // REPLACE THIS

  final TextEditingController nameController = TextEditingController();
  final TextEditingController bioController = TextEditingController();
  final TextEditingController ageController = TextEditingController();

  String? selectedReligion;
  String? selectedHeritage;
  File? _imageFile;
  bool isLoading = false;

  final List<String> religions = ['Orthodox', 'Muslim', 'Protestant', 'Catholic', 'Other'];
  final List<String> heritages = ['Addis Ababa', 'Gonder', 'Mekelle', 'Jimma', 'Bahir Dar', 'Hawassa', 'Diaspora'];

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (pickedFile != null) {
      setState(() => _imageFile = File(pickedFile.path));
    }
  }

  // --- STRICT UNSIGNED UPLOAD ---
 
Future<String?> _uploadToImageKit(File file, String uid) async {
  final dio = Dio();
  String fileName = "profile_$uid.jpg";
  
  // Use your Private Key
  String privateKey = "private_3N4/zd4hm3FynTzX/P/sPVucY94="; 

  // Basic Auth: private_key + ":" encoded in base64
  String basicAuth = 'Basic ${base64Encode(utf8.encode('$privateKey:'))}';

  FormData formData = FormData.fromMap({
    "file": await MultipartFile.fromFile(
      file.path, 
      filename: fileName,
      contentType: DioMediaType('image', 'jpeg'),
    ),
    "fileName": fileName,
    "publicKey": _ikPublicKey, // <--- ADD THIS BACK IN
    "useUniqueFileName": "true",
    "folder": "/profile_pics",
  });

  try {
    final response = await dio.post(
      "https://upload.imagekit.io/api/v1/files/upload",
      data: formData,
      options: Options(
        headers: {
          "Authorization": basicAuth,
          "Accept": "*/*", // Helps ensure the server accepts the response
        },
      ),
    );

    if (response.statusCode == 200) {
      return response.data['url'];
    }
  } on DioException catch (e) {
    debugPrint("ImageKit Final Error: ${e.response?.data}");
    // This will tell us if it's an Auth issue or a File issue
    rethrow;
  }
  return null;
}

  Future<void> _saveProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (nameController.text.isEmpty || ageController.text.isEmpty || _imageFile == null || selectedReligion == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please complete all fields and add a photo")),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      // 1. Upload
      String? downloadUrl = await _uploadToImageKit(_imageFile!, user.uid);

      if (downloadUrl == null) throw Exception("Upload returned no URL");

      // 2. Save to Firestore
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'name': nameController.text.trim(),
        'age': int.tryParse(ageController.text.trim()) ?? 18,
        'bio': bioController.text.trim(),
        'religion': selectedReligion,
        'heritage': selectedHeritage,
        'profileImageUrl': downloadUrl,
        'phoneNumber': user.phoneNumber,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) context.go('/discovery');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Upload Error: Check if 'Unsigned Upload' is enabled in ImageKit Dashboard")),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundDark,
      appBar: AppBar(title: const Text("Complete Profile", style: TextStyle(color: habeshaGold)), backgroundColor: Colors.transparent, elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 60,
                backgroundColor: Colors.white10,
                backgroundImage: _imageFile != null ? FileImage(_imageFile!) : null,
                child: _imageFile == null ? const Icon(Icons.camera_alt, color: habeshaGold, size: 40) : null,
              ),
            ),
            const SizedBox(height: 30),
            _buildTextField(nameController, "Full Name", Icons.person),
            const SizedBox(height: 15),
            _buildTextField(ageController, "Age", Icons.calendar_today, isNumber: true),
            const SizedBox(height: 15),
            _buildDropdown("Religion", religions, selectedReligion, (val) => setState(() => selectedReligion = val)),
            const SizedBox(height: 15),
            _buildDropdown("Heritage/Region", heritages, selectedHeritage, (val) => setState(() => selectedHeritage = val)),
            const SizedBox(height: 15),
            _buildTextField(bioController, "Bio", Icons.book, maxLines: 3),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: habeshaGold, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                onPressed: isLoading ? null : _saveProfile,
                child: isLoading 
                  ? const CircularProgressIndicator(color: Colors.black) 
                  : const Text("Save & Start Matching", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool isNumber = false, int maxLines = 1}) {
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
        fillColor: Colors.white.withOpacity(0.05),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildDropdown(String label, List<String> items, String? currentVal, Function(String?) onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(15)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: currentVal,
          hint: Text(label, style: const TextStyle(color: Colors.white60)),
          isExpanded: true,
          dropdownColor: const Color(0xFF1A1A1A),
          style: const TextStyle(color: Colors.white),
          items: items.map((val) => DropdownMenuItem(value: val, child: Text(val))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}