import 'dart:convert';
import 'dart:io';

import 'check_logger.dart';

/// 中文字符数据
class CharacterData {
  final String character;
  final String pinyin;
  final int strokeCount;
  final Map<String, dynamic> metadata;

  const CharacterData({
    required this.character,
    required this.pinyin,
    required this.strokeCount,
    this.metadata = const {},
  });

  factory CharacterData.fromJson(Map<String, dynamic> json) {
    final metadata = Map<String, dynamic>.from(json);
    metadata.remove('character');
    metadata.remove('pinyin');
    metadata.remove('strokes');

    return CharacterData(
      character: json['character'] as String,
      pinyin: json['pinyin'] as String,
      strokeCount: json['strokes'] as int,
      metadata: metadata,
    );
  }

  Map<String, dynamic> toJson() => {
        'character': character,
        'pinyin': pinyin,
        'strokes': strokeCount,
        ...metadata,
      };
}

/// 测试数据帮助类
class TestDataHelper {
  static final instance = TestDataHelper._();
  static const _testDataPath = 'test/data';

  static TestDataHelper get I => instance;
  final _logger = CheckLogger();
  final _characterCache = <String, CharacterData>{};

  final _workCache = <String, WorkData>{};
  TestDataHelper._();

  String get dataPath => _testDataPath;

  /// 清理缓存
  void clearCache() {
    _characterCache.clear();
    _workCache.clear();
  }

  /// 创建模拟字符数据
  CharacterData createMockCharacterData(String char) {
    return CharacterData(
      character: char,
      pinyin: 'test',
      strokeCount: 1,
      metadata: {
        'mock': true,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// 加载字符数据
  Future<CharacterData> loadCharacterData(String char) async {
    if (_characterCache.containsKey(char)) {
      return _characterCache[char]!;
    }

    try {
      final file = File('$_testDataPath/characters/$char.json');
      if (!file.existsSync()) {
        throw Exception('Character data not found: $char');
      }

      final json = jsonDecode(await file.readAsString());
      final data = CharacterData.fromJson(json);
      _characterCache[char] = data;
      return data;
    } catch (e, stack) {
      _logger.error('Failed to load character data: $char', '$e\n$stack');
      rethrow;
    }
  }

  /// 加载作品数据
  Future<WorkData> loadWorkData(String id) async {
    if (_workCache.containsKey(id)) {
      return _workCache[id]!;
    }

    try {
      final file = File('$_testDataPath/works/$id.json');
      if (!file.existsSync()) {
        throw Exception('Work data not found: $id');
      }

      final json = jsonDecode(await file.readAsString());
      final data = WorkData.fromJson(json);
      _workCache[id] = data;
      return data;
    } catch (e, stack) {
      _logger.error('Failed to load work data: $id', '$e\n$stack');
      rethrow;
    }
  }

  /// 备份测试数据
  Future<String> _backupTestData([String? path]) async {
    path ??= '$_testDataPath.backup';
    final sourceDir = Directory(_testDataPath);
    final targetDir = Directory(path);

    if (!sourceDir.existsSync()) {
      throw Exception('Test data directory not found');
    }

    if (targetDir.existsSync()) {
      targetDir.deleteSync(recursive: true);
    }

    _copyDirectory(sourceDir, targetDir);
    _logger.info('Backed up test data to: $path');
    return path;
  }

  void _copyDirectory(Directory source, Directory target) {
    target.createSync(recursive: true);
    source.listSync(recursive: false).forEach((entity) {
      if (entity is Directory) {
        final newDirectory =
            Directory('${target.path}/${entity.path.split('/').last}');
        _copyDirectory(entity.absolute, newDirectory);
      } else if (entity is File) {
        final newFile = File('${target.path}/${entity.path.split('/').last}');
        entity.copySync(newFile.path);
      }
    });
  }

  /// 获取测试字符
  Future<List<CharacterData>> _getTestCharacters() async {
    final dir = Directory('$_testDataPath/characters');
    if (!dir.existsSync()) return [];

    final characters = <CharacterData>[];
    for (final file in dir.listSync().whereType<File>()) {
      if (!file.path.endsWith('.json')) continue;
      final char = file.path.split('/').last.replaceAll('.json', '');
      characters.add(await loadCharacterData(char));
    }
    return characters;
  }

  /// 获取测试作品
  Future<List<WorkData>> _getTestWorks() async {
    final dir = Directory('$_testDataPath/works');
    if (!dir.existsSync()) return [];

    final works = <WorkData>[];
    for (final file in dir.listSync().whereType<File>()) {
      if (!file.path.endsWith('.json')) continue;
      final id = file.path.split('/').last.replaceAll('.json', '');
      works.add(await loadWorkData(id));
    }
    return works;
  }

  /// 初始化测试数据目录
  Future<void> _initializeTestDataDirectory() async {
    final dir = Directory(_testDataPath);
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }

    final charactersDir = Directory('$_testDataPath/characters');
    if (!charactersDir.existsSync()) {
      charactersDir.createSync();
    }

    final worksDir = Directory('$_testDataPath/works');
    if (!worksDir.existsSync()) {
      worksDir.createSync();
    }

    _logger.info('Initialized test data directory: $_testDataPath');
  }

  /// 加载模拟数据
  Future<List<CharacterData>> _loadMockData() async {
    await _initializeTestDataDirectory();

    final mockWorks = [
      const WorkData(
        id: 'test1',
        title: '测试作品1',
        characters: ['一', '二', '三'],
        metadata: {'mock': true},
      ),
      const WorkData(
        id: 'test2',
        title: '测试作品2',
        characters: ['四', '五', '六'],
        metadata: {'mock': true},
      ),
    ];

    final mockChars = <CharacterData>[];
    for (final work in mockWorks) {
      final file = File('$_testDataPath/works/${work.id}.json');
      await file.writeAsString(jsonEncode(work.toJson()));
      _workCache[work.id] = work;

      for (final char in work.characters) {
        if (!_characterCache.containsKey(char)) {
          final charData = createMockCharacterData(char);
          final charFile = File('$_testDataPath/characters/$char.json');
          await charFile.writeAsString(jsonEncode(charData.toJson()));
          _characterCache[char] = charData;
          mockChars.add(charData);
        }
      }
    }

    _logger.info('Loaded mock test data');
    return mockChars;
  }

  /// 验证测试数据
  Future<bool> _verifyTestData() async {
    try {
      final charactersDir = Directory('$_testDataPath/characters');
      final worksDir = Directory('$_testDataPath/works');

      if (!charactersDir.existsSync() || !worksDir.existsSync()) {
        return false;
      }

      final characterFiles = charactersDir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.json'));

      final workFiles = worksDir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.json'));

      if (characterFiles.isEmpty || workFiles.isEmpty) {
        return false;
      }

      // 验证数据格式
      for (final file in characterFiles) {
        final json = jsonDecode(await file.readAsString());
        CharacterData.fromJson(json);
      }

      for (final file in workFiles) {
        final json = jsonDecode(await file.readAsString());
        WorkData.fromJson(json);
      }

      return true;
    } catch (e) {
      _logger.error('Failed to verify test data', e);
      return false;
    }
  }

  static Future<String> backupTestData([String? path]) =>
      instance._backupTestData(path);

  static Future<List<CharacterData>> getTestCharacters() =>
      instance._getTestCharacters();

  static Future<List<WorkData>> getTestWorks() => instance._getTestWorks();

  /// 静态方法
  static Future<void> initializeTestDataDirectory() =>
      instance._initializeTestDataDirectory();

  static Future<List<CharacterData>> loadMockData() => instance._loadMockData();

  static Future<bool> verifyTestData() => instance._verifyTestData();
}

/// 作品数据
class WorkData {
  final String id;
  final String title;
  final List<String> characters;
  final Map<String, dynamic> metadata;

  const WorkData({
    required this.id,
    required this.title,
    required this.characters,
    this.metadata = const {},
  });

  factory WorkData.fromJson(Map<String, dynamic> json) {
    final metadata = Map<String, dynamic>.from(json);
    metadata.remove('id');
    metadata.remove('title');
    metadata.remove('characters');

    return WorkData(
      id: json['id'] as String,
      title: json['title'] as String,
      characters: List<String>.from(json['characters'] as List),
      metadata: metadata,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'characters': characters,
        ...metadata,
      };
}
