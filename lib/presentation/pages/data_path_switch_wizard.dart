import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers/import_export_providers.dart';
import '../../application/services/data_path_switch_manager.dart';
import '../../application/services/enhanced_backup_service.dart';
import '../../domain/models/backup_models.dart';
import '../../infrastructure/logging/logger.dart';
import '../../l10n/app_localizations.dart';

/// 数据路径切换向导
class DataPathSwitchWizard extends ConsumerStatefulWidget {
  const DataPathSwitchWizard({Key? key}) : super(key: key);

  @override
  ConsumerState<DataPathSwitchWizard> createState() =>
      _DataPathSwitchWizardState();
}

class _DataPathSwitchWizardState extends ConsumerState<DataPathSwitchWizard> {
  int _currentStep = 0;
  String? _selectedPath;
  bool _backupCompleted = false;
  bool _isProcessing = false;
  BackupRecommendation? _recommendation;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    // 延迟到下一帧执行，确保 context 完全可用
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkRecommendations();
    });
  }

  Future<void> _checkRecommendations() async {
    try {
      final recommendation =
          await DataPathSwitchManager.checkPreSwitchRecommendations(context);
      setState(() {
        _recommendation = recommendation;
        _statusMessage = recommendation.reason;
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error: $e'; // 简化处理，用英文错误信息
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.dataPathSwitchWizard),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => _handleExit(),
        ),
      ),
      body: _isProcessing
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(l10n.processingPleaseWait),
                ],
              ),
            )
          : Theme(
              data: Theme.of(context).copyWith(
                colorScheme: Theme.of(context).colorScheme.copyWith(
                      primary: Colors.blue,
                    ),
              ),
              child: Stepper(
                currentStep: _currentStep,
                onStepTapped: (step) {
                  if (step <= _currentStep && !_isProcessing) {
                    setState(() => _currentStep = step);
                  }
                },
                controlsBuilder: (context, details) {
                  return Row(
                    children: [
                      if (details.stepIndex > 0)
                        TextButton(
                          onPressed: details.onStepCancel,
                          child: Text(l10n.previousStep),
                        ),
                      const SizedBox(width: 24),
                      if (details.stepIndex < 2)
                        ElevatedButton(
                          onPressed: details.onStepContinue,
                          child: Text(l10n.nextStep),
                        ),
                    ],
                  );
                },
                onStepContinue: () {
                  if (_currentStep < 2) {
                    setState(() => _currentStep++);
                  }
                },
                onStepCancel: () {
                  if (_currentStep > 0) {
                    setState(() => _currentStep--);
                  }
                },
                steps: [
                  Step(
                    title: Text(l10n.dataBackup),
                    content: _buildBackupStep(context),
                    isActive: _currentStep >= 0,
                    state: _getStepState(0),
                  ),
                  Step(
                    title: Text(l10n.selectNewPath),
                    content: _buildPathSelectionStep(context),
                    isActive: _currentStep >= 1,
                    state: _getStepState(1),
                  ),
                  Step(
                    title: Text(l10n.confirmSwitch),
                    content: _buildConfirmationStep(context),
                    isActive: _currentStep >= 2,
                    state: _getStepState(2),
                  ),
                ],
              ),
            ),
    );
  }

  StepState _getStepState(int stepIndex) {
    if (stepIndex < _currentStep) {
      return StepState.complete;
    } else if (stepIndex == _currentStep) {
      return StepState.editing;
    } else {
      return StepState.disabled;
    }
  }

  Widget _buildBackupStep(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.info, color: Colors.blue.shade700, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    l10n.dataSafetyRecommendation,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_statusMessage != null)
                Text(
                  _statusMessage!,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade800,
                    height: 1.4,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          l10n.backupBeforeSwitchRecommendation,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _backupCompleted ? null : _performBackup,
                icon: _backupCompleted
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : const Icon(Icons.backup),
                label: Text(
                    _backupCompleted ? l10n.backupCompleted : l10n.startBackup),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _backupCompleted ? Colors.green : null,
                  foregroundColor: _backupCompleted ? Colors.white : null,
                ),
              ),
            ),
            const SizedBox(width: 16),
            TextButton(
              onPressed: _skipBackup,
              child: Text(l10n.skipBackup),
            ),
          ],
        ),
        if (_backupCompleted) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle,
                    color: Colors.green.shade700, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.backupSuccessCanSwitchPath,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.green.shade800,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        // 在步骤内容末尾添加额外间距，与导航按钮保持适当距离
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildPathSelectionStep(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.selectNewDataPath,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ElevatedButton.icon(
                onPressed: _selectNewPath,
                icon: const Icon(Icons.folder_open),
                label: Text(l10n.selectPathButton),
              ),
              if (_selectedPath != null) ...[
                const SizedBox(height: 16),
                Text(
                  l10n.selectedPath,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _selectedPath!,
                    style: const TextStyle(fontFamily: 'monospace'),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange.shade700, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    l10n.noticeTitle,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.orange.shade700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildNoticeItem(l10n.selectSufficientSpaceDisk),
                  const SizedBox(height: 8),
                  _buildNoticeItem(l10n.ensureReadWritePermission),
                  const SizedBox(height: 8),
                  _buildNoticeItem(l10n.oldDataNotAutoDeleted),
                ],
              ),
            ],
          ),
        ),
        // 在步骤内容末尾添加额外间距，与导航按钮保持适当距离
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildConfirmationStep(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.confirmSwitchToNewPath,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 16),
        if (_selectedPath != null) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.newDataPath,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(_selectedPath!,
                    style: const TextStyle(fontFamily: 'monospace')),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.red.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.info, color: Colors.red.shade700, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    l10n.importantReminder,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.red.shade700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildWarningItem(l10n.oldPathDataNotAutoDeleted),
                  const SizedBox(height: 8),
                  _buildWarningItem(l10n.canCleanOldDataLater),
                  const SizedBox(height: 8),
                  _buildWarningItem(l10n.recommendConfirmNewDataBeforeClean),
                  const SizedBox(height: 8),
                  _buildWarningItem(l10n.operationCannotUndo),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _canConfirmSwitch() ? _confirmSwitch : null,
            icon: const Icon(Icons.swap_horiz),
            label: Text(l10n.confirmSwitch),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        // 在步骤内容末尾添加额外间距，与导航按钮保持适当距离
        const SizedBox(height: 24),
      ],
    );
  }

  bool _canConfirmSwitch() {
    return (_backupCompleted || _recommendation?.recommendBackup == false) &&
        _selectedPath != null;
  }

  Future<void> _performBackup() async {
    final l10n = AppLocalizations.of(context);
    try {
      setState(() => _isProcessing = true);

      // 使用provider获取ServiceLocator
      final serviceLocator = ref.read(syncServiceLocatorProvider);

      // 检查服务是否已注册
      if (!serviceLocator.isRegistered<EnhancedBackupService>()) {
        // 提供更友好的错误信息和恢复建议
        throw Exception(l10n.backupServiceInitializing);
      }

      final backupService = serviceLocator.get<EnhancedBackupService>();

      // 添加额外的检查和重试逻辑
      int retryCount = 0;
      const maxRetries = 3;

      while (retryCount < maxRetries) {
        try {
          await backupService.createBackup(
              description: l10n.safetyBackupBeforePathSwitch);
          break; // 成功则跳出循环
        } catch (e) {
          retryCount++;
          if (retryCount >= maxRetries) {
            rethrow; // 达到最大重试次数后重新抛出异常
          }
          // 短暂等待后重试
          await Future.delayed(const Duration(milliseconds: 500));
        }
      }

      setState(() {
        _backupCompleted = true;
        _isProcessing = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.backupCreatedSuccessfully)),
        );
      }
    } catch (e) {
      setState(() => _isProcessing = false);

      AppLogger.error(l10n.createBackupFailed,
          error: e, tag: 'DataPathSwitchWizard');

      if (mounted) {
        String errorMessage;
        String suggestion = '';

        if (e.toString().contains('Service of type') ||
            e.toString().contains(l10n.backupServiceInitializing)) {
          errorMessage = l10n.backupServiceNotAvailable;
          suggestion = l10n.suggestRestartOrWaitService;
        } else if (e.toString().contains('请先设置备份路径')) {
          errorMessage = l10n.backupPathNotSetUp;
          suggestion = l10n.suggestConfigureBackupPathFirst;
        } else {
          errorMessage = l10n.createBackupFailed;
          suggestion = '${l10n.detailedError}: ${e.toString()}';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(errorMessage),
                if (suggestion.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    suggestion,
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ],
              ],
            ),
            duration: const Duration(seconds: 6),
            action: SnackBarAction(
              label: l10n.retryAction,
              onPressed: () => _performBackup(),
            ),
          ),
        );
      }
    }
  }

  Future<void> _skipBackup() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.skipBackupConfirm),
        content: Text(l10n.skipBackupWarningMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.confirmSkipAction),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _backupCompleted = true);
    }
  }

  Future<void> _selectNewPath() async {
    final l10n = AppLocalizations.of(context);
    try {
      final path = await FilePicker.platform.getDirectoryPath(
        dialogTitle: l10n.selectNewDataPathDialog,
      );

      if (path != null) {
        setState(() => _selectedPath = path);
      }
    } catch (e) {
      AppLogger.error(l10n.selectPathFailed,
          error: e, tag: 'DataPathSwitchWizard');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.selectPathFailed}: $e')),
        );
      }
    }
  }

  Future<void> _confirmSwitch() async {
    final l10n = AppLocalizations.of(context);
    if (_selectedPath == null) return;

    try {
      setState(() => _isProcessing = true);

      await DataPathSwitchManager.performDataPathSwitch(
          _selectedPath!, context);

      if (mounted) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: Text(l10n.switchSuccessful),
            content: Text(l10n.pathSwitchCompleted),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // 关闭对话框
                  Navigator.pop(context, true); // 关闭向导并返回成功
                },
                child: Text(l10n.confirm),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      setState(() => _isProcessing = false);

      AppLogger.error(l10n.pathSwitchFailed,
          error: e, tag: 'DataPathSwitchWizard');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.pathSwitchFailedMessage}: $e')),
        );
      }
    }
  }

  Future<void> _handleExit() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.exitWizard),
        content: Text(l10n.confirmExitWizard),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.exit),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      Navigator.pop(context);
    }
  }

  /// 构建注意事项列表项
  Widget _buildNoticeItem(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 6),
          width: 4,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.orange.shade700,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: Colors.orange.shade800,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  /// 构建警告列表项
  Widget _buildWarningItem(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 6),
          width: 4,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.red.shade700,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: Colors.red.shade800,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
