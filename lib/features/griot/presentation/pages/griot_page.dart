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
        title: const Text('GRIOT v0.3'),
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
          final isThinking = state is GriotThinking;

          String response = '';

          if (state is GriotSpeaking) {
            response = state.response;
          }

          if (state is GriotError) {
            response = state.message;
          }

          return Column(
            children: [
              Expanded(
                child: isThinking
                    ? const GriotLoadingIndicator()
                    : GriotResponse(response: response),
              ),
              GriotInput(
                isLoading: isThinking,
                onSubmitted: context.read<GriotCubit>().submitTextInput,
                onStartVoiceInput: context.read<GriotCubit>().startVoiceInput,
                onStopSpeaking: context.read<GriotCubit>().stopSpeaking,
              ),
            ],
          );
        },
      ),
    );
  }
}
