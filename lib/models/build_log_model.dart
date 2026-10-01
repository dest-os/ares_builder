import 'package:flutter/material.dart';
import '../core/app_colors.dart';

enum LogLevel { info, build, success, warning, error }

class BuildLog {
  final DateTime time;
  final LogLevel level;
  final String message;

  BuildLog(this.level, this.message) : time = DateTime.now();

  String get timeText {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(time.hour)}:${two(time.minute)}:${two(time.second)}';
  }

  String get tag {
    switch (level) {
      case LogLevel.info:
        return 'INFO';
      case LogLevel.build:
        return 'BUILD';
      case LogLevel.success:
        return 'SUCCESS';
      case LogLevel.warning:
        return 'WARN';
      case LogLevel.error:
        return 'ERROR';
    }
  }

  Color get color {
    switch (level) {
      case LogLevel.info:
        return AppColors.cyanNeon;
      case LogLevel.build:
        return AppColors.yellowNeon;
      case LogLevel.success:
        return AppColors.greenNeon;
      case LogLevel.warning:
        return AppColors.yellowNeon;
      case LogLevel.error:
        return AppColors.redNeon;
    }
  }
}
