import 'package:drivebuddy/Features/Login/presenation/view/login_view.dart';
import 'package:drivebuddy/core/Utils/Shared%20Methods.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:drivebuddy/Features/Profile/presentation/manger/profile_cubit.dart';
import 'package:drivebuddy/Features/Profile/presentation/manger/profile_state.dart';

import '../data/ProfileModel.dart';

class ProfileScreen extends StatelessWidget {
  final String uid;

  const ProfileScreen({required this.uid});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ProfileCubit()..getProfile(uid),
      child: Scaffold(
        backgroundColor: Color(0xFFFFF3EE),
        appBar: _buildAppBar(context),
        body: _buildBody(context),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(context) {
    return AppBar(
      elevation: 0,
      backgroundColor: Color(0xFFE67E5E),
      leading: Container(),
      title: Text(
        'User Profile',
        style: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.logout_rounded, color: Colors.white),
          onPressed: () {
            showDialog(
              context: context,
              builder: (BuildContext dialogContext) {
                return AlertDialog(
                  title: Text('Logout'),
                  content: Text('Are you sure you want to logout?'),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(dialogContext).pop(); // Close dialog
                      },
                      child: Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {

                        navigateAndFinished(context, LoginView());
                      },
                      child: Text('Logout'),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildBody(BuildContext context) {
    return BlocConsumer<ProfileCubit, ProfileState>(
      listener: (context, state) {
        if (state is ProfileUpdated) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Profile updated successfully'),
                ],
              ),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        } else if (state is ProfileError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.white),
                  SizedBox(width: 8),
                  Text(state.message),
                ],
              ),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
      },
      builder: (context, state) {
        if (state is ProfileLoading) {
          return Center(child: CircularProgressIndicator());
        }
        if (state is ProfileLoaded || state is ProfileUpdated) {
          return SingleChildScrollView(
            child: Column(
              children: [
                _buildProfileHeader((state as dynamic ).profile),
                _buildProfileInfo(context, (state as dynamic ).profile),
                _buildFooter(context),
              ],
            ),
          );
        }
        return Center(child: Text('Please wait...'));
      },
    );
  }

  Widget _buildProfileHeader(ProfileModel profile) {
    return Container(
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Color(0xFFE67E5E),
                    width: 3,
                  ),
                ),
                child: CircleAvatar(
                  radius: 55,
                  backgroundColor: Colors.white,
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: 80,
                    height: 80,
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Color(0xFFE67E5E),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 2,
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Text(
            profile.displayName??"",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileInfo(BuildContext context, ProfileModel profile) {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildTextField(
            context: context,
            label: 'Username',
            value: profile.displayName ?? "",
            icon: Icons.person_outline,
            onEdit: (newValue) => _updateProfile(context, uid, displayName: newValue),
          ),
          _buildDivider(),
          _buildTextField(
            context: context,
            label: 'Email',
            value: profile.email,
            icon: Icons.email_outlined,
            onEdit: (newValue) => _updateProfile(context, uid, email: newValue),
          ),
          _buildDivider(),
          _buildTextField(
            context: context,
            label: 'Phone Number',
            value: profile.phoneNumber ??"",
            icon: Icons.phone_outlined,
            onEdit: (newValue) => _updateProfile(context, uid, phoneNumber: newValue),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFE67E5E),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {},
              child: Text(
                'SAVE CHANGES',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required BuildContext context,
    required String label,
    required String value,
    required IconData icon,
    bool isPassword = false,
    required Function(String) onEdit,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Color(0xFFFFF3EE),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: Color(0xFFE67E5E),
              size: 20,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              isPassword ? Icons.visibility_outlined : Icons.edit_outlined,
              color: Color(0xFFE67E5E),
              size: 20,
            ),
            onPressed: () async {
              final newValue = await _showEditDialog(context, label, value);
              if (newValue != null && newValue != value) {
                onEdit(newValue);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      color: Colors.grey[200],
      height: 32,
      thickness: 1,
    );
  }

  Future<String?> _showEditDialog(BuildContext context, String label, String currentValue) async {
    TextEditingController controller = TextEditingController(text: currentValue);
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit $label'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: 'Enter new $label'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: Text('Save'),
          ),
        ],
      ),
    );
  }

  void _updateProfile(BuildContext context, String uid, {
    String? displayName,
    String? email,
    String? phoneNumber,
  }) {
    context.read<ProfileCubit>().updateProfile(
      uid: uid,
      displayName: displayName,
      email: email,
      phoneNumber: phoneNumber,
    );
  }
}