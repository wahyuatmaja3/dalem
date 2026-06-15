import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/notes_repository.dart';
import '../../presentation/controllers/dashboard_controller.dart';

final dashboardControllerProvider =
    StateNotifierProvider<DashboardController, DashboardState>((ref) {
  final repository = ref.read(notesRepositoryProvider);
  return DashboardController(repository: repository);
});
