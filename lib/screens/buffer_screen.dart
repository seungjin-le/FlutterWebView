import 'package:flutter/cupertino.dart';
import 'package:web_view_test/screens/web_view_screen.dart';

class Buffer extends StatelessWidget {
  const Buffer({super.key});

  @override
  Widget build(BuildContext context) {
    return WebViewScreen(url: "/buffer");
  }
}
