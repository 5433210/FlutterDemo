import 'package:flutter/material.dart';

import '../infrastructure/logging/logger.dart';

/// 路由观察者，用于诊断导航问题
class AppRouteObserver extends NavigatorObserver {
  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    AppLogger.debug('路由被弹出', tag: 'Navigation', data: {
      'route': route.settings.name ?? route.toString(),
      'previousRoute': previousRoute?.settings.name ?? previousRoute.toString(),
    });
    super.didPop(route, previousRoute);
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    AppLogger.debug('路由被推入', tag: 'Navigation', data: {
      'route': route.settings.name ?? route.toString(),
      'previousRoute': previousRoute?.settings.name ?? previousRoute.toString(),
    });
    super.didPush(route, previousRoute);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    AppLogger.debug('路由被移除', tag: 'Navigation', data: {
      'route': route.settings.name ?? route.toString(),
      'previousRoute': previousRoute?.settings.name ?? previousRoute.toString(),
    });
    super.didRemove(route, previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    AppLogger.debug('路由被替换', tag: 'Navigation', data: {
      'newRoute': newRoute?.settings.name ?? newRoute.toString(),
      'oldRoute': oldRoute?.settings.name ?? oldRoute.toString(),
    });
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }
}
