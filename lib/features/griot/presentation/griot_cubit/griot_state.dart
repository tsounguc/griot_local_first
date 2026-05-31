part of 'griot_cubit.dart';

sealed class GriotState extends Equatable {
  const GriotState();

  @override
  List<Object?> get props => [];
}

final class GriotInitial extends GriotState {
  const GriotInitial();
}

final class GriotIdle extends GriotState {
  const GriotIdle();
}

final class GriotListening extends GriotState {
  const GriotListening();
}

final class GriotThinking extends GriotState {
  const GriotThinking();
}

final class GriotSpeaking extends GriotState {
  const GriotSpeaking(this.response);

  final String response;

  @override
  List<Object?> get props => [response];
}

final class GriotTranscribing extends GriotState {
  const GriotTranscribing();
}

final class GriotError extends GriotState {
  const GriotError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
