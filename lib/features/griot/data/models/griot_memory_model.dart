import 'package:hive/hive.dart';
import 'package:griot/features/griot/domain/entities/griot_memory.dart';

part 'griot_memory_model.g.dart';

@HiveType(typeId: 0)
class GriotMemoryModel extends HiveObject {
  GriotMemoryModel({
    required this.id,
    required this.content,
    required this.tags,
    required this.createdAt,
    required this.updatedAt,
    required this.importance,
  });

  @HiveField(0)
  final String id;

  @HiveField(1)
  final String content;

  @HiveField(2)
  final List<String> tags;

  @HiveField(3)
  final DateTime createdAt;

  @HiveField(4)
  final DateTime updatedAt;

  @HiveField(5)
  final double importance;

  factory GriotMemoryModel.fromEntity(GriotMemory memory) {
    return GriotMemoryModel(
      id: memory.id,
      content: memory.content,
      tags: memory.tags,
      createdAt: memory.createdAt,
      updatedAt: memory.updatedAt,
      importance: memory.importance,
    );
  }

  GriotMemory toEntity() {
    return GriotMemory(
      id: id,
      content: content,
      tags: tags,
      createdAt: createdAt,
      updatedAt: updatedAt,
      importance: importance,
    );
  }
}
