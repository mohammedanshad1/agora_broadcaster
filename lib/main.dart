import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models/index.dart';
import 'repositories/index.dart';
import 'services/index.dart';
import 'viewmodels/index.dart';
import 'views/index.dart';

const String agoraAppId = 'YOUR_AGORA_APP_ID'; // Replace with your Agora App ID

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Agora Live Broadcaster',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6200EA),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: 'Inter', // Assuming Inter is available or fallback
      ),
      home: _buildProviders(child: const _AppRouter()),
    );
  }

  Widget _buildProviders({required Widget child}) {
    return MultiProvider(
      providers: [
        // Services
        Provider(create: (_) => AgoraService(agoraAppId: agoraAppId)),
        Provider(create: (_) => RTMPService()),
        Provider(create: (_) => PermissionService()),
        // Repository
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
          update:
              (_, agoraService, rtmpService, permissionService, repo) =>
                  repo ??
                  StreamRepository(
                    agoraService: agoraService,
                    rtmpService: rtmpService,
                    permissionService: permissionService,
                  ),
        ),
        // ViewModels
        ChangeNotifierProxyProvider<StreamRepository, LiveStreamViewModel>(
          create:
              (context) => LiveStreamViewModel(
                repository: context.read<StreamRepository>(),
              ),
          update:
              (context, repository, previous) =>
                  previous ?? LiveStreamViewModel(repository: repository),
        ),
        ChangeNotifierProxyProvider<StreamRepository, RTMPConfigViewModel>(
          create:
              (context) => RTMPConfigViewModel(
                repository: context.read<StreamRepository>(),
              ),
          update:
              (context, repository, previous) =>
                  previous ?? RTMPConfigViewModel(repository: repository),
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
  Widget build(BuildContext context) {
    if (_showSplash) {
      return SplashScreen(
        onInitializationComplete: () {
          setState(() {
            _showSplash = false;
          });
        },
      );
    }

    if (_isBroadcaster == null) {
      return HomeScreen(
        onRoleSelected: (isBroadcaster) {
          setState(() {
            _isBroadcaster = isBroadcaster;
          });
        },
      );
    }

    if (_isBroadcaster!) {
      return HostLiveScreen(
        onExit: () {
          setState(() {
            _isBroadcaster = null;
          });
        },
      );
    } else {
      return AudienceLiveScreen(
        onExit: () {
          setState(() {
            _isBroadcaster = null;
          });
        },
      );
    }
  }
}
