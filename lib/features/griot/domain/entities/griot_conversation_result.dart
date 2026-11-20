import 'package:griot/features/griot/domain/entities/griot_model_route.dart';

class GriotConversationResult {
  const GriotConversationResult({required this.response, required this.route});

  final String response;
  final GriotModelRoute route;
}
