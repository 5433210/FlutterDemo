import 'package:flutter/material.dart';
import '../widgets/character/character_detail_view.dart';

class CharacterDetailDialog extends StatelessWidget {
  final String charId;

  const CharacterDetailDialog({
    super.key,
    required this.charId,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 600,
        height: 800,
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              children: [
                const Text('集字详情', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // 移除 SingleChildScrollView，直接使用 Expanded
            Expanded(
              child: CharacterDetailView(
                charId: charId,                
              ),
            ),
          ],
        ),
      ),
    );
  }
}
