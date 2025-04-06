import 'package:flutter/material.dart';
import 'package:web_view_test/screens/web_view_screen.dart';

class Test extends StatelessWidget {
  const Test({super.key});

  @override
  Widget build(BuildContext context) {
    return WebViewScreen(url: "/test");
  }
}
