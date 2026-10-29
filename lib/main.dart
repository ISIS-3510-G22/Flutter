import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:plansync/firebase_options.dart';
import 'package:plansync/model/data/auth_repository.dart';
import 'package:plansync/model/data/connectivity_repository.dart';
import 'package:plansync/model/data/pending_write_repository.dart';
import 'package:plansync/model/data/split_outbox_repository.dart';
import 'package:plansync/model/data/theme_repository.dart';
import 'package:plansync/model/data/write_queue.dart';
import 'package:plansync/model/models/user.dart';
import 'package:plansync/model/services/notification_service.dart';
import 'package:plansync/viewmodels/crew/friend_viewmodel.dart';
import 'package:plansync/viewmodels/crew/group_viewmodel.dart';
import 'package:plansync/viewmodels/global/connectivity_viewmodel.dart';
import 'package:plansync/viewmodels/global/theme_viewmodel.dart';
import 'package:plansync/views/auth/login_view.dart';
import 'package:plansync/views/crew/friend_request_view.dart';
import 'package:plansync/views/crew/group_invite_view.dart';
import 'package:plansync/views/home_shell.dart';
import 'package:plansync/views/theme/app_theme.dart';
import 'package:provider/provider.dart';

final _appNavigatorKey = GlobalKey<NavigatorState>();
final _messengerKey = GlobalKey<ScaffoldMessengerState>();
final _homeShellKey = GlobalKey<HomeShellState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final savedTheme = await ThemeRepository().loadPreference();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await ConnectivityRepository.instance.init();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeViewModel(savedTheme)),
        ChangeNotifierProvider(create: (_) => ConnectivityViewModel()),
      ],
      child: const AuthGate(),
    ),
  );
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final AuthRepository _authRepository = AuthRepository();
  late Stream<User?> _authStateChanges;
  final NotificationService _notificationService = NotificationService();
  String? _notificationRegistrationUserId;
  String? _activeUserId;
  String? _pendingNotificationType;
  bool _notificationRouteScheduled = false;

  bool _loadFailed = false;

  late final ConnectivityViewModel _connectivity;

  @override
  void initState() {
    super.initState();
    _listenForDropped(PendingWriteRepository.instance);
    _listenForDropped(SplitOutboxRepository.instance);
    _connectivity = context.read<ConnectivityViewModel>()
      ..addListener(_retryWhenOnline);
    _authStateChanges = _authRepository.authStateChanges;
    unawaited(
      _notificationService.initialize(onTap: _handleNotificationTap).catchError(
        (Object error) {
          debugPrint('Could not initialize notifications: $error');
        },
      ),
    );
  }

  void _handleNotificationTap(String type) {
    _pendingNotificationType = type;
    _scheduleNotificationRoute();
  }

  void _retryAuthState() {
    setState(() {
      _authStateChanges = _authRepository.authStateChanges;
    });
  }

  void _retryWhenOnline() {
    if (_loadFailed && _connectivity.isOnline) _retryAuthState();
  }

  void _scheduleNotificationRoute() {
    if (_notificationRouteScheduled || _activeUserId == null) return;
    _notificationRouteScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _notificationRouteScheduled = false;
      if (!mounted) return;

      final type = _pendingNotificationType;
      final userId = _activeUserId;
      final navigator = _appNavigatorKey.currentState;
      if (type == null || userId == null || navigator == null) return;
      _pendingNotificationType = null;

      if (type == 'nearby_friend') {
        navigator.popUntil((route) => route.isFirst);
        _homeShellKey.currentState?.showExplore();
      } else if (type == 'friend_request') {
        navigator.push<void>(
          MaterialPageRoute<void>(
            builder: (_) => ChangeNotifierProvider(
              create: (_) => FriendsViewModel(userId),
              child: const FriendRequestView(),
            ),
          ),
        );
      } else if (type == 'group_invite') {
        navigator.push<void>(
          MaterialPageRoute<void>(
            builder: (_) => ChangeNotifierProvider(
              create: (_) => CrewViewmodel(userId),
              child: const Scaffold(body: SafeArea(child: GroupInviteView())),
            ),
          ),
        );
      }
    });
  }

  void _registerNotificationsOnce(User user) {
    if (_notificationRegistrationUserId == user.id) return;

    _notificationRegistrationUserId = user.id;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _notificationRegistrationUserId != user.id) return;
      unawaited(_registerNotifications(user));
    });
  }

  Future<void> _registerNotifications(User user) async {
    await _notificationService.requestPermissionAndRegisterToken(user.id);
    final error = _notificationService.lastError;
    if (error != null) debugPrint(error);
  }

  void _listenForDropped(WriteQueue queue) {
    queue.changes.listen((_) {
      final message = queue.takeDropped();
      if (message == null) return;
      _messengerKey.currentState?.showSnackBar(
        SnackBar(content: Text(message)),
      );
    });
  }

  @override
  void dispose() {
    unawaited(_notificationService.dispose());
    _connectivity.removeListener(_retryWhenOnline);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = context.watch<ThemeViewModel>().mode;

    return StreamBuilder<User?>(
      stream: _authStateChanges,
      builder: (context, snapshot) {
        final user = snapshot.data;
        return MaterialApp(
          navigatorKey: _appNavigatorKey,
          scaffoldMessengerKey: _messengerKey,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: themeMode,
          builder: (_, child) => user == null
              ? child!
              : Provider<User>.value(value: user, child: child!),
          home: _home(snapshot),
        );
      },
    );
  }

  Widget _home(AsyncSnapshot<User?> snapshot) {
    _loadFailed = snapshot.hasError;
    if (snapshot.hasError) {
      debugPrint(
        'Could not load the signed-in user profile: ${snapshot.error}',
      );
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'We need a connection once to finish loading your account.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _retryAuthState,
                    child: const Text('Try again'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final user = snapshot.data;

    if (user == null) {
      _activeUserId = null;
      return const LoginView();
    }
    _activeUserId = user.id;
    _registerNotificationsOnce(user);
    unawaited(PendingWriteRepository.instance.start());
    unawaited(SplitOutboxRepository.instance.start());
    if (_pendingNotificationType != null) _scheduleNotificationRoute();
    return HomeShell(
      key: _homeShellKey,
      notificationService: _notificationService,
    );
  }
}
