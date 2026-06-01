import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:griot/features/griot/presentation/griot_cubit/griot_cubit.dart';
import 'package:griot/features/griot/presentation/pages/memory_panel_page.dart';
import 'package:griot/features/griot/presentation/widgets/griot_input.dart';
import 'package:griot/features/griot/presentation/widgets/griot_loading_indicator.dart';
import 'package:griot/features/griot/presentation/widgets/griot_response.dart';

class GriotPage extends StatelessWidget {
  const GriotPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GRIOT v0.4'),
        actions: [
          IconButton(
            icon: const Icon(Icons.memory_rounded),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const MemoryPanelPage()),
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<GriotCubit, GriotState>(
        builder: (context, state) {
          final isListening = state is GriotListening;
          final isThinking = state is GriotThinking;
          final isTranscribing = state is GriotTranscribing;

          String response = '';

          if (state is GriotListening) {
            response = 'Listening... tap stop when you are done.';
          }

          if (state is GriotTranscribing) {
            response = 'Transcribing audio locally...';
          }

          if (state is GriotThinking) {
            response = 'Thinking...';
          }

          if (state is GriotSpeaking) {
            response = state.response;
          }

          if (state is GriotError) {
            response = state.message;
          }

          return Column(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (isThinking || isTranscribing)
                      const GriotLoadingIndicator(),
                    if (response.isNotEmpty) GriotResponse(response: response),

                    if (state is GriotSpeaking)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(
                          '${state.taskType.toUpperCase()} • ${state.model}',
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                        ),
                      ),
                  ],
                ),
              ),
              GriotInput(
                isLoading: isThinking,
                isListening: isListening,
                onSubmitted: context.read<GriotCubit>().submitTextInput,
                onStartVoiceInput: context.read<GriotCubit>().startVoiceInput,
                onStopVoiceInput: context.read<GriotCubit>().stopVoiceInput,
                onStopSpeaking: context.read<GriotCubit>().stopSpeaking,
              ),
            ],
          );
        },
      ),
    );
  }
}
