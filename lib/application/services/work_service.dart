import '../../domain/entities/work.dart';
import '../../domain/repositories/work_repository.dart';

class WorkUpdate {
  final String id;
  final String? name;
  final String? style;
  final Map<String, dynamic>? metadata;

  WorkUpdate({
    required this.id,
    this.name,
    this.style,
    this.metadata,
  });
}

class WorkService {
  final WorkRepository _repository;

  WorkService(this._repository);

  Future<String> createWork(String name, {
    String? author,
    String? style,
    String? tool,
    DateTime? creationDate,
    Map<String, dynamic>? metadata,
  }) async {
    final work = Work(
      id: '',  // Will be set by repository
      name: name,
      author: author,
      style: style,
      tool: tool,
      creationDate: creationDate,
      createTime: DateTime.now(),
      updateTime: DateTime.now(),
      metadata: metadata ?? {
        'version': '1.0',
        'imageCount': 0,
        'tags': [],
        'remarks': '',
      },
    );
    
    return await _repository.insertWork(work);
  }

  Future<Work?> getWork(String id) => _repository.getWork(id);
  
  Future<List<Work>> getWorks({
    String? style,
    String? author,
    List<String>? tags,
    DateTime? fromDate,
    DateTime? toDate,
    int? limit,
    int? offset,
    String? sortBy = 'creationDate',
    bool descending = true,
  }) => _repository.getWorks(
    style: style,
    author: author,
    tags: tags,
    limit: limit,
    offset: offset,
  );

  Future<void> updateWork(String id, {
    String? name,
    String? author,
    String? style,
    String? tool,
    DateTime? creationDate,
    Map<String, dynamic>? metadata,
  }) async {
    final existing = await _repository.getWork(id);
    if (existing == null) throw Exception('Work not found');

    final updated = Work(
      id: id,
      name: name ?? existing.name,
      author: author ?? existing.author,
      style: style ?? existing.style,
      tool: tool ?? existing.tool,
      creationDate: creationDate ?? existing.creationDate,
      createTime: existing.createTime,
      updateTime: DateTime.now(),
      metadata: metadata != null 
          ? {...existing.metadata ?? {}, ...metadata}
          : existing.metadata,
    );

    await _repository.updateWork(updated);
  }

  Future<void> deleteWork(String id) async {
    if (!await _repository.workExists(id)) {
      throw Exception('Work not found');
    }
    await _repository.deleteWork(id);
  }

  Future<void> addTag(String id, String tag) async {
    final work = await _repository.getWork(id);
    if (work == null) throw Exception('Work not found');

    final metadata = work.metadata ?? {};
    final tags = (metadata['tags'] as List<dynamic>?) ?? [];
    if (!tags.contains(tag)) {
      tags.add(tag);
      await updateWork(id, metadata: {...metadata, 'tags': tags});
    }
  }

  Future<void> removeTag(String id, String tag) async {
    final work = await _repository.getWork(id);
    if (work == null) throw Exception('Work not found');

    final metadata = work.metadata ?? {};
    final tags = (metadata['tags'] as List<dynamic>?) ?? [];
    if (tags.contains(tag)) {
      tags.remove(tag);
      await updateWork(id, metadata: {...metadata, 'tags': tags});
    }
  }

  Future<void> updateImageCount(String id, int count) async {
    final work = await _repository.getWork(id);
    if (work == null) throw Exception('Work not found');

    final metadata = work.metadata ?? {};
    await updateWork(
      id,
      metadata: {...metadata, 'imageCount': count},
    );
  }

  Future<List<String>> getAllStyles() async {
    final works = await _repository.getWorks();
    return works
        .where((w) => w.style != null)
        .map((w) => w.style!)
        .toSet()
        .toList();
  }

  Future<List<String>> getAllAuthors() async {
    final works = await _repository.getWorks();
    return works
        .where((w) => w.author != null)
        .map((w) => w.author!)
        .toSet()
        .toList();
  }

  Future<bool> workExists(String id) => _repository.workExists(id);

  Future<int> getWorksCount({
    String? style,
    String? author,
    List<String>? tags,
  }) async {
    return await _repository.getWorksCount(
      style: style,
      author: author,
      tags: tags,
    );
  }

  Future<List<String>> getAllTags() async {
    final works = await _repository.getWorks();
    final Set<String> tags = {};
    
    for (final work in works) {
      final workTags = (work.metadata?['tags'] as List<dynamic>?) ?? [];
      tags.addAll(workTags.map((t) => t.toString()));
    }
    
    return tags.toList();
  }

  Future<void> updateRemarks(String id, String remarks) async {
    final work = await _repository.getWork(id);
    if (work == null) throw Exception('Work not found');

    final metadata = work.metadata ?? {};
    await updateWork(
      id,
      metadata: {...metadata, 'remarks': remarks},
    );
  }

  Future<Map<String, dynamic>> getWorkStats(String id) async {
    final work = await _repository.getWork(id);
    if (work == null) throw Exception('Work not found');

    final characters = await _repository.getCharactersByWorkId(id);
    
    return {
      'characterCount': characters.length,
      'imageCount': work.metadata?['imageCount'] ?? 0,
      'tagCount': (work.metadata?['tags'] as List<dynamic>?)?.length ?? 0,
      'createTime': work.createTime.toIso8601String(),
      'lastUpdateTime': work.updateTime.toIso8601String(),
    };
  }

  Future<void> batchUpdateTags(String id, List<String> tagsToAdd, List<String> tagsToRemove) async {
    final work = await _repository.getWork(id);
    if (work == null) throw Exception('Work not found');

    final metadata = work.metadata ?? {};
    final currentTags = (metadata['tags'] as List<dynamic>?) ?? [];
    
    // Remove tags
    currentTags.removeWhere((tag) => tagsToRemove.contains(tag));
    
    // Add new tags
    for (final tag in tagsToAdd) {
      if (!currentTags.contains(tag)) {
        currentTags.add(tag);
      }
    }

    await updateWork(
      id,
      metadata: {...metadata, 'tags': currentTags},
    );
  }

  Future<void> updateMetadataField(String id, String field, dynamic value) async {
    final work = await _repository.getWork(id);
    if (work == null) throw Exception('Work not found');

    final metadata = work.metadata ?? {};
    await updateWork(
      id,
      metadata: {...metadata, field: value},
    );
  }

  Future<void> batchCreateWorks(List<Map<String, String>> workDataList) async {
    await _repository.transaction((txn) async {
      for (final workData in workDataList) {
        final work = Work(
          id: '',
          name: workData['name']!,
          author: workData['author'],
          style: workData['style'],
          createTime: DateTime.now(),
          updateTime: DateTime.now(),
        );
        await txn.insertWork(work.toMap());
      }
    });
  }

  Future<void> batchUpdateWorks(List<WorkUpdate> updates) async {
    await _repository.transaction((txn) async {
      for (final update in updates) {
        final existing = await _repository.getWork(update.id);
        if (existing == null) continue;

        final updated = existing.copyWith(
          name: update.name,
          style: update.style,
          metadata: update.metadata,
          updateTime: DateTime.now(),
        );
        await txn.updateWork(update.id, updated.toMap());
      }
    });
  }

  Future<void> batchDeleteWorks(List<String> ids) async {
    await _repository.transaction((txn) async {
      for (final id in ids) {
        await txn.deleteWork(id);
      }
    });
  }
}