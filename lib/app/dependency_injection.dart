import 'package:get_it/get_it.dart';
import 'package:griot/features/griot/data/gateways/cluster_gateway.dart';
import 'package:griot/features/griot/data/gateways/local_ollama_gateway.dart';
import 'package:griot/features/griot/data/models/griot_memory_model.dart';
import 'package:griot/features/griot/data/repositories/hive_memory_repository.dart';
import 'package:griot/features/griot/data/repositories/in_memory_conversation_session_repository.dart';
import 'package:griot/features/griot/data/services/kokoro_speech_output_service.dart';
import 'package:griot/features/griot/data/services/local_whisper_voice_input_service.dart';
import 'package:griot/features/griot/domain/gateways/llm_gateway.dart';
import 'package:griot/features/griot/domain/repositories/conversation_session_repository.dart';
import 'package:griot/features/griot/domain/repositories/memory_repository.dart';
import 'package:griot/features/griot/domain/services/conversation_session_manager.dart';
import 'package:griot/features/griot/domain/services/speech_output_service.dart';
import 'package:griot/features/griot/domain/services/voice_input_service.dart';
import 'package:griot/features/griot/domain/usecases/build_coding_prompt.dart';
import 'package:griot/features/griot/domain/usecases/build_prompt.dart';
import 'package:griot/features/griot/domain/usecases/delete_memory.dart';
import 'package:griot/features/griot/domain/usecases/get_all_memories.dart';
import 'package:griot/features/griot/domain/usecases/route_cluster_task.dart';
import 'package:griot/features/griot/domain/usecases/run_griot_core_loop.dart';
import 'package:griot/features/griot/domain/usecases/select_model_route.dart';
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
        voiceInputService: serviceLocator(),
        routeClusterTask: serviceLocator(),
        sessionManager: serviceLocator(),
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
        buildCodingPrompt: serviceLocator(),
        selectModelRoute: serviceLocator(),
      ),
    )
    ..registerLazySingleton<RouteClusterTask>(
      () => RouteClusterTask(serviceLocator()),
    )
    ..registerLazySingleton(() => ConversationSessionManager(serviceLocator()))
    ..registerLazySingleton(() => GetAllMemories(serviceLocator()))
    ..registerLazySingleton(() => BuildPrompt())
    ..registerLazySingleton(() => BuildCodingPrompt())
    ..registerLazySingleton(() => DeleteMemory(serviceLocator()))
    ..registerLazySingleton(() => SelectModelRoute())
    // repositories
    ..registerLazySingleton<MemoryRepository>(
      () => HiveMemoryRepository(memoryBox),
    )
    ..registerLazySingleton<ConversationSessionRepository>(
      () => InMemoryConversationSessionRepository(),
    )
    ..registerLazySingleton<LLMGateway>(() => LocalOllamaGateWay())
    ..registerLazySingleton<ClusterGateway>(
      () => ClusterGateway(baseUrl: 'http://127.0.0.1:9200'),
    )
    // services
    // ..registerLazySingleton<SpeechOutputService>(
    //   () => FlutterTTSSpeechOutputService(),
    // )
    ..registerLazySingleton<SpeechOutputService>(
      () => KokoroSpeechOutputService(),
    )
    // ..registerLazySingleton<VoiceInputService>(
    //   () => SpeechToTextVoiceInputService(),
    // )
    ..registerLazySingleton<VoiceInputService>(
      () => LocalWhisperVoiceInputService(),
    );
}
