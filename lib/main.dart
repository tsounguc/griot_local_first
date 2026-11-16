import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:griot/app/dependency_injection.dart';
import 'package:griot/app/services/local_service_manager.dart';
import 'package:griot/features/griot/presentation/griot_cubit/griot_cubit.dart';
import 'package:griot/features/griot/presentation/pages/griot_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initDependencies();

  final serviceManager = LocalServiceManager();

  try {
    await serviceManager.startOllama();
  } catch (error) {
    debugPrint('Ollama startup failed: $error');
  }

  try {
    await serviceManager.startKokoro();
  } catch (error) {
    debugPrint('Kokoro startup failed: $error');
  }

  runApp(GriotApp(serviceManager: serviceManager));
}

class GriotApp extends StatefulWidget {
  final LocalServiceManager serviceManager;

  const GriotApp({super.key, required this.serviceManager});

  @override
  State<GriotApp> createState() => _GriotAppState();
}

class _GriotAppState extends State<GriotApp> {
  late final AppLifecycleListener _lifecycleListener;
  bool _isShuttingDown = false;

  @override
  void initState() {
    super.initState();

    _lifecycleListener = AppLifecycleListener(
      onExitRequested: _handleExitRequested,
    );
  }

  Future<AppExitResponse> _handleExitRequested() async {
    if (_isShuttingDown) {
      return AppExitResponse.cancel;
    }

    _isShuttingDown = true;

    try {
      debugPrint('GRIOT shutdown requested.');

      await widget.serviceManager.stopKokoro();

      debugPrint('GRIOT shutdown completed.');

      return AppExitResponse.exit;
    } catch (error) {
      debugPrint('GRIOT shutdown failed: $error');
      return AppExitResponse.cancel;
    } finally {
      _isShuttingDown = false;
    }
  }

  @override
  void dispose() {
    _lifecycleListener.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData.dark(useMaterial3: true),
    home: BlocProvider.value(
      value: serviceLocator<GriotCubit>(),
      child: const GriotPage(),
    ),
  );
}
