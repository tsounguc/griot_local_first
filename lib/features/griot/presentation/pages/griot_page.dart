import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:griot/features/griot/presentation/cubit/griot_cubit.dart';
import 'package:griot/features/griot/presentation/widgets/griot_input.dart';
import 'package:griot/features/griot/presentation/widgets/griot_loading_indicator.dart';
import 'package:griot/features/griot/presentation/widgets/griot_response.dart';

class GriotPage extends StatelessWidget {
  const GriotPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('GRIOT v0.1')),
      body: BlocConsumer<GriotCubit, GriotState>(
        listener: (BuildContext context, GriotState state) {},
        builder: (context, state) {
          final isLoading = state is GriotLoading;

          String response = '';

          if (state is GriotSuccess) {
            response = state.response;
          }

          if (state is GriotFailure) {
            response = state.message;
          }

          return Column(
            children: [
              Expanded(
                child: isLoading
                    ? const GriotLoadingIndicator()
                    : GriotResponse(response: response),
              ),
              GriotInput(
                isLoading: isLoading,
                onSubmitted: context.read<GriotCubit>().submitInput,
                onStopSpeaking: context.read<GriotCubit>().stopSpeaking,
              ),
            ],
          );
        },
      ),
    );
  }
}
