import 'package:flutter/material.dart';

class CustomBottomNavBar extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;

  CustomBottomNavBar(
      {Key? key, required this.currentIndex, required this.onTap})
      : super(key: key);

  @override
  _CustomBottomNavBarState createState() => _CustomBottomNavBarState();
}

class _CustomBottomNavBarState extends State<CustomBottomNavBar> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border(
          top: BorderSide(
            color: Colors.grey.shade800,
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
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined, size: 30),
              label: 'Home',
              activeIcon: Icon(Icons.home, size: 30),
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.explore_outlined, size: 30),
              label: 'Explore',
              activeIcon: Icon(Icons.explore, size: 30),
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.group_outlined, size: 30),
              label: 'Community',
              activeIcon: Icon(Icons.group, size: 30),
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_2_outlined, size: 30),
              label: 'Profile',
              activeIcon: Icon(Icons.person_2, size: 30),
            ),
          ],
          selectedItemColor: Colors.yellow, // Active tab color
          unselectedItemColor: Colors.white, // Inactive tab color
          selectedLabelStyle: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Colors.yellow,
          ),
          unselectedLabelStyle: TextStyle(
            fontWeight: FontWeight.normal,
            fontSize: 12,
            color: Colors.white,
          ),
          type: BottomNavigationBarType.fixed,
        ),
      ),
    );
  }
}
