import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:griot/app/depency_injection.dart';
import 'package:griot/features/griot/presentation/memory_cubit/memory_cubit.dart';

class MemoryPanelPage extends StatelessWidget {
  const MemoryPanelPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => serviceLocator<MemoryCubit>()..loadMemories(),
      child: Scaffold(
        appBar: AppBar(title: const Text('GRIOT Memory')),
        body: BlocBuilder<MemoryCubit, MemoryState>(
          builder: (context, state) {
            if (state is MemoryLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is MemoryFailure) {
              return Center(child: Text(state.message));
            }

            if (state is MemoryLoaded) {
              if (state.memories.isEmpty) {
                return const Center(child: Text('No memories stored yet.'));
              }

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: state.memories.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final memory = state.memories[index];

                  return Card(
                    child: ListTile(
                      title: Text(memory.content),
                      subtitle: Text(
                        'Importance: ${memory.importance.toStringAsFixed(2)}\nTags: ${memory.tags.join(", ")}',
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () {
                          context.read<MemoryCubit>().removeMemory(memory.id);
                        },
                      ),
                    ),
                  );
                },
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}
