import 'package:get_it/get_it.dart';
import 'package:griot/features/griot/data/gateways/local_ollama_gateway.dart';
import 'package:griot/features/griot/data/models/griot_memory_model.dart';
import 'package:griot/features/griot/data/repositories/hive_memory_repository.dart';
import 'package:griot/features/griot/data/services/flutter_tts_speech_output_service.dart';
import 'package:griot/features/griot/domain/gateways/llm_gateway.dart';
import 'package:griot/features/griot/domain/repositories/memory_repository.dart';
import 'package:griot/features/griot/domain/services/speech_output_service.dart';
import 'package:griot/features/griot/domain/usecases/build_prompt.dart';
import 'package:griot/features/griot/domain/usecases/delete_memory.dart';
import 'package:griot/features/griot/domain/usecases/get_all_memories.dart';
import 'package:griot/features/griot/domain/usecases/run_griot_core_loop.dart';
import 'package:griot/features/griot/presentation/griot_cubit/griot_cubit.dart';
import 'package:griot/features/griot/presentation/memory_cubit/memory_cubit.dart';
import 'package:hive_flutter/hive_flutter.dart';

final GetIt serviceLocator = GetIt.instance;

Future<void> initDependencies() async {
  await Hive.initFlutter();

  Hive.registerAdapter(GriotMemoryModelAdapter());

  // await Hive.deleteBoxFromDisk('griot_memories');

  final memoryBox = await Hive.openBox<GriotMemoryModel>('griot_memories');

  serviceLocator
    // App logic
    ..registerFactory(
      () => GriotCubit(
        runGriotCoreLoop: serviceLocator(),
        speechOutputService: serviceLocator(),
      ),
    )
    ..registerFactory(
      () => MemoryCubit(
        getAllMemories: serviceLocator(),
        deleteMemory: serviceLocator(),
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
    ..registerLazySingleton(() => GetAllMemories(serviceLocator()))
    ..registerLazySingleton(() => BuildPrompt())
    ..registerLazySingleton(() => DeleteMemory(serviceLocator()))
    // repositories
    ..registerLazySingleton<MemoryRepository>(
      () => HiveMemoryRepository(memoryBox),
    )
    ..registerLazySingleton<LLMGateway>(() => LocalOllamaGateWay())
    ..registerLazySingleton<SpeechOutputService>(
      () => FlutterTTSSpeechOutputService(),
    );
}
