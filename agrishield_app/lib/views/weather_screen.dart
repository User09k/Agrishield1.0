import 'package:flutter/material.dart';
import 'wx.dart';

// This file redirects to Wx (Weather screen) for backward compatibility
class WeatherScreen extends StatelessWidget {
  const WeatherScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Wx();
  }
}
