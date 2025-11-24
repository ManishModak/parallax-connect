import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/chat/presentation/chat_screen.dart';
import '../../features/chat/presentation/history_screen.dart';
import '../../features/config/presentation/config_screen.dart';
import '../../features/splash/presentation/splash_screen.dart';

// Route paths
class AppRoutes {
  static const splash = '/';
  static const config = '/config';
  static const chat = '/chat';
  static const history = '/history';
}

// GoRouter provider
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.chat,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const SplashScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      ),
      GoRoute(
        path: AppRoutes.config,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const ConfigScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      ),
      GoRoute(
        path: AppRoutes.chat,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const ChatScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      ),
      GoRoute(
        path: AppRoutes.history,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const HistoryScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // Slide from left
            const begin = Offset(-1.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.easeOutCubic;
            var tween = Tween(
              begin: begin,
              end: end,
            ).chain(CurveTween(curve: curve));
            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
        ),
      ),
    ],
  );
});
