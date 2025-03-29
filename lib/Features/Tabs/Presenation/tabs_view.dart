import 'package:drivebuddy/core/Utils/Shared%20Methods.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

// Assuming these are the paths to your screens
import '../../Camera_Scanning_and_Results/presentation/camera_scanning_view.dart';
import '../../History/presentation/history_view.dart';
import '../../Main/view/presentation/Main_view.dart';
import '../../Notification/presentation/notification_view.dart';
import '../../Profile/presentation/Profile_view.dart';

class TabsScreen extends StatefulWidget {
  final String uid;
  final String email;
  final String userName;
  TabsScreen(this.email, this.uid, this.userName, {super.key});

  @override
  _TabsScreenState createState() => _TabsScreenState();
}

class _TabsScreenState extends State<TabsScreen> {
  int _selectedIndex = 0;
  final PageController _pageController = PageController();

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      _pageController.jumpToPage(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: NeverScrollableScrollPhysics(),
        children: [
          MainScreenView(
            uid: widget.uid,
            userName: widget.userName,
            email: widget.email,
          ),
          HistoryScreen(),
          NotificationScreen(),
          ProfileScreen(
            uid: widget.uid,
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        shape: CircularNotchedRectangle(), // Adds a notch for the FAB
        notchMargin: 8.0, // Space between the notch and FAB
        color: Color(0xFFE67E5E),
        elevation: 10,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(Iconsax.home, 'Home', 0),
            _buildNavItem(Iconsax.clock, 'History', 1),
            SizedBox(width: 40), // Space for the FAB notch
            _buildNavItem(Iconsax.notification, 'Notifications', 2),
            _buildNavItem(Iconsax.profile_circle, 'Profile', 3),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          navigateTo(context, CameraScanScreen());
        },
        backgroundColor: Colors.white,
        shape: const CircleBorder(),

        child: Icon(Iconsax.camera, color: Color(0xFFE67E5E), size: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    return InkWell(
      onTap: () => _onItemTapped(index),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color:
                  _selectedIndex == index
                      ? Colors.white
                      : Colors.white.withOpacity(0.6),
              size: 18,
            ),
            SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color:
                    _selectedIndex == index
                        ? Colors.white
                        : Colors.white.withOpacity(0.6),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Simple MainScreenView implementation
