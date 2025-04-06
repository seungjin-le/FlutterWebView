import 'package:flutter/material.dart';
import 'package:web_view_test/screens/web_view_screen.dart';

class Test2 extends StatelessWidget {
  const Test2({super.key});

  @override
  Widget build(BuildContext context) {
    return WebViewScreen(url: "/test2");
  }
}
