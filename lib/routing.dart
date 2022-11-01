import 'package:go_router/go_router.dart';
import 'package:sequential_recognition/ui/home_tab/home_tab_page.dart';

final router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeTabPage(),
    ),
  ],
);
