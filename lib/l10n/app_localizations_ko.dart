// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get a4Size => 'A4 (210×297mm)';

  @override
  String get a5Size => 'A5 (148×210mm)';

  @override
  String get about => '정보';

  @override
  String get activated => '활성화됨';

  @override
  String get activatedDescription => '활성화 - 선택기에서 표시';

  @override
  String get activeStatus => '활성 상태';

  @override
  String get add => '추가';

  @override
  String get addCategory => '카테고리 추가';

  @override
  String addCategoryItem(Object category) {
    return '$category 추가';
  }

  @override
  String get addConfigItem => '구성 항목 추가';

  @override
  String addConfigItemHint(Object category) {
    return '오른쪽 하단 버튼을 클릭하여 $category 구성 항목을 추가하세요';
  }

  @override
  String get addFavorite => '즐겨찾기에 추가';

  @override
  String addFromGalleryFailed(Object error) {
    return '갤러리에서 이미지 추가 실패: $error';
  }

  @override
  String get addImage => '이미지 추가';

  @override
  String get addImageHint => '이미지를 추가하려면 클릭하세요';

  @override
  String get addImages => '이미지 추가';

  @override
  String get addLayer => '레이어 추가';

  @override
  String get addTag => '태그 추가';

  @override
  String get addWork => '작품 추가';

  @override
  String get addedToCategory => '카테고리에 추가됨';

  @override
  String addingImagesToGallery(Object count) {
    return '$count개의 로컬 이미지를 갤러리에 추가하는 중...';
  }

  @override
  String get adjust => '조정';

  @override
  String get adjustGridSize => '그리드 크기 조정';

  @override
  String get afterDate => '특정 날짜 이후';

  @override
  String get alignBottom => '아래쪽 정렬';

  @override
  String get alignCenter => '가운데 정렬';

  @override
  String get alignHorizontalCenter => '수평 가운데 정렬';

  @override
  String get alignLeft => '왼쪽 정렬';

  @override
  String get alignMiddle => '중앙 정렬';

  @override
  String get alignRight => '오른쪽 정렬';

  @override
  String get alignTop => '위쪽 정렬';

  @override
  String get alignVerticalCenter => '수직 가운데 정렬';

  @override
  String get alignment => '정렬';

  @override
  String get alignmentAssist => '정렬 도우미';

  @override
  String get alignmentCenter => '가운데';

  @override
  String get alignmentGrid => '격자 스냅 모드 - 클릭하여 가이드라인 정렬로 전환';

  @override
  String get alignmentGuideline => '가이드라인 정렬 모드 - 클릭하여 보조 없음으로 전환';

  @override
  String get alignmentNone => '보조 없음 정렬 - 클릭하여 격자 스냅 활성화';

  @override
  String get alignmentOperations => '정렬 작업';

  @override
  String get all => '모두';

  @override
  String get allBackupsDeleteWarning => '이 작업은 되돌릴 수 없습니다! 모든 백업 데이터가 영구적으로 손실됩니다.';

  @override
  String get allCategories => '모든 카테고리';

  @override
  String get allPages => '모든 페이지';

  @override
  String get allTime => '전체 기간';

  @override
  String get allTypes => '모든 유형';

  @override
  String get analyzePathInfoFailed => '경로 정보 분석 실패';

  @override
  String get appRestartFailed => '앱 다시 시작 실패, 수동으로 앱을 다시 시작하세요';

  @override
  String get appRestarting => '앱을 다시 시작하는 중입니다';

  @override
  String get appRestartingMessage => '데이터 복구 성공, 앱을 다시 시작하는 중입니다...';

  @override
  String get appStartupFailed => '앱 시작 실패';

  @override
  String appStartupFailedWith(Object error) {
    return '앱 시작 실패: $error';
  }

  @override
  String get appTitle => '자자주기';

  @override
  String get appVersion => '앱 버전';

  @override
  String get appVersionInfo => '앱 버전 정보';

  @override
  String get appWillRestartAfterRestore => '복구 후 앱이 자동으로 다시 시작됩니다.';

  @override
  String appWillRestartInSeconds(Object message) {
    return '$message\n앱이 3초 후에 자동으로 다시 시작됩니다...';
  }

  @override
  String get appWillRestartMessage => '복구가 완료되면 앱이 자동으로 다시 시작됩니다';

  @override
  String get apply => '적용';

  @override
  String get applyFormatBrush => '서식 복사 적용 (Alt+W)';

  @override
  String get applyNewPath => '새 경로 적용';

  @override
  String get applyTransform => '변형 적용';

  @override
  String get ascending => '오름차순';

  @override
  String get askUser => '사용자에게 묻기';

  @override
  String get askUserDescription => '각 충돌에 대해 사용자에게 묻기';

  @override
  String get author => '작가';

  @override
  String get autoBackup => '자동 백업';

  @override
  String get autoBackupDescription => '데이터를 정기적으로 자동 백업합니다';

  @override
  String get autoBackupInterval => '자동 백업 간격';

  @override
  String get autoBackupIntervalDescription => '자동 백업 빈도';

  @override
  String get autoCleanup => '자동 정리';

  @override
  String get autoCleanupDescription => '오래된 캐시 파일을 자동으로 정리합니다';

  @override
  String get autoCleanupInterval => '자동 정리 간격';

  @override
  String get autoCleanupIntervalDescription => '자동 정리 실행 빈도';

  @override
  String get autoDetect => '자동 감지';

  @override
  String get autoDetectPageOrientation => '페이지 방향 자동 감지';

  @override
  String get autoLineBreak => '자동 줄 바꿈';

  @override
  String get autoLineBreakDisabled => '자동 줄 바꿈 비활성화됨';

  @override
  String get autoLineBreakEnabled => '자동 줄 바꿈 활성화됨';

  @override
  String get availableCharacters => '사용 가능한 문자';

  @override
  String get back => '뒤로';

  @override
  String get backgroundColor => '배경색';

  @override
  String get backgroundTexture => '배경 텍스처';

  @override
  String get backupBeforeSwitchRecommendation => '데이터 안전을 위해 데이터 경로를 전환하기 전에 먼저 백업을 생성하는 것이 좋습니다:';

  @override
  String backupChecksum(Object checksum) {
    return '체크섬: $checksum...';
  }

  @override
  String get backupCompleted => '✓ 백업 완료';

  @override
  String backupCount(Object count) {
    return '$count개의 백업';
  }

  @override
  String backupCountFormat(Object count) {
    return '$count개의 백업';
  }

  @override
  String get backupCreatedSuccessfully => '백업이 성공적으로 생성되어 안전하게 경로를 전환할 수 있습니다';

  @override
  String get backupCreationFailed => '백업 생성 실패';

  @override
  String backupCreationTime(Object time) {
    return '생성 시간: $time';
  }

  @override
  String get backupDeletedSuccessfully => '백업이 성공적으로 삭제되었습니다';

  @override
  String get backupDescription => '백업 설명';

  @override
  String get backupDescriptionHint => '이 백업에 대한 설명을 입력하세요';

  @override
  String get backupDescriptionInputExample => '예: 주간 백업, 중요 업데이트 전 백업 등';

  @override
  String get backupDescriptionInputLabel => '백업 설명';

  @override
  String backupDescriptionLabel(Object description) {
    return '백업 설명: $description';
  }

  @override
  String get backupEnsuresDataSafety => '• 백업은 데이터 안전을 보장합니다';

  @override
  String backupExportedSuccessfully(Object filename) {
    return '백업 내보내기 성공: $filename';
  }

  @override
  String get backupFailure => '백업 생성 실패';

  @override
  String get backupFile => '백업 파일';

  @override
  String get backupFileChecksumMismatchError => '백업 파일 체크섬이 일치하지 않습니다';

  @override
  String get backupFileCreationFailed => '백업 파일 생성 실패';

  @override
  String get backupFileCreationFailedError => '백업 파일 생성 실패';

  @override
  String backupFileLabel(Object filename) {
    return '백업 파일: $filename';
  }

  @override
  String backupFileListTitle(Object count) {
    return '백업 파일 목록 ($count개)';
  }

  @override
  String get backupFileMissingDirectoryStructureError => '백업 파일에 필요한 디렉토리 구조가 없습니다';

  @override
  String backupFileNotExist(Object path) {
    return '백업 파일이 존재하지 않습니다: $path';
  }

  @override
  String get backupFileNotExistError => '백업 파일이 존재하지 않습니다';

  @override
  String get backupFileNotFound => '백업 파일을 찾을 수 없습니다';

  @override
  String get backupFileSizeMismatchError => '백업 파일 크기가 일치하지 않습니다';

  @override
  String get backupFileVerificationFailedError => '백업 파일 확인 실패';

  @override
  String get backupFirst => '먼저 백업';

  @override
  String get backupImportSuccessMessage => '백업 가져오기 성공';

  @override
  String get backupImportedSuccessfully => '백업을 성공적으로 가져왔습니다';

  @override
  String get backupImportedToCurrentPath => '백업이 현재 경로로 가져와졌습니다';

  @override
  String get backupLabel => '백업';

  @override
  String get backupList => '백업 목록';

  @override
  String get backupLocationTips => '• 백업 위치로 충분한 여유 공간이 있는 디스크를 선택하는 것이 좋습니다\n• 백업 위치는 외부 저장 장치(예: 외장 하드 드라이브)일 수 있습니다\n• 백업 위치를 변경하면 모든 백업 정보가 통합 관리됩니다\n• 이전 백업 파일은 자동으로 이동되지 않지만 백업 관리에서 볼 수 있습니다';

  @override
  String get backupManagement => '백업 관리';

  @override
  String get backupManagementSubtitle => '모든 백업 파일을 생성, 복원, 가져오기, 내보내기 및 관리합니다';

  @override
  String get backupMayTakeMinutes => '백업은 몇 분 정도 걸릴 수 있습니다. 앱을 계속 실행 상태로 유지하세요';

  @override
  String get backupNotAvailable => '백업 관리를 현재 사용할 수 없습니다';

  @override
  String get backupNotAvailableMessage => '백업 관리 기능은 데이터베이스 지원이 필요합니다.\n\n가능한 원인:\n• 데이터베이스 초기화 중\n• 데이터베이스 초기화 실패\n• 앱 시작 중\n\n나중에 다시 시도하거나 앱을 다시 시작하세요.';

  @override
  String backupNotFound(Object id) {
    return '백업을 찾을 수 없음: $id';
  }

  @override
  String backupNotFoundError(Object id) {
    return '백업을 찾을 수 없음: $id';
  }

  @override
  String get backupOperationTimeoutError => '백업 작업 시간 초과, 저장 공간을 확인하고 다시 시도하세요';

  @override
  String get backupOverview => '백업 개요';

  @override
  String get backupPathDeleted => '백업 경로가 삭제되었습니다';

  @override
  String get backupPathDeletedMessage => '백업 경로가 삭제되었습니다';

  @override
  String get backupPathNotSet => '먼저 백업 경로를 설정하세요';

  @override
  String get backupPathNotSetError => '먼저 백업 경로를 설정하세요';

  @override
  String get backupPathNotSetUp => '백업 경로가 설정되지 않았습니다';

  @override
  String get backupPathSetSuccessfully => '백업 경로가 성공적으로 설정되었습니다';

  @override
  String get backupPathSettings => '백업 경로 설정';

  @override
  String get backupPathSettingsSubtitle => '백업 저장 경로를 구성하고 관리합니다';

  @override
  String backupPreCheckFailed(Object error) {
    return '백업 전 확인 실패: $error';
  }

  @override
  String get backupReadyRestartMessage => '백업 파일이 준비되었습니다. 복구를 완료하려면 앱을 다시 시작해야 합니다';

  @override
  String get backupRecommendation => '가져오기 전에 백업을 생성하는 것이 좋습니다';

  @override
  String get backupRecommendationDescription => '데이터 안전을 위해 가져오기 전에 수동으로 백업을 생성하는 것이 좋습니다';

  @override
  String get backupRestartWarning => '변경 사항을 적용하려면 앱을 다시 시작하세요';

  @override
  String backupRestoreFailedMessage(Object error) {
    return '백업 복구 실패: $error';
  }

  @override
  String get backupRestoreSuccessMessage => '백업 복구 성공, 복구를 완료하려면 앱을 다시 시작하세요';

  @override
  String get backupRestoreSuccessWithRestartMessage => '백업 복구 성공, 변경 사항을 적용하려면 앱을 다시 시작해야 합니다.';

  @override
  String get backupRestoredSuccessfully => '백업 복구 성공, 복구를 완료하려면 앱을 다시 시작하세요';

  @override
  String get backupServiceInitializing => '백업 서비스 초기화 중입니다. 잠시 후 다시 시도하세요';

  @override
  String get backupServiceNotAvailable => '백업 서비스를 일시적으로 사용할 수 없습니다';

  @override
  String get backupServiceNotInitialized => '백업 서비스가 초기화되지 않았습니다';

  @override
  String get backupServiceNotReady => '백업 서비스를 일시적으로 사용할 수 없습니다';

  @override
  String get backupSettings => '백업 설정';

  @override
  String backupSize(Object size) {
    return '크기: $size';
  }

  @override
  String get backupStatistics => '백업 통계';

  @override
  String get backupStorageLocation => '백업 저장 위치';

  @override
  String get backupSuccess => '백업이 생성되었습니다';

  @override
  String get backupSuccessCanSwitchPath => '백업이 성공적으로 생성되어 안전하게 경로를 전환할 수 있습니다';

  @override
  String backupTimeLabel(Object time) {
    return '백업 시간: $time';
  }

  @override
  String get backupTimeoutDetailedError => '백업 작업 시간 초과. 가능한 원인:\n• 데이터 양이 너무 많음\n• 저장 공간 부족\n• 디스크 읽기/쓰기 속도 느림\n\n저장 공간을 확인하고 다시 시도하세요.';

  @override
  String get backupTimeoutError => '백업 생성 시간 초과 또는 실패, 저장 공간이 충분한지 확인하세요';

  @override
  String get backupVerificationFailed => '백업 파일 확인 실패';

  @override
  String get backups => '백업';

  @override
  String get backupsCount => '개의 백업';

  @override
  String get basicInfo => '기본 정보';

  @override
  String get basicProperties => '기본 속성';

  @override
  String batchDeleteMessage(Object count) {
    return '$count개의 항목을 삭제하려고 합니다. 이 작업은 되돌릴 수 없습니다.';
  }

  @override
  String get batchExportFailed => '일괄 내보내기 실패';

  @override
  String batchExportFailedMessage(Object error) {
    return '일괄 내보내기 실패: $error';
  }

  @override
  String get batchImport => '일괄 가져오기';

  @override
  String get batchMode => '일괄 모드';

  @override
  String get batchOperations => '일괄 작업';

  @override
  String get beforeDate => '특정 날짜 이전';

  @override
  String get binarizationParameters => '이진화 매개변수';

  @override
  String get binarizationProcessing => '이진화 처리';

  @override
  String get binarizationToggle => '이진화 토글';

  @override
  String get binaryThreshold => '이진화 임계값';

  @override
  String get border => '테두리';

  @override
  String get borderColor => '테두리 색상';

  @override
  String get borderWidth => '테두리 너비';

  @override
  String get bottomCenter => '아래쪽 가운데';

  @override
  String get bottomLeft => '왼쪽 아래';

  @override
  String get bottomRight => '오른쪽 아래';

  @override
  String get boxRegion => '미리보기 영역에서 문자를 선택하세요';

  @override
  String get boxTool => '수집 도구';

  @override
  String get bringLayerToFront => '레이어를 맨 앞으로 가져오기';

  @override
  String get bringToFront => '맨 앞으로 가져오기 (Ctrl+T)';

  @override
  String get browse => '찾아보기';

  @override
  String get browsePath => '경로 찾아보기';

  @override
  String get brushSize => '브러시 크기';

  @override
  String get buildEnvironment => '빌드 환경';

  @override
  String get buildNumber => '빌드 번호';

  @override
  String get buildTime => '빌드 시간';

  @override
  String get cacheClearedMessage => '캐시가 성공적으로 지워졌습니다';

  @override
  String get cacheSettings => '캐시 설정';

  @override
  String get cacheSize => '캐시 크기';

  @override
  String get calligraphyStyle => '서예 스타일';

  @override
  String get calligraphyStyleText => '서예 스타일';

  @override
  String get canChooseDirectSwitch => '• 직접 전환을 선택할 수도 있습니다';

  @override
  String get canCleanOldDataLater => '나중에 \"데이터 경로 관리\"를 통해 이전 데이터를 정리할 수 있습니다';

  @override
  String get canCleanupLaterViaManagement => '나중에 데이터 경로 관리를 통해 이전 데이터를 정리할 수 있습니다';

  @override
  String get canManuallyCleanLater => '• 나중에 이전 경로의 데이터를 수동으로 정리할 수 있습니다';

  @override
  String get canNotPreview => '미리보기를 생성할 수 없습니다';

  @override
  String get cancel => '취소';

  @override
  String get cancelAction => '취소';

  @override
  String get cannotApplyNoImage => '사용 가능한 이미지가 없습니다';

  @override
  String get cannotApplyNoSizeInfo => '이미지 크기 정보를 가져올 수 없습니다';

  @override
  String get cannotCapturePageImage => '페이지 이미지를 캡처할 수 없습니다';

  @override
  String get cannotDeleteOnlyPage => '유일한 페이지는 삭제할 수 없습니다';

  @override
  String get cannotGetStorageInfo => '저장소 정보를 가져올 수 없습니다';

  @override
  String get cannotReadPathContent => '경로 내용을 읽을 수 없습니다';

  @override
  String get cannotReadPathFileInfo => '경로 파일 정보를 읽을 수 없습니다';

  @override
  String get cannotSaveMissingController => '저장할 수 없음: 컨트롤러가 없습니다';

  @override
  String get cannotSaveNoPages => '페이지가 없어 저장할 수 없습니다';

  @override
  String get canvasPixelSize => '캔버스 픽셀 크기';

  @override
  String get canvasResetViewTooltip => '보기 위치 재설정';

  @override
  String get categories => '카테고리';

  @override
  String get categoryManagement => '카테고리 관리';

  @override
  String get categoryName => '카테고리 이름';

  @override
  String get categoryNameCannotBeEmpty => '카테고리 이름은 비워둘 수 없습니다';

  @override
  String get centerLeft => '왼쪽 가운데';

  @override
  String get centerRight => '오른쪽 가운데';

  @override
  String get centimeter => '센티미터';

  @override
  String get changeDataPathMessage => '데이터 경로를 변경한 후에는 변경 사항을 적용하려면 응용 프로그램을 다시 시작해야 합니다.';

  @override
  String get changePath => '경로 변경';

  @override
  String get character => '글자';

  @override
  String get characterCollection => '글자 수집';

  @override
  String characterCollectionFindSwitchFailed(Object error) {
    return '페이지 찾기 및 전환 실패: $error';
  }

  @override
  String get characterCollectionPreviewTab => '문자 미리보기';

  @override
  String get characterCollectionResultsTab => '수집 결과';

  @override
  String get characterCollectionSearchHint => '문자 검색...';

  @override
  String get characterCollectionTitle => '글자 수집';

  @override
  String get characterCollectionToolBox => '수집 도구 (Ctrl+B)';

  @override
  String get characterCollectionToolPan => '다중 선택 도구 (Ctrl+V)';

  @override
  String get characterCollectionUseBoxTool => '상자 선택 도구를 사용하여 이미지에서 문자 추출';

  @override
  String get characterCount => '수집된 문자 수';

  @override
  String characterDisplayFormat(Object character) {
    return '문자: $character';
  }

  @override
  String get characterDetailFormatBinary => '이진화';

  @override
  String get characterDetailFormatBinaryDesc => '흑백 이진화 이미지';

  @override
  String get characterDetailFormatDescription => '설명';

  @override
  String get characterDetailFormatOutline => '윤곽선';

  @override
  String get characterDetailFormatOutlineDesc => '윤곽선만 표시';

  @override
  String get characterDetailFormatSquareBinary => '정사각형 이진화';

  @override
  String get characterDetailFormatSquareBinaryDesc => '정사각형으로 정규화된 이진화 이미지';

  @override
  String get characterDetailFormatSquareOutline => '정사각형 윤곽선';

  @override
  String get characterDetailFormatSquareOutlineDesc => '정사각형으로 정규화된 윤곽선 이미지';

  @override
  String get characterDetailFormatSquareTransparent => '정사각형 투명';

  @override
  String get characterDetailFormatSquareTransparentDesc => '정사각형으로 정규화된 투명 PNG 이미지';

  @override
  String get characterDetailFormatThumbnail => '썸네일';

  @override
  String get characterDetailFormatThumbnailDesc => '썸네일';

  @override
  String get characterDetailFormatTransparent => '투명';

  @override
  String get characterDetailFormatTransparentDesc => '배경이 제거된 투명 PNG 이미지';

  @override
  String get characterDetailLoadError => '문자 세부 정보 로드 실패';

  @override
  String get characterDetailSimplifiedChar => '간체자';

  @override
  String get characterDetailTitle => '문자 세부 정보';

  @override
  String characterEditSaveConfirmMessage(Object character) {
    return '\"$character\"을(를) 저장하시겠습니까?';
  }

  @override
  String get characterUpdated => '문자가 업데이트되었습니다';

  @override
  String get characters => '글자';

  @override
  String charactersCount(Object count) {
    return '$count개의 수집된 문자';
  }

  @override
  String charactersSelected(Object count) {
    return '$count개의 문자가 선택되었습니다';
  }

  @override
  String get checkBackupRecommendationFailed => '백업 권장 사항 확인 실패';

  @override
  String get checkFailedRecommendBackup => '확인 실패, 데이터 안전을 위해 먼저 백업을 생성하는 것이 좋습니다';

  @override
  String get checkSpecialChars => '• 작품 제목에 특수 문자가 포함되어 있는지 확인하세요';

  @override
  String get cleanDuplicateRecords => '중복 기록 정리';

  @override
  String get cleanDuplicateRecordsDescription => '이 작업은 중복된 백업 기록을 정리하며 실제 백업 파일은 삭제하지 않습니다.';

  @override
  String get cleanDuplicateRecordsTitle => '중복 기록 정리';

  @override
  String cleanupCompleted(Object count) {
    return '정리 완료, $count개의 잘못된 경로를 제거했습니다';
  }

  @override
  String cleanupCompletedMessage(Object count) {
    return '정리 완료, $count개의 잘못된 경로를 제거했습니다';
  }

  @override
  String cleanupCompletedWithCount(Object count) {
    return '정리 완료, $count개의 중복 기록을 제거했습니다';
  }

  @override
  String get cleanupFailed => '정리 실패';

  @override
  String cleanupFailedMessage(Object error) {
    return '정리 실패: $error';
  }

  @override
  String get cleanupInvalidPaths => '잘못된 경로 정리';

  @override
  String cleanupOperationFailed(Object error) {
    return '정리 작업 실패: $error';
  }

  @override
  String get clearCache => '캐시 지우기';

  @override
  String get clearCacheConfirmMessage => '모든 캐시 데이터를 지우시겠습니까? 이렇게 하면 디스크 공간이 확보되지만 일시적으로 응용 프로그램 속도가 느려질 수 있습니다.';

  @override
  String get clearSelection => '선택 해제';

  @override
  String get close => '닫기';

  @override
  String get code => '코드';

  @override
  String get collapse => '접기';

  @override
  String get collapseFileList => '파일 목록을 접으려면 클릭하세요';

  @override
  String get collectionDate => '수집 날짜';

  @override
  String get collectionElement => '수집 요소';

  @override
  String get collectionTextElement => '텍스트';

  @override
  String get candidateCharacters => '후보 문자';

  @override
  String get characterScale => '문자 크기';

  @override
  String get positionOffset => '위치 오프셋';

  @override
  String get scale => '크기 조정';

  @override
  String get xOffset => 'X 오프셋';

  @override
  String get yOffset => 'Y 오프셋';

  @override
  String get reset => '재설정';

  @override
  String get collectionIdCannotBeEmpty => '수집 ID는 비워둘 수 없습니다';

  @override
  String get collectionTime => '수집 시간';

  @override
  String get color => '색상';

  @override
  String get colorCode => '색상 코드';

  @override
  String get colorCodeHelp => '6자리 16진수 색상 코드를 입력하세요 (예: FF5500)';

  @override
  String get colorCodeInvalid => '잘못된 색상 코드';

  @override
  String get colorInversion => '색상 반전';

  @override
  String get colorPicker => '색상 선택';

  @override
  String get colorSettings => '색상 설정';

  @override
  String get commonProperties => '공통 속성';

  @override
  String get commonTags => '자주 사용하는 태그:';

  @override
  String get completingSave => '저장 완료 중...';

  @override
  String get compressData => '데이터 압축';

  @override
  String get compressDataDescription => '내보낸 파일 크기 줄이기';

  @override
  String get configInitFailed => '구성 데이터 초기화 실패';

  @override
  String get configInitializationFailed => '구성 초기화 실패';

  @override
  String get configInitializing => '구성 초기화 중...';

  @override
  String get configKey => '구성 키';

  @override
  String get configManagement => '구성 관리';

  @override
  String get configManagementDescription => '서예 스타일 및 쓰기 도구 구성 관리';

  @override
  String get configManagementTitle => '서예 스타일 관리';

  @override
  String get confirm => '확인';

  @override
  String get confirmChangeDataPath => '데이터 경로 변경 확인';

  @override
  String get confirmContinue => '계속하시겠습니까?';

  @override
  String get confirmDataNormalBeforeClean => '• 데이터를 정리하기 전에 데이터가 정상인지 확인하는 것이 좋습니다';

  @override
  String get confirmDataPathSwitch => '데이터 경로 전환 확인';

  @override
  String get confirmDelete => '삭제 확인';

  @override
  String get confirmDeleteAction => '삭제 확인';

  @override
  String get confirmDeleteAll => '모두 삭제 확인';

  @override
  String get confirmDeleteAllBackups => '모든 백업 삭제 확인';

  @override
  String get confirmDeleteAllButton => '모두 삭제 확인';

  @override
  String confirmDeleteBackup(Object description, Object filename) {
    return '백업 파일 \"$filename\"($description)을(를) 삭제하시겠습니까?\n이 작업은 되돌릴 수 없습니다.';
  }

  @override
  String confirmDeleteBackupPath(Object path) {
    return '전체 백업 경로를 삭제하시겠습니까?\n\n경로: $path\n\n이렇게 하면:\n• 해당 경로의 모든 백업 파일이 삭제됩니다\n• 기록에서 해당 경로가 제거됩니다\n• 이 작업은 복구할 수 없습니다\n\n신중하게 작업하십시오!';
  }

  @override
  String get confirmDeleteButton => '삭제 확인';

  @override
  String get confirmDeleteHistoryPath => '이 기록 경로 기록을 삭제하시겠습니까?';

  @override
  String get confirmDeleteTitle => '삭제 확인';

  @override
  String get confirmExitWizard => '데이터 경로 전환 마법사를 종료하시겠습니까?';

  @override
  String get confirmImportAction => '가져오기 확인';

  @override
  String get confirmImportButton => '가져오기 확인';

  @override
  String get confirmOverwrite => '덮어쓰기 확인';

  @override
  String confirmRemoveFromCategory(Object count) {
    return '선택한 $count개의 항목을 현재 카테고리에서 제거하시겠습니까?';
  }

  @override
  String get confirmResetToDefaultPath => '기본 경로로 재설정 확인';

  @override
  String get confirmRestoreAction => '복원 확인';

  @override
  String get confirmRestoreBackup => '이 백업을 복원하시겠습니까?';

  @override
  String get confirmRestoreButton => '복원 확인';

  @override
  String get confirmRestoreMessage => '다음 백업을 복원하려고 합니다:';

  @override
  String get confirmRestoreTitle => '복원 확인';

  @override
  String get confirmShortcuts => '단축키: Enter 확인, Esc 취소';

  @override
  String get confirmSkip => '건너뛰기 확인';

  @override
  String get confirmSkipAction => '건너뛰기 확인';

  @override
  String get confirmSwitch => '전환 확인';

  @override
  String get confirmSwitchButton => '전환 확인';

  @override
  String get confirmSwitchToNewPath => '새 데이터 경로로 전환 확인';

  @override
  String get conflictDetailsTitle => '충돌 처리 세부 정보';

  @override
  String get conflictReason => '충돌 원인';

  @override
  String get conflictResolution => '충돌 해결';

  @override
  String conflictsCount(Object count) {
    return '$count개의 충돌 발견';
  }

  @override
  String get conflictsFound => '충돌 발견';

  @override
  String get contentProperties => '내용 속성';

  @override
  String get contentSettings => '내용 설정';

  @override
  String get continueDuplicateImport => '이 백업을 계속 가져오시겠습니까?';

  @override
  String get continueImport => '가져오기 계속';

  @override
  String get continueQuestion => '계속하시겠습니까?';

  @override
  String get copy => '복사';

  @override
  String copyFailed(Object error) {
    return '복사 실패: $error';
  }

  @override
  String get copyFormat => '서식 복사 (Alt+Q)';

  @override
  String get copySelected => '선택 항목 복사';

  @override
  String get copyVersionInfo => '버전 정보 복사';

  @override
  String get couldNotGetFilePath => '파일 경로를 가져올 수 없습니다';

  @override
  String get countUnit => '개';

  @override
  String get create => '생성';

  @override
  String get createBackup => '백업 생성';

  @override
  String get createBackupBeforeImport => '가져오기 전에 백업 생성';

  @override
  String get createBackupDescription => '새 데이터 백업 생성';

  @override
  String get createBackupFailed => '백업 생성 실패';

  @override
  String createBackupFailedMessage(Object error) {
    return '백업 생성 실패: $error';
  }

  @override
  String createExportDirectoryFailed(Object error) {
    return '내보내기 디렉토리 생성 실패$error';
  }

  @override
  String get createFirstBackup => '첫 번째 백업 생성';

  @override
  String get createTime => '생성 시간';

  @override
  String get createdAt => '생성 시간';

  @override
  String get creatingBackup => '백업 생성 중...';

  @override
  String get creatingBackupPleaseWaitMessage => '몇 분 정도 걸릴 수 있습니다. 잠시 기다려 주세요';

  @override
  String get creatingBackupProgressMessage => '백업 생성 중...';

  @override
  String get creationDate => '창작 날짜';

  @override
  String get criticalError => '심각한 오류';

  @override
  String get cropAdjustmentHint => '위의 미리보기 이미지에서 선택 상자와 제어점을 드래그하여 자르기 영역을 조정하세요';

  @override
  String get cropBottom => '아래쪽 자르기';

  @override
  String get cropLeft => '왼쪽 자르기';

  @override
  String get cropRight => '오른쪽 자르기';

  @override
  String get cropTop => '위쪽 자르기';

  @override
  String get cropping => '자르기';

  @override
  String croppingApplied(Object bottom, Object left, Object right, Object top) {
    return '(자르기: 왼쪽${left}px, 위쪽${top}px, 오른쪽${right}px, 아래쪽${bottom}px)';
  }

  @override
  String get crossPagePasteSuccess => '페이지 간 붙여넣기 성공';

  @override
  String get currentBackupPathNotSet => '현재 백업 경로가 설정되지 않았습니다';

  @override
  String get currentCharInversion => '현재 문자 반전';

  @override
  String get currentCustomPath => '현재 사용자 정의 데이터 경로 사용 중';

  @override
  String get currentDataPath => '현재 데이터 경로';

  @override
  String get currentDefaultPath => '현재 기본 데이터 경로 사용 중';

  @override
  String get currentLabel => '현재';

  @override
  String get currentLocation => '현재 위치';

  @override
  String get currentPage => '현재 페이지';

  @override
  String get currentPath => '현재 경로';

  @override
  String get currentPathBackup => '현재 경로 백업';

  @override
  String get currentPathBackupDescription => '현재 경로 백업';

  @override
  String get currentPathFileExists => '현재 경로에 동일한 이름의 백업 파일이 이미 존재합니다:';

  @override
  String get currentPathFileExistsMessage => '현재 경로에 동일한 이름의 백업 파일이 이미 존재합니다:';

  @override
  String get currentStorageInfo => '현재 저장소 정보';

  @override
  String get currentStorageInfoSubtitle => '현재 저장 공간 사용 현황 보기';

  @override
  String get currentStorageInfoTitle => '현재 저장소 정보';

  @override
  String get currentTool => '현재 도구';

  @override
  String get pageInfo => '페이지';

  @override
  String get custom => '사용자 정의';

  @override
  String get customPath => '사용자 정의 경로';

  @override
  String get customRange => '사용자 정의 범위';

  @override
  String get customSize => '사용자 정의 크기';

  @override
  String get cutSelected => '선택 항목 잘라내기';

  @override
  String get dangerZone => '위험 구역';

  @override
  String get dangerousOperationConfirm => '위험한 작업 확인';

  @override
  String get dangerousOperationConfirmTitle => '위험한 작업 확인';

  @override
  String get dartVersion => 'Dart 버전';

  @override
  String get dataBackup => '데이터 백업';

  @override
  String get dataEmpty => '데이터가 비어 있습니다';

  @override
  String get dataIncomplete => '데이터가 불완전합니다';

  @override
  String get dataMergeOptions => '데이터 병합 옵션:';

  @override
  String get dataPath => '데이터 경로';

  @override
  String get dataPathChangedMessage => '데이터 경로가 변경되었습니다. 변경 사항을 적용하려면 응용 프로그램을 다시 시작하세요.';

  @override
  String get dataPathHint => '데이터 저장 경로 선택';

  @override
  String get dataPathManagement => '데이터 경로 관리';

  @override
  String get dataPathManagementSubtitle => '현재 및 이전 데이터 경로 관리';

  @override
  String get dataPathManagementTitle => '데이터 경로 관리';

  @override
  String get dataPathSettings => '데이터 경로 설정';

  @override
  String get dataPathSettingsDescription => '앱 데이터의 저장 위치를 설정합니다. 변경 후 응용 프로그램을 다시 시작해야 합니다.';

  @override
  String get dataPathSettingsSubtitle => '앱 데이터 저장 위치 구성';

  @override
  String get dataPathSwitchOptions => '데이터 경로 전환 옵션';

  @override
  String get dataPathSwitchWizard => '데이터 경로 전환 마법사';

  @override
  String get dataSafetyRecommendation => '데이터 안전 권장 사항';

  @override
  String get dataSafetySuggestion => '데이터 안전 제안';

  @override
  String get dataSafetySuggestions => '데이터 안전 제안';

  @override
  String get dataSize => '데이터 크기';

  @override
  String get databaseSize => '데이터베이스 크기';

  @override
  String get dayBeforeYesterday => '그저께';

  @override
  String days(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count일',
      one: '1일',
    );
    return '$_temp0';
  }

  @override
  String get daysAgo => '일 전';

  @override
  String get defaultEditableText => '속성 패널 편집 텍스트';

  @override
  String get defaultLayer => '기본 레이어';

  @override
  String defaultLayerName(Object number) {
    return '레이어$number';
  }

  @override
  String get defaultPage => '기본 페이지';

  @override
  String defaultPageName(Object number) {
    return '페이지$number';
  }

  @override
  String get defaultPath => '기본 경로';

  @override
  String get defaultPathName => '기본 경로';

  @override
  String get degrees => '도';

  @override
  String get delete => '삭제';

  @override
  String get deleteAll => '모두 삭제';

  @override
  String get deleteAllBackups => '모든 백업 삭제';

  @override
  String get deleteBackup => '백업 삭제';

  @override
  String get deleteBackupFailed => '백업 삭제 실패';

  @override
  String deleteBackupsCountMessage(Object count) {
    return '$count개의 백업 파일을 삭제하려고 합니다.';
  }

  @override
  String get deleteCategory => '카테고리 삭제';

  @override
  String get deleteCategoryOnly => '카테고리만 삭제';

  @override
  String get deleteCategoryWithFiles => '카테고리 및 파일 삭제';

  @override
  String deleteCharacterFailed(Object error) {
    return '문자 삭제 실패: $error';
  }

  @override
  String get deleteCompleteTitle => '삭제 완료';

  @override
  String get deleteConfigItem => '구성 항목 삭제';

  @override
  String get deleteConfigItemMessage => '이 구성 항목을 삭제하시겠습니까? 이 작업은 되돌릴 수 없습니다.';

  @override
  String get deleteConfirm => '삭제 확인';

  @override
  String get deleteElementConfirmMessage => '이 요소들을 삭제하시겠습니까?';

  @override
  String deleteFailCount(Object count) {
    return '삭제 실패: $count개 파일';
  }

  @override
  String get deleteFailDetails => '실패 세부 정보:';

  @override
  String deleteFailed(Object error) {
    return '삭제에 실패했습니다: $error';
  }

  @override
  String deleteFailedMessage(Object error) {
    return '삭제 실패: $error';
  }

  @override
  String get deleteFailure => '백업 삭제 실패';

  @override
  String get deleteGroup => '그룹 삭제';

  @override
  String get deleteGroupConfirm => '그룹 삭제 확인';

  @override
  String get deleteHistoryPathNote => '참고: 이 작업은 기록만 삭제하고 실제 폴더와 데이터는 삭제하지 않습니다.';

  @override
  String get deleteHistoryPathRecord => '기록 경로 기록 삭제';

  @override
  String get deleteImage => '이미지 삭제';

  @override
  String get deleteLastMessage => '이것은 마지막 항목입니다. 삭제하시겠습니까?';

  @override
  String get deleteLayer => '레이어 삭제';

  @override
  String get deleteLayerConfirmMessage => '이 레이어를 삭제하시겠습니까?';

  @override
  String get deleteLayerMessage => '이 레이어의 모든 요소가 삭제됩니다. 이 작업은 되돌릴 수 없습니다.';

  @override
  String deleteMessage(Object count) {
    return '$count개 항목을 삭제합니다.\n이 작업은 취소할 수 없습니다.';
  }

  @override
  String get deletePage => '페이지 삭제';

  @override
  String get deletePath => '경로 삭제';

  @override
  String get deletePathButton => '경로 삭제';

  @override
  String deletePathConfirmContent(Object path) {
    return '백업 경로 $path를 삭제하시겠습니까? 이 작업은 되돌릴 수 없으며 해당 경로의 모든 백업 파일이 삭제됩니다.';
  }

  @override
  String deleteRangeItem(Object count, Object path) {
    return '• $path: $count개 파일';
  }

  @override
  String get deleteRangeTitle => '삭제 범위 포함:';

  @override
  String get deleteSelected => '선택 항목 삭제';

  @override
  String get deleteSelectedArea => '선택 영역 삭제';

  @override
  String get deleteSelectedWithShortcut => '선택 항목 삭제 (Ctrl+D)';

  @override
  String get deleteSuccess => '삭제가 완료되었습니다';

  @override
  String deleteSuccessCount(Object count) {
    return '성공적으로 삭제: $count개 파일';
  }

  @override
  String get deleteText => '삭제';

  @override
  String get deleting => '삭제 중...';

  @override
  String get deletingBackups => '백업 삭제 중...';

  @override
  String get deletingBackupsProgress => '백업 파일을 삭제하는 중입니다. 잠시 기다려 주세요...';

  @override
  String get descending => '내림차순';

  @override
  String get descriptionLabel => '설명';

  @override
  String get deselectAll => '모두 선택 해제';

  @override
  String get detail => '세부 정보';

  @override
  String get detailedError => '상세 오류';

  @override
  String get detailedReport => '상세 보고서';

  @override
  String get deviceInfo => '기기 정보';

  @override
  String get dimensions => '크기';

  @override
  String get directSwitch => '직접 전환';

  @override
  String get disabled => '비활성화됨';

  @override
  String get disabledDescription => '비활성화 - 선택기에서 숨김';

  @override
  String get diskCacheSize => '디스크 캐시 크기';

  @override
  String get diskCacheSizeDescription => '디스크 캐시의 최대 크기';

  @override
  String get diskCacheTtl => '디스크 캐시 수명';

  @override
  String get diskCacheTtlDescription => '캐시 파일이 디스크에 보관되는 시간';

  @override
  String get displayMode => '표시 모드';

  @override
  String get displayName => '표시 이름';

  @override
  String get displayNameCannotBeEmpty => '표시 이름은 비워둘 수 없습니다';

  @override
  String get displayNameHint => '사용자 인터페이스에 표시되는 이름';

  @override
  String get displayNameMaxLength => '표시 이름은 최대 100자입니다';

  @override
  String get displayNameRequired => '표시 이름을 입력하세요';

  @override
  String get distributeHorizontally => '수평으로 균등 분배';

  @override
  String get distributeVertically => '수직으로 균등 분배';

  @override
  String get distribution => '분배';

  @override
  String get doNotCloseApp => '응용 프로그램을 닫지 마세요...';

  @override
  String get doNotCloseAppMessage => '앱을 닫지 마세요, 복구 과정은 몇 분이 걸릴 수 있습니다';

  @override
  String get done => '완료';

  @override
  String get dropToImportImages => '마우스를 놓아 이미지 가져오기';

  @override
  String get duplicateBackupFound => '중복 백업 발견';

  @override
  String get duplicateBackupFoundDesc => '가져오려는 백업 파일이 기존 백업과 중복되는 것으로 감지되었습니다:';

  @override
  String get duplicateFileImported => '(중복 파일 가져옴)';

  @override
  String get dynasty => '왕조';

  @override
  String get edit => '편집';

  @override
  String get editConfigItem => '구성 항목 편집';

  @override
  String editField(Object field) {
    return '$field 편집';
  }

  @override
  String get editGroupContents => '그룹 내용 편집';

  @override
  String get editGroupContentsDescription => '선택한 그룹의 내용 편집';

  @override
  String editLabel(Object label) {
    return '$label 편집';
  }

  @override
  String get editOperations => '편집 작업';

  @override
  String get editTags => '태그 편집';

  @override
  String get editTitle => '제목 편집';

  @override
  String get elementCopied => '요소가 클립보드에 복사되었습니다';

  @override
  String get elementCopiedToClipboard => '요소가 클립보드에 복사되었습니다';

  @override
  String get elementHeight => '높이';

  @override
  String get elementId => '요소 ID';

  @override
  String get elementSize => '크기';

  @override
  String get elementWidth => '너비';

  @override
  String get elements => '요소';

  @override
  String get empty => '비어 있음';

  @override
  String get emptyGroup => '빈 그룹';

  @override
  String get emptyStateError => '로드 실패, 나중에 다시 시도하세요';

  @override
  String get emptyStateNoCharacters => '글꼴 없음, 작품에서 글꼴을 추출한 후 여기에서 볼 수 있습니다';

  @override
  String get emptyStateNoPractices => '연습장이 없습니다, 추가 버튼을 클릭하여 새 연습장을 만드세요';

  @override
  String get emptyStateNoResults => '일치하는 결과를 찾을 수 없습니다, 검색 조건을 변경해 보세요';

  @override
  String get emptyStateNoSelection => '선택된 항목 없음, 항목을 클릭하여 선택하세요';

  @override
  String get emptyStateNoWorks => '작품 없음, 추가 버튼을 클릭하여 작품을 가져오세요';

  @override
  String get enableBinarization => '이진화 활성화';

  @override
  String get enabled => '활성화됨';

  @override
  String get endDate => '종료 날짜';

  @override
  String get ensureCompleteTransfer => '• 파일이 완전히 전송되었는지 확인하세요';

  @override
  String get ensureReadWritePermission => '새 경로에 읽기/쓰기 권한이 있는지 확인하세요';

  @override
  String get enterBackupDescription => '백업 설명을 입력하세요(선택 사항):';

  @override
  String get enterCategoryName => '카테고리 이름을 입력하세요';

  @override
  String get enterTagHint => '태그를 입력하고 Enter를 누르세요';

  @override
  String error(Object message) {
    return '오류: $message';
  }

  @override
  String get errors => '오류';

  @override
  String get estimatedTime => '예상 시간';

  @override
  String get executingImportOperation => '가져오기 작업 실행 중...';

  @override
  String existingBackupInfo(Object filename) {
    return '기존 백업: $filename';
  }

  @override
  String get existingItem => '기존 항목';

  @override
  String get exit => '종료';

  @override
  String get exitBatchMode => '일괄 모드 종료';

  @override
  String get exitConfirm => '종료';

  @override
  String get exitPreview => '미리보기 모드 종료';

  @override
  String get exitWizard => '마법사 종료';

  @override
  String get expand => '펼치기';

  @override
  String expandFileList(Object count) {
    return '클릭하여 $count개의 백업 파일 펼치기';
  }

  @override
  String get export => '내보내기';

  @override
  String get exportAllBackups => '모든 백업 내보내기';

  @override
  String get exportAllBackupsButton => '모든 백업 내보내기';

  @override
  String get exportBackup => '백업 내보내기';

  @override
  String get exportBackupFailed => '백업 내보내기 실패';

  @override
  String exportBackupFailedMessage(Object error) {
    return '백업 내보내기 실패: $error';
  }

  @override
  String get exportCharactersOnly => '수집된 문자만 내보내기';

  @override
  String get exportCharactersOnlyDescription => '선택한 수집된 문자 데이터만 포함';

  @override
  String get exportCharactersWithWorks => '수집된 문자와 출처 작품 내보내기 (권장)';

  @override
  String get exportCharactersWithWorksDescription => '수집된 문자와 해당 출처 작품 데이터 포함';

  @override
  String exportCompleted(Object failed, Object success) {
    return '내보내기 완료: 성공 $success개$failed';
  }

  @override
  String exportCompletedFormat(Object failedMessage, Object successCount) {
    return '내보내기 완료: 성공 $successCount개$failedMessage';
  }

  @override
  String exportCompletedFormat2(Object failed, Object success) {
    return '내보내기 완료, 성공: $success$failed';
  }

  @override
  String get exportConfig => '구성 내보내기';

  @override
  String get exportDialogRangeExample => '예: 1-3,5,7-9';

  @override
  String exportDimensions(Object height, Object orientation, Object width) {
    return '${width}cm × ${height}cm ($orientation)';
  }

  @override
  String get exportEncodingIssue => '• 내보낼 때 특수 문자 인코딩 문제 발생';

  @override
  String get exportFailed => '내보내기에 실패했습니다';

  @override
  String exportFailedPartFormat(Object failCount) {
    return ', 실패 $failCount개';
  }

  @override
  String exportFailedPartFormat2(Object count) {
    return ', 실패: $count';
  }

  @override
  String exportFailedWith(Object error) {
    return '내보내기 실패: $error';
  }

  @override
  String get exportFailure => '백업 내보내기 실패';

  @override
  String get exportFormat => '내보내기 형식';

  @override
  String get exportFullData => '전체 데이터 내보내기';

  @override
  String get exportFullDataDescription => '모든 관련 데이터 포함';

  @override
  String get exportLocation => '내보내기 위치';

  @override
  String get exportNotImplemented => '구성 내보내기 기능은 구현 예정입니다';

  @override
  String get exportOptions => '내보내기 옵션';

  @override
  String get exportSuccess => '내보내기가 완료되었습니다';

  @override
  String exportSuccessMessage(Object path) {
    return '백업 내보내기 성공: $path';
  }

  @override
  String get exportSummary => '내보내기 요약';

  @override
  String get exportType => '내보내기 형식';

  @override
  String get exportWorksOnly => '작품만 내보내기';

  @override
  String get exportWorksOnlyDescription => '선택한 작품 데이터만 포함';

  @override
  String get exportWorksWithCharacters => '작품 및 관련 수집 문자 내보내기 (권장)';

  @override
  String get exportWorksWithCharactersDescription => '작품 및 관련 수집 문자 데이터 포함';

  @override
  String get exporting => '내보내는 중, 잠시 기다려 주세요...';

  @override
  String get exportingBackup => '백업 내보내는 중...';

  @override
  String get exportingBackupMessage => '백업 내보내는 중...';

  @override
  String exportingBackups(Object count) {
    return '$count개의 백업 내보내는 중...';
  }

  @override
  String get exportingBackupsProgress => '백업 내보내는 중...';

  @override
  String exportingBackupsProgressFormat(Object count) {
    return '$count개의 백업 파일 내보내는 중...';
  }

  @override
  String get exportingDescription => '데이터 내보내는 중, 잠시 기다려 주세요...';

  @override
  String get extract => '추출';

  @override
  String get extractionError => '추출 중 오류 발생';

  @override
  String failedCount(Object count) {
    return ', 실패 $count개';
  }

  @override
  String get favorite => '즐겨찾기';

  @override
  String get favoritesOnly => '즐겨찾기만 표시';

  @override
  String get fileCorrupted => '• 전송 중 파일 손상';

  @override
  String get fileCount => '파일 수';

  @override
  String get fileExistsTitle => '파일이 이미 존재합니다';

  @override
  String get fileExtension => '파일 확장자';

  @override
  String get fileMigrationWarning => '파일을 마이그레이션하지 않으면 이전 경로의 백업 파일이 원래 위치에 남아 있습니다';

  @override
  String get fileName => '파일 이름';

  @override
  String fileNotExist(Object path) {
    return '파일이 존재하지 않습니다: $path';
  }

  @override
  String get fileRestored => '갤러리에서 이미지가 복원되었습니다';

  @override
  String get fileSize => '파일 크기';

  @override
  String get fileUpdatedAt => '파일 수정 시간';

  @override
  String get filenamePrefix => '파일 이름 접두사 입력 (페이지 번호가 자동으로 추가됩니다)';

  @override
  String get files => '파일';

  @override
  String get filter => '필터';

  @override
  String get filterAndSort => '필터 및 정렬';

  @override
  String get filterClear => '지우기';

  @override
  String get fineRotation => '미세 회전';

  @override
  String get firstPage => '첫 페이지';

  @override
  String get fitContain => '포함';

  @override
  String get fitCover => '덮기';

  @override
  String get fitFill => '채우기';

  @override
  String get fitHeight => '높이에 맞춤';

  @override
  String get fitMode => '맞춤 모드';

  @override
  String get fitWidth => '너비에 맞춤';

  @override
  String get flip => '뒤집기';

  @override
  String get flipHorizontal => '수평 뒤집기';

  @override
  String get flipOptions => '뒤집기 옵션';

  @override
  String get flipVertical => '수직 뒤집기';

  @override
  String get flutterVersion => 'Flutter 버전';

  @override
  String get folderImportComplete => '폴더 가져오기 완료';

  @override
  String get fontColor => '텍스트 색상';

  @override
  String get fontFamily => '글꼴';

  @override
  String get fontSize => '글꼴 크기';

  @override
  String get fontStyle => '글꼴 스타일';

  @override
  String get fontTester => '글꼴 테스트 도구';

  @override
  String get fontWeight => '글꼴 굵기';

  @override
  String get fontWeightTester => '글꼴 굵기 테스트 도구';

  @override
  String get format => '형식';

  @override
  String get formatBrushActivated => '서식 복사 활성화됨, 대상 요소를 클릭하여 스타일 적용';

  @override
  String get formatType => '형식 유형';

  @override
  String get fromGallery => '갤러리에서 선택';

  @override
  String get fromLocal => '로컬에서 선택';

  @override
  String get fullScreen => '전체 화면 표시';

  @override
  String get geometryProperties => '기하학적 속성';

  @override
  String get getHistoryPathsFailed => '기록 경로 가져오기 실패';

  @override
  String get getPathInfoFailed => '경로 정보를 가져올 수 없습니다';

  @override
  String get getPathUsageTimeFailed => '경로 사용 시간 가져오기 실패';

  @override
  String get getStorageInfoFailed => '저장소 정보 가져오기 실패';

  @override
  String get getThumbnailSizeError => '썸네일 크기 가져오기 실패';

  @override
  String get gettingPathInfo => '경로 정보 가져오는 중...';

  @override
  String get gettingStorageInfo => '저장소 정보 가져오는 중...';

  @override
  String get gitBranch => 'Git 브랜치';

  @override
  String get gitCommit => 'Git 커밋';

  @override
  String get goToBackup => '백업으로 이동';

  @override
  String get gridSettings => '그리드 설정';

  @override
  String get gridSize => '그리드 크기';

  @override
  String get gridSizeExtraLarge => '특대';

  @override
  String get gridSizeLarge => '대';

  @override
  String get gridSizeMedium => '중';

  @override
  String get gridSizeSmall => '소';

  @override
  String get gridView => '그리드 보기';

  @override
  String get group => '그룹 (Ctrl+J)';

  @override
  String get groupElements => '요소 그룹화';

  @override
  String get groupOperations => '그룹 작업';

  @override
  String get groupProperties => '그룹 속성';

  @override
  String get height => '높이';

  @override
  String get help => '도움말';

  @override
  String get hideDetails => '세부 정보 숨기기';

  @override
  String get hideElement => '요소 숨기기';

  @override
  String get hideGrid => '그리드 숨기기 (Ctrl+G)';

  @override
  String get hideImagePreview => '이미지 미리보기 숨기기';

  @override
  String get hideThumbnails => '페이지 썸네일 숨기기';

  @override
  String get hideToolbar => '도구 모음 숨기기';

  @override
  String get historicalPaths => '과거 경로';

  @override
  String get historyDataPaths => '과거 데이터 경로';

  @override
  String get historyLabel => '기록';

  @override
  String get historyLocation => '과거 위치';

  @override
  String get historyPath => '과거 경로';

  @override
  String get historyPathBackup => '과거 경로 백업';

  @override
  String get historyPathBackupDescription => '과거 경로 백업';

  @override
  String get historyPathDeleted => '과거 경로 기록이 삭제되었습니다';

  @override
  String get homePage => '홈';

  @override
  String get horizontalAlignment => '수평 정렬';

  @override
  String get horizontalLeftToRight => '가로 쓰기(왼쪽에서 오른쪽으로)';

  @override
  String get horizontalRightToLeft => '가로 쓰기(오른쪽에서 왼쪽으로)';

  @override
  String hours(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count시간',
      one: '1시간',
    );
    return '$_temp0';
  }

  @override
  String get hoursAgo => '시간 전';

  @override
  String get image => '이미지';

  @override
  String get imageAlignment => '이미지 정렬';

  @override
  String get imageCount => '이미지 수';

  @override
  String get imageElement => '이미지 요소';

  @override
  String get imageExportFailed => '이미지 내보내기 실패';

  @override
  String get imageFileNotExists => '이미지 파일이 존재하지 않습니다';

  @override
  String imageImportError(Object error) {
    return '이미지 가져오기 실패: $error';
  }

  @override
  String get imageImportSuccess => '이미지 가져오기 성공';

  @override
  String get imageIndexError => '이미지 인덱스 오류';

  @override
  String get imageInvalid => '이미지 데이터가 유효하지 않거나 손상되었습니다';

  @override
  String get imageInvert => '이미지 반전';

  @override
  String imageLoadError(Object error) {
    return '이미지 로드 실패: $error...';
  }

  @override
  String get imageLoadFailed => '이미지 로드 실패';

  @override
  String get imageNameInfo => '이미지 이름';

  @override
  String imageProcessingPathError(Object error) {
    return '처리 경로 오류: $error';
  }

  @override
  String get imageProperties => '이미지 속성';

  @override
  String get imagePropertyPanelAutoImportNotice => '선택한 이미지는 더 나은 관리를 위해 갤러리에 자동으로 가져옵니다';

  @override
  String get imagePropertyPanelFlipInfo => '뒤집기 효과는 캔버스 렌더링 단계에서 처리되어 이미지 데이터를 다시 처리하지 않고 즉시 적용됩니다. 뒤집기는 순수한 시각적 변환으로, 이미지 처리 파이프라인과 독립적입니다.';

  @override
  String get imagePropertyPanelGeometryWarning => '이러한 속성은 이미지 내용 자체가 아닌 전체 요소 상자를 조정합니다';

  @override
  String get imagePropertyPanelPreviewNotice => '참고: 미리보기 중에 표시되는 중복 로그는 정상입니다';

  @override
  String get imagePropertyPanelTransformWarning => '이러한 변환은 요소 프레임뿐만 아니라 이미지 내용 자체를 수정합니다';

  @override
  String get imageResetSuccess => '재설정 성공';

  @override
  String get imageRestoring => '이미지 데이터 복원 중...';

  @override
  String get imageSelection => '이미지 선택';

  @override
  String get imageSizeInfo => '이미지 크기';

  @override
  String get imageTransform => '이미지 변환';

  @override
  String imageTransformError(Object error) {
    return '변환 적용 실패: $error';
  }

  @override
  String get imageUpdated => '이미지가 업데이트되었습니다';

  @override
  String get images => '이미지';

  @override
  String get implementationComingSoon => '이 기능은 개발 중입니다. 기대해주세요!';

  @override
  String get import => '가져오기';

  @override
  String get importBackup => '백업 가져오기';

  @override
  String get importBackupFailed => '백업 가져오기 실패';

  @override
  String importBackupFailedMessage(Object error) {
    return '백업 가져오기 실패: $error';
  }

  @override
  String get importBackupProgressDialog => '현재 경로로 백업을 가져오는 중...';

  @override
  String get importBackupSuccessMessage => '백업이 현재 경로로 성공적으로 가져와졌습니다';

  @override
  String get importConfig => '구성 가져오기';

  @override
  String get importError => '가져오기 오류';

  @override
  String get importErrorCauses => '이 문제는 일반적으로 다음 원인으로 인해 발생합니다:';

  @override
  String importFailed(Object error) {
    return '가져오기에 실패했습니다: $error';
  }

  @override
  String get importFailure => '백업 가져오기 실패';

  @override
  String get importFileSuccess => '파일 가져오기 성공';

  @override
  String get importFiles => '파일 가져오기';

  @override
  String get importFolder => '폴더 가져오기';

  @override
  String get importNotImplemented => '구성 가져오기 기능은 구현 예정입니다';

  @override
  String get importOptions => '가져오기 옵션';

  @override
  String get importPreview => '가져오기 미리보기';

  @override
  String get importRequirements => '가져오기 요구 사항';

  @override
  String get importResultTitle => '가져오기 결과';

  @override
  String get importStatistics => '가져오기 통계';

  @override
  String get importSuccess => '가져오기가 완료되었습니다';

  @override
  String importSuccessMessage(Object count) {
    return '$count개의 파일을 성공적으로 가져왔습니다';
  }

  @override
  String get importToCurrentPath => '현재 경로로 가져오기';

  @override
  String get importToCurrentPathButton => '현재 경로로 가져오기';

  @override
  String get importToCurrentPathConfirm => '현재 경로로 가져오기';

  @override
  String get importToCurrentPathDesc => '이렇게 하면 백업 파일이 현재 경로로 복사되고 원본 파일은 그대로 유지됩니다.';

  @override
  String get importToCurrentPathDescription => '가져온 후 이 백업은 현재 경로의 백업 목록에 나타납니다';

  @override
  String get importToCurrentPathDialogContent => '이렇게 하면 백업이 현재 백업 경로로 가져와집니다. 계속하시겠습니까？';

  @override
  String get importToCurrentPathFailed => '현재 경로로 백업 가져오기 실패';

  @override
  String get importToCurrentPathMessage => '이 백업 파일을 현재 백업 경로로 가져오려고 합니다:';

  @override
  String get importToCurrentPathSuccessMessage => '백업이 현재 경로로 성공적으로 가져와졌습니다';

  @override
  String get importToCurrentPathTitle => '현재 경로로 가져오기';

  @override
  String get importantReminder => '중요 알림';

  @override
  String get importedBackupDescription => '가져온 백업';

  @override
  String get importedCharacters => '가져온 수집 문자';

  @override
  String get importedFile => '가져온 파일';

  @override
  String get importedImages => '가져온 이미지';

  @override
  String get importedSuffix => '가져온 백업';

  @override
  String get importedWorks => '가져온 작품';

  @override
  String get importing => '가져오는 중...';

  @override
  String get importingBackup => '백업 가져오는 중...';

  @override
  String get importingBackupProgressMessage => '백업 가져오는 중...';

  @override
  String get importingDescription => '데이터 가져오는 중, 잠시 기다려 주세요...';

  @override
  String get importingToCurrentPath => '현재 경로로 가져오는 중...';

  @override
  String get importingToCurrentPathMessage => '현재 경로로 가져오는 중...';

  @override
  String get importingWorks => '작품 가져오는 중...';

  @override
  String get includeImages => '이미지 포함';

  @override
  String get includeImagesDescription => '관련 이미지 파일 내보내기';

  @override
  String get includeMetadata => '메타데이터 포함';

  @override
  String get includeMetadataDescription => '생성 시간, 태그 등 메타데이터 내보내기';

  @override
  String get incompatibleCharset => '• 호환되지 않는 문자 집합 사용';

  @override
  String initializationFailed(Object error) {
    return '초기화 실패: $error';
  }

  @override
  String get initializing => '초기화 중...';

  @override
  String get inputCharacter => '문자 입력';

  @override
  String get inputChineseContent => '한자 내용을 입력하세요';

  @override
  String inputFieldHint(Object field) {
    return '$field을(를) 입력하세요';
  }

  @override
  String get inputFileName => '파일 이름 입력';

  @override
  String get inputHint => '여기에 입력';

  @override
  String get inputNewTag => '새 태그 입력...';

  @override
  String get inputTitle => '연습장 제목을 입력하세요';

  @override
  String get invalidFilename => '파일 이름에는 다음 문자를 포함할 수 없습니다: \\ / : * ? \" < > |';

  @override
  String get invalidNumber => '유효한 숫자를 입력하세요';

  @override
  String get invertMode => '반전 모드';

  @override
  String get isActive => '활성화 여부';

  @override
  String itemsCount(Object count) {
    return '$count개 항목';
  }

  @override
  String itemsPerPage(Object count) {
    return '페이지당 $count개 항목';
  }

  @override
  String get jsonFile => 'JSON 파일';

  @override
  String get justNow => '방금';

  @override
  String get keepBackupCount => '보관할 백업 수';

  @override
  String get keepBackupCountDescription => '이전 백업을 삭제하기 전에 보관할 백업 수';

  @override
  String get keepExisting => '기존 항목 유지';

  @override
  String get keepExistingDescription => '기존 데이터 유지, 가져오기 건너뛰기';

  @override
  String get key => '키';

  @override
  String get keyCannotBeEmpty => '키는 비워둘 수 없습니다';

  @override
  String get keyExists => '구성 키가 이미 존재합니다';

  @override
  String get keyHelperText => '문자, 숫자, 밑줄, 하이픈만 포함할 수 있습니다';

  @override
  String get keyHint => '구성 항목의 고유 식별자';

  @override
  String get keyInvalidCharacters => '키는 문자, 숫자, 밑줄, 하이픈만 포함할 수 있습니다';

  @override
  String get keyMaxLength => '키는 최대 50자입니다';

  @override
  String get keyMinLength => '키는 최소 2자 이상이어야 합니다';

  @override
  String get keyRequired => '구성 키를 입력하세요';

  @override
  String get landscape => '가로';

  @override
  String get language => '언어';

  @override
  String get languageEn => 'English';

  @override
  String get languageJa => '日本語';

  @override
  String get languageKo => '한국어';

  @override
  String get languageSystem => '시스템';

  @override
  String get languageZh => '简体中文';

  @override
  String get languageZhTw => '繁體中文';

  @override
  String get last30Days => '최근 30일';

  @override
  String get last365Days => '최근 365일';

  @override
  String get last7Days => '최근 7일';

  @override
  String get last90Days => '최근 90일';

  @override
  String get lastBackup => '마지막 백업';

  @override
  String get lastBackupTime => '마지막 백업 시간';

  @override
  String get lastMonth => '지난 달';

  @override
  String get lastPage => '마지막 페이지';

  @override
  String get lastUsed => '마지막 사용';

  @override
  String get lastUsedTime => '마지막 사용 시간';

  @override
  String get lastWeek => '지난 주';

  @override
  String get lastYear => '작년';

  @override
  String get layer => '레이어';

  @override
  String get layer1 => '레이어 1';

  @override
  String get layerElements => '레이어 요소';

  @override
  String get layerInfo => '레이어 정보';

  @override
  String layerName(Object index) {
    return '레이어$index';
  }

  @override
  String get layerOperations => '레이어 작업';

  @override
  String get layerProperties => '레이어 속성';

  @override
  String get leave => '나가기';

  @override
  String get legacyBackupDescription => '과거 백업';

  @override
  String get legacyDataPathDescription => '정리해야 할 이전 데이터 경로';

  @override
  String get letterSpacing => '문자 간격';

  @override
  String get library => '라이브러리';

  @override
  String get libraryCount => '라이브러리 수';

  @override
  String get libraryManagement => '라이브러리';

  @override
  String get lineHeight => '줄 간격';

  @override
  String get lineThrough => '취소선';

  @override
  String get listView => '목록 보기';

  @override
  String get loadBackupRegistryFailed => '백업 레지스트리 로드 실패';

  @override
  String loadCharacterDataFailed(Object error) {
    return '문자 데이터 로드 실패: $error';
  }

  @override
  String get loadConfigFailed => '구성 로드 실패';

  @override
  String get loadCurrentBackupPathFailed => '현재 백업 경로 로드 실패';

  @override
  String get loadDataFailed => '데이터 로드 실패';

  @override
  String get loadFailed => '로드에 실패했습니다';

  @override
  String get loadPathInfoFailed => '경로 정보 로드 실패';

  @override
  String get loadPracticeSheetFailed => '연습장 로드 실패';

  @override
  String get loading => '로딩 중...';

  @override
  String get loadingImage => '이미지 로드 중...';

  @override
  String get location => '위치';

  @override
  String get lock => '잠금';

  @override
  String get lockElement => '요소 잠금';

  @override
  String get lockStatus => '잠금 상태';

  @override
  String get lockUnlockAllElements => '모든 요소 잠금/해제';

  @override
  String get locked => '잠김';

  @override
  String get manualBackupDescription => '수동으로 생성된 백업';

  @override
  String get marginBottom => '아래';

  @override
  String get marginLeft => '왼쪽';

  @override
  String get marginRight => '오른쪽';

  @override
  String get marginTop => '위';

  @override
  String get max => '최대';

  @override
  String get memoryDataCacheCapacity => '메모리 데이터 캐시 용량';

  @override
  String get memoryDataCacheCapacityDescription => '메모리에 보관할 데이터 항목 수';

  @override
  String get memoryImageCacheCapacity => '메모리 이미지 캐시 용량';

  @override
  String get memoryImageCacheCapacityDescription => '메모리에 보관할 이미지 수';

  @override
  String get mergeAndMigrateFiles => '파일 병합 및 마이그레이션';

  @override
  String get mergeBackupInfo => '백업 정보 병합';

  @override
  String get mergeBackupInfoDesc => '이전 경로의 백업 정보를 새 경로의 레지스트리에 병합합니다';

  @override
  String get mergeData => '데이터 병합';

  @override
  String get mergeDataDescription => '기존 데이터와 가져온 데이터 병합';

  @override
  String get mergeOnlyBackupInfo => '백업 정보만 병합';

  @override
  String get metadata => '메타데이터';

  @override
  String get migrateBackupFiles => '백업 파일 마이그레이션';

  @override
  String get migrateBackupFilesDesc => '이전 경로의 백업 파일을 새 경로로 복사합니다 (권장)';

  @override
  String get migratingData => '데이터 마이그레이션 중';

  @override
  String get min => '최소';

  @override
  String get monospace => 'Monospace';

  @override
  String get monthsAgo => '개월 전';

  @override
  String moreErrorsCount(Object count) {
    return '...그리고 $count개의 오류 더 보기';
  }

  @override
  String get moveDown => '아래로 이동 (Ctrl+Shift+B)';

  @override
  String get moveLayerDown => '레이어 아래로 이동';

  @override
  String get moveLayerUp => '레이어 위로 이동';

  @override
  String get moveUp => '위로 이동 (Ctrl+Shift+T)';

  @override
  String get multiSelectTool => '다중 선택 도구';

  @override
  String multipleFilesNote(Object count) {
    return '참고: $count개의 이미지 파일을 내보냅니다. 파일 이름에 페이지 번호가 자동으로 추가됩니다.';
  }

  @override
  String get name => '이름';

  @override
  String get navCollapseSidebar => '사이드바 접기';

  @override
  String get navExpandSidebar => '사이드바 펼치기';

  @override
  String get navigatedToBackupSettings => '백업 설정 페이지로 이동했습니다';

  @override
  String get navigationAttemptBack => '이전 기능 영역으로 돌아가기 시도';

  @override
  String get navigationAttemptToNewSection => '새 기능 영역으로 이동 시도';

  @override
  String get navigationAttemptToSpecificItem => '특정 기록 항목으로 이동 시도';

  @override
  String get navigationBackToPrevious => '이전 페이지로 돌아가기';

  @override
  String get navigationClearHistory => '탐색 기록 지우기';

  @override
  String get navigationClearHistoryFailed => '탐색 기록 지우기 실패';

  @override
  String get navigationClearHistorySuccess => '내비게이션 기록이 성공적으로 지워졌습니다';

  @override
  String get navigationFailedBack => '이전으로 탐색 실패';

  @override
  String get navigationFailedInvalidHistoryItem => '내비게이션 실패: 유효하지 않은 기록 항목';

  @override
  String get navigationFailedNoHistory => '되돌아갈 수 없음: 사용 가능한 기록이 없습니다';

  @override
  String get navigationFailedNoValidSection => '내비게이션 실패: 유효한 섹션이 없습니다';

  @override
  String get navigationFailedSection => '탐색 전환 실패';

  @override
  String get navigationFailedToBack => '내비게이션 실패: 이전 섹션으로 되돌아갈 수 없습니다';

  @override
  String get navigationFailedToGoBack => '내비게이션 실패: 되돌아갈 수 없습니다';

  @override
  String get navigationFailedToNewSection => '내비게이션 실패: 새 섹션으로 이동할 수 없습니다';

  @override
  String get navigationFailedToSpecificItem => '특정 기록 항목으로 탐색 실패';

  @override
  String get navigationHistoryCleared => '탐색 기록이 지워졌습니다';

  @override
  String get navigationItemNotFound => '기록에서 대상 항목을 찾을 수 없어 해당 기능 영역으로 바로 이동합니다';

  @override
  String get navigationNoHistory => '기록이 없습니다';

  @override
  String get navigationNoHistoryMessage => '현재 기능 영역의 맨 처음 페이지에 도달했습니다.';

  @override
  String get navigationRecordRoute => '기능 영역 내 경로 변경 기록';

  @override
  String get navigationRecordRouteFailed => '경로 변경 기록 실패';

  @override
  String get navigationRestoreStateFailed => '탐색 상태 복원 실패';

  @override
  String get navigationSaveState => '탐색 상태 저장';

  @override
  String get navigationSaveStateFailed => '탐색 상태 저장 실패';

  @override
  String get navigationSectionCharacterManagement => '문자 관리';

  @override
  String get navigationSectionGalleryManagement => '갤러리 관리';

  @override
  String get navigationSectionPracticeList => '연습장 목록';

  @override
  String get navigationSectionSettings => '설정';

  @override
  String get navigationSectionWorkBrowse => '작품 탐색';

  @override
  String get navigationSelectPage => '어느 페이지로 돌아가시겠습니까?';

  @override
  String get navigationStateRestored => '탐색 상태가 저장소에서 복원되었습니다';

  @override
  String get navigationStateSaved => '탐색 상태가 저장되었습니다';

  @override
  String get navigationSuccessBack => '이전 기능 영역으로 성공적으로 돌아왔습니다';

  @override
  String get navigationSuccessToNewSection => '새 기능 영역으로 성공적으로 이동했습니다';

  @override
  String get navigationSuccessToSpecificItem => '특정 기록 항목으로 성공적으로 이동했습니다';

  @override
  String get navigationToggleExpanded => '탐색 바 확장 상태 전환';

  @override
  String get needRestartApp => '앱을 다시 시작해야 합니다';

  @override
  String get newConfigItem => '새 구성 항목';

  @override
  String get newDataPath => '새 데이터 경로:';

  @override
  String get newItem => '새 항목';

  @override
  String get nextField => '다음 필드';

  @override
  String get nextPage => '다음 페이지';

  @override
  String get nextStep => '다음 단계';

  @override
  String get no => '아니오';

  @override
  String get noBackupExistsRecommendCreate => '아직 백업이 생성되지 않았습니다. 데이터 안전을 위해 먼저 백업을 생성하는 것이 좋습니다';

  @override
  String get noBackupFilesInPath => '이 경로에 백업 파일이 없습니다';

  @override
  String get noBackupFilesInPathMessage => '이 경로에 백업 파일이 없습니다';

  @override
  String get noBackupFilesToExport => '이 경로에 내보낼 백업 파일이 없습니다';

  @override
  String get noBackupFilesToExportMessage => '내보낼 백업 파일이 없습니다';

  @override
  String get noBackupPathSetRecommendCreateBackup => '백업 경로가 설정되지 않았습니다. 먼저 백업 경로를 설정하고 백업을 생성하는 것이 좋습니다';

  @override
  String get noBackupPaths => '백업 경로 없음';

  @override
  String get noBackups => '사용 가능한 백업 없음';

  @override
  String get noBackupsInPath => '이 경로에 백업 파일이 없습니다';

  @override
  String get noBackupsToDelete => '삭제할 백업 파일이 없습니다';

  @override
  String get noCategories => '카테고리 없음';

  @override
  String get noCharacters => '문자를 찾을 수 없음';

  @override
  String get noCharactersFound => '일치하는 문자를 찾을 수 없음';

  @override
  String noConfigItems(Object category) {
    return '$category 구성 없음';
  }

  @override
  String get noCropping => '(자르기 없음)';

  @override
  String get noDisplayableImages => '표시할 이미지가 없습니다';

  @override
  String get noElementsInLayer => '이 레이어에 요소가 없습니다';

  @override
  String get noElementsSelected => '선택된 요소 없음';

  @override
  String get noHistoryPaths => '과거 경로 없음';

  @override
  String get noHistoryPathsDescription => '아직 다른 데이터 경로를 사용한 적이 없습니다';

  @override
  String get noImageSelected => '선택된 이미지 없음';

  @override
  String get noImages => '이미지 없음';

  @override
  String get noItemsSelected => '선택된 항목 없음';

  @override
  String get noLayers => '레이어 없음, 레이어를 추가하세요';

  @override
  String get noMatchingConfigItems => '일치하는 구성 항목을 찾을 수 없음';

  @override
  String get noPageSelected => '선택된 페이지 없음';

  @override
  String get noPagesToExport => '내보낼 페이지가 없습니다';

  @override
  String get noPagesToPrint => '인쇄할 페이지가 없습니다';

  @override
  String get noPreviewAvailable => '유효한 미리보기 없음';

  @override
  String get noRegionBoxed => '선택된 영역 없음';

  @override
  String get noRemarks => '비고 없음';

  @override
  String get noResults => '결과를 찾을 수 없음';

  @override
  String get noTags => '태그 없음';

  @override
  String get noTexture => '텍스처 없음';

  @override
  String get noTopLevelCategory => '없음 (최상위 카테고리)';

  @override
  String get noWorks => '작품을 찾을 수 없음';

  @override
  String get noWorksHint => '새 작품을 가져오거나 필터 조건을 변경해 보세요';

  @override
  String get noiseReduction => '노이즈 감소';

  @override
  String get noiseReductionLevel => '노이즈 감소 레벨';

  @override
  String get noiseReductionToggle => '노이즈 감소 토글';

  @override
  String get none => '없음';

  @override
  String get notSet => '설정되지 않음';

  @override
  String get note => '참고';

  @override
  String get notesTitle => '주의 사항:';

  @override
  String get noticeTitle => '주의 사항';

  @override
  String get ok => '확인';

  @override
  String get oldBackupRecommendCreateNew => '마지막 백업 시간이 24시간을 초과했습니다. 새 백업을 생성하는 것이 좋습니다';

  @override
  String get oldDataNotAutoDeleted => '경로 전환 후 이전 데이터는 자동으로 삭제되지 않습니다';

  @override
  String get oldDataNotDeleted => '경로 전환 후 이전 데이터는 자동으로 삭제되지 않습니다';

  @override
  String get oldDataWillNotBeDeleted => '전환 후 이전 경로의 데이터는 자동으로 삭제되지 않습니다';

  @override
  String get oldPathDataNotAutoDeleted => '전환 후 이전 경로의 데이터는 자동으로 삭제되지 않습니다';

  @override
  String get onlyOneCharacter => '하나의 문자만 허용됩니다';

  @override
  String get opacity => '불투명도';

  @override
  String get openBackupManagementFailed => '백업 관리 열기 실패';

  @override
  String get openFolder => '폴더 열기';

  @override
  String openGalleryFailed(Object error) {
    return '갤러리 열기 실패: $error';
  }

  @override
  String get openPathFailed => '경로 열기 실패';

  @override
  String get openPathSwitchWizardFailed => '데이터 경로 전환 마법사 열기 실패';

  @override
  String get operatingSystem => '운영 체제';

  @override
  String get operationCannotBeUndone => '이 작업은 되돌릴 수 없으므로 신중하게 확인하십시오';

  @override
  String get operationCannotUndo => '이 작업은 되돌릴 수 없으므로 신중하게 확인하십시오';

  @override
  String get optional => '선택 사항';

  @override
  String get original => '원본';

  @override
  String get originalImageDesc => '처리되지 않은 원본 이미지';

  @override
  String get outputQuality => '출력 품질';

  @override
  String get overwrite => '덮어쓰기';

  @override
  String get overwriteConfirm => '덮어쓰기 확인';

  @override
  String get overwriteExisting => '기존 항목 덮어쓰기';

  @override
  String get overwriteExistingDescription => '가져온 데이터로 기존 항목 교체';

  @override
  String overwriteExistingPractice(Object title) {
    return '\"$title\"이라는 제목의 연습장이 이미 존재합니다. 덮어쓰시겠습니까?';
  }

  @override
  String get overwriteFile => '파일 덮어쓰기';

  @override
  String get overwriteFileAction => '파일 덮어쓰기';

  @override
  String overwriteMessage(Object title) {
    return '\"$title\"이라는 제목의 연습장이 이미 존재합니다. 덮어쓰시겠습니까?';
  }

  @override
  String get overwrittenCharacters => '덮어쓴 수집 문자';

  @override
  String get overwrittenItems => '덮어쓴 항목';

  @override
  String get overwrittenWorks => '덮어쓴 작품';

  @override
  String get padding => '안쪽 여백';

  @override
  String get pageBuildError => '페이지 빌드 오류';

  @override
  String get pageMargins => '페이지 여백 (cm)';

  @override
  String get pageNotImplemented => '페이지가 구현되지 않았습니다';

  @override
  String get pageOrientation => '페이지 방향';

  @override
  String get pageProperties => '페이지 속성';

  @override
  String get pageRange => '페이지 범위';

  @override
  String get pageSize => '페이지 크기';

  @override
  String get pages => '페이지';

  @override
  String get parentCategory => '상위 카테고리 (선택 사항)';

  @override
  String get parsingImportData => '가져온 데이터 분석 중...';

  @override
  String get paste => '붙여넣기';

  @override
  String get path => '경로';

  @override
  String get pathAnalysis => '경로 분석';

  @override
  String get pathConfigError => '경로 구성 오류';

  @override
  String get pathInfo => '경로 정보';

  @override
  String get pathInvalid => '잘못된 경로';

  @override
  String get pathNotExists => '경로가 존재하지 않습니다';

  @override
  String get pathSettings => '경로 설정';

  @override
  String get pathSize => '경로 크기';

  @override
  String get pathSwitchCompleted => '데이터 경로 전환 완료!\n\n\"데이터 경로 관리\"에서 이전 경로의 데이터를 확인하고 정리할 수 있습니다.';

  @override
  String get pathSwitchCompletedMessage => '데이터 경로 전환 완료!\n\n데이터 경로 관리에서 이전 경로의 데이터를 확인하고 정리할 수 있습니다.';

  @override
  String get pathSwitchFailed => '경로 전환 실패';

  @override
  String get pathSwitchFailedMessage => '경로 전환 실패';

  @override
  String pathValidationFailed(Object error) {
    return '경로 유효성 검사 실패: $error';
  }

  @override
  String get pathValidationFailedGeneric => '경로 유효성 검사 실패, 경로가 유효한지 확인하세요';

  @override
  String get pdfExportFailed => 'PDF 내보내기 실패';

  @override
  String pdfExportSuccess(Object path) {
    return 'PDF 내보내기 성공: $path';
  }

  @override
  String get pinyin => '병음';

  @override
  String get pixels => '픽셀';

  @override
  String get platformInfo => '플랫폼 정보';

  @override
  String get pleaseEnterValidNumber => '유효한 숫자를 입력하세요';

  @override
  String get pleaseSelectOperation => '작업을 선택하세요:';

  @override
  String get pleaseSetBackupPathFirst => '먼저 백업 경로를 설정하세요';

  @override
  String get pleaseWaitMessage => '잠시 기다려 주세요';

  @override
  String get portrait => '세로';

  @override
  String get position => '위치';

  @override
  String get ppiSetting => 'PPI 설정 (인치당 픽셀 수)';

  @override
  String get practiceEditCollection => '수집';

  @override
  String get practiceEditDefaultLayer => '기본 레이어';

  @override
  String practiceEditPracticeLoaded(Object title) {
    return '연습장 \"$title\" 로드 성공';
  }

  @override
  String get practiceEditTitle => '연습장 편집';

  @override
  String get practiceListSearch => '연습장 검색...';

  @override
  String get practiceListTitle => '연습장';

  @override
  String get practiceSheetNotExists => '연습장이 존재하지 않습니다';

  @override
  String practiceSheetSaved(Object title) {
    return '연습장 \"$title\"이(가) 저장되었습니다';
  }

  @override
  String practiceSheetSavedMessage(Object title) {
    return '연습장 \"$title\" 저장 성공';
  }

  @override
  String get practices => '연습';

  @override
  String get preparingPrint => '인쇄 준비 중, 잠시 기다려 주세요...';

  @override
  String get preparingSave => '저장 준비 중...';

  @override
  String get preserveMetadata => '메타데이터 보존';

  @override
  String get preserveMetadataDescription => '원본 생성 시간 및 메타데이터 보존';

  @override
  String get preserveMetadataMandatory => '데이터 일관성을 보장하기 위해 원본 생성 시간, 작성자 정보 등 메타데이터를 강제로 보존합니다';

  @override
  String get presetSize => '사전 설정 크기';

  @override
  String get presets => '사전 설정';

  @override
  String get preview => '미리보기';

  @override
  String get previewMode => '미리보기 모드';

  @override
  String previewPage(Object current, Object total) {
    return '($current/$total 페이지)';
  }

  @override
  String get previousField => '이전 필드';

  @override
  String get previousPage => '이전 페이지';

  @override
  String get previousStep => '이전 단계';

  @override
  String processedCount(Object current, Object total) {
    return '처리됨: $current / $total';
  }

  @override
  String processedProgress(Object current, Object total) {
    return '처리됨: $current / $total';
  }

  @override
  String get processing => '처리 중...';

  @override
  String get processingDetails => '처리 세부 정보';

  @override
  String get processingEraseData => '데이터 삭제 처리 중...';

  @override
  String get processingImage => '이미지 처리 중...';

  @override
  String get processingPleaseWait => '처리 중입니다. 잠시 기다려 주세요...';

  @override
  String get properties => '속성';

  @override
  String get qualityHigh => '고화질 (2x)';

  @override
  String get qualityStandard => '표준 (1x)';

  @override
  String get qualityUltra => '초고화질 (3x)';

  @override
  String get quickRecoveryOnIssues => '• 전환 중 문제 발생 시 빠른 복구 가능';

  @override
  String get reExportWork => '• 이 작품 다시 내보내기';

  @override
  String get recent => '최근';

  @override
  String get recentBackupCanSwitch => '최근에 백업이 있으므로 직접 전환할 수 있습니다';

  @override
  String get recommendConfirmBeforeCleanup => '새 경로 데이터가 정상인지 확인한 후 이전 경로를 정리하는 것이 좋습니다';

  @override
  String get recommendConfirmNewDataBeforeClean => '새 경로 데이터가 정상인지 확인한 후 이전 경로를 정리하는 것이 좋습니다';

  @override
  String get recommendSufficientSpace => '충분한 여유 공간이 있는 디스크를 선택하는 것이 좋습니다';

  @override
  String get redo => '다시 실행';

  @override
  String get refresh => '새로 고침';

  @override
  String refreshDataFailed(Object error) {
    return '데이터 새로고침 실패: $error';
  }

  @override
  String get reload => '다시 로드';

  @override
  String get remarks => '비고';

  @override
  String get remarksHint => '비고 정보 추가';

  @override
  String get remove => '제거';

  @override
  String get removeFavorite => '즐겨찾기에서 제거';

  @override
  String get removeFromCategory => '현재 카테고리에서 제거';

  @override
  String get rename => '이름 바꾸기';

  @override
  String get renameDuplicates => '중복 항목 이름 바꾸기';

  @override
  String get renameDuplicatesDescription => '충돌을 피하기 위해 가져온 항목 이름 바꾸기';

  @override
  String get renameLayer => '레이어 이름 바꾸기';

  @override
  String get renderFailed => '렌더링 실패';

  @override
  String get reselectFile => '파일 다시 선택';

  @override
  String resetCategoryConfig(Object category) {
    return '$category 구성 재설정';
  }

  @override
  String resetCategoryConfigMessage(Object category) {
    return '$category 구성을 기본 설정으로 재설정하시겠습니까? 이 작업은 되돌릴 수 없습니다.';
  }

  @override
  String get resetDataPathToDefault => '기본값으로 재설정';

  @override
  String get resetSettingsConfirmMessage => '기본값으로 재설정하시겠습니까?';

  @override
  String get resetSettingsConfirmTitle => '설정 재설정';

  @override
  String get resetToDefault => '기본값으로 재설정';

  @override
  String get resetToDefaultFailed => '기본 경로로 재설정 실패';

  @override
  String resetToDefaultFailedWithError(Object error) {
    return '기본 경로로 재설정 실패: $error';
  }

  @override
  String get resetToDefaultPathMessage => '데이터 경로를 기본 위치로 재설정합니다. 변경 사항을 적용하려면 응용 프로그램을 다시 시작해야 합니다. 계속하시겠습니까?';

  @override
  String get resetToDefaults => '기본값으로 재설정';

  @override
  String get resetTransform => '변환 재설정';

  @override
  String get resetZoom => '확대/축소 재설정';

  @override
  String get resolution => '해상도';

  @override
  String get restartAfterRestored => '참고: 복구 완료 후 앱이 자동으로 다시 시작됩니다';

  @override
  String get restartLaterButton => '나중에';

  @override
  String get restartNeeded => '다시 시작 필요';

  @override
  String get restartNow => '지금 다시 시작';

  @override
  String get restartNowButton => '지금 다시 시작';

  @override
  String get restore => '복원';

  @override
  String get restoreBackup => '백업에서 복원';

  @override
  String get restoreBackupFailed => '백업 복원 실패';

  @override
  String get restoreConfirmMessage => '이 백업에서 복원하시겠습니까? 현재 모든 데이터가 대체됩니다.';

  @override
  String get restoreConfirmTitle => '복원 확인';

  @override
  String get restoreDefaultSize => '기본 크기로 복원';

  @override
  String get restoreFailure => '복원 실패';

  @override
  String get restoreWarningMessage => '경고: 이 작업은 현재 모든 데이터를 덮어씁니다!';

  @override
  String get restoringBackup => '백업에서 복원 중...';

  @override
  String get restoringBackupMessage => '백업 복원 중...';

  @override
  String get retry => '재시도';

  @override
  String get retryAction => '재시도';

  @override
  String get rotateClockwise => '시계 방향 회전';

  @override
  String get rotateCounterclockwise => '시계 반대 방향 회전';

  @override
  String get rotateLeft => '왼쪽으로 회전';

  @override
  String get rotateRight => '오른쪽으로 회전';

  @override
  String get rotation => '회전';

  @override
  String get rotationFineControl => '각도 미세 조정';

  @override
  String get safetyBackupBeforePathSwitch => '데이터 경로 전환 전 안전 백업';

  @override
  String get safetyBackupRecommendation => '데이터 안전을 위해 데이터 경로를 전환하기 전에 먼저 백업을 생성하는 것이 좋습니다:';

  @override
  String get safetyTip => '💡 안전 팁:';

  @override
  String get sansSerif => 'Sans Serif';

  @override
  String get save => '저장';

  @override
  String get saveAs => '다른 이름으로 저장';

  @override
  String get saveComplete => '저장 완료';

  @override
  String get saveFailed => '저장에 실패했습니다';

  @override
  String saveFailedWithError(Object error) {
    return '저장 실패: $error';
  }

  @override
  String get saveFailure => '저장 실패';

  @override
  String get savePreview => '문자 미리보기:';

  @override
  String get saveSuccess => '저장이 완료되었습니다';

  @override
  String get saveTimeout => '저장 시간 초과';

  @override
  String get savingToStorage => '저장소에 저장 중...';

  @override
  String get scannedBackupFileDescription => '스캔에서 발견된 백업 파일';

  @override
  String get search => '검색';

  @override
  String get searchCategories => '카테고리 검색...';

  @override
  String get searchConfigDialogTitle => '구성 항목 검색';

  @override
  String get searchConfigHint => '구성 항목 이름 또는 키 입력';

  @override
  String get searchConfigItems => '구성 항목 검색';

  @override
  String get searching => '검색 중...';

  @override
  String get select => '선택';

  @override
  String get selectAll => '모두 선택';

  @override
  String get selectAllWithShortcut => '모두 선택 (Ctrl+Shift+A)';

  @override
  String get selectBackup => '백업 선택';

  @override
  String get selectBackupFileToImportDialog => '가져올 백업 파일 선택';

  @override
  String get selectBackupStorageLocation => '백업 저장 위치 선택';

  @override
  String get selectCategoryToApply => '적용할 카테고리를 선택하세요:';

  @override
  String get selectCharacterFirst => '먼저 문자를 선택하세요';

  @override
  String selectColor(Object type) {
    return '$type 선택';
  }

  @override
  String get selectDate => '날짜 선택';

  @override
  String get selectExportLocation => '내보내기 위치 선택';

  @override
  String get selectExportLocationDialog => '내보내기 위치 선택';

  @override
  String get selectExportLocationHint => '내보내기 위치 선택...';

  @override
  String get selectFileError => '파일 선택 실패';

  @override
  String get selectFolder => '폴더 선택';

  @override
  String get selectImage => '이미지 선택';

  @override
  String get selectImages => '이미지 선택';

  @override
  String get selectImagesWithCtrl => '이미지 선택 (Ctrl 키를 누른 채 다중 선택 가능)';

  @override
  String get selectImportFile => '백업 파일 선택';

  @override
  String get selectNewDataPath => '새 데이터 저장 경로 선택:';

  @override
  String get selectNewDataPathDialog => '새 데이터 저장 경로 선택';

  @override
  String get selectNewDataPathTitle => '새 데이터 저장 경로 선택';

  @override
  String get selectNewPath => '새 경로 선택';

  @override
  String get selectParentCategory => '상위 카테고리 선택';

  @override
  String get selectPath => '경로 선택';

  @override
  String get selectPathButton => '경로 선택';

  @override
  String get selectPathFailed => '경로 선택 실패';

  @override
  String get selectSufficientSpaceDisk => '충분한 여유 공간이 있는 디스크를 선택하는 것이 좋습니다';

  @override
  String get selectTargetLayer => '대상 레이어 선택';

  @override
  String get selected => '선택됨';

  @override
  String get selectedCharacter => '선택된 문자';

  @override
  String selectedCount(Object count) {
    return '$count개 선택됨';
  }

  @override
  String get selectedElementNotFound => '선택한 요소를 찾을 수 없습니다';

  @override
  String get selectedItems => '선택된 항목';

  @override
  String get selectedPath => '선택된 경로:';

  @override
  String get selectionMode => '선택 모드';

  @override
  String get sendToBack => '맨 뒤로 보내기 (Ctrl+B)';

  @override
  String get serif => 'Serif';

  @override
  String get serviceNotReady => '서비스가 준비되지 않았습니다. 나중에 다시 시도하세요';

  @override
  String get setBackupPathFailed => '백업 경로 설정 실패';

  @override
  String get setCategory => '카테고리 설정';

  @override
  String setCategoryForItems(Object count) {
    return '카테고리 설정 ($count개 항목)';
  }

  @override
  String get setDataPathFailed => '데이터 경로 설정 실패, 경로 권한 및 호환성을 확인하세요';

  @override
  String setDataPathFailedWithError(Object error) {
    return '데이터 경로 설정 실패: $error';
  }

  @override
  String get settings => '설정';

  @override
  String get settingsResetMessage => '설정이 기본값으로 재설정되었습니다';

  @override
  String get shortcuts => '키보드 단축키';

  @override
  String get showContour => '윤곽선 표시';

  @override
  String get showDetails => '세부 정보 표시';

  @override
  String get showElement => '요소 표시';

  @override
  String get showGrid => '그리드 표시 (Ctrl+G)';

  @override
  String get showHideAllElements => '모든 요소 표시/숨기기';

  @override
  String get showImagePreview => '이미지 미리보기 표시';

  @override
  String get showThumbnails => '페이지 썸네일 표시';

  @override
  String get showToolbar => '도구 모음 표시';

  @override
  String get skipBackup => '백업 건너뛰기';

  @override
  String get skipBackupConfirm => '백업 건너뛰기';

  @override
  String get skipBackupWarning => '백업을 건너뛰고 바로 경로를 전환하시겠습니까?\n\n데이터 손실 위험이 있을 수 있습니다.';

  @override
  String get skipBackupWarningMessage => '백업을 건너뛰고 바로 경로를 전환하시겠습니까?\n\n데이터 손실 위험이 있을 수 있습니다.';

  @override
  String get skipConflicts => '충돌 건너뛰기';

  @override
  String get skipConflictsDescription => '이미 존재하는 항목 건너뛰기';

  @override
  String get skippedCharacters => '건너뛴 수집 문자';

  @override
  String get skippedItems => '건너뛴 항목';

  @override
  String get skippedWorks => '건너뛴 작품';

  @override
  String get sort => '정렬';

  @override
  String get sortBy => '정렬 기준';

  @override
  String get sortByCreateTime => '생성 시간순 정렬';

  @override
  String get sortByTitle => '제목순 정렬';

  @override
  String get sortByUpdateTime => '업데이트 시간순 정렬';

  @override
  String get sortFailed => '정렬 실패';

  @override
  String get sortOrder => '정렬 순서';

  @override
  String get sortOrderCannotBeEmpty => '정렬 순서는 비워둘 수 없습니다';

  @override
  String get sortOrderHint => '숫자가 작을수록 앞에 정렬됩니다';

  @override
  String get sortOrderLabel => '정렬 순서';

  @override
  String get sortOrderNumber => '정렬 값은 숫자여야 합니다';

  @override
  String get sortOrderRange => '정렬 순서는 1-999 사이여야 합니다';

  @override
  String get sortOrderRequired => '정렬 값을 입력하세요';

  @override
  String get sourceBackupFileNotFound => '소스 백업 파일을 찾을 수 없습니다';

  @override
  String sourceFileNotFound(Object path) {
    return '소스 파일을 찾을 수 없습니다: $path';
  }

  @override
  String sourceFileNotFoundError(Object path) {
    return '소스 파일을 찾을 수 없습니다: $path';
  }

  @override
  String get sourceHanSansFont => '본고딕 (Source Han Sans)';

  @override
  String get sourceHanSerifFont => '본명조 (Source Han Serif)';

  @override
  String get sourceInfo => '출처 정보';

  @override
  String get startBackup => '백업 시작';

  @override
  String get startDate => '시작 날짜';

  @override
  String get stateAndDisplay => '상태 및 표시';

  @override
  String get statisticsInProgress => '통계 집계 중...';

  @override
  String get status => '상태';

  @override
  String get statusAvailable => '사용 가능';

  @override
  String get statusLabel => '상태';

  @override
  String get statusUnavailable => '사용 불가능';

  @override
  String get storageDetails => '저장소 세부 정보';

  @override
  String get storageLocation => '저장 위치';

  @override
  String get storageSettings => '저장소 설정';

  @override
  String get storageUsed => '사용된 저장 공간';

  @override
  String get stretch => '늘이기';

  @override
  String get strokeCount => '획수';

  @override
  String submitFailed(Object error) {
    return '제출 실패: $error';
  }

  @override
  String successDeletedCount(Object count) {
    return '$count개의 백업 파일을 성공적으로 삭제했습니다';
  }

  @override
  String get suggestConfigureBackupPath => '권장: 설정에서 먼저 백업 경로를 구성하세요';

  @override
  String get suggestConfigureBackupPathFirst => '권장: 설정에서 먼저 백업 경로를 구성하세요';

  @override
  String get suggestRestartOrWait => '권장: 앱을 다시 시작하거나 서비스 초기화가 완료될 때까지 기다린 후 다시 시도하세요';

  @override
  String get suggestRestartOrWaitService => '권장: 앱을 다시 시작하거나 서비스 초기화가 완료될 때까지 기다린 후 다시 시도하세요';

  @override
  String get suggestedSolutions => '권장 해결책:';

  @override
  String get suggestedTags => '추천 태그';

  @override
  String get switchSuccessful => '전환 성공';

  @override
  String get switchingPage => '문자 페이지로 전환 중...';

  @override
  String get systemConfig => '시스템 구성';

  @override
  String get systemConfigItemNote => '이것은 시스템 구성 항목이므로 키 값은 수정할 수 없습니다';

  @override
  String get systemInfo => '시스템 정보';

  @override
  String get tabToNextField => 'Tab 키를 눌러 다음 필드로 이동';

  @override
  String tagAddError(Object error) {
    return '태그 추가 실패: $error';
  }

  @override
  String get tagHint => '태그 이름 입력';

  @override
  String tagRemoveError(Object error) {
    return '태그 제거 실패, 오류: $error';
  }

  @override
  String get tags => '태그';

  @override
  String get tagsAddHint => '태그 이름을 입력하고 Enter를 누르세요';

  @override
  String get tagsHint => '태그 입력...';

  @override
  String get tagsSelected => '선택된 태그:';

  @override
  String get targetLocationExists => '대상 위치에 동일한 이름의 파일이 이미 존재합니다:';

  @override
  String get targetPathLabel => '작업을 선택하세요:';

  @override
  String get text => '텍스트';

  @override
  String get textAlign => '텍스트 정렬';

  @override
  String get textContent => '텍스트 내용';

  @override
  String get textElement => '텍스트 요소';

  @override
  String get textProperties => '텍스트 속성';

  @override
  String get textSettings => '텍스트 설정';

  @override
  String get textureFillMode => '텍스처 채우기 모드';

  @override
  String get textureFillModeContain => '포함';

  @override
  String get textureFillModeCover => '덮기';

  @override
  String get textureFillModeRepeat => '반복';

  @override
  String get textureOpacity => '텍스처 불투명도';

  @override
  String get texturePreview => '텍스처 미리보기';

  @override
  String get textureSize => '텍스처 크기';

  @override
  String get themeMode => '테마 모드';

  @override
  String get themeModeDark => '다크 모드';

  @override
  String get themeModeDescription => '더 나은 야간 시청 경험을 위해 어두운 테마를 사용하세요';

  @override
  String get themeModeSystemDescription => '시스템 설정에 따라 어두운/밝은 테마를 자동으로 전환합니다';

  @override
  String get thisMonth => '이번 달';

  @override
  String get thisWeek => '이번 주';

  @override
  String get thisYear => '올해';

  @override
  String get threshold => '임계값';

  @override
  String get thumbnailCheckFailed => '썸네일 확인 실패';

  @override
  String get thumbnailEmpty => '썸네일 파일이 비어 있습니다';

  @override
  String get thumbnailLoadError => '썸네일 로드 실패';

  @override
  String get thumbnailNotFound => '썸네일을 찾을 수 없습니다';

  @override
  String get timeInfo => '시간 정보';

  @override
  String get timeLabel => '시간';

  @override
  String get title => '제목';

  @override
  String get titleAlreadyExists => '동일한 제목의 연습장이 이미 존재합니다. 다른 제목을 사용하세요';

  @override
  String get titleCannotBeEmpty => '제목은 비워둘 수 없습니다';

  @override
  String get titleExists => '제목이 이미 존재합니다';

  @override
  String get titleExistsMessage => '동일한 이름의 연습장이 이미 존재합니다. 덮어쓰시겠습니까?';

  @override
  String titleUpdated(Object title) {
    return '제목이 \"$title\"(으)로 업데이트되었습니다';
  }

  @override
  String get to => '까지';

  @override
  String get today => '오늘';

  @override
  String get toggleBackground => '배경 전환';

  @override
  String get toolModePanTooltip => '다중 선택 도구 (Ctrl+V)';

  @override
  String get toolModeSelectTooltip => '수집 도구 (Ctrl+B)';

  @override
  String get toolModePanShort => '다중선택';

  @override
  String get toolModeSelectShort => '수집';

  @override
  String get resultShort => '결과';

  @override
  String get topCenter => '위쪽 가운데';

  @override
  String get topLeft => '왼쪽 위';

  @override
  String get topRight => '오른쪽 위';

  @override
  String get total => '총계';

  @override
  String get totalBackups => '총 백업 수';

  @override
  String totalItems(Object count) {
    return '총 $count개';
  }

  @override
  String get totalSize => '총 크기';

  @override
  String get transformApplied => '변환이 적용되었습니다';

  @override
  String get tryOtherKeywords => '다른 키워드로 검색해 보세요';

  @override
  String get type => '유형';

  @override
  String get underline => '밑줄';

  @override
  String get undo => '실행 취소';

  @override
  String get ungroup => '그룹 해제 (Ctrl+U)';

  @override
  String get ungroupConfirm => '그룹 해제 확인';

  @override
  String get ungroupDescription => '이 그룹을 해제하시겠습니까?';

  @override
  String get unknown => '알 수 없음';

  @override
  String get unknownCategory => '알 수 없는 카테고리';

  @override
  String unknownElementType(Object type) {
    return '알 수 없는 요소 유형: $type';
  }

  @override
  String get unknownError => '알 수 없는 오류';

  @override
  String get unlockElement => '요소 잠금 해제';

  @override
  String get unlocked => '잠금 해제됨';

  @override
  String get unnamedElement => '이름 없는 요소';

  @override
  String get unnamedGroup => '이름 없는 그룹';

  @override
  String get unnamedLayer => '이름 없는 레이어';

  @override
  String get unsavedChanges => '저장되지 않은 변경 사항이 있습니다';

  @override
  String get updateTime => '업데이트 시간';

  @override
  String get updatedAt => '업데이트 시간';

  @override
  String get usageInstructions => '사용 설명서';

  @override
  String get useDefaultPath => '기본 경로 사용';

  @override
  String get userConfig => '사용자 구성';

  @override
  String get validCharacter => '유효한 문자를 입력하세요';

  @override
  String get validPath => '유효한 경로';

  @override
  String get validateData => '데이터 유효성 검사';

  @override
  String get validateDataDescription => '가져오기 전 데이터 무결성 확인';

  @override
  String get validateDataMandatory => '데이터 안전을 보장하기 위해 가져온 파일의 무결성 및 형식을 강제로 확인합니다';

  @override
  String get validatingImportFile => '가져온 파일 확인 중...';

  @override
  String valueTooLarge(Object label, Object max) {
    return '$label은(는) $max보다 클 수 없습니다';
  }

  @override
  String valueTooSmall(Object label, Object min) {
    return '$label은(는) $min보다 작을 수 없습니다';
  }

  @override
  String get versionDetails => '버전 세부 정보';

  @override
  String get versionInfoCopied => '버전 정보가 클립보드에 복사되었습니다';

  @override
  String get verticalAlignment => '수직 정렬';

  @override
  String get verticalLeftToRight => '세로 쓰기(왼쪽에서 오른쪽으로)';

  @override
  String get verticalRightToLeft => '세로 쓰기(오른쪽에서 왼쪽으로)';

  @override
  String get viewAction => '보기';

  @override
  String get viewDetails => '세부 정보 보기';

  @override
  String get viewExportResultsButton => '보기';

  @override
  String get visibility => '가시성';

  @override
  String get visible => '보임';

  @override
  String get visualProperties => '시각적 속성';

  @override
  String get visualSettings => '시각적 설정';

  @override
  String get warningOverwriteData => '경고: 이 작업은 현재 모든 데이터를 덮어씁니다!';

  @override
  String get warnings => '경고';

  @override
  String get widgetRefRequired => 'CollectionPainter를 생성하려면 WidgetRef가 필요합니다';

  @override
  String get width => '너비';

  @override
  String get windowButtonMaximize => '최대화';

  @override
  String get windowButtonMinimize => '최소화';

  @override
  String get windowButtonRestore => '복원';

  @override
  String get work => '작품';

  @override
  String get workBrowseSearch => '작품 검색...';

  @override
  String get workBrowseTitle => '작품';

  @override
  String get workCount => '작품 수';

  @override
  String get workDetailCharacters => '문자';

  @override
  String get workDetailOtherInfo => '기타 정보';

  @override
  String get workDetailTitle => '작품 세부 정보';

  @override
  String get workFormAuthorHelp => '선택 사항, 작품의 창작자';

  @override
  String get workFormAuthorHint => '작가 이름 입력';

  @override
  String get workFormAuthorMaxLength => '작가 이름은 50자를 초과할 수 없습니다';

  @override
  String get workFormAuthorTooltip => 'Ctrl+A를 눌러 작가 필드로 빠르게 이동';

  @override
  String get workFormCreationDateError => '창작 날짜는 현재 날짜를 초과할 수 없습니다';

  @override
  String get workFormDateHelp => '작품 완성 날짜';

  @override
  String get workFormRemarkHelp => '선택 사항, 작품에 대한 추가 정보';

  @override
  String get workFormRemarkMaxLength => '비고는 500자를 초과할 수 없습니다';

  @override
  String get workFormRemarkTooltip => 'Ctrl+R을 눌러 비고 필드로 빠르게 이동';

  @override
  String get workFormStyleHelp => '작품의 주요 스타일 유형';

  @override
  String get workFormTitleHelp => '작품의 주 제목, 작품 목록에 표시됨';

  @override
  String get workFormTitleMaxLength => '제목은 100자를 초과할 수 없습니다';

  @override
  String get workFormTitleMinLength => '제목은 최소 2자 이상이어야 합니다';

  @override
  String get workFormTitleRequired => '제목은 필수 항목입니다';

  @override
  String get workFormTitleTooltip => 'Ctrl+T를 눌러 제목 필드로 빠르게 이동';

  @override
  String get workFormToolHelp => '이 작품을 만드는 데 사용된 주요 도구';

  @override
  String get workIdCannotBeEmpty => '작품 ID는 비워둘 수 없습니다';

  @override
  String get workInfo => '작품 정보';

  @override
  String get workStyleClerical => '예서';

  @override
  String get workStyleCursive => '초서';

  @override
  String get workStyleRegular => '해서';

  @override
  String get workStyleRunning => '행서';

  @override
  String get workStyleSeal => '전서';

  @override
  String get workToolBrush => '붓';

  @override
  String get workToolHardPen => '경필';

  @override
  String get workToolOther => '기타';

  @override
  String get works => '작품';

  @override
  String worksCount(Object count) {
    return '$count개 작품';
  }

  @override
  String get writingMode => '쓰기 모드';

  @override
  String get writingTool => '서예 도구';

  @override
  String get writingToolManagement => '쓰기 도구 관리';

  @override
  String get writingToolText => '쓰기 도구';

  @override
  String get yes => '예';

  @override
  String get yesterday => '어제';

  @override
  String get zipFile => 'ZIP 압축 파일';
}
