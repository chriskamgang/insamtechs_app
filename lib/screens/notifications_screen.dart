import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    final List<NotificationItem> notifications = [
      NotificationItem(
        title: 'Transaction réussie!',
        message: 'Lorem ipsum dolor sit amet consectetur.',
        time: '5 mins ago',
        icon: Icons.check_circle,
        iconColor: const Color(0xFF1E3A8A),
      ),
      NotificationItem(
        title: 'Transaction réussie!',
        message: 'Lorem ipsum dolor sit amet consectetur.',
        time: '5 mins ago',
        icon: Icons.thumb_up,
        iconColor: const Color(0xFF1E3A8A),
      ),
      NotificationItem(
        title: 'Lorem ipsum',
        message: 'Lorem ipsum dolor sit amet consectetur.',
        time: '5 mins ago',
        icon: Icons.check_circle,
        iconColor: const Color(0xFF1E3A8A),
      ),
      NotificationItem(
        title: 'Lorem ipsum',
        message: 'Lorem ipsum dolor sit amet consectetur.',
        time: '5 mins ago',
        icon: Icons.check_circle,
        iconColor: const Color(0xFF1E3A8A),
      ),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          'Notifications',
          style: TextStyle(
            fontSize: screenWidth * 0.055,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: Icon(
              Icons.settings,
              color: Colors.grey[400],
              size: 28,
            ),
            onPressed: () {
              Navigator.pushNamed(context, '/settings');
            },
          ),
          IconButton(
            icon: const Icon(
              Icons.notifications,
              color: Color(0xFF1E3A8A),
              size: 28,
            ),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
          child: Column(
            children: [
              SizedBox(height: screenHeight * 0.02),

              // Notifications List
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: notifications.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: EdgeInsets.only(bottom: screenHeight * 0.015),
                    child: _buildNotificationCard(notifications[index], screenWidth),
                  );
                },
              ),

              SizedBox(height: screenHeight * 0.1),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationCard(NotificationItem notification, double screenWidth) {
    return Container(
      padding: EdgeInsets.all(screenWidth * 0.04),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: notification.iconColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              notification.icon,
              color: Colors.white,
              size: 20,
            ),
          ),

          SizedBox(width: screenWidth * 0.04),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notification.title,
                  style: TextStyle(
                    fontSize: screenWidth * 0.045,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: screenWidth * 0.01),
                Text(
                  notification.message,
                  style: TextStyle(
                    fontSize: screenWidth * 0.035,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),

          // Time
          Text(
            notification.time,
            style: TextStyle(
              fontSize: screenWidth * 0.03,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}

class NotificationItem {
  final String title;
  final String message;
  final String time;
  final IconData icon;
  final Color iconColor;

  NotificationItem({
    required this.title,
    required this.message,
    required this.time,
    required this.icon,
    required this.iconColor,
  });
}