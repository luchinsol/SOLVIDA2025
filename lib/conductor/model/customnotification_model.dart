//import 'dart:ui';
import 'package:flutter/material.dart';

class CustomNotification {
  final String title;
  final String message;
  final VoidCallback? onAccept;
  final VoidCallback? onView;

  CustomNotification({
    required this.title,
    required this.message,
    this.onAccept,
    this.onView,
  });
}
