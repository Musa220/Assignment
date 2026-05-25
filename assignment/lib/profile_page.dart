import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();

  String? avatarUrl;
  bool isLoading = true;
  bool isSaving = false;
  bool isUploadingPhoto = false;
  String userEmail = '';

  @override
  void initState() {
    super.initState();
    fetchProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> fetchProfile() async {
    setState(() => isLoading = true);
    final user = supabase.auth.currentUser;
    if (user == null) return;

    userEmail = user.email ?? '';

    try {
      final data = await supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .single();

      _nameController.text = data['name'] ?? '';
      _ageController.text = data['age']?.toString() ?? '';
      _heightController.text = data['height']?.toString() ?? '';
      _weightController.text = data['weight']?.toString() ?? '';
      avatarUrl = data['avatar_url'];

      setState(() => isLoading = false);
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  Future<void> saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isSaving = true);
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      await supabase.from('profiles').upsert({
        'id': user.id,
        'name': _nameController.text.trim(),
        'email': userEmail,
        'age': int.tryParse(_ageController.text),
        'height': double.tryParse(_heightController.text),
        'weight': double.tryParse(_weightController.text),
        'avatar_url': avatarUrl,
        'updated_at': DateTime.now().toIso8601String(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Profile saved! ✅', style: GoogleFonts.poppins()),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }

    setState(() => isSaving = false);
  }

  Future<void> pickAndUploadPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (picked == null) return;

    setState(() => isUploadingPhoto = true);
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      final file = File(picked.path);
      final fileExt = picked.path.split('.').last;
      final filePath = 'avatars/${user.id}.$fileExt';

      await supabase.storage
          .from('avatars')
          .upload(filePath, file, fileOptions: const FileOptions(upsert: true));

      final url = supabase.storage.from('avatars').getPublicUrl(filePath);

      setState(() {
        avatarUrl = '$url?t=${DateTime.now().millisecondsSinceEpoch}';
        isUploadingPhoto = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Photo updated! 📷', style: GoogleFonts.poppins()),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } catch (e) {
      setState(() => isUploadingPhoto = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Photo upload failed: $e')));
    }
  }

  // Computed BMI from profile fields
  String get computedBmi {
    final height = double.tryParse(_heightController.text);
    final weight = double.tryParse(_weightController.text);
    if (height == null || weight == null || height == 0) return '--';
    final heightM = height / 100; // assuming cm input
    final bmi = weight / (heightM * heightM);
    return bmi.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('My Profile', style: GoogleFonts.poppins()),
        actions: [
          TextButton.icon(
            onPressed: isSaving ? null : saveProfile,
            icon: isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.save_outlined, color: Colors.white),
            label: Text(
              'Save',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Avatar Section ──
                    Center(
                      child: Column(
                        children: [
                          Stack(
                            children: [
                              GestureDetector(
                                onTap: pickAndUploadPhoto,
                                child: Container(
                                  width: 110,
                                  height: 110,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: colors.primary,
                                      width: 3,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: colors.primary.withOpacity(0.2),
                                        blurRadius: 16,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: ClipOval(
                                    child: isUploadingPhoto
                                        ? Container(
                                            color: colors.primary.withOpacity(
                                              0.1,
                                            ),
                                            child: const Center(
                                              child:
                                                  CircularProgressIndicator(),
                                            ),
                                          )
                                        : avatarUrl != null
                                        ? Image.network(
                                            avatarUrl!,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) =>
                                                _defaultAvatar(colors),
                                          )
                                        : _defaultAvatar(colors),
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 2,
                                right: 2,
                                child: GestureDetector(
                                  onTap: pickAndUploadPhoto,
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: colors.primary,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 2,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.camera_alt,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            userEmail,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Tap photo to change',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: colors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    // ── Personal Info ──
                    _sectionTitle('Personal Information'),
                    const SizedBox(height: 12),

                    _buildField(
                      controller: _nameController,
                      label: 'Full Name',
                      icon: Icons.person_outline,
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Name is required' : null,
                    ),
                    const SizedBox(height: 14),

                    _buildField(
                      controller: _ageController,
                      label: 'Age',
                      icon: Icons.cake_outlined,
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Age is required';
                        final age = int.tryParse(v);
                        if (age == null || age < 1 || age > 120) {
                          return 'Enter a valid age';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 28),

                    // ── Body Measurements ──
                    _sectionTitle('Body Measurements'),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: _buildField(
                            controller: _heightController,
                            label: 'Height (cm)',
                            icon: Icons.height,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _buildField(
                            controller: _weightController,
                            label: 'Weight (kg)',
                            icon: Icons.monitor_weight_outlined,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // BMI Preview card
                    if (_heightController.text.isNotEmpty &&
                        _weightController.text.isNotEmpty)
                      _bmiPreviewCard(colors),

                    const SizedBox(height: 30),

                    // Save button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: isSaving ? null : saveProfile,
                        icon: isSaving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.save),
                        label: Text(
                          isSaving ? 'Saving...' : 'Save Profile',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _defaultAvatar(ColorScheme colors) {
    return Container(
      color: colors.primary.withOpacity(0.1),
      child: Icon(Icons.person, size: 60, color: colors.primary),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    final colors = Theme.of(context).colorScheme;
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: colors.primary),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colors.primary, width: 2),
        ),
      ),
    );
  }

  Widget _bmiPreviewCard(ColorScheme colors) {
    final bmi = double.tryParse(computedBmi);
    String category = '--';
    Color catColor = Colors.grey;

    if (bmi != null) {
      if (bmi < 18.5) {
        category = 'Underweight';
        catColor = Colors.blue;
      } else if (bmi <= 24.9) {
        category = 'Healthy';
        catColor = Colors.green;
      } else if (bmi <= 29.9) {
        category = 'Overweight';
        catColor = Colors.orange;
      } else {
        category = 'Obese';
        catColor = Colors.red;
      }
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: catColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: catColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.calculate_outlined, color: catColor, size: 32),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your BMI',
                style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey),
              ),
              Text(
                computedBmi,
                style: GoogleFonts.poppins(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: catColor,
                ),
              ),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: catColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              category,
              style: GoogleFonts.poppins(
                color: catColor,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
