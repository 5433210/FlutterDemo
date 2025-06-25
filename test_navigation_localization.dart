import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'lib/l10n/app_localizations.dart';
import 'lib/presentation/utils/navigation_localizations.dart';
import 'lib/presentation/utils/cross_navigation_helper.dart';

void main() {
  runApp(const NavigationTestApp());
}

class NavigationTestApp extends StatelessWidget {
  const NavigationTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const ProviderScope(
      child: MaterialApp(
        title: 'Navigation Localization Test',
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: NavigationTestPage(),
      ),
    );
  }
}

class NavigationTestPage extends StatefulWidget {
  const NavigationTestPage({super.key});

  @override
  State<NavigationTestPage> createState() => _NavigationTestPageState();
}

class _NavigationTestPageState extends State<NavigationTestPage> {
  Locale _currentLocale = const Locale('zh');

  void _toggleLocale() {
    setState(() {
      _currentLocale = _currentLocale.languageCode == 'zh'
          ? const Locale('en')
          : const Locale('zh');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Localizations.override(
      context: context,
      locale: _currentLocale,
      child: Builder(
        builder: (context) {
          return Scaffold(
            appBar: AppBar(
              title: Text('导航本地化测试 - ${_currentLocale.languageCode}'),
              actions: [
                IconButton(
                  onPressed: _toggleLocale,
                  icon: const Icon(Icons.language),
                  tooltip: '切换语言',
                ),
              ],
            ),
            body: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '区域名称测试:',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  for (int i = 0; i < 5; i++)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        children: [
                          Text('区域 $i: '),
                          Text(
                            CrossNavigationHelper.getSectionName(context, i),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 32),
                  Text(
                    '导航消息测试:',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  _buildMessageTest(
                    context,
                    '导航到特定项成功',
                    NavigationLocalizations.getNavigationSuccessMessage(
                      context,
                      NavigationOperation.toSpecificItem,
                    ),
                  ),
                  _buildMessageTest(
                    context,
                    '返回上一个区域成功',
                    NavigationLocalizations.getNavigationSuccessMessage(
                      context,
                      NavigationOperation.back,
                    ),
                  ),
                  _buildMessageTest(
                    context,
                    '导航到新区域成功',
                    NavigationLocalizations.getNavigationSuccessMessage(
                      context,
                      NavigationOperation.toNewSection,
                    ),
                  ),
                  _buildMessageTest(
                    context,
                    '导航失败示例',
                    NavigationLocalizations.getNavigationFailedMessage(
                      context,
                      NavigationOperation.toSpecificItem,
                    ),
                  ),
                  _buildMessageTest(
                    context,
                    '清空历史记录失败',
                    NavigationLocalizations.getClearHistoryFailedMessage(
                        context),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMessageTest(BuildContext context, String label, String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text('$label: '),
          ),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
