import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../application/providers/service_providers.dart';
import '../../../../application/services/character/character_service.dart';
import '../../../../domain/models/character/character_entity.dart';
import '../../../../domain/models/character/character_region.dart';
import '../../../../domain/models/character/processing_options.dart';
import '../../common/editable_number_field.dart';
import '../practice_edit_controller.dart';
import 'element_common_property_panel.dart';
import 'layer_info_panel.dart';

/// 集字内容属性面板
class CollectionPropertyPanel extends ConsumerStatefulWidget {
  final Map<String, dynamic> element;
  final Function(Map<String, dynamic>) onElementPropertiesChanged;
  final Function(String) onUpdateChars;
  final PracticeEditController controller;
  final WidgetRef? ref;

  const CollectionPropertyPanel({
    Key? key,
    required this.controller,
    required this.element,
    required this.onElementPropertiesChanged,
    required this.onUpdateChars,
    this.ref,
  }) : super(key: key);

  @override
  ConsumerState<CollectionPropertyPanel> createState() =>
      _CollectionPropertyPanelState();
}

class _CollectionPropertyPanelState
    extends ConsumerState<CollectionPropertyPanel> {
  // 当前选中的字符索引
  int _selectedCharIndex = 0;

  // 当前选中字符的候选集字列表
  List<CharacterEntity> _candidateCharacters = [];
  bool _isLoadingCharacters = false;

  // 文本控制器
  final TextEditingController _textController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final x = (widget.element['x'] as num).toDouble();
    final y = (widget.element['y'] as num).toDouble();
    final width = (widget.element['width'] as num).toDouble();
    final height = (widget.element['height'] as num).toDouble();
    final rotation = (widget.element['rotation'] as num?)?.toDouble() ?? 0.0;
    final opacity = (widget.element['opacity'] as num?)?.toDouble() ?? 1.0;
    final layerId = widget.element['layerId'] as String?;

    // 获取图层信息
    Map<String, dynamic>? layer;
    if (layerId != null) {
      layer = widget.controller.state.getLayerById(layerId);
    }

    // 集字特有属性
    final content = widget.element['content'] as Map<String, dynamic>;
    final characters = content['characters'] as String? ?? '';
    final fontSize = (content['fontSize'] as num?)?.toDouble() ?? 36.0;
    final lineSpacing = (content['lineSpacing'] as num?)?.toDouble() ?? 10.0;
    final letterSpacing = (content['letterSpacing'] as num?)?.toDouble() ?? 5.0;
    final textAlign = content['textAlign'] as String? ?? 'left';
    final verticalAlign = content['verticalAlign'] as String? ?? 'top';
    final writingMode = content['writingMode'] as String? ?? 'horizontal-l';
    final padding = (content['padding'] as num?)?.toDouble() ?? 0.0;
    final fontColor = content['fontColor'] as String? ?? '#000000';
    final backgroundColor =
        content['backgroundColor'] as String? ?? 'transparent';

    return ListView(
      children: [
        // 基本属性部分 (放在最顶部)
        ElementCommonPropertyPanel(
          element: widget.element,
          onElementPropertiesChanged: widget.onElementPropertiesChanged,
          controller: widget.controller,
        ),

        // 图层信息部分
        LayerInfoPanel(layer: layer),

        // 几何属性部分
        ExpansionTile(
          title: const Text('几何属性'),
          initiallyExpanded: true,
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // X和Y位置
                  Row(
                    children: [
                      Expanded(
                        child: EditableNumberField(
                          label: 'X',
                          value: x,
                          suffix: 'px',
                          min: 0,
                          max: 10000,
                          onChanged: (value) => _updateProperty('x', value),
                        ),
                      ),
                      const SizedBox(width: 8.0),
                      Expanded(
                        child: EditableNumberField(
                          label: 'Y',
                          value: y,
                          suffix: 'px',
                          min: 0,
                          max: 10000,
                          onChanged: (value) => _updateProperty('y', value),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8.0),
                  // 宽度和高度
                  Row(
                    children: [
                      Expanded(
                        child: EditableNumberField(
                          label: '宽度',
                          value: width,
                          suffix: 'px',
                          min: 10,
                          max: 10000,
                          onChanged: (value) => _updateProperty('width', value),
                        ),
                      ),
                      const SizedBox(width: 8.0),
                      Expanded(
                        child: EditableNumberField(
                          label: '高度',
                          value: height,
                          suffix: 'px',
                          min: 10,
                          max: 10000,
                          onChanged: (value) =>
                              _updateProperty('height', value),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8.0),
                  // 旋转角度
                  EditableNumberField(
                    label: '旋转',
                    value: rotation,
                    suffix: '°',
                    min: -360,
                    max: 360,
                    decimalPlaces: 1,
                    onChanged: (value) => _updateProperty('rotation', value),
                  ),
                ],
              ),
            ),
          ],
        ),

        // 视觉属性部分
        ExpansionTile(
          title: const Text('视觉设置'),
          initiallyExpanded: true,
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 字体颜色和背景颜色
                  const Text('颜色设置:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8.0),
                  Row(
                    children: [
                      const Text('字体颜色:'),
                      const SizedBox(width: 8.0),
                      GestureDetector(
                        onTap: () {
                          _showColorPicker(
                            context,
                            fontColor,
                            (color) {
                              _updateContentProperty(
                                  'fontColor', _colorToHex(color));
                            },
                          );
                        },
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: _hexToColor(fontColor),
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16.0),
                      const Text('背景颜色:'),
                      const SizedBox(width: 8.0),
                      GestureDetector(
                        onTap: () {
                          _showColorPicker(
                            context,
                            backgroundColor,
                            (color) {
                              _updateContentProperty(
                                  'backgroundColor', _colorToHex(color));
                            },
                          );
                        },
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: _hexToColor(backgroundColor),
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16.0),

                  // 透明度
                  const Text('透明度:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8.0),
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Slider(
                          value: opacity,
                          min: 0.0,
                          max: 1.0,
                          divisions: 100,
                          label: '${(opacity * 100).round()}%',
                          onChanged: (value) {
                            _updateProperty('opacity', value);
                          },
                        ),
                      ),
                      const SizedBox(width: 8.0),
                      Expanded(
                        flex: 2,
                        child: EditableNumberField(
                          label: '透明度',
                          value: opacity * 100, // 转换为百分比
                          suffix: '%',
                          min: 0,
                          max: 100,
                          decimalPlaces: 0,
                          onChanged: (value) {
                            // 转换回 0-1 范围
                            _updateProperty('opacity', value / 100);
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16.0),

                  // 内边距设置
                  const Text('内边距:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8.0),
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Slider(
                          value: padding,
                          min: 0,
                          max: 50,
                          divisions: 50,
                          label: '${padding.round()}px',
                          onChanged: (value) {
                            _updateContentProperty('padding', value);
                          },
                        ),
                      ),
                      const SizedBox(width: 8.0),
                      Expanded(
                        flex: 2,
                        child: EditableNumberField(
                          label: '内边距',
                          value: padding,
                          suffix: 'px',
                          min: 0,
                          max: 100,
                          decimalPlaces: 0,
                          onChanged: (value) {
                            _updateContentProperty('padding', value);
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),

        // 内容设置部分
        ExpansionTile(
          title: const Text('内容设置'),
          initiallyExpanded: true,
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 汉字内容
                  const Text('汉字内容:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8.0),
                  _buildTextContentField(characters),

                  const SizedBox(height: 16.0),

                  // 集字预览
                  const Text('集字预览:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8.0),
                  _buildCharacterPreview(characters),

                  const SizedBox(height: 16.0),

                  // 候选集字
                  const Text('候选集字:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8.0),
                  _buildCandidateCharacters(),

                  const SizedBox(height: 16.0),

                  // 清除图片缓存按钮
                  ElevatedButton.icon(
                    icon: const Icon(Icons.cleaning_services),
                    label: const Text('清除图片缓存'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[100],
                      foregroundColor: Colors.red[900],
                    ),
                    onPressed: _clearImageCache,
                  ),

                  const SizedBox(height: 16.0),

                  // 字号设置
                  const Text('字号:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8.0),
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Slider(
                          value: fontSize,
                          min: 1,
                          max: 100,
                          divisions: 99,
                          label: '${fontSize.round()}px',
                          onChanged: (value) {
                            _updateContentProperty('fontSize', value);
                          },
                        ),
                      ),
                      const SizedBox(width: 8.0),
                      Expanded(
                        flex: 2,
                        child: EditableNumberField(
                          label: '字号',
                          value: fontSize,
                          suffix: 'px',
                          min: 1,
                          max: 200,
                          onChanged: (value) {
                            _updateContentProperty('fontSize', value);
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16.0),

                  // 字间距设置
                  const Text('字间距:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8.0),
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Slider(
                          value: letterSpacing,
                          min: 0,
                          max: 50,
                          divisions: 50,
                          label: '${letterSpacing.round()}px',
                          onChanged: (value) {
                            _updateContentProperty('letterSpacing', value);
                          },
                        ),
                      ),
                      const SizedBox(width: 8.0),
                      Expanded(
                        flex: 2,
                        child: EditableNumberField(
                          label: '字间距',
                          value: letterSpacing,
                          suffix: 'px',
                          min: 0,
                          max: 100,
                          decimalPlaces: 1,
                          onChanged: (value) {
                            _updateContentProperty('letterSpacing', value);
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16.0),

                  // 行（列）间距设置
                  const Text('行（列）间距:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8.0),
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Slider(
                          value: lineSpacing,
                          min: 0,
                          max: 50,
                          divisions: 50,
                          label: '${lineSpacing.round()}px',
                          onChanged: (value) {
                            _updateContentProperty('lineSpacing', value);
                          },
                        ),
                      ),
                      const SizedBox(width: 8.0),
                      Expanded(
                        flex: 2,
                        child: EditableNumberField(
                          label: '行（列）间距',
                          value: lineSpacing,
                          suffix: 'px',
                          min: 0,
                          max: 100,
                          decimalPlaces: 1,
                          onChanged: (value) {
                            _updateContentProperty('lineSpacing', value);
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16.0),

                  // 水平对齐方式
                  const Text('水平对齐:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8.0),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: ToggleButtons(
                      isSelected: [
                        textAlign == 'left',
                        textAlign == 'center',
                        textAlign == 'right',
                        textAlign == 'justify',
                      ],
                      onPressed: (index) {
                        String newAlign;
                        switch (index) {
                          case 0:
                            newAlign = 'left';
                            break;
                          case 1:
                            newAlign = 'center';
                            break;
                          case 2:
                            newAlign = 'right';
                            break;
                          case 3:
                            newAlign = 'justify';
                            break;
                          default:
                            newAlign = 'left';
                        }
                        _updateContentProperty('textAlign', newAlign);
                      },
                      children: const [
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10.0),
                          child: Icon(Icons.align_horizontal_left),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10.0),
                          child: Icon(Icons.align_horizontal_center),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10.0),
                          child: Icon(Icons.align_horizontal_right),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10.0),
                          child: Icon(Icons.format_align_justify),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16.0),

                  // 垂直对齐
                  const Text('垂直对齐:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8.0),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: ToggleButtons(
                      isSelected: [
                        verticalAlign == 'top',
                        verticalAlign == 'middle',
                        verticalAlign == 'bottom',
                        verticalAlign == 'justify',
                      ],
                      onPressed: (index) {
                        String newAlign;
                        switch (index) {
                          case 0:
                            newAlign = 'top';
                            break;
                          case 1:
                            newAlign = 'middle';
                            break;
                          case 2:
                            newAlign = 'bottom';
                            break;
                          case 3:
                            newAlign = 'justify';
                            break;
                          default:
                            newAlign = 'top';
                        }
                        _updateContentProperty('verticalAlign', newAlign);
                      },
                      children: const [
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10.0),
                          child: Icon(Icons.vertical_align_top),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10.0),
                          child: Icon(Icons.vertical_align_center),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10.0),
                          child: Icon(Icons.vertical_align_bottom),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10.0),
                          child: Icon(Icons.format_align_justify),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16.0),

                  // 书写方向
                  const Text('书写方向:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8.0),
                  Wrap(
                    spacing: 8.0,
                    children: [
                      _buildWritingModeButton(
                        mode: 'horizontal-l',
                        label: '横排左起',
                        currentMode: writingMode,
                        icon: Icons.format_textdirection_l_to_r,
                      ),
                      _buildWritingModeButton(
                        mode: 'vertical-r',
                        label: '竖排右起',
                        currentMode: writingMode,
                        icon: Icons.format_textdirection_r_to_l,
                      ),
                      _buildWritingModeButton(
                        mode: 'horizontal-r',
                        label: '横排右起',
                        currentMode: writingMode,
                        icon: Icons.keyboard_double_arrow_left,
                      ),
                      _buildWritingModeButton(
                        mode: 'vertical-l',
                        label: '竖排左起',
                        currentMode: writingMode,
                        icon: Icons.keyboard_double_arrow_right,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  void didUpdateWidget(CollectionPropertyPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.element != widget.element) {
      // 更新文本控制器
      final content = widget.element['content'] as Map<String, dynamic>;
      final characters = content['characters'] as String? ?? '';
      final oldContent = oldWidget.element['content'] as Map<String, dynamic>;
      final oldCharacters = oldContent['characters'] as String? ?? '';

      // 仅在文本实际变化时更新控制器，避免光标位置重置
      if (_textController.text != characters) {
        _textController.text = characters;
      }

      // 如果字符内容发生变化，则重新加载候选集字并更新字符图像
      if (oldCharacters != characters) {
        debugPrint('字符内容已变更: "$oldCharacters" -> "$characters"');
        _loadCandidateCharacters().then((_) {
          _updateCharacterImagesForNewText(characters);
        });
      } else {
        _loadCandidateCharacters();
      }
    }
  }

  @override
  void dispose() {
    // 释放文本控制器
    _textController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _initCharacterImages();
    // 初始化文本控制器
    final content = widget.element['content'] as Map<String, dynamic>;
    final characters = content['characters'] as String? ?? '';
    _textController.text = characters;

    _loadCandidateCharacters();
  }

  // 构建候选集字
  Widget _buildCandidateCharacters() {
    debugPrint('构建候选集字面板，候选集字数量: ${_candidateCharacters.length}');

    if (_candidateCharacters.isEmpty) {
      debugPrint('没有候选集字，显示提示信息');
      return Container(
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(4.0),
        ),
        child: _isLoadingCharacters
            ? const Center(child: CircularProgressIndicator())
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Center(
                    child: Text('无候选集字', style: TextStyle(color: Colors.grey)),
                  ),
                  const SizedBox(height: 8),
                  Text('当前作品ID: ${widget.controller.practiceId ?? "未设置"}',
                      style: const TextStyle(fontSize: 10, color: Colors.grey)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          _loadCandidateCharacters();
                        },
                        child: const Text('重新加载'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          _showAddCharacterDialog();
                        },
                        child: const Text('手动添加'),
                      ),
                    ],
                  ),
                ],
              ),
      );
    }

    final content = widget.element['content'] as Map<String, dynamic>;
    final characters = content['characters'] as String? ?? '';
    final selectedChar = _selectedCharIndex < characters.length
        ? characters[_selectedCharIndex]
        : '';

    debugPrint(
        '当前选中字符: "$selectedChar", 索引: $_selectedCharIndex, 总字符: "$characters"');

    // 过滤出与当前选中字符匹配的候选集字
    final matchingCharacters = _candidateCharacters
        .where((entity) => entity.character == selectedChar)
        .toList();

    debugPrint('匹配的候选集字数量: ${matchingCharacters.length}');

    if (matchingCharacters.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(4.0),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Center(
              child: Text('无匹配的候选集字', style: TextStyle(color: Colors.grey)),
            ),
            const SizedBox(height: 8),
            Text('当前选中字符: "$selectedChar"',
                style: const TextStyle(fontSize: 10, color: Colors.grey)),
            if (_candidateCharacters.isNotEmpty)
              Text(
                  '可用字符: ${_candidateCharacters.map((e) => e.character).join(", ")}',
                  style: const TextStyle(fontSize: 10, color: Colors.grey)),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                _showAddCharacterDialog();
              },
              child: const Text('手动添加此字符'),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(4.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 8.0),
            child:
                Text('候选集字列表', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: List.generate(
              matchingCharacters.length,
              (index) {
                final entity = matchingCharacters[index];

                // 检查当前元素是否已经选中
                final content =
                    widget.element['content'] as Map<String, dynamic>;
                final characterImages =
                    content['characterImages'] as Map<String, dynamic>? ?? {};
                final imageInfo = characterImages['$_selectedCharIndex']
                    as Map<String, dynamic>?;
                final isSelected =
                    imageInfo != null && imageInfo['characterId'] == entity.id;

                return FutureBuilder<Map<String, String>?>(
                  future: ref
                      .read(characterImageServiceProvider)
                      .getAvailableFormat(entity.id),
                  builder: (context, snapshot) {
                    return GestureDetector(
                      onTap: () => _selectCandidateCharacter(entity),
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color:
                                isSelected ? Colors.blue : Colors.grey.shade300,
                            width: isSelected ? 2.0 : 1.0,
                          ),
                          borderRadius: BorderRadius.circular(4.0),
                        ),
                        child: Stack(
                          children: [
                            if (snapshot.connectionState ==
                                ConnectionState.waiting)
                              const Center(
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                ),
                              )
                            else if (snapshot.hasData && snapshot.data != null)
                              FutureBuilder<Uint8List?>(
                                future: ref
                                    .read(characterImageServiceProvider)
                                    .getCharacterImage(
                                      entity.id,
                                      snapshot.data!['type']!,
                                      snapshot.data!['format']!,
                                    ),
                                builder: (context, imageSnapshot) {
                                  if (imageSnapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return const Center(
                                      child: SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2),
                                      ),
                                    );
                                  } else if (imageSnapshot.hasData &&
                                      imageSnapshot.data != null) {
                                    return Center(
                                      child: Image.memory(
                                        imageSnapshot.data!,
                                        fit: BoxFit.contain,
                                      ),
                                    );
                                  } else {
                                    return Center(
                                      child: Text(
                                        '${entity.character}${_getSubscript(index + 1)}',
                                        style: const TextStyle(fontSize: 20),
                                      ),
                                    );
                                  }
                                },
                              )
                            else
                              Center(
                                child: Text(
                                  '${entity.character}${_getSubscript(index + 1)}',
                                  style: const TextStyle(fontSize: 20),
                                ),
                              ),
                            if (isSelected)
                              const Positioned(
                                right: 2,
                                bottom: 2,
                                child: Icon(
                                  Icons.check_circle,
                                  size: 16,
                                  color: Colors.green,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () {
                  _showAddCharacterDialog();
                },
                child: const Text('添加新候选字'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 构建字符图像
  Widget _buildCharacterImage(String character,
      {bool isSelected = false, int? index}) {
    // 检查元素内容中是否已有字符图像信息
    final content = widget.element['content'] as Map<String, dynamic>? ?? {};
    final characterImages =
        content['characterImages'] as Map<String, dynamic>? ?? {};
    final idx = index ?? _selectedCharIndex;

    debugPrint('构建字符图像: $character, 索引: $idx, 选中: $isSelected');

    // 如果有该索引的字符图像信息，则使用它
    if (characterImages.containsKey('$idx')) {
      final imageInfo = characterImages['$idx'] as Map<String, dynamic>;
      final characterId = imageInfo['characterId'] as String?;
      final type = imageInfo['type'] as String?;
      final format = imageInfo['format'] as String?;

      debugPrint(
          '使用已有字符图像信息: characterId=$characterId, type=$type, format=$format');

      if (characterId != null && type != null && format != null) {
        return FutureBuilder<Uint8List?>(
          future: Future.any([
            ref
                .read(characterImageServiceProvider)
                .getCharacterImage(characterId, type, format),
            // 添加3秒超时
            Future.delayed(const Duration(seconds: 3), () => null),
          ]),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                  child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2)));
            }

            if (!snapshot.hasData || snapshot.data == null) {
              debugPrint('无法加载字符图像: $characterId, $type, $format');
              return _buildDefaultCharacterText(character, isSelected);
            }

            debugPrint(
                '成功加载字符图像: $characterId, $type, $format, 大小: ${snapshot.data!.length} 字节');
            return Image.memory(
              snapshot.data!,
              fit: BoxFit.contain,
              color: isSelected ? Colors.blue : null,
              colorBlendMode: isSelected ? BlendMode.srcATop : null,
              errorBuilder: (context, error, stackTrace) {
                debugPrint('图像渲染错误: $error');
                return _buildDefaultCharacterText(character, isSelected);
              },
            );
          },
        );
      }
    }

    // 如果没有匹配的候选集字，则显示文本
    final matchingCharacters = _candidateCharacters
        .where((entity) => entity.character == character)
        .toList();

    if (matchingCharacters.isEmpty) {
      debugPrint('没有匹配的候选集字: $character');
      return _buildDefaultCharacterText(character, isSelected);
    }

    // 使用第一个匹配的字符实体
    final entity = matchingCharacters.first;
    debugPrint('使用候选集字: ${entity.id}, 字符: ${entity.character}');

    // 使用 CharacterImageService 加载图像，优先使用缩略图
    return FutureBuilder<Map<String, String>?>(
      future: Future.any([
        ref
            .read(characterImageServiceProvider)
            .getAvailableFormat(entity.id, preferThumbnail: true),
        // 添加2秒超时
        Future.delayed(const Duration(seconds: 2), () => null),
      ]),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2)));
        }

        if (!snapshot.hasData || snapshot.data == null) {
          debugPrint('无法获取可用格式: ${entity.id}');
          return _buildDefaultCharacterText(character, isSelected);
        }

        final format = snapshot.data!;
        debugPrint('获取到可用格式: ${format['type']}, ${format['format']}');

        return FutureBuilder<Uint8List?>(
          future: Future.any([
            ref.read(characterImageServiceProvider).getCharacterImage(
                entity.id, format['type']!, format['format']!),
            // 添加3秒超时
            Future.delayed(const Duration(seconds: 3), () => null),
          ]),
          builder: (context, imageSnapshot) {
            if (imageSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                  child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2)));
            }

            if (!imageSnapshot.hasData || imageSnapshot.data == null) {
              debugPrint(
                  '无法加载字符图像: ${entity.id}, ${format['type']}, ${format['format']}');
              return _buildDefaultCharacterText(character, isSelected);
            }

            debugPrint(
                '成功加载字符图像: ${entity.id}, ${format['type']}, ${format['format']}, 大小: ${imageSnapshot.data!.length} 字节');

            // 更新元素内容中的字符图像信息
            _updateCharacterImage(
                idx, entity.id, format['type']!, format['format']!);

            return Image.memory(
              imageSnapshot.data!,
              fit: BoxFit.contain,
              color: isSelected ? Colors.blue : null,
              colorBlendMode: isSelected ? BlendMode.srcATop : null,
              errorBuilder: (context, error, stackTrace) {
                debugPrint('图像渲染错误: $error');
                return _buildDefaultCharacterText(character, isSelected);
              },
            );
          },
        );
      },
    );
  }

  // 构建集字预览
  Widget _buildCharacterPreview(String characters) {
    if (characters.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(4.0),
        ),
        child: const Center(
          child: Text('无集字内容', style: TextStyle(color: Colors.grey)),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(4.0),
      ),
      child: Wrap(
        spacing: 8.0,
        runSpacing: 8.0,
        children: List.generate(
          characters.characters.length,
          (index) => GestureDetector(
            onTap: () => _selectCharacter(index),
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                border: Border.all(
                  color: _selectedCharIndex == index
                      ? Colors.blue
                      : Colors.grey.shade300,
                  width: _selectedCharIndex == index ? 2.0 : 1.0,
                ),
                borderRadius: BorderRadius.circular(4.0),
              ),
              child: _buildCharacterImage(
                  characters.characters.elementAt(index),
                  isSelected: _selectedCharIndex == index,
                  index: index),
            ),
          ),
        ),
      ),
    );
  }

  // 构建默认字符文本
  Widget _buildDefaultCharacterText(String character, bool isSelected) {
    return Center(
      child: Text(
        character,
        style: TextStyle(
          fontSize: 24,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Colors.blue : Colors.black,
        ),
      ),
    );
  }

  // 构建文本内容输入字段
  Widget _buildTextContentField(String initialText) {
    // 确保控制器内容与初始文本一致
    if (_textController.text != initialText) {
      _textController.text = initialText;
    }

    return TextField(
      controller: _textController,
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      ),
      keyboardType: TextInputType.multiline,
      maxLines: 5,
      minLines: 3,
      onChanged: (value) {
        widget.onUpdateChars(value);
        // 重置选中的字符索引
        setState(() {
          _selectedCharIndex = 0;
        });
        // 加载候选集字并为新输入的字符自动设置图片
        _loadCandidateCharacters().then((_) {
          _updateCharacterImagesForNewText(value);
        });
      },
    );
  }

  // 构建书写模式按钮
  Widget _buildWritingModeButton({
    required String mode,
    required String label,
    required String currentMode,
    required IconData icon,
  }) {
    final isSelected = currentMode == mode;

    return ElevatedButton.icon(
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.blue : null,
        foregroundColor: isSelected ? Colors.white : null,
      ),
      onPressed: () {
        _updateContentProperty('writingMode', mode);
      },
    );
  }

  // 清除图片缓存
  void _clearImageCache() {
    // 使用更简单的方法，避免复杂的异步操作和对话框管理
    // showDialog(
    //   context: context,
    //   barrierDismissible: false,
    //   builder: (BuildContext dialogContext) {
    //     // 创建一个简单的加载对话框
    //     return const AlertDialog(
    //       content: Column(
    //         mainAxisSize: MainAxisSize.min,
    //         children: [
    //           CircularProgressIndicator(),
    //           SizedBox(height: 16),
    //           Text('正在清除图片缓存...'),
    //         ],
    //       ),
    //     );

    //     // 注意：不使用PopScope或WillPopScope，允许用户通过返回键关闭对话框
    //   },
    // );

    // 在对话框显示后，执行清除缓存操作
    Future.delayed(const Duration(milliseconds: 100), () async {
      try {
        // 清除缓存
        final characterImageService = ref.read(characterImageServiceProvider);
        await characterImageService.clearAllImageCache();

        // 确保组件仍然挂载
        if (!mounted) return;

        // // 关闭加载对话框
        // if (Navigator.canPop(context)) {
        //   Navigator.of(context).pop();
        // }

        // 显示成功消息
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('图片缓存已清除'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        // 刷新UI
        setState(() {});
      } catch (e) {
        // 确保组件仍然挂载
        if (!mounted) return;

        // // 关闭加载对话框
        // if (Navigator.canPop(context)) {
        //   Navigator.of(context).pop();
        // }

        // 显示错误消息
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('清除图片缓存失败: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );

        debugPrint('清除图片缓存失败: $e');
      }
    });
  }

  /// 将颜色转换为十六进制字符串
  String _colorToHex(Color color) {
    if (color == Colors.transparent) {
      return 'transparent';
    }

    try {
      // 将 RGB 值转换为十六进制
      final colorValue = color.toString();
      // 从 Color(0xFFFFFFFF) 格式中提取十六进制值
      final hexCode = colorValue.split('(0x')[1].split(')')[0];
      // 移除前两位的透明度值
      final colorCode = hexCode.length > 6 ? hexCode.substring(2) : hexCode;

      debugPrint('Converting color to hex: $color -> #$colorCode');
      return '#$colorCode'; // 包含 # 前缀
    } catch (e) {
      debugPrint('Error converting color to hex: $e');
      return '#000000'; // 出错时返回默认黑色
    }
  }

  // 获取默认字符图像格式
  Future<Map<String, String>?> _getDefaultCharacterImageFormat(
      String characterId,
      {bool preferThumbnail = false}) async {
    try {
      final characterImageService = ref.read(characterImageServiceProvider);

      // 如果优先使用缩略图，则直接检查缩略图格式
      if (preferThumbnail) {
        // 检查是否有缩略图格式
        bool hasThumbnail = await characterImageService.hasCharacterImage(
            characterId, 'thumbnail', 'jpg');
        if (hasThumbnail) {
          return {'type': 'thumbnail', 'format': 'jpg'};
        }
      }

      // 否则使用默认格式
      return await characterImageService.getAvailableFormat(characterId);
    } catch (e) {
      debugPrint('获取默认字符图像格式失败: $e');
      return null;
    }
  }

  // 获取下标
  String _getSubscript(int number) {
    const Map<String, String> subscripts = {
      '0': '₀',
      '1': '₁',
      '2': '₂',
      '3': '₃',
      '4': '₄',
      '5': '₅',
      '6': '₆',
      '7': '₇',
      '8': '₈',
      '9': '₉',
    };

    final String numberStr = number.toString();
    final StringBuffer result = StringBuffer();

    for (int i = 0; i < numberStr.length; i++) {
      result.write(subscripts[numberStr[i]] ?? numberStr[i]);
    }

    return result.toString();
  }

  /// 将十六进制颜色字符串转换为Color对象
  Color _hexToColor(String hexString) {
    if (hexString == 'transparent') {
      return Colors.transparent;
    }

    try {
      final buffer = StringBuffer();
      if (hexString.startsWith('#')) {
        if (hexString.length == 7) {
          // #RRGGBB format
          buffer.write('ff'); // Add full opacity
          buffer.write(hexString.substring(1));
        } else if (hexString.length == 9) {
          // #AARRGGBB format
          buffer.write(hexString.substring(1));
        } else {
          debugPrint('Invalid color format: $hexString');
          return Colors.black; // Invalid format
        }
      } else {
        if (hexString.length == 6) {
          buffer.write('ff'); // Add full opacity
          buffer.write(hexString);
        } else {
          debugPrint('Invalid color format: $hexString');
          return Colors.black;
        }
      }

      final hexValue = buffer.toString();
      final colorValue = int.parse(hexValue, radix: 16);
      final color = Color(colorValue);

      debugPrint('Parsed color: $hexString -> 0x$hexValue -> $color');

      return color;
    } catch (e) {
      debugPrint('解析颜色失败: $e, hexString: $hexString');
      return Colors.black;
    }
  }

  // 初始化字符图像
  Future<void> _initCharacterImages() async {
    try {
      final content = widget.element['content'] as Map<String, dynamic>? ?? {};
      final characters = content['characters'] as String? ?? '';

      if (characters.isEmpty) {
        return;
      }

      // 检查是否已有字符图像信息
      if (content.containsKey('characterImages')) {
        return;
      }

      // 创建字符图像信息
      final characterImages = <String, dynamic>{};

      // 获取候选集字
      await _loadCandidateCharacters();

      // 为每个字符查找匹配的候选集字
      for (int i = 0; i < characters.length; i++) {
        final char = characters[i];
        final matchingCharacters = _candidateCharacters
            .where((entity) => entity.character == char)
            .toList();

        if (matchingCharacters.isNotEmpty) {
          final entity = matchingCharacters.first;
          // 获取缩略图格式用于预览
          final format = await _getDefaultCharacterImageFormat(entity.id,
              preferThumbnail: true);

          // 在属性面板中使用缩略图，但在集字元素绘制时优先使用方形二值化图，其次是方形SVG轮廓
          final characterImageService = ref.read(characterImageServiceProvider);

          // 检查是否有方形二值化图格式
          bool hasSquareBinary = await characterImageService.hasCharacterImage(
              entity.id, 'square-binary', 'png-binary');

          // 检查是否有方形SVG轮廓格式
          bool hasSquareOutline = await characterImageService.hasCharacterImage(
              entity.id, 'square-outline', 'svg-outline');

          // 确定绘制格式
          String drawingType;
          String drawingFormat;

          if (hasSquareBinary) {
            // 优先使用方形二值化图
            drawingType = 'square-binary';
            drawingFormat = 'png-binary';
          } else if (hasSquareOutline) {
            // 其次使用方形SVG轮廓
            drawingType = 'square-outline';
            drawingFormat = 'svg-outline';
          } else {
            // 默认使用方形二值化图
            drawingType = 'square-binary';
            drawingFormat = 'png-binary';
          }

          if (format != null) {
            characterImages['$i'] = {
              'characterId': entity.id,
              // 使用缩略图格式用于预览
              'type': format['type'],
              'format': format['format'],
              // 添加绘制时使用的格式
              'drawingType': drawingType,
              'drawingFormat': drawingFormat,
            };
          }
        }
      }

      // 更新元素内容
      if (characterImages.isNotEmpty) {
        final updatedContent = Map<String, dynamic>.from(content);
        updatedContent['characterImages'] = characterImages;
        _updateProperty('content', updatedContent);
      }
    } catch (e) {
      debugPrint('初始化字符图像失败: $e');
    }
  }

  // 加载候选集字
  Future<void> _loadCandidateCharacters() async {
    try {
      setState(() {
        _isLoadingCharacters = true;
      });

      // 使用CharacterService获取所有字符
      final characterService = ref.read(characterServiceProvider);

      // 获取当前选中的字符
      final content = widget.element['content'] as Map<String, dynamic>;
      final characters = content['characters'] as String? ?? '';

      if (characters.isEmpty) {
        debugPrint('集字内容为空，无法加载候选集字');
        setState(() {
          _candidateCharacters = [];
          _isLoadingCharacters = false;
        });
        return;
      }

      final selectedChar = _selectedCharIndex < characters.length
          ? characters[_selectedCharIndex]
          : '';

      if (selectedChar.isEmpty) {
        debugPrint('当前选中字符为空，无法加载候选集字');
        setState(() {
          _candidateCharacters = [];
          _isLoadingCharacters = false;
        });
        return;
      }

      debugPrint('开始搜索字符: "$selectedChar"');

      // 搜索字符库中匹配的字符
      final matchingCharacters =
          await characterService.searchCharacters(selectedChar);
      debugPrint('搜索到 ${matchingCharacters.length} 个匹配的字符视图模型');

      if (matchingCharacters.isEmpty) {
        debugPrint('没有找到匹配的字符，尝试添加一个临时字符');

        // 如果没有找到匹配的字符，可以考虑添加一个临时字符
        setState(() {
          _candidateCharacters = [];
          _isLoadingCharacters = false;
        });
        return;
      }

      // 转换为CharacterEntity列表
      debugPrint('开始获取字符详情...');
      final futures = matchingCharacters.map((viewModel) async {
        debugPrint('获取字符详情: ${viewModel.id}, 字符: ${viewModel.character}');
        return await characterService.getCharacterDetails(viewModel.id);
      }).toList();

      final results = await Future.wait(futures);
      final entities = results.whereType<CharacterEntity>().toList();
      debugPrint('获取到 ${entities.length} 个字符实体');

      for (final entity in entities) {
        debugPrint('字符实体: ${entity.id}, 字符: ${entity.character}');
      }

      setState(() {
        _candidateCharacters = entities;
        _isLoadingCharacters = false;
      });
    } catch (e, stack) {
      debugPrint('加载候选集字失败: $e');
      debugPrint('堆栈: $stack');
      setState(() {
        _candidateCharacters = [];
        _isLoadingCharacters = false;
      });
    }
  }

  // 选择候选集字
  Future<void> _selectCandidateCharacter(CharacterEntity entity,
      {bool isTemporary = false}) async {
    debugPrint(
        '选择候选集字: ${entity.id}, 字符: ${entity.character}, 是否临时: $isTemporary');

    try {
      // 获取字符图像格式
      final characterImageService = ref.read(characterImageServiceProvider);
      final format = await characterImageService.getAvailableFormat(entity.id);

      if (format == null) {
        debugPrint('无法获取字符图像格式: ${entity.id}');
        return;
      }

      // 更新元素的字符图像信息
      final content = Map<String, dynamic>.from(
          widget.element['content'] as Map<String, dynamic>? ?? {});

      // 获取当前选中字符的索引
      final characters = content['characters'] as String? ?? '';
      if (_selectedCharIndex < 0 || _selectedCharIndex >= characters.length) {
        debugPrint('无效的字符索引: $_selectedCharIndex');
        return;
      }

      // 使用 _updateCharacterImage 方法更新字符图像信息
      await _updateCharacterImage(
        _selectedCharIndex,
        entity.id,
        format['type'] ?? 'square-binary',
        format['format'] ?? 'png-binary',
        isTemporary: isTemporary,
      );

      // 刷新UI
      setState(() {});

      debugPrint(
          '已更新字符图像信息: ${entity.id}, 索引: $_selectedCharIndex, 是否临时: $isTemporary');
    } catch (e) {
      debugPrint('选择候选集字失败: $e');
    }
  }

  // 选择字符
  void _selectCharacter(int index) {
    final content = widget.element['content'] as Map<String, dynamic>;
    final characters = content['characters'] as String? ?? '';

    debugPrint('选择字符，索引: $index, 总字符: "$characters"');

    if (index >= 0 && index < characters.length) {
      final selectedChar = characters[index];
      debugPrint('选中字符: "$selectedChar"');

      setState(() {
        _selectedCharIndex = index;
      });

      // 检查候选集字中是否有匹配的字符
      final matchingChars = _candidateCharacters
          .where((entity) => entity.character == selectedChar)
          .toList();

      debugPrint('匹配的候选集字数量: ${matchingChars.length}');
      if (matchingChars.isNotEmpty) {
        debugPrint(
            '匹配的候选集字: ${matchingChars.map((e) => "${e.character}(${e.id})").join(", ")}');
      }

      _loadCandidateCharacters();
    } else {
      debugPrint('无效的字符索引: $index, 字符长度: ${characters.length}');
    }
  }

  /// 显示添加字符对话框
  void _showAddCharacterDialog() {
    // 获取当前选中的字符
    final content = widget.element['content'] as Map<String, dynamic>;
    final characters = content['characters'] as String? ?? '';
    final selectedChar = _selectedCharIndex < characters.length
        ? characters[_selectedCharIndex]
        : '';

    final TextEditingController charController =
        TextEditingController(text: selectedChar);
    final TextEditingController idController = TextEditingController();

    // 生成一个随机ID
    const uuid = Uuid();
    final randomId = uuid.v4();
    idController.text = randomId;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('手动添加候选集字'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: charController,
              decoration: const InputDecoration(
                labelText: '字符',
                hintText: '输入单个字符',
              ),
              maxLength: 1,
            ),
            TextField(
              controller: idController,
              decoration: const InputDecoration(
                labelText: '字符ID',
                hintText: '自动生成的ID',
              ),
              enabled: false, // 禁用编辑，使用自动生成的ID
            ),
            const SizedBox(height: 16),
            const Text('注意：这将创建一个临时的字符实体，仅用于当前会话。'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              final char = charController.text;
              if (char.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('字符不能为空')),
                );
                return;
              }

              final id = idController.text;

              // 创建一个临时的字符实体
              final entity = CharacterEntity(
                id: id,
                workId: widget.controller.practiceId ?? 'temp',
                pageId: 'temp',
                character: char,
                region: CharacterRegion.create(
                  pageId: 'temp',
                  rect: const Rect.fromLTWH(0, 0, 100, 100),
                  options: const ProcessingOptions(),
                  character: char,
                ),
                createTime: DateTime.now(),
                updateTime: DateTime.now(),
              );

              debugPrint('创建临时字符实体: ${entity.id}, 字符: ${entity.character}');

              // 添加到候选集字列表
              setState(() {
                // 检查是否已存在相同字符的实体
                final existingIndex =
                    _candidateCharacters.indexWhere((e) => e.character == char);

                if (existingIndex >= 0) {
                  // 如果已存在，则替换
                  _candidateCharacters[existingIndex] = entity;
                  debugPrint('替换现有字符实体');
                } else {
                  // 如果不存在，则添加
                  _candidateCharacters.add(entity);
                  debugPrint('添加新字符实体');
                }
              });

              Navigator.of(context).pop();

              // 如果当前选中的字符与添加的字符匹配，则自动选择该字符
              if (selectedChar == char) {
                debugPrint('自动选择新添加的字符实体');
                _selectCandidateCharacter(entity, isTemporary: true);
              }
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }

  /// 显示颜色选择器对话框
  void _showColorPicker(
    BuildContext context,
    String initialColor,
    Function(Color) onColorSelected,
  ) {
    // 预设颜色列表
    final presetColors = [
      Colors.black,
      Colors.white,
      Colors.red,
      Colors.pink,
      Colors.purple,
      Colors.deepPurple,
      Colors.indigo,
      Colors.blue,
      Colors.lightBlue,
      Colors.cyan,
      Colors.teal,
      Colors.green,
      Colors.lightGreen,
      Colors.lime,
      Colors.yellow,
      Colors.amber,
      Colors.orange,
      Colors.deepOrange,
      Colors.brown,
      Colors.grey,
      Colors.blueGrey,
      Colors.transparent,
    ];

    // 解析初始颜色（仅用于调试）
    debugPrint('显示颜色选择器，初始颜色: $initialColor');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('选择颜色'),
        content: SizedBox(
          width: 300,
          height: 300,
          child: GridView.builder(
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1,
            ),
            itemCount: presetColors.length,
            itemBuilder: (context, index) {
              return InkWell(
                onTap: () {
                  onColorSelected(presetColors[index]);
                  Navigator.of(context).pop();
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: presetColors[index],
                    border: Border.all(
                      color: presetColors[index] == Colors.white ||
                              presetColors[index] == Colors.transparent
                          ? Colors.grey
                          : presetColors[index],
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: presetColors[index] == Colors.transparent
                      ? const Center(
                          child: Text('透明', style: TextStyle(fontSize: 10)))
                      : null,
                ),
              );
            },
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('取消'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  // 更新字符图像信息
  Future<void> _updateCharacterImage(
      int index, String characterId, String type, String format,
      {bool isTemporary = false}) async {
    try {
      final content = widget.element['content'] as Map<String, dynamic>;
      Map<String, dynamic> characterImages;

      if (content.containsKey('characterImages')) {
        characterImages = Map<String, dynamic>.from(
            content['characterImages'] as Map<String, dynamic>);
      } else {
        characterImages = {};
      }

      // 在属性面板中使用缩略图，但在集字元素绘制时优先使用方形二值化图，其次是方形SVG轮廓
      final characterImageService = ref.read(characterImageServiceProvider);

      // 检查是否有方形二值化图格式
      bool hasSquareBinary = await characterImageService.hasCharacterImage(
          characterId, 'square-binary', 'png-binary');

      // 检查是否有方形SVG轮廓格式
      bool hasSquareOutline = await characterImageService.hasCharacterImage(
          characterId, 'square-outline', 'svg-outline');

      // 确定绘制格式
      String drawingType;
      String drawingFormat;

      if (hasSquareBinary) {
        // 优先使用方形二值化图
        drawingType = 'square-binary';
        drawingFormat = 'png-binary';
      } else if (hasSquareOutline) {
        // 其次使用方形SVG轮廓
        drawingType = 'square-outline';
        drawingFormat = 'svg-outline';
      } else {
        // 默认使用方形二值化图
        drawingType = 'square-binary';
        drawingFormat = 'png-binary';
      }

      // 创建字符图像信息
      final Map<String, dynamic> imageInfo = {
        'characterId': characterId,
        // 使用缩略图格式用于预览
        'type': type,
        'format': format,
        // 添加绘制时使用的格式
        'drawingType': drawingType,
        'drawingFormat': drawingFormat,
      };

      // 如果是临时字符，添加isTemporary标记
      if (isTemporary) {
        imageInfo['isTemporary'] = true;
        debugPrint('添加临时字符标记: characterId=$characterId, index=$index');
      }

      characterImages['$index'] = imageInfo;

      final updatedContent = Map<String, dynamic>.from(content);
      updatedContent['characterImages'] = characterImages;

      _updateProperty('content', updatedContent);
    } catch (e) {
      debugPrint('更新字符图像信息失败: $e');
    }
  }

  // 为新输入的文本更新字符图像
  Future<void> _updateCharacterImagesForNewText(String newText) async {
    try {
      debugPrint('为新输入的文本更新字符图像: $newText');

      // 获取当前内容
      final content = Map<String, dynamic>.from(
          widget.element['content'] as Map<String, dynamic>? ?? {});

      // 获取现有的字符图像信息
      Map<String, dynamic> characterImages = {};
      if (content.containsKey('characterImages')) {
        characterImages = Map<String, dynamic>.from(
            content['characterImages'] as Map<String, dynamic>);
      }

      // 检查每个字符是否已有图像信息
      bool hasUpdates = false;

      for (int i = 0; i < newText.length; i++) {
        // 如果该索引已有图像信息，则跳过
        if (characterImages.containsKey('$i')) {
          continue;
        }

        final char = newText[i];
        debugPrint('处理新字符: $char, 索引: $i');

        // 查找匹配的候选集字
        final matchingCharacters = _candidateCharacters
            .where((entity) => entity.character == char)
            .toList();

        if (matchingCharacters.isNotEmpty) {
          // 使用第一个匹配的字符实体
          final entity = matchingCharacters.first;
          debugPrint('找到匹配的候选集字: ${entity.id}, 字符: ${entity.character}');

          // 获取缩略图格式用于预览
          final characterImageService = ref.read(characterImageServiceProvider);
          final previewFormat = await characterImageService
              .getAvailableFormat(entity.id, preferThumbnail: true);

          // 检查是否有方形二值化图格式
          bool hasSquareBinary = await characterImageService.hasCharacterImage(
              entity.id, 'square-binary', 'png-binary');

          // 检查是否有方形SVG轮廓格式
          bool hasSquareOutline = await characterImageService.hasCharacterImage(
              entity.id, 'square-outline', 'svg-outline');

          // 确定绘制格式
          String drawingType;
          String drawingFormat;

          if (hasSquareBinary) {
            // 优先使用方形二值化图
            drawingType = 'square-binary';
            drawingFormat = 'png-binary';
          } else if (hasSquareOutline) {
            // 其次使用方形SVG轮廓
            drawingType = 'square-outline';
            drawingFormat = 'svg-outline';
          } else {
            // 默认使用方形二值化图
            drawingType = 'square-binary';
            drawingFormat = 'png-binary';
          }

          if (previewFormat != null) {
            characterImages['$i'] = {
              'characterId': entity.id,
              // 使用缩略图格式用于预览
              'type': previewFormat['type'],
              'format': previewFormat['format'],
              // 添加绘制时使用的格式
              'drawingType': drawingType,
              'drawingFormat': drawingFormat,
            };
            hasUpdates = true;
            debugPrint('已为字符 $char 设置图像信息');
          }
        } else {
          debugPrint('未找到字符 $char 的匹配候选集字，创建临时字符图像信息');

          // 生成一个临时ID
          const uuid = Uuid();
          final tempId = uuid.v4();

          // 创建临时字符图像信息，添加isTemporary标记
          characterImages['$i'] = {
            'characterId': tempId,
            'type': 'square-binary',
            'format': 'png-binary',
            'drawingType': 'square-binary',
            'drawingFormat': 'png-binary',
            'isTemporary': true, // 添加临时标记
          };

          debugPrint('已为字符 $char 创建临时字符图像信息:');
          debugPrint('  - 临时ID: $tempId');
          debugPrint('  - 索引: $i');

          hasUpdates = true;
        }
      }

      // 如果有更新，则更新元素内容
      if (hasUpdates) {
        final updatedContent = Map<String, dynamic>.from(content);
        updatedContent['characterImages'] = characterImages;
        _updateProperty('content', updatedContent);
        debugPrint('已更新字符图像信息');

        // 刷新UI
        setState(() {});
      }
    } catch (e) {
      debugPrint('更新字符图像信息失败: $e');
    }
  }

  // 更新内容属性
  void _updateContentProperty(String key, dynamic value) {
    final content = Map<String, dynamic>.from(
        widget.element['content'] as Map<String, dynamic>? ?? {});
    content[key] = value;
    _updateProperty('content', content);
  }

  // 更新属性
  void _updateProperty(String key, dynamic value) {
    final updates = {key: value};
    widget.onElementPropertiesChanged(updates);
  }
}
