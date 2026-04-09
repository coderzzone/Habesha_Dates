import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/image_service.dart';
import '../../core/theme/app_theme.dart';

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

  String? _selectedGender;
  String? _selectedReligion;
  String? _selectedEducation;
  String? _selectedHeight;
  String? _selectedSmoking;
  String? _selectedIntent;

  // Telegram Style: List for all photos (Main is index 0)
  List<String> _profileImages = [];
  final Map<int, File?> _newImages = {}; // key is index
  bool _isLoading = false;

  final String uid = FirebaseAuth.instance.currentUser?.uid ?? "";

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _heritageController.dispose();
    _jobController.dispose();
    super.dispose();
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
        _selectedGender = data['gender'];
        _selectedReligion = data['religion'];
        _selectedEducation = data['education'];
        _selectedHeight = data['height'];
        _selectedSmoking = data['smoking'];
        _selectedIntent = data['intent'];
        
        if (data['profileImages'] != null) {
          _profileImages = List<String>.from(data['profileImages']);
        } else if (data['profileImageUrl'] != null) {
          _profileImages = [data['profileImageUrl']];
        }
      });
    }
  }

  Future<void> _pickImage(int index) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery, 
      imageQuality: 70,
    );
    if (pickedFile != null) {
      setState(() => _newImages[index] = File(pickedFile.path));
    }
  }

  void _removeImage(int index) {
    setState(() {
      if (index < _profileImages.length) {
        _profileImages.removeAt(index);
      } else {
        _newImages.remove(index);
      }
    });
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    
    try {
      List<String> finalImageUrls = List.from(_profileImages);
      
      // Upload new images (sorted by their index)
      final sortedIndices = _newImages.keys.toList()..sort();
      for (var idx in sortedIndices) {
        final file = _newImages[idx];
        if (file != null) {
          final fileName = "profile_${uid}_${DateTime.now().millisecondsSinceEpoch}_$idx.jpg";
          final result = await ImageService.uploadImage(file, fileName);
          if (result != null && result != "size_limit_exceeded") {
            finalImageUrls.add(result);
          }
        }
      }

      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'name': _nameController.text.trim(),
        'bio': _bioController.text.trim(),
        'heritage': _heritageController.text.trim(),
        'jobTitle': _jobController.text.trim(),
        'gender': _selectedGender,
        'religion': _selectedReligion,
        'education': _selectedEducation,
        'height': _selectedHeight,
        'smoking': _selectedSmoking,
        'intent': _selectedIntent,
        'profileImages': finalImageUrls,
        'profileImageUrl': finalImageUrls.isNotEmpty ? finalImageUrls.first : null,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profile updated!")));
        context.pop();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Update failed: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("Edit Profile", style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold)),
        centerTitle: true,
        leading: IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => context.pop()),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveProfile,
            child: _isLoading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.gold))
                : const Text("SAVE", style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildMainAvatar(),
              const SizedBox(height: 25),
              _buildHorizontalGallery(),
              const SizedBox(height: 35),
              
              _buildSection("BRANDING & BIO", [
                _buildTextField("Full Name", _nameController, Icons.person_outline),
                _buildTextField("Short Bio", _bioController, Icons.notes, maxLines: 3, hint: "Tell them about yourself..."),
              ]),

              _buildSection("IDENTITY", [
                _buildSelectionTile(Icons.wc, "Gender", _selectedGender ?? "Select", 
                  () => _showPicker("Gender", ["Male", "Female"], (v) => setState(() => _selectedGender = v))),
                _buildTextField("Heritage", _heritageController, Icons.map_outlined, hint: "e.g. Addis Ababa"),
                _buildTextField("Job Title", _jobController, Icons.work_outline, hint: "e.g. Designer"),
              ]),

              _buildSection("DETAILS", [
                _buildSelectionTile(Icons.church_outlined, "Religion", _selectedReligion ?? "Select", 
                  () => _showPicker("Religion", ["Orthodox", "Muslim", "Protestant", "Catholic", "Other"], (v) => setState(() => _selectedReligion = v))),
                _buildSelectionTile(Icons.school_outlined, "Education", _selectedEducation ?? "Select", 
                  () => _showPicker("Education", ["Bachelors", "Masters", "PhD", "High School"], (v) => setState(() => _selectedEducation = v))),
                _buildSelectionTile(Icons.height, "Height", _selectedHeight ?? "Select", 
                  () => _showPicker("Height", ["150cm", "160cm", "170cm", "180cm", "190cm+"], (v) => setState(() => _selectedHeight = v))),
              ]),

              _buildSection("LIFESTYLE & INTENT", [
                _buildSelectionTile(Icons.favorite_outline, "Intent", _selectedIntent ?? "Select", 
                  () => _showPicker("What are you looking for?", ["Marriage", "Long-term", "Friendship", "Hobby Partner"], (v) => setState(() => _selectedIntent = v))),
                _buildSelectionTile(Icons.smoking_rooms_outlined, "Smoking", _selectedSmoking ?? "Select", 
                  () => _showPicker("Smoking", ["Never", "Socially", "Regularly"], (v) => setState(() => _selectedSmoking = v))),
              ]),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainAvatar() {
    ImageProvider? imageProvider;
    if (_newImages.containsKey(0)) {
      imageProvider = FileImage(_newImages[0]!);
    } else if (_profileImages.isNotEmpty) {
      imageProvider = CachedNetworkImageProvider(_profileImages.first);
    }

    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        Container(
          width: 130, height: 130,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.surface,
            border: Border.all(color: AppColors.gold, width: 3),
            boxShadow: [
              BoxShadow(color: Colors.black45, blurRadius: 15, spreadRadius: 2),
            ],
            image: imageProvider != null ? DecorationImage(image: imageProvider, fit: BoxFit.cover) : null,
          ),
          child: imageProvider == null ? const Icon(Icons.person, color: Colors.white24, size: 60) : null,
        ),
        GestureDetector(
          onTap: () => _pickImage(0),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(color: AppColors.gold, shape: BoxShape.circle),
            child: const Icon(Icons.camera_alt, color: Colors.black, size: 20),
          ),
        ),
      ],
    );
  }

  Widget _buildHorizontalGallery() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("GALLERY", style: TextStyle(color: AppColors.gold, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 6, // Show 5 more slots + current ones
            itemBuilder: (context, index) {
              int trueIndex = index + 1; // 0 is main
              
              ImageProvider? provider;
              bool exists = trueIndex < _profileImages.length;
              bool isNew = _newImages.containsKey(trueIndex);

              if (exists) {
                provider = CachedNetworkImageProvider(_profileImages[trueIndex]);
              } else if (isNew) {
                provider = FileImage(_newImages[trueIndex]!);
              }

              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: GestureDetector(
                  onTap: () => (exists || isNew) ? null : _pickImage(trueIndex),
                  child: Container(
                    width: 80,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(15),
                      image: provider != null ? DecorationImage(image: provider, fit: BoxFit.cover) : null,
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Stack(
                      children: [
                        if (provider == null) const Center(child: Icon(Icons.add, color: Colors.white24)),
                        if (provider != null)
                          Positioned(
                            top: 4, right: 4,
                            child: GestureDetector(
                              onTap: () => _removeImage(trueIndex),
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                                child: const Icon(Icons.close, color: Colors.white, size: 12),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, top: 25, bottom: 10),
          child: Text(title, style: const TextStyle(color: AppColors.gold, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
        ),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, {int maxLines = 1, String? hint}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white, fontSize: 15),
      decoration: InputDecoration(
        labelText: label, hintText: hint,
        labelStyle: const TextStyle(color: Colors.white38),
        prefixIcon: Icon(icon, color: AppColors.gold.withValues(alpha: 0.5), size: 20),
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  Widget _buildSelectionTile(IconData icon, String label, String value, VoidCallback onTap) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: AppColors.gold.withValues(alpha: 0.5), size: 20),
      title: Text(label, style: const TextStyle(color: Colors.white70, fontSize: 15)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.w600)),
          const Icon(Icons.chevron_right, color: Colors.white24, size: 20),
        ],
      ),
    );
  }

  void _showPicker(String title, List<String> options, Function(String) onSelect) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              ...options.map((opt) => ListTile(
                    title: Text(opt, style: const TextStyle(color: Colors.white)),
                    onTap: () {
                      onSelect(opt);
                      Navigator.pop(context);
                    },
                  )),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }
}
