import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models/index.dart';
import 'repositories/index.dart';
import 'services/index.dart';
import 'viewmodels/index.dart';
import 'views/index.dart';

const String agoraAppId =
    'dd522d50dc8945a38da60ba87d9da0e0'; // Your Agora App ID

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Agora Live Broadcaster',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6200EA),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: _buildProviders(child: const _AppRouter()),
    );
  }

  Widget _buildProviders({required Widget child}) {
    return MultiProvider(
      providers: [
        // Services - Use lazy loading to avoid initialization issues
        ChangeNotifierProvider(
          create: (context) => AgoraService(agoraAppId: agoraAppId),
          lazy: false,
        ),
        Provider(create: (_) => RTMPService()),
        Provider(create: (_) => PermissionService()),

        // Repository - Use ProxyProvider to handle dependencies
        ProxyProvider3<
          AgoraService,
          RTMPService,
          PermissionService,
          StreamRepository
        >(
          create:
              (context) => StreamRepository(
                agoraService: context.read<AgoraService>(),
                rtmpService: context.read<RTMPService>(),
                permissionService: context.read<PermissionService>(),
              ),
          update: (_, agoraService, rtmpService, permissionService, previous) {
            return previous ??
                StreamRepository(
                  agoraService: agoraService,
                  rtmpService: rtmpService,
                  permissionService: permissionService,
                );
          },
        ),

        // ViewModels - Use ChangeNotifierProvider directly
        ChangeNotifierProvider(
          create: (context) {
            final repository = context.read<StreamRepository>();
            return LiveStreamViewModel(repository: repository);
          },
        ),

        ChangeNotifierProvider(
          create: (context) {
            final repository = context.read<StreamRepository>();
            return RTMPConfigViewModel(repository: repository);
          },
        ),
      ],
      child: child,
    );
  }
}

class _AppRouter extends StatefulWidget {
  const _AppRouter();

  @override
  State<_AppRouter> createState() => _AppRouterState();
}

class _AppRouterState extends State<_AppRouter> {
  bool _showSplash = true;
  bool? _isBroadcaster;

  @override
  void initState() {
    super.initState();
    // Initialize Agora after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final agoraService = context.read<AgoraService>();
        agoraService.initialize();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showSplash) {
      return SplashScreen(
        onInitializationComplete: () {
          if (mounted) {
            setState(() {
              _showSplash = false;
            });
          }
        },
      );
    }

    if (_isBroadcaster == null) {
      return HomeScreen(
        onRoleSelected: (isBroadcaster) {
          if (mounted) {
            setState(() {
              _isBroadcaster = isBroadcaster;
            });
          }
        },
      );
    }

    if (_isBroadcaster!) {
      return HostLiveScreen(
        onExit: () {
          if (mounted) {
            setState(() {
              _isBroadcaster = null;
            });
          }
        },
      );
    } else {
      return AudienceLiveScreen(
        onExit: () {
          if (mounted) {
            setState(() {
              _isBroadcaster = null;
            });
          }
        },
      );
    }
  }
}
