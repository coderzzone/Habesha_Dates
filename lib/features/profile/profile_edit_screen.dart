import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  final _heritageController = TextEditingController();
  final _jobController = TextEditingController();
  
  // Detailed Traits
  String? _selectedReligion;
  String? _selectedEducation;
  String? _selectedHeight;
  String? _selectedSmoking;

  File? _imageFile;
  String? _currentImageUrl;
  bool _isLoading = false;

  final String uid = FirebaseAuth.instance.currentUser?.uid ?? "";
  static const Color habeshaGold = Color(0xFFD4AF35);
  static const Color backgroundDark = Color(0xFF0A0A0A);

  // Constants for ImageKit (Consider moving these to a secure config file)
  final String imageKitPrivateKey = "private_3N4/zd4hm3FynTzX/P/sPVucY94="; 
  final String imageKitUploadEndpoint = "https://upload.imagekit.io/api/v1/files/upload";

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (doc.exists) {
      final data = doc.data()!;
      setState(() {
        _nameController.text = data['name'] ?? "";
        _bioController.text = data['bio'] ?? "";
        _heritageController.text = data['heritage'] ?? "";
        _jobController.text = data['jobTitle'] ?? "";
        _selectedReligion = data['religion'];
        _selectedEducation = data['education'];
        _selectedHeight = data['height'];
        _selectedSmoking = data['smoking'];
        _currentImageUrl = data['profileImageUrl'];
      });
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (pickedFile != null) setState(() => _imageFile = File(pickedFile.path));
  }

  Future<String?> _uploadToImageKit(File file) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse(imageKitUploadEndpoint));
      String authString = base64Encode(utf8.encode("$imageKitPrivateKey:"));
      request.headers.addAll({'Authorization': 'Basic $authString'});
      request.fields['fileName'] = "profile_$uid.jpg";
      request.fields['useUniqueFileName'] = "true";
      request.fields['folder'] = "/user_profiles/";
      request.files.add(await http.MultipartFile.fromPath('file', file.path));
      
      var response = await request.send();
      var responseData = await response.stream.bytesToString();
      var jsonResponse = jsonDecode(responseData);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonResponse['url'];
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      String? finalImageUrl = _currentImageUrl;
      if (_imageFile != null) {
        final uploadedUrl = await _uploadToImageKit(_imageFile!);
        if (uploadedUrl != null) {
          finalImageUrl = uploadedUrl;
        }
      }

      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'name': _nameController.text.trim(),
        'bio': _bioController.text.trim(),
        'heritage': _heritageController.text.trim(),
        'jobTitle': _jobController.text.trim(),
        'religion': _selectedReligion,
        'education': _selectedEducation,
        'height': _selectedHeight,
        'smoking': _selectedSmoking,
        'profileImageUrl': finalImageUrl,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profile updated!")));
        context.pop();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Update failed: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundDark,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text("Edit Profile", style: TextStyle(color: habeshaGold)),
        leading: IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => context.pop()),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveProfile,
            child: _isLoading 
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: habeshaGold))
              : const Text("DONE", style: TextStyle(color: habeshaGold, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildImageSection(),
              const SizedBox(height: 30),
              
              _buildSectionHeader("BASIC INFO"),
              _buildTextField("Name", _nameController),
              _buildTextField("Job Title", _jobController),
              _buildTextField("Heritage (e.g. Gondar, Axum)", _heritageController),
              
              const SizedBox(height: 30),
              _buildSectionHeader("ABOUT ME"),
              _buildTextField("Bio", _bioController, maxLines: 4, hint: "Tell them something interesting..."),

              const SizedBox(height: 30),
              _buildSectionHeader("Dating Essentials"),
              _buildSelectionTile(Icons.height, "Height", _selectedHeight ?? "Add", () => _showPicker("Height", ["150cm", "160cm", "170cm", "180cm", "190cm+"], (v) => setState(() => _selectedHeight = v))),
              _buildSelectionTile(Icons.school, "Education", _selectedEducation ?? "Add", () => _showPicker("Education", ["Bachelors", "Masters", "PhD", "High School"], (v) => setState(() => _selectedEducation = v))),
              _buildSelectionTile(Icons.church, "Religion", _selectedReligion ?? "Add", () => _showPicker("Religion", ["Orthodox", "Muslim", "Protestant", "Catholic", "Other"], (v) => setState(() => _selectedReligion = v))),
              _buildSelectionTile(Icons.smoking_rooms, "Smoking", _selectedSmoking ?? "Add", () => _showPicker("Smoking", ["Never", "Socially", "Regularly"], (v) => setState(() => _selectedSmoking = v))),
              
              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(title, style: const TextStyle(color: habeshaGold, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
    );
  }

  Widget _buildImageSection() {
    ImageProvider? imageProvider;
    if (_imageFile != null) {
      imageProvider = FileImage(_imageFile!);
    } else if (_currentImageUrl != null && _currentImageUrl!.isNotEmpty) {
      imageProvider = CachedNetworkImageProvider(_currentImageUrl!);
    }

    return Center(
      child: Column(
        children: [
          GestureDetector(
            onTap: _pickImage,
            child: CircleAvatar(
              radius: 80,
              backgroundColor: Colors.white10,
              backgroundImage: imageProvider,
              child: imageProvider == null ? const Icon(Icons.add_a_photo, color: habeshaGold, size: 40) : null,
            ),
          ),
          const SizedBox(height: 10),
          const Text("Change Profile Photo", style: TextStyle(color: Colors.white54, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {int maxLines = 1, String? hint}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white24),
          labelStyle: const TextStyle(color: Colors.white38),
          filled: true,
          fillColor: const Color(0xFF1A1A1A),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        ),
      ),
    );
  }

  Widget _buildSelectionTile(IconData icon, String label, String value, VoidCallback onTap) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
      leading: Icon(icon, color: Colors.white54, size: 22),
      title: Text(label, style: const TextStyle(color: Colors.white, fontSize: 15)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: TextStyle(color: value == "Add" ? Colors.white24 : habeshaGold, fontSize: 15)),
          const Icon(Icons.chevron_right, color: Colors.white24),
        ],
      ),
    );
  }

  void _showPicker(String title, List<String> options, Function(String) onSelect) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              ...options.map((opt) => ListTile(
                title: Text(opt, style: const TextStyle(color: Colors.white)),
                onTap: () {
                  onSelect(opt);
                  Navigator.pop(context);
                },
              )),
            ],
          ),
        );
      },
    );
  }
}