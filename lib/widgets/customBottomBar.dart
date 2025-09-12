import 'package:eureka_app/screens/home/homeScreen.dart';
import 'package:flutter/material.dart';

class CustomBottomNavBar extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;

  CustomBottomNavBar({
    Key? key,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  @override
  _CustomBottomNavBarState createState() => _CustomBottomNavBarState();
}

class _CustomBottomNavBarState extends State<CustomBottomNavBar> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bg,
        border: Border(
          top: BorderSide(
            color: Color.fromRGBO(66, 66, 66, 1),
            width: 1.0,
          ),
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          splashColor: Colors.transparent, // Disable splash effect
          highlightColor: Colors.transparent, // Disable highlight effect
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.transparent,
          currentIndex: widget.currentIndex,
          onTap: widget.onTap,
          elevation: 0,
          items: [
            _buildNavItem(
              imagePath: 'lib/assets/homeIcon.png',
              label: 'Home',
              isActive: widget.currentIndex == 0,
            ),
            // _buildNavItem(
            //   imagePath: 'lib/assets/questIcon.png',
            //   label: 'Quests',
            //   isActive: widget.currentIndex == 1,
            // ),
            // _buildNavItem(
            //   imagePath: 'lib/assets/leaderboardIcon.png',
            //   label: 'Leaderboard',
            //   isActive: widget.currentIndex == 2,
            // ),
            // _buildNavItem(
            //   imagePath: 'lib/assets/progressReportIcon.png',
            //   label: 'Progress Report',
            //   isActive: widget.currentIndex == 3,
            // ),
            _buildNavItem(
              imagePath: 'lib/assets/profileIcon.png',
              label: 'Profile',
              isActive: widget.currentIndex == 1,
            ),
            // _buildNavItem(
            //   imagePath: 'lib/assets/feedIcon.png',
            //   label: 'Feeds',
            //   isActive: widget.currentIndex == 5,
            // ),
          ],
          showSelectedLabels: false,
          showUnselectedLabels: false,
          type: BottomNavigationBarType.fixed,
        ),
      ),
    );
  }

  BottomNavigationBarItem _buildNavItem({
    required String imagePath,
    required String label,
    required bool isActive,
  }) {
    return BottomNavigationBarItem(
      icon: Container(
        padding: const EdgeInsets.all(8.0), // Add some padding around the icon
        decoration: BoxDecoration(
          color: isActive ? Colors.grey[900] : null,
          border: isActive
              ? Border.all(
                  color: Color.fromRGBO(255, 217, 0, 1),
                  width: 2) // Yellow border for active
              : null, // No border for inactive
          borderRadius: BorderRadius.circular(8), // Rounded corners
        ),
        child: Image.asset(
          imagePath,
          height: 30,
          width: 30,
        ),
      ),
      label: label,
    );
  }
}
