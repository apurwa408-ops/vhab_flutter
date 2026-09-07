import 'package:flutter/material.dart';

enum DeviceScreenType { mobile, tablet, desktop }

class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget desktop;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    required this.desktop,
  });

  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 650;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= 650 &&
      MediaQuery.of(context).size.width <= 1024;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width > 1024;

  static DeviceScreenType getDeviceType(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 1024) return DeviceScreenType.desktop;
    if (width >= 650) return DeviceScreenType.tablet;
    return DeviceScreenType.mobile;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 1024) {
          return desktop;
        } else if (constraints.maxWidth >= 650) {
          return tablet ?? desktop;
        } else {
          return mobile;
        }
      },
    );
  }
}
