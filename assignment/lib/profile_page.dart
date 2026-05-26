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
  final SupabaseClient supabase = Supabase.instance.client;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  final TextEditingController heightController = TextEditingController();
  final TextEditingController weightController = TextEditingController();

  String? profileImageUrl;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  Future<void> loadProfile() async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      return;
    }

    try {
      final response = await supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (response != null) {
        setState(() {
          nameController.text = response['full_name']?.toString() ?? '';
          ageController.text = response['age']?.toString() ?? '';
          heightController.text = response['height']?.toString() ?? '';
          weightController.text = response['weight']?.toString() ?? '';
          profileImageUrl = response['avatar_url']?.toString();
        });
      }
    } catch (e) {
      showMessage('Profile load failed: $e');
    }
  }

  Future<void> pickAndUploadImage() async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      showMessage('User not logged in');
      return;
    }

    try {
      final ImagePicker picker = ImagePicker();

      final XFile? pickedImage = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (pickedImage == null) {
        return;
      }

      setState(() {
        isLoading = true;
      });

      // File() use korchi na. Bytes use korchi.
      // Eta phone/app/web sob jaygay safer.
      final bytes = await pickedImage.readAsBytes();

      // Protibar new file name hobe, tai 2nd time upload fail korbe na
      final String filePath =
          '${user.id}/profile_${DateTime.now().millisecondsSinceEpoch}.jpg';

      await supabase.storage
          .from('avatars')
          .uploadBinary(
            filePath,
            bytes,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              cacheControl: '3600',
            ),
          );

      final String publicUrl = supabase.storage
          .from('avatars')
          .getPublicUrl(filePath);

      await supabase.from('profiles').upsert({
        'id': user.id,
        'email': user.email,
        'avatar_url': publicUrl,
      });

      setState(() {
        profileImageUrl = publicUrl;
      });

      showMessage('Photo uploaded successfully');
    } catch (e) {
      showMessage('Photo upload failed: $e');
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> saveProfile() async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      showMessage('User not logged in');
      return;
    }

    try {
      setState(() {
        isLoading = true;
      });

      await supabase.from('profiles').upsert({
        'id': user.id,
        'email': user.email,
        'full_name': nameController.text.trim(),
        'age': int.tryParse(ageController.text.trim()),
        'height': double.tryParse(heightController.text.trim()),
        'weight': double.tryParse(weightController.text.trim()),
        'avatar_url': profileImageUrl,
      });

      showMessage('Profile saved successfully');
    } catch (e) {
      showMessage('Profile save failed: $e');
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.black87),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    ageController.dispose();
    heightController.dispose();
    weightController.dispose();
    super.dispose();
  }

  Widget buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: GoogleFonts.poppins(fontSize: 18, color: Colors.black),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(color: Colors.grey[700]),
        prefixIcon: Icon(icon, color: const Color(0xFF625BFF)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFF625BFF), width: 2),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = supabase.auth.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF625BFF),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'My Profile',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(onPressed: saveProfile, icon: const Icon(Icons.save)),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const SizedBox(height: 20),

                  GestureDetector(
                    onTap: pickAndUploadImage,
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 70,
                          backgroundColor: Colors.white,
                          backgroundImage:
                              profileImageUrl != null &&
                                  profileImageUrl!.isNotEmpty
                              ? NetworkImage(profileImageUrl!)
                              : null,
                          child:
                              profileImageUrl == null ||
                                  profileImageUrl!.isEmpty
                              ? const Icon(
                                  Icons.person,
                                  size: 80,
                                  color: Color(0xFF625BFF),
                                )
                              : null,
                        ),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: const BoxDecoration(
                            color: Color(0xFF625BFF),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  Text(
                    user?.email ?? 'No email',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      color: Colors.grey[600],
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    'Tap photo to change',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: const Color(0xFF625BFF),
                    ),
                  ),

                  const SizedBox(height: 35),

                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Personal Information',
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(height: 15),

                  buildTextField(
                    controller: nameController,
                    label: 'Full Name',
                    icon: Icons.person_outline,
                  ),

                  const SizedBox(height: 18),

                  buildTextField(
                    controller: ageController,
                    label: 'Age',
                    icon: Icons.cake_outlined,
                    keyboardType: TextInputType.number,
                  ),

                  const SizedBox(height: 30),

                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Body Measurements',
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(height: 15),

                  Row(
                    children: [
                      Expanded(
                        child: buildTextField(
                          controller: heightController,
                          label: 'Height (cm)',
                          icon: Icons.height,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: buildTextField(
                          controller: weightController,
                          label: 'Weight (kg)',
                          icon: Icons.monitor_weight_outlined,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 45),

                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton.icon(
                      onPressed: saveProfile,
                      icon: const Icon(Icons.save),
                      label: Text(
                        'Save Profile',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF625BFF),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
