import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/user.dart';
import '../services/api_service.dart';
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
    AppLogger.info(_tag, 'Loading profile for user ${widget.userId}');
    setState(() { _loading = true; _error = null; });
    try {
      final user = await ApiService.getMyProfile();
      _nameController.text = user.name;
      _phoneController.text = user.phone ?? '';
      _selectedGender = user.gender;
      _dob = user.dateOfBirth != null ? DateTime.parse(user.dateOfBirth!) : null;
      setState(() { _user = user; _loading = false; });
      AppLogger.debug(_tag, 'Profile loaded');
    } on AuthException catch (e) {
      AppLogger.warning(_tag, 'Auth expired: $e');
      _redirectToLogin();
    } on NetworkException catch (e) {
      AppLogger.error(_tag, 'Network error loading profile', e);
      setState(() { _error = e.message; _loading = false; });
    } on AppException catch (e) {
      AppLogger.error(_tag, 'Error loading profile', e);
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
    } on AuthException catch (e) {
      AppLogger.warning(_tag, 'Auth expired on save: $e');
      _redirectToLogin();
    } on ValidationException catch (e) {
      AppLogger.warning(_tag, 'Validation error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } on NetworkException catch (e) {
      AppLogger.error(_tag, 'Network error saving profile', e);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } on AppException catch (e) {
      AppLogger.error(_tag, 'Error saving profile', e);
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
    AppLogger.info(_tag, 'Uploading profile picture');
    try {
      final updated = await ApiService.uploadProfilePicture(File(picked.path));
      if (!mounted) return;
      setState(() => _user = updated);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Photo updated!')),
      );
    } on AuthException catch (e) {
      AppLogger.warning(_tag, 'Auth expired on photo upload: $e');
      _redirectToLogin();
    } on NetworkException catch (e) {
      AppLogger.error(_tag, 'Network error uploading photo', e);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } on AppException catch (e) {
      AppLogger.error(_tag, 'Error uploading photo', e);
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
      appBar: AppBar(title: const Text('My Profile')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.wifi_off, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text(_error!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.grey)),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _loadProfile,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: _uploadPhoto,
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 50,
                              backgroundColor:
                                  const Color(0xFFE91E8C).withValues(alpha: 0.15),
                              backgroundImage: _user?.profilePicture != null
                                  ? NetworkImage(
                                      '${AppConfig.baseUrl}${_user!.profilePicture}')
                                  : null,
                              child: _user?.profilePicture == null
                                  ? const Icon(Icons.person,
                                      size: 50, color: Color(0xFFE91E8C))
                                  : null,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFE91E8C),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.camera_alt,
                                    size: 16, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(_user?.email ?? '',
                          style: const TextStyle(color: Colors.grey)),
                      const SizedBox(height: 24),
                      TextField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                            labelText: 'Full Name',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.person)),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _phoneController,
                        decoration: const InputDecoration(
                            labelText: 'Phone',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.phone)),
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedGender,
                        decoration: const InputDecoration(
                            labelText: 'Gender',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.wc)),
                        items: const [
                          DropdownMenuItem(value: 'Male', child: Text('Male')),
                          DropdownMenuItem(value: 'Female', child: Text('Female')),
                          DropdownMenuItem(value: 'Other', child: Text('Other')),
                        ],
                        onChanged: (val) => setState(() => _selectedGender = val),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: _pickDob,
                        icon: const Icon(Icons.cake),
                        label: Text(_dob == null
                            ? 'Date of Birth'
                            : '${_dob!.year}-${_dob!.month.toString().padLeft(2, '0')}-${_dob!.day.toString().padLeft(2, '0')}'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48),
                          side: const BorderSide(color: Colors.grey),
                        ),
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _saving ? null : _saveProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE91E8C),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: _saving
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text('Save Profile',
                                  style: TextStyle(fontSize: 16)),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
