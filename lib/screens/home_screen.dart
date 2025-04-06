import 'package:flutter/material.dart';
import 'package:web_view_test/screens/web_view_screen.dart';

class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    return WebViewScreen(url: "/");
  }
}
