import 'package:go_router/go_router.dart';
import 'home_shell.dart';

final appRouter = GoRouter(
  routes: [GoRoute(path: '/', builder: (context, _) => const HomeShell())],
);
