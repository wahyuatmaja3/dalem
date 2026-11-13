import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/providers/dashboard_providers.dart';
import '../controllers/dashboard_controller.dart';
import '../widgets/note_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/note_edit_sheet.dart';
import '../../data/models/note_model.dart';
import '../../data/repositories/notes_repository.dart';
import '../../../../app/router.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/app_error_view.dart';

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
    });
  }

  Future<void> _handleEditNote(NoteModel note) async {
    final repo = ref.read(notesRepositoryProvider);
    final result = await showNoteEditSheet(
      context,
      initialTitle: note.title,
      initialCategory: note.category,
      customCategories: repo.getCustomCategories(),
      saveLabel: 'Simpan',
    );
    if (result == null) return;
    await ref.read(dashboardControllerProvider.notifier).updateNote(
          note.id,
          title: result.title,
          category: result.category,
        );
  }

  Future<void> _openRecorder() async {
    await Navigator.of(context).pushNamed(AppRouter.recorder);
    if (mounted) {
      ref.read(dashboardControllerProvider.notifier).loadNotes();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final dashboardState = ref.watch(dashboardControllerProvider);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dalem',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
                letterSpacing: -0.5,
              ),
            ),
            Text(
              'Catatan Suara & Transkripsi',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.secondary,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, size: 22),
            onPressed: () {
              Navigator.of(context).pushNamed(AppRouter.settings);
            },
            tooltip: AppStrings.settings,
            color: colorScheme.secondary,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _buildBody(dashboardState),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openRecorder,
        icon: const Icon(Icons.mic_rounded, size: 20),
        label: const Text(
          'Rekam Catatan',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
    );
  }

  Widget _buildBody(DashboardState state) {
    return switch (state) {
      DashboardInitial() =>
        const Center(child: Text('Memuat catatan...')),
      DashboardLoading() =>
        const Center(child: CircularProgressIndicator()),
      DashboardLoaded() => _buildLoaded(state),
      DashboardError(message: final message) => AppErrorView(
          message: message,
          onRetry: () {
            ref.read(dashboardControllerProvider.notifier).loadNotes();
          },
        ),
    };
  }

  Widget _buildLoaded(DashboardLoaded state) {
    final colorScheme = Theme.of(context).colorScheme;

    if (state.notes.isEmpty) {
      return EmptyState(
        onRecord: _openRecorder,
      );
    }

    final visible = state.visibleNotes;
    final categories = state.availableCategories;

    return Column(
      children: [
        if (categories.isNotEmpty)
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: const Text('Semua'),
                    selected: state.selectedCategory == null,
                    showCheckmark: false,
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
                      showCheckmark: false,
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
            color: colorScheme.primary,
            onRefresh: () async {
              await ref.read(dashboardControllerProvider.notifier).refresh();
            },
            child: ListView.builder(
              padding: const EdgeInsets.only(top: 8, bottom: 96),
              itemCount: visible.length,
              itemBuilder: (context, index) {
                final note = visible[index];
                return Dismissible(
                  key: ValueKey(note.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 24),
                    margin: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 5),
                    decoration: BoxDecoration(
                      color: colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.edit_rounded,
                            size: 18, color: colorScheme.onSecondaryContainer),
                        const SizedBox(width: 8),
                        Text(
                          'Ubah',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSecondaryContainer,
                          ),
                        ),
                      ],
                    ),
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
}
