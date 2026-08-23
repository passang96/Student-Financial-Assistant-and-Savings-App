import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/gradient_button.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({
    super.key,
    this.initialName = '',
    this.initialEmail = '',
    this.initialUniversity = '',
  });

  final String initialName;
  final String initialEmail;
  final String initialUniversity;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _universityController;

  final TextEditingController _phoneController = TextEditingController();

  bool _isSaving = false;
  bool _isLoadingProfile = true;

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(text: widget.initialName);

    _emailController = TextEditingController(text: widget.initialEmail);

    _universityController = TextEditingController(
      text: widget.initialUniversity,
    );

    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = _auth.currentUser;

    if (user == null) {
      if (mounted) {
        setState(() {
          _isLoadingProfile = false;
        });
      }

      return;
    }

    try {
      final snapshot = await _firestore.collection('users').doc(user.uid).get();

      final data = snapshot.data();

      if (data != null) {
        final String savedName = data['name']?.toString().trim() ?? '';

        final String savedPhone = data['phone']?.toString().trim() ?? '';

        final String savedUniversity =
            data['university']?.toString().trim() ?? '';

        if (savedName.isNotEmpty) {
          _nameController.text = savedName;
        } else if ((user.displayName ?? '').trim().isNotEmpty) {
          _nameController.text = user.displayName!.trim();
        }

        _phoneController.text = savedPhone;

        if (savedUniversity.isNotEmpty) {
          _universityController.text = savedUniversity;
        }
      } else {
        if ((user.displayName ?? '').trim().isNotEmpty) {
          _nameController.text = user.displayName!.trim();
        }
      }

      _emailController.text = user.email ?? widget.initialEmail;
    } catch (_) {
      _emailController.text = user.email ?? widget.initialEmail;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _isLoadingProfile = false;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _universityController.dispose();
    _phoneController.dispose();

    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final user = _auth.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must be logged in to update your profile.'),
          backgroundColor: Colors.red,
        ),
      );

      return;
    }

    final String name = _nameController.text.trim();

    final String phone = _phoneController.text.trim();

    final String university = _universityController.text.trim();

    /*
     * Email is controlled by Firebase Authentication.
     * We do not change the login email from this profile screen
     * because Firebase may require verification/re-authentication.
     */
    final String currentEmail = user.email?.trim() ?? '';

    if (_emailController.text.trim() != currentEmail) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email cannot be changed from this screen.'),
          backgroundColor: Colors.orange,
        ),
      );

      _emailController.text = currentEmail;

      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      /*
       * Update Firebase Authentication display name.
       * The Dashboard can use this value for "Hello, <name>".
       */
      await user.updateDisplayName(name);

      await user.reload();

      /*
       * Save the full profile under:
       *
       * users/{firebaseUid}
       *
       * SetOptions(merge: true) means existing account data
       * will not be deleted.
       */
      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'name': name,
        'email': currentEmail,
        'phone': phone,
        'university': university,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully'),
          backgroundColor: Colors.green,
        ),
      );

      /*
       * true tells ProfileScreen that something changed,
       * so we can refresh it there if needed.
       */
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not update profile: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingProfile) {
      return Scaffold(
        backgroundColor: AppColors.backgroundLight,
        appBar: AppBar(
          backgroundColor: AppColors.backgroundLight,
          elevation: 0,
          title: const Text(
            'Edit Profile',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          iconTheme: const IconThemeData(color: AppColors.textPrimary),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundLight,
        elevation: 0,
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 44,
                        backgroundColor: AppColors.primaryTeal.withValues(
                          alpha: 0.15,
                        ),
                        child: Text(
                          _nameController.text.trim().isNotEmpty
                              ? _nameController.text.trim()[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryTeal,
                          ),
                        ),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: AppColors.primaryTeal,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.person_outline,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                CustomTextField(
                  label: 'Full Name',
                  hint: 'Enter your full name',
                  icon: Icons.person_outline,
                  controller: _nameController,
                  keyboardType: TextInputType.name,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Name is required';
                    }

                    if (value.trim().length < 2) {
                      return 'Enter a valid name';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 18),

                CustomTextField(
                  label: 'Email',
                  hint: 'Your login email',
                  icon: Icons.mail_outline,
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Email is required';
                    }

                    if (!value.contains('@')) {
                      return 'Enter a valid email address';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 6),

                const Text(
                  'Your login email is managed by Firebase Authentication and cannot be changed here.',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),

                const SizedBox(height: 18),

                CustomTextField(
                  label: 'Phone Number',
                  hint: 'Enter your phone number',
                  icon: Icons.phone_outlined,
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return null;
                    }

                    if (value.trim().length < 8) {
                      return 'Enter a valid phone number';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 18),

                CustomTextField(
                  label: 'University',
                  hint: 'Enter your university',
                  icon: Icons.school_outlined,
                  controller: _universityController,
                  keyboardType: TextInputType.text,
                  validator: (value) => null,
                ),

                const SizedBox(height: 32),

                GradientButton(
                  label: 'Save Changes',
                  isLoading: _isSaving,
                  onPressed: _handleSave,
                ),

                const SizedBox(height: 12),

                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: _isSaving
                        ? null
                        : () {
                            Navigator.of(context).pop(false);
                          },
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
