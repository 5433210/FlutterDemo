import 'package:go_router/go_router.dart';

import '../presentation/pages/home_page.dart';

/// The route configuration.
final routes = <RouteBase>[
  GoRoute(
    path: AppRoutes.home,
    builder: (context, state) =>
        const HomePagePlaceholder(), // Placeholder for home page
  ),
];

/// App route definitions
class AppRoutes {
  static const home = '/';
  static const workBrowse = '/work_browse';
  static const workDetail = '/work_detail';
  static const workImport = '/work_import';
  static const characterList = '/character_list';
  static const characterDetail = '/character_detail';
  static const practiceList = '/practice_list';
  static const practiceDetail = '/practice_detail';
  static const practiceEdit = '/practice_edit';
  static const settings = '/settings';
  static const String workEdit = '/work/edit';
  static const String workExtract = '/work/extract';
}
