import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../screens/web_view_screen.dart';

final router = GoRouter(
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return Scaffold(
          body: SafeArea(child: navigationShell),
          bottomNavigationBar: BottomAppBar(
            color: Colors.red,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,

              children: [
                IconButton(
                  onPressed: () {
                    context.go('/');
                  },
                  icon: const Icon(Icons.home),
                ),
                IconButton(
                  onPressed: () {
                    context.go('/attacker');
                  },
                  icon: const Icon(Icons.arrow_forward),
                ),
                IconButton(
                  onPressed: () {
                    context.go('/buffer');
                  },
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
          ),
        );
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => WebViewScreen(url: '/'),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/attacker',
              builder: (context, state) => WebViewScreen(url: '/attacker'),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/buffer',
              builder: (context, state) => WebViewScreen(url: '/buffer'),
            ),
          ],
        ),
      ],
    ),
  ],
);
