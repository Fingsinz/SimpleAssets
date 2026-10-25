import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/import_export_repository_impl.dart';
import '../../domain/repositories/import_export_repository.dart';
import 'database_provider.dart';

final importExportRepositoryProvider = Provider<ImportExportRepository>(
  (ref) => ImportExportRepositoryImpl(ref.watch(databaseProvider)),
);
