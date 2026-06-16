import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/providers/dashboard_providers.dart';
import '../../../auth/domain/providers/auth_providers.dart';
import '../controllers/dashboard_controller.dart';
import '../widgets/note_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/note_edit_sheet.dart';
import '../../data/models/note_model.dart';
import '../../data/repositories/notes_repository.dart';
import '../../../../app/router.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_colors.dart';
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

  Future<void> _handleEditNote(NoteModel note) async {
    final repo = ref.read(notesRepositoryProvider);
    final result = await showNoteEditSheet(
      context,
      initialTitle: note.title,
      initialCategory: note.category,
      customCategories: repo.getCustomCategories(),
      saveLabel: 'Save changes',
    );
    if (result == null) return;
    await ref.read(dashboardControllerProvider.notifier).updateNote(
          note.id,
          title: result.title,
          category: result.category,
        );
  }

  @override
  Widget build(BuildContext context) {
    final dashboardState = ref.watch(dashboardControllerProvider);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.mic_rounded,
                  color: AppColors.textPrimary, size: 20),
            ),
            const SizedBox(width: 10),
            const Text(
              'Dalem',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 20,
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.logout_rounded, size: 20),
              onPressed: _handleLogout,
              tooltip: AppStrings.logout,
              color: AppColors.secondary,
            ),
          ),
        ],
      ),
      body: _buildBody(dashboardState),
      floatingActionButton: Container(
        margin: const EdgeInsets.only(bottom: 8, right: 4),
        child: FloatingActionButton.extended(
          onPressed: () async {
            await Navigator.of(context).pushNamed(AppRouter.recorder);
            if (mounted) {
              ref.read(dashboardControllerProvider.notifier).loadNotes();
            }
          },
          icon: const Icon(Icons.mic_rounded),
          label: const Text(
            AppStrings.record,
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(DashboardState state) {
    return switch (state) {
      DashboardInitial() =>
        const Center(child: Text('Initializing...')),
      DashboardLoading() =>
        const Center(child: CircularProgressIndicator()),
      DashboardLoaded() => _buildLoaded(state),
      DashboardError(message: final message) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.error_outline,
                    size: 32, color: AppColors.error),
              ),
              const SizedBox(height: 16),
              Text(message,
                  style: const TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 20),
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

  Widget _buildLoaded(DashboardLoaded state) {
    if (state.notes.isEmpty) {
      return const EmptyState();
    }

    final visible = state.visibleNotes;
    final categories = state.availableCategories;

    return Column(
      children: [
        if (categories.isNotEmpty)
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: const Text('Semua'),
                    selected: state.selectedCategory == null,
                    onSelected: (_) => ref
                        .read(dashboardControllerProvider.notifier)
                        .setCategoryFilter(null),
                  ),
                ),
                for (final cat in categories)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(cat),
                      selected: state.selectedCategory == cat,
                      onSelected: (_) => ref
                          .read(dashboardControllerProvider.notifier)
                          .setCategoryFilter(cat),
                    ),
                  ),
              ],
            ),
          ),
        Expanded(
          child: RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async {
              await ref.read(dashboardControllerProvider.notifier).refresh();
            },
            child: ListView.builder(
              padding: const EdgeInsets.only(top: 8, bottom: 100),
              itemCount: visible.length,
              itemBuilder: (context, index) {
                final note = visible[index];
                return Dismissible(
                  key: ValueKey(note.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 28),
                    margin: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.edit_rounded,
                        color: AppColors.primaryDark),
                  ),
                  confirmDismiss: (_) async {
                    await _handleEditNote(note);
                    return false;
                  },
                  child: NoteCard(
                    note: note,
                    onTap: () {
                      Navigator.of(context).pushNamed(
                        AppRouter.noteDetail,
                        arguments: note.id,
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    final authInterceptor = ref.read(authInterceptorProvider);
    authInterceptor.removeListener(_onUnauthorized);
    super.dispose();
  }
}
