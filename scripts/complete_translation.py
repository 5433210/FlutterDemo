#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
完整翻译脚本 - 日语和韩语
基于书法应用的专业术语翻译
"""

import json
import os
from pathlib import Path
from collections import OrderedDict

class TranslationCompleter:
    """翻译完成器"""
    
    def __init__(self):
        self.project_root = Path(__file__).parent.parent
        self.l10n_dir = self.project_root / 'lib' / 'l10n'
        
        # 日语翻译字典
        self.ja_translations = {
            # 基础操作
            "add": "追加",
            "cancel": "キャンセル", 
            "confirm": "確認",
            "delete": "削除",
            "edit": "編集",
            "export": "エクスポート",
            "import": "インポート",
            "save": "保存",
            "settings": "設定",
            "about": "について",
            "yes": "はい",
            "no": "いいえ",
            "ok": "OK",
            "back": "戻る",
            "next": "次へ",
            "previous": "前へ",
            "close": "閉じる",
            "open": "開く",
            "create": "作成",
            "loading": "読み込み中...",
            "success": "成功",
            "failed": "失敗",
            "retry": "再試行",
            "help": "ヘルプ",
            "done": "完了",
            "apply": "適用",
            "reset": "リセット",
            "browse": "参照",
            "select": "選択",
            "copy": "コピー",
            "paste": "貼り付け",
            "cut": "切り取り",
            "undo": "元に戻す",
            "redo": "やり直し",
            "refresh": "更新",
            "search": "検索",
            "filter": "フィルター",
            "sort": "並び替え",
            "view": "表示",
            "preview": "プレビュー",
            "print": "印刷",
            "exit": "終了",
            
            # 书法相关
            "appTitle": "字字珠玉",
            "work": "作品",
            "works": "作品",
            "character": "文字",
            "characters": "文字",
            "practice": "練習",
            "practices": "練習",
            "calligraphyStyle": "書道スタイル",
            "writingTool": "書道具",
            "workStyleRegular": "楷書",
            "workStyleRunning": "行書", 
            "workStyleCursive": "草書",
            "workStyleClerical": "隷書",
            "workStyleSeal": "篆書",
            "workToolBrush": "筆",
            "workToolHardPen": "硬筆",
            "workToolOther": "その他",
            "characterCollection": "文字収集",
            "characterCollectionTitle": "文字収集",
            "practiceSheetSaved": "練習帳「{title}」が保存されました",
            
            # 界面元素
            "title": "タイトル",
            "name": "名前",
            "description": "説明",
            "author": "作者",
            "date": "日付",
            "time": "時間",
            "size": "サイズ",
            "type": "種類",
            "status": "状態",
            "category": "カテゴリ",
            "tag": "タグ",
            "tags": "タグ",
            "image": "画像",
            "images": "画像",
            "file": "ファイル",
            "files": "ファイル",
            "folder": "フォルダ",
            "path": "パス",
            "location": "場所",
            "properties": "プロパティ",
            "details": "詳細",
            "information": "情報",
            "metadata": "メタデータ",
            
            # 操作相关
            "addWork": "作品を追加",
            "addImage": "画像を追加",
            "addCategory": "カテゴリを追加",
            "addTag": "タグを追加",
            "deleteSelected": "選択項目を削除",
            "deleteAll": "すべて削除",
            "selectAll": "すべて選択",
            "clearSelection": "選択をクリア",
            "batchMode": "バッチモード",
            "batchOperations": "バッチ操作",
            "exportSelected": "選択項目をエクスポート",
            "importFiles": "ファイルをインポート",
            
            # 错误和消息
            "error": "エラー：{message}",
            "loadFailed": "読み込みに失敗しました",
            "saveFailed": "保存に失敗しました",
            "deleteFailed": "削除に失敗しました：{error}",
            "exportFailed": "エクスポートに失敗しました",
            "importFailed": "インポートに失敗しました：{error}",
            "deleteMessage": "{count}項目を削除します。この操作は元に戻せません。",
            "titleCannotBeEmpty": "タイトルは空にできません",
            "titleUpdated": "タイトルが「{title}」に更新されました",
            "saveSuccess": "保存が完了しました",
            "deleteSuccess": "削除が完了しました",
            "exportSuccess": "エクスポートが完了しました",
            "importSuccess": "インポートが完了しました",
            
            # 设置相关
            "language": "言語",
            "languageSystem": "システム",
            "languageZh": "简体中文",
            "languageEn": "English",
            "languageJa": "日本語",
            "languageKo": "한국어",
            "themeMode": "テーマモード",
            "themeModeDark": "ダークモード",
            "themeModeLight": "ライトモード",
            "themeModeSystem": "システム設定に従う",
            "cacheSettings": "キャッシュ設定",
            "clearCache": "キャッシュをクリア",
            "backupSettings": "バックアップ設定",
            "createBackup": "バックアップを作成",
            "restoreBackup": "バックアップから復元",
            "dataPathSettings": "データパス設定",
            
            # 备份相关
            "backup": "バックアップ",
            "backups": "バックアップ",
            "restore": "復元",
            "backupDescription": "バックアップの説明",
            "createBackup": "バックアップを作成",
            "deleteBackup": "バックアップを削除",
            "exportBackup": "バックアップをエクスポート",
            "importBackup": "バックアップをインポート",
            "backupSuccess": "バックアップが作成されました",
            "restoreSuccess": "復元が完了しました",
            "backupFailed": "バックアップの作成に失敗しました",
            "restoreFailed": "復元に失敗しました",
            
            # 时间相关
            "today": "今日",
            "yesterday": "昨日", 
            "thisWeek": "今週",
            "lastWeek": "先週",
            "thisMonth": "今月",
            "lastMonth": "先月",
            "thisYear": "今年",
            "lastYear": "昨年",
            "recent": "最近",
            "all": "すべて",
            "allTime": "全期間",
            
            # 页面和导航
            "homePage": "ホーム",
            "workBrowseTitle": "作品",
            "practiceListTitle": "練習帳",
            "libraryManagement": "ライブラリ",
            "navigationBackToPrevious": "前のページに戻る",
            "navigationNoHistory": "履歴がありません",
            "navigationSelectPage": "どのページに戻りますか？",
        }
        
        # 韩语翻译字典
        self.ko_translations = {
            # 基础操作
            "add": "추가",
            "cancel": "취소",
            "confirm": "확인", 
            "delete": "삭제",
            "edit": "편집",
            "export": "내보내기",
            "import": "가져오기",
            "save": "저장",
            "settings": "설정",
            "about": "정보",
            "yes": "예",
            "no": "아니오",
            "ok": "확인",
            "back": "뒤로",
            "next": "다음",
            "previous": "이전",
            "close": "닫기",
            "open": "열기",
            "create": "생성",
            "loading": "로딩 중...",
            "success": "성공",
            "failed": "실패",
            "retry": "재시도",
            "help": "도움말",
            "done": "완료",
            "apply": "적용",
            "reset": "재설정",
            "browse": "찾아보기",
            "select": "선택",
            "copy": "복사",
            "paste": "붙여넣기",
            "cut": "잘라내기",
            "undo": "실행 취소",
            "redo": "다시 실행",
            "refresh": "새로 고침",
            "search": "검색",
            "filter": "필터",
            "sort": "정렬",
            "view": "보기",
            "preview": "미리보기",
            "print": "인쇄",
            "exit": "종료",
            
            # 书法相关
            "appTitle": "字字珠玑",
            "work": "작품",
            "works": "작품",
            "character": "글자",
            "characters": "글자",
            "practice": "연습",
            "practices": "연습",
            "calligraphyStyle": "서예 스타일",
            "writingTool": "서예 도구",
            "workStyleRegular": "해서",
            "workStyleRunning": "행서",
            "workStyleCursive": "초서", 
            "workStyleClerical": "예서",
            "workStyleSeal": "전서",
            "workToolBrush": "붓",
            "workToolHardPen": "경필",
            "workToolOther": "기타",
            "characterCollection": "글자 수집",
            "characterCollectionTitle": "글자 수집",
            "practiceSheetSaved": "연습장 \"{title}\"이(가) 저장되었습니다",
            
            # 界面元素
            "title": "제목",
            "name": "이름",
            "description": "설명",
            "author": "작가",
            "date": "날짜",
            "time": "시간",
            "size": "크기",
            "type": "유형",
            "status": "상태",
            "category": "카테고리",
            "tag": "태그",
            "tags": "태그",
            "image": "이미지",
            "images": "이미지",
            "file": "파일",
            "files": "파일",
            "folder": "폴더",
            "path": "경로",
            "location": "위치",
            "properties": "속성",
            "details": "세부사항",
            "information": "정보",
            "metadata": "메타데이터",
            
            # 操作相关
            "addWork": "작품 추가",
            "addImage": "이미지 추가",
            "addCategory": "카테고리 추가",
            "addTag": "태그 추가",
            "deleteSelected": "선택 항목 삭제",
            "deleteAll": "모두 삭제",
            "selectAll": "모두 선택",
            "clearSelection": "선택 해제",
            "batchMode": "일괄 모드",
            "batchOperations": "일괄 작업",
            "exportSelected": "선택 항목 내보내기",
            "importFiles": "파일 가져오기",
            
            # 错误和消息
            "error": "오류: {message}",
            "loadFailed": "로드에 실패했습니다",
            "saveFailed": "저장에 실패했습니다",
            "deleteFailed": "삭제에 실패했습니다: {error}",
            "exportFailed": "내보내기에 실패했습니다",
            "importFailed": "가져오기에 실패했습니다: {error}",
            "deleteMessage": "{count}개 항목을 삭제합니다. 이 작업은 취소할 수 없습니다.",
            "titleCannotBeEmpty": "제목은 비워둘 수 없습니다",
            "titleUpdated": "제목이 \"{title}\"로 업데이트되었습니다",
            "saveSuccess": "저장이 완료되었습니다",
            "deleteSuccess": "삭제가 완료되었습니다",
            "exportSuccess": "내보내기가 완료되었습니다",
            "importSuccess": "가져오기가 완료되었습니다",
            
            # 设置相关
            "language": "언어",
            "languageSystem": "시스템",
            "languageZh": "简体中文",
            "languageEn": "English",
            "languageJa": "日本語",
            "languageKo": "한국어",
            "themeMode": "테마 모드",
            "themeModeDark": "다크 모드",
            "themeModeLight": "라이트 모드",
            "themeModeSystem": "시스템 설정 따르기",
            "cacheSettings": "캐시 설정",
            "clearCache": "캐시 지우기",
            "backupSettings": "백업 설정",
            "createBackup": "백업 생성",
            "restoreBackup": "백업에서 복원",
            "dataPathSettings": "데이터 경로 설정",
            
            # 备份相关
            "backup": "백업",
            "backups": "백업",
            "restore": "복원",
            "backupDescription": "백업 설명",
            "createBackup": "백업 생성",
            "deleteBackup": "백업 삭제",
            "exportBackup": "백업 내보내기",
            "importBackup": "백업 가져오기",
            "backupSuccess": "백업이 생성되었습니다",
            "restoreSuccess": "복원이 완료되었습니다",
            "backupFailed": "백업 생성에 실패했습니다",
            "restoreFailed": "복원에 실패했습니다",
            
            # 时间相关
            "today": "오늘",
            "yesterday": "어제",
            "thisWeek": "이번 주",
            "lastWeek": "지난 주",
            "thisMonth": "이번 달",
            "lastMonth": "지난 달",
            "thisYear": "올해",
            "lastYear": "작년",
            "recent": "최근",
            "all": "모두",
            "allTime": "전체 기간",
            
            # 页面和导航
            "homePage": "홈",
            "workBrowseTitle": "작품",
            "practiceListTitle": "연습장",
            "libraryManagement": "라이브러리",
            "navigationBackToPrevious": "이전 페이지로 돌아가기",
            "navigationNoHistory": "기록이 없습니다",
            "navigationSelectPage": "어느 페이지로 돌아가시겠습니까?",
        }
    
    def load_arb_file(self, file_path):
        """加载 ARB 文件"""
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                return json.load(f, object_pairs_hook=OrderedDict)
        except Exception as e:
            print(f"❌ 加载文件失败 {file_path}: {e}")
            return None
    
    def save_arb_file(self, file_path, data):
        """保存 ARB 文件"""
        try:
            with open(file_path, 'w', encoding='utf-8') as f:
                json.dump(data, f, ensure_ascii=False, indent=2)
            return True
        except Exception as e:
            print(f"❌ 保存文件失败 {file_path}: {e}")
            return False
    
    def translate_text(self, key, zh_text, translations_dict):
        """翻译文本"""
        # 直接匹配键名
        if key in translations_dict:
            return translations_dict[key]
        
        # 如果没有翻译，保持原文
        return zh_text
    
    def complete_translation(self, lang_code, translations_dict):
        """完成指定语言的翻译"""
        zh_file = self.l10n_dir / 'app_zh.arb'
        target_file = self.l10n_dir / f'app_{lang_code}.arb'
        
        print(f"📋 完成{lang_code.upper()}翻译: {target_file}")
        
        # 加载中文模板
        zh_data = self.load_arb_file(zh_file)
        if zh_data is None:
            return False
        
        # 加载现有目标文件
        target_data = self.load_arb_file(target_file)
        if target_data is None:
            target_data = OrderedDict()
        
        translated_count = 0
        total_count = len(zh_data)
        
        # 翻译所有条目
        for key, zh_text in zh_data.items():
            translated_text = self.translate_text(key, zh_text, translations_dict)
            target_data[key] = translated_text
            
            if translated_text != zh_text:
                translated_count += 1
        
        # 保存翻译结果
        if self.save_arb_file(target_file, target_data):
            print(f"✅ {lang_code.upper()}翻译完成: {translated_count}/{total_count} 项已翻译")
            return True
        else:
            return False
    
    def complete_all_translations(self):
        """完成所有翻译"""
        print("🌐 开始完成日语和韩语翻译")
        print("="*60)
        
        # 完成日语翻译
        if not self.complete_translation('ja', self.ja_translations):
            print("❌ 日语翻译失败")
            return False
        
        print()
        
        # 完成韩语翻译
        if not self.complete_translation('ko', self.ko_translations):
            print("❌ 韩语翻译失败")
            return False
        
        print()
        print("🎉 翻译完成！")
        print("📋 后续步骤:")
        print("1. 运行 'flutter gen-l10n' 重新生成本地化代码")
        print("2. 在设置页面添加语言切换功能")
        print("3. 测试多语言界面效果")
        
        return True

def main():
    """主函数"""
    try:
        completer = TranslationCompleter()
        success = completer.complete_all_translations()
        
        if success:
            print("\n✅ 翻译完成成功！")
        else:
            print("\n❌ 翻译过程中出现错误")
            
    except Exception as e:
        print(f"\n❌ 程序出错: {e}")

if __name__ == '__main__':
    main()
