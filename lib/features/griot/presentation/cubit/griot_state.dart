part of 'griot_cubit.dart';

sealed class GriotState extends Equatable {
  const GriotState();
  @override
  List<Object?> get props => [];
}

final class GriotInitial extends GriotState {

}

class GriotLoading extends GriotState {}

class GriotSuccess extends GriotState {
  const GriotSuccess(this.response);

  final String response;

  @override
  List<Object?> get props => [response];
}

class GriotFailure extends GriotState {
  const GriotFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
