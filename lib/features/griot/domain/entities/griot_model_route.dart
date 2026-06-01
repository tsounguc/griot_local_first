import 'griot_task_type.dart';

class GriotModelRoute {
  const GriotModelRoute({required this.taskType, required this.modelName});

  final GriotTaskType taskType;
  final String modelName;
}
