import 'package:get_it/get_it.dart';
import 'package:griot/features/griot/data/gateways/local_ollama_gateway.dart';
import 'package:griot/features/griot/data/models/griot_memory_model.dart';
import 'package:griot/features/griot/data/repositories/hive_memory_repository.dart';
import 'package:griot/features/griot/data/repositories/in_memory_memory_repository.dart';
import 'package:griot/features/griot/data/services/flutter_tts_speech_output_service.dart';
import 'package:griot/features/griot/domain/gateways/llm_gateway.dart';
import 'package:griot/features/griot/domain/repositories/memory_repository.dart';
import 'package:griot/features/griot/domain/services/speech_output_service.dart';
import 'package:griot/features/griot/domain/usecases/build_prompt.dart';
import 'package:griot/features/griot/domain/usecases/run_griot_core_loop.dart';
import 'package:griot/features/griot/presentation/cubit/griot_cubit.dart';
import 'package:hive_flutter/hive_flutter.dart';

final GetIt serviceLocator = GetIt.instance;

Future<void> initDependencies() async {
  await Hive.initFlutter();

  Hive.registerAdapter(GriotMemoryModelAdapter());

  final memoryBox = await Hive.openBox<GriotMemoryModel>('griot_memories');

  serviceLocator
    // App logic
    ..registerFactory(
      () => GriotCubit(
        runGriotCoreLoop: serviceLocator(),
        speechOutputService: serviceLocator(),
      ),
    )
    // use cases
    ..registerLazySingleton(
      () => RunGriotCoreLoop(
        memoryRepository: serviceLocator(),
        llmGateway: serviceLocator(),
        buildPrompt: serviceLocator(),
      ),
    )
    ..registerLazySingleton(() => BuildPrompt())
    // repositories
    ..registerLazySingleton<MemoryRepository>(
      () => HiveMemoryRepository(memoryBox),
    )
    ..registerLazySingleton<LLMGateway>(() => LocalOllamaGateWay())
    ..registerLazySingleton<SpeechOutputService>(
      () => FlutterTTSSpeechOutputService(),
    );
}
