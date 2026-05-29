class GriotMemory {
   const GriotMemory ({
    required this.id,
    required this.content,
    required this.tags,
    required this.createdAt,
    required this.updatedAt,
  });
   
  final String id;
  final String content;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;
}