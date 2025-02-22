import 'package:flutter/material.dart';
import 'panels/general_settings_panel.dart';
import 'panels/storage_settings_panel.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  int _selectedIndex = 0;

  final _panels = [
    const GeneralSettingsPanel(),
    const StorageSettingsPanel(),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // 左侧导航栏
        NavigationRail(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (index) {
            setState(() => _selectedIndex = index);
          },
          labelType: NavigationRailLabelType.all,
          destinations: const [
            NavigationRailDestination(
              icon: Icon(Icons.settings),
              label: Text('常规设置'),
            ),
            NavigationRailDestination(
              icon: Icon(Icons.storage),
              label: Text('存储设置'),
            ),
          ],
        ),
        // 右侧内容区
        Expanded(
          child: _panels[_selectedIndex],
        ),
      ],
    );
  }
}
