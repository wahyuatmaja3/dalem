import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/providers/dashboard_providers.dart';
import '../../../auth/domain/providers/auth_providers.dart';
import '../controllers/dashboard_controller.dart';
import '../widgets/note_card.dart';
import '../widgets/empty_state.dart';
import '../../../../app/router.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/api/auth_interceptor.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(dashboardControllerProvider.notifier).loadNotes();
      _setupAuthListener();
    });
  }

  void _setupAuthListener() {
    final authInterceptor = ref.read(authInterceptorProvider);
    authInterceptor.addListener(_onUnauthorized);
  }

  void _onUnauthorized() {
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRouter.signIn,
        (route) => false,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.sessionExpired)),
      );
    }
  }

  void _handleLogout() async {
    final authController = ref.read(authControllerProvider.notifier);
    await authController.logout();
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRouter.signIn,
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final dashboardState = ref.watch(dashboardControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.dashboard),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _handleLogout,
            tooltip: AppStrings.logout,
          ),
        ],
      ),
      body: _buildBody(dashboardState),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).pushNamed(AppRouter.recorder);
        },
        icon: const Icon(Icons.mic),
        label: const Text(AppStrings.record),
      ),
    );
  }

  Widget _buildBody(DashboardState state) {
    return switch (state) {
      DashboardInitial() => const Center(child: Text('Initializing...')),
      DashboardLoading() => const Center(child: CircularProgressIndicator()),
      DashboardLoaded(notes: final notes) => notes.isEmpty
          ? const EmptyState()
          : RefreshIndicator(
              onRefresh: () async {
                await ref.read(dashboardControllerProvider.notifier).refresh();
              },
              child: ListView.builder(
                itemCount: notes.length,
                itemBuilder: (context, index) {
                  final note = notes[index];
                  return NoteCard(
                    note: note,
                    onTap: () {
                      Navigator.of(context).pushNamed(
                        AppRouter.noteDetail,
                        arguments: note.id,
                      );
                    },
                  );
                },
              ),
            ),
      DashboardError(message: final message) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(message),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.read(dashboardControllerProvider.notifier).loadNotes();
                },
                child: const Text(AppStrings.tryAgain),
              ),
            ],
          ),
        ),
    };
  }

  @override
  void dispose() {
    final authInterceptor = ref.read(authInterceptorProvider);
    authInterceptor.removeListener(_onUnauthorized);
    super.dispose();
  }
}
