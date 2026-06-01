import 'package:griot/features/griot/domain/entities/griot_model_route.dart';
import 'package:griot/features/griot/domain/entities/griot_task_type.dart';

class SelectModelRoute {
  GriotModelRoute call(String input) {
    final lower = input.toLowerCase();

    if (_isMemoryTask(lower)) {
      return const GriotModelRoute(
        taskType: GriotTaskType.memory,
        modelName: 'qwen3:8b',
      );
    }

    if (_isVisionTask(lower)) {
      return const GriotModelRoute(
        taskType: GriotTaskType.vision,
        modelName: 'qwen3:8b', // later: Gemma Vision
      );
    }

    if (_isCodingTask(lower)) {
      return const GriotModelRoute(
        taskType: GriotTaskType.coding,
        modelName: 'qwen3:8b', // later: DeepSeek / Qwen Coder
      );
    }

    if (_needsDeeperReasoning(lower)) {
      return const GriotModelRoute(
        taskType: GriotTaskType.general,
        modelName: 'qwen3:8b',
      );
    }

    return const GriotModelRoute(
      taskType: GriotTaskType.general,
      modelName: 'qwen3:1.7b',
    );
  }

  bool _isMemoryTask(String input) {
    return input.contains('remember') ||
        input.contains('what do you remember') ||
        input.contains('forget') ||
        input.contains('my memory') ||
        input.contains('saved memories');
  }

  bool _isVisionTask(String input) {
    return input.contains('look at') ||
        input.contains('what do you see') ||
        input.contains('image') ||
        input.contains('picture') ||
        input.contains('screenshot') ||
        input.contains('camera');
  }

  bool _isCodingTask(String input) {
    return input.contains('code') ||
        input.contains('flutter') ||
        input.contains('dart') ||
        input.contains('debug') ||
        input.contains('error') ||
        input.contains('algorithm') ||
        input.contains('function') ||
        input.contains('class') ||
        input.contains('repository') ||
        input.contains('cubit') ||
        input.contains('pointer') ||
        input.contains('memory leak');
  }

  bool _needsDeeperReasoning(String input) {
    return input.length > 120 ||
        input.contains('explain') ||
        input.contains('why') ||
        input.contains('architecture') ||
        input.contains('strategy') ||
        input.contains('compare');
  }
}
