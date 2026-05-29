import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:griot/app/depency_injection.dart';
import 'package:griot/features/griot/presentation/griot_cubit/griot_cubit.dart';
import 'package:griot/features/griot/presentation/pages/griot_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initDependencies();
  runApp(const GriotApp());
}

class GriotApp extends StatelessWidget {
  const GriotApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData.dark(useMaterial3: true),
    home: BlocProvider.value(
      value: serviceLocator<GriotCubit>(),
      child: const GriotPage(),
    ),
    // home: const GriotDashboard(),
  );
}
