import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import '../features/onboarding/screens/hook_screen.dart';
import '../features/onboarding/screens/dopamine_screen.dart';
import '../features/onboarding/screens/form_screen.dart';
import '../features/onboarding/screens/calculating_screen.dart';
import '../features/onboarding/screens/result_screen.dart';
import '../features/onboarding/screens/upsell_screen.dart';
import '../features/auth/screens/register_screen.dart';
import '../features/home/screens/home_screen.dart';

class PausaRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/onboarding/hook',
    routes: [
      // Onboarding
      GoRoute(
        path: '/onboarding/hook',
        name: 'hook',
        builder: (context, state) => const HookScreen(),
      ),
      GoRoute(
        path: '/onboarding/dopamina',
        name: 'dopamina',
        builder: (context, state) => const DopamineScreen(),
      ),
      GoRoute(
        path: '/onboarding/formulario',
        name: 'formulario',
        builder: (context, state) => const FormScreen(),
      ),
      GoRoute(
        path: '/onboarding/calculando',
        name: 'calculando',
        pageBuilder: (context, state) => CustomTransitionPage(
          child: const CalculatingScreen(),
          transitionsBuilder: (context, animation, _, child) =>
              FadeTransition(opacity: animation, child: child),
        ),
      ),
      GoRoute(
        path: '/onboarding/resultado',
        name: 'resultado',
        pageBuilder: (context, state) => CustomTransitionPage(
          child: ResultScreen(extra: state.extra as Map<String, dynamic>?),
          transitionsBuilder: (context, animation, _, child) =>
              FadeTransition(opacity: animation, child: child),
        ),
      ),
      GoRoute(
        path: '/onboarding/upsell',
        name: 'upsell',
        builder: (context, state) => const UpsellScreen(),
      ),

      // Auth
      GoRoute(
        path: '/registro',
        name: 'registro',
        builder: (context, state) => const RegisterScreen(),
      ),

      // App principal
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
    ],
  );
}