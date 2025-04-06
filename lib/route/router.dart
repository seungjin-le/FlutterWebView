// GetX 라우트 설정
import 'package:get/get_navigation/src/routes/get_route.dart';
import 'package:web_view_test/screens/home_screen.dart';
import 'package:web_view_test/screens/test2_screen.dart';
import 'package:web_view_test/screens/test_screen.dart';

class AppRoutes {
  static const String home = '/';
  static const String test = '/test';
  static const String test2 = '/test2';

  static final routes = [
    GetPage(name: home, page: () => const Home()),
    GetPage(name: test, page: () => const Test()),
    GetPage(name: test2, page: () => const Test2()),
  ];
}
