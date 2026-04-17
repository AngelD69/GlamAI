import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../utils/app_theme.dart';
import '../utils/config.dart';
import '../utils/exceptions.dart';
import '../utils/logger.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  final int userId;
  const ProfileScreen({super.key, required this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const _tag = 'ProfileScreen';

  User? _user;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  String? _selectedGender;
  DateTime? _dob;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() { _loading = true; _error = null; });
    try {
      final user = await ApiService.getMyProfile();
      _nameController.text = user.name;
      _phoneController.text = user.phone ?? '';
      _selectedGender = user.gender;
      _dob = user.dateOfBirth != null ? DateTime.parse(user.dateOfBirth!) : null;
      setState(() { _user = user; _loading = false; });
    } on AuthException {
      _redirectToLogin();
    } on NetworkException catch (e) {
      setState(() { _error = e.message; _loading = false; });
    } on AppException catch (e) {
      setState(() { _error = e.message; _loading = false; });
    }
  }

  Future<void> _saveProfile() async {
    AppLogger.info(_tag, 'Saving profile');
    setState(() => _saving = true);
    try {
      final updates = <String, dynamic>{
        'name': _nameController.text.trim(),
        if (_phoneController.text.isNotEmpty) 'phone': _phoneController.text.trim(),
        if (_selectedGender != null) 'gender': _selectedGender,
        if (_dob != null)
          'date_of_birth':
              '${_dob!.year}-${_dob!.month.toString().padLeft(2, '0')}-${_dob!.day.toString().padLeft(2, '0')}',
      };
      final updated = await ApiService.updateMyProfile(updates);
      setState(() => _user = updated);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated!')),
      );
    } on AuthException {
      _redirectToLogin();
    } on ValidationException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } on AppException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      setState(() => _saving = false);
    }
  }

  Future<void> _uploadPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (picked == null) return;
    try {
      final updated = await ApiService.uploadProfilePicture(File(picked.path));
      if (!mounted) return;
      setState(() => _user = updated);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Photo updated!')),
      );
    } on AuthException {
      _redirectToLogin();
    } on AppException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _pickDob() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dob ?? DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _dob = picked);
  }

  void _redirectToLogin() {
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.wifi_off_rounded,
                            size: 64, color: AppColors.textHint),
                        const SizedBox(height: 16),
                        Text(_error!,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                                fontSize: 14, color: AppColors.textSecondary)),
                        const SizedBox(height: 20),
                        GradientButton(
                            label: 'Retry',
                            onPressed: _loadProfile,
                            icon: Icons.refresh_rounded),
                      ],
                    ),
                  ),
                )
              : CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Container(
                        decoration: BoxDecoration(gradient: primaryGradient),
                        child: SafeArea(
                          bottom: false,
                          child: Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 12),
                                child: Text('My Profile',
                                    style: GoogleFonts.poppins(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white)),
                              ),
                              // Avatar
                              GestureDetector(
                                onTap: _uploadPhoto,
                                child: Stack(
                                  children: [
                                    Container(
                                      width: 96,
                                      height: 96,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.white.withValues(alpha: 0.3),
                                        image: _user?.profilePicture != null
                                            ? DecorationImage(
                                                image: NetworkImage(
                                                    '${AppConfig.baseUrl}${_user!.profilePicture}'),
                                                fit: BoxFit.cover)
                                            : null,
                                        border: Border.all(
                                            color: Colors.white, width: 3),
                                      ),
                                      child: _user?.profilePicture == null
                                          ? const Icon(Icons.person_rounded,
                                              size: 48, color: Colors.white)
                                          : null,
                                    ),
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: Container(
                                        width: 28,
                                        height: 28,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black
                                                  .withValues(alpha: 0.15),
                                              blurRadius: 6,
                                            )
                                          ],
                                        ),
                                        child: const Icon(
                                            Icons.camera_alt_rounded,
                                            size: 16,
                                            color: AppColors.primary),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(_user?.name ?? '',
                                  style: GoogleFonts.poppins(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white)),
                              Text(_user?.email ?? '',
                                  style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      color: Colors.white.withValues(alpha: 0.85))),
                              const SizedBox(height: 28),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Transform.translate(
                        offset: const Offset(0, -20),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 20),
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.07),
                                blurRadius: 20,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Personal Information',
                                  style: GoogleFonts.poppins(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary)),
                              const SizedBox(height: 16),
                              TextField(
                                controller: _nameController,
                                decoration: const InputDecoration(
                                  hintText: 'Full name',
                                  prefixIcon: Icon(Icons.person_outline_rounded,
                                      color: AppColors.textSecondary),
                                ),
                              ),
                              const SizedBox(height: 14),
                              TextField(
                                controller: _phoneController,
                                keyboardType: TextInputType.phone,
                                decoration: const InputDecoration(
                                  hintText: 'Phone number',
                                  prefixIcon: Icon(Icons.phone_outlined,
                                      color: AppColors.textSecondary),
                                ),
                              ),
                              const SizedBox(height: 14),
                              DropdownButtonFormField<String>(
                                initialValue: _selectedGender,
                                decoration: const InputDecoration(
                                  hintText: 'Gender',
                                  prefixIcon: Icon(Icons.wc_rounded,
                                      color: AppColors.textSecondary),
                                ),
                                items: ['Male', 'Female', 'Other']
                                    .map((g) => DropdownMenuItem(
                                        value: g, child: Text(g)))
                                    .toList(),
                                onChanged: (val) =>
                                    setState(() => _selectedGender = val),
                              ),
                              const SizedBox(height: 14),
                              GestureDetector(
                                onTap: _pickDob,
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 14),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F1F5),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.cake_rounded,
                                          color: AppColors.textSecondary,
                                          size: 20),
                                      const SizedBox(width: 12),
                                      Text(
                                        _dob == null
                                            ? 'Date of birth'
                                            : '${_dob!.day}/${_dob!.month}/${_dob!.year}',
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          color: _dob == null
                                              ? AppColors.textHint
                                              : AppColors.textPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 28),
                              GradientButton(
                                label: 'Save Changes',
                                onPressed: _saveProfile,
                                loading: _saving,
                                icon: Icons.check_rounded,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 32)),
                  ],
                ),
    );
  }
}
