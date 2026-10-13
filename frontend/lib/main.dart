import 'package:clipflow/screens/terms_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'core/theme.dart';
import 'screens/auth_screen.dart';
import 'screens/dashboard_screen.dart';
import 'state/auth_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final auth = AuthState();
  await auth.init(); // restore session before the first route is chosen
  runApp(ChangeNotifierProvider.value(value: auth, child: ClipFlowApp(auth: auth)));
}

class ClipFlowApp extends StatefulWidget {
  const ClipFlowApp({super.key, required this.auth});
  final AuthState auth;

  @override
  State<ClipFlowApp> createState() => _ClipFlowAppState();
}

class _ClipFlowAppState extends State<ClipFlowApp> {
  late final GoRouter _router = GoRouter(
    initialLocation: '/',
    refreshListenable: widget.auth, // re-run redirect whenever login state changes
    redirect: (context, state) {
      final loggedIn = widget.auth.isAuthenticated;
      final atLogin = state.matchedLocation == '/login';
      if (!loggedIn && !atLogin) return '/login'; // route guard: dashboard needs a session
      if (loggedIn && atLogin) return '/';
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (_, __) => const DashboardScreen()),
      GoRoute(path: '/login', builder: (_, __) => const AuthScreen()),
      GoRoute(path: '/terms', builder: (_, __) => const TermsScreen()),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'ClipFlow',
      debugShowCheckedModeBanner: false,
      theme: CF.theme(),
      routerConfig: _router,
    );
  }
}
