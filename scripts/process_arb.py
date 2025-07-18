#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
ARB 文件处理工具
1. 删除 metadata
2. 对键值进行排序
3. 删除重复键值
4. 增加日语和韩语的语言支持
"""

import json
import os
import sys
from pathlib import Path
from collections import OrderedDict

class ARBProcessor:
    """ARB 文件处理器"""
    
    def __init__(self):
        self.project_root = Path(__file__).parent.parent
        self.l10n_dir = self.project_root / 'lib' / 'l10n'
        
    def load_arb_file(self, file_path):
        """加载 ARB 文件"""
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                return json.load(f)
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
    
    def remove_metadata(self, arb_data):
        """删除 metadata（以 @ 开头的键）"""
        cleaned_data = {}
        removed_count = 0
        
        for key, value in arb_data.items():
            if key.startswith('@'):
                removed_count += 1
                continue
            cleaned_data[key] = value
        
        print(f"✅ 删除了 {removed_count} 个 metadata 项")
        return cleaned_data
    
    def sort_keys(self, arb_data):
        """对键值进行排序"""
        sorted_data = OrderedDict(sorted(arb_data.items()))
        print(f"✅ 对 {len(sorted_data)} 个键进行了排序")
        return sorted_data
    
    def remove_duplicates(self, arb_data):
        """删除重复键值（保留第一个出现的）"""
        seen_keys = set()
        unique_data = OrderedDict()
        duplicate_count = 0
        
        for key, value in arb_data.items():
            if key in seen_keys:
                duplicate_count += 1
                print(f"⚠️ 发现重复键: {key}")
                continue
            seen_keys.add(key)
            unique_data[key] = value
        
        if duplicate_count > 0:
            print(f"✅ 删除了 {duplicate_count} 个重复键")
        else:
            print("✅ 未发现重复键")
        
        return unique_data
    
    def process_chinese_arb(self):
        """处理中文 ARB 文件"""
        zh_file = self.l10n_dir / 'app_zh.arb'
        
        if not zh_file.exists():
            print(f"❌ 文件不存在: {zh_file}")
            return None
        
        print(f"📋 处理中文 ARB 文件: {zh_file}")
        
        # 加载文件
        arb_data = self.load_arb_file(zh_file)
        if arb_data is None:
            return None
        
        print(f"📊 原始文件包含 {len(arb_data)} 个项目")
        
        # 1. 删除 metadata
        arb_data = self.remove_metadata(arb_data)
        
        # 2. 删除重复键值
        arb_data = self.remove_duplicates(arb_data)
        
        # 3. 对键值进行排序
        arb_data = self.sort_keys(arb_data)
        
        # 保存处理后的文件
        if self.save_arb_file(zh_file, arb_data):
            print(f"✅ 中文 ARB 文件处理完成，最终包含 {len(arb_data)} 个项目")
            return arb_data
        else:
            return None
    
    def create_japanese_arb(self, zh_data):
        """创建日语 ARB 文件"""
        ja_file = self.l10n_dir / 'app_ja.arb'
        
        print(f"📋 创建日语 ARB 文件: {ja_file}")
        
        # 创建日语翻译数据（这里只是示例，实际需要专业翻译）
        ja_data = OrderedDict()
        
        # 添加一些基本的日语翻译示例
        sample_translations = {
            "appTitle": "字字珠玑",  # 保持原文或使用假名
            "add": "追加",
            "cancel": "キャンセル",
            "confirm": "確認",
            "delete": "削除",
            "edit": "編集",
            "export": "エクスポート",
            "import": "インポート",
            "save": "保存",
            "settings": "設定",
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
            "error": "エラー: {message}",
            "success": "成功",
            "failed": "失敗",
            "retry": "再試行",
            "help": "ヘルプ",
            "about": "について"
        }
        
        # 为所有键创建条目（未翻译的保持原文）
        for key in zh_data.keys():
            if key in sample_translations:
                ja_data[key] = sample_translations[key]
            else:
                # 保持原文，标记为需要翻译
                ja_data[key] = zh_data[key]  # 或者添加 "[JA]" 前缀标记
        
        if self.save_arb_file(ja_file, ja_data):
            print(f"✅ 日语 ARB 文件创建完成，包含 {len(ja_data)} 个项目")
            print("⚠️ 注意：大部分内容需要专业日语翻译")
            return True
        else:
            return False
    
    def create_korean_arb(self, zh_data):
        """创建韩语 ARB 文件"""
        ko_file = self.l10n_dir / 'app_ko.arb'
        
        print(f"📋 创建韩语 ARB 文件: {ko_file}")
        
        # 创建韩语翻译数据（这里只是示例，实际需要专业翻译）
        ko_data = OrderedDict()
        
        # 添加一些基本的韩语翻译示例
        sample_translations = {
            "appTitle": "字字珠玑",  # 保持原文
            "add": "추가",
            "cancel": "취소",
            "confirm": "확인",
            "delete": "삭제",
            "edit": "편집",
            "export": "내보내기",
            "import": "가져오기",
            "save": "저장",
            "settings": "설정",
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
            "error": "오류: {message}",
            "success": "성공",
            "failed": "실패",
            "retry": "재시도",
            "help": "도움말",
            "about": "정보"
        }
        
        # 为所有键创建条目（未翻译的保持原文）
        for key in zh_data.keys():
            if key in sample_translations:
                ko_data[key] = sample_translations[key]
            else:
                # 保持原文，标记为需要翻译
                ko_data[key] = zh_data[key]  # 或者添加 "[KO]" 前缀标记
        
        if self.save_arb_file(ko_file, ko_data):
            print(f"✅ 韩语 ARB 文件创建完成，包含 {len(ko_data)} 个项目")
            print("⚠️ 注意：大部分内容需要专业韩语翻译")
            return True
        else:
            return False
    
    def update_supported_locales(self):
        """更新 pubspec.yaml 中的支持语言列表"""
        pubspec_file = self.project_root / 'pubspec.yaml'
        
        if not pubspec_file.exists():
            print(f"❌ pubspec.yaml 文件不存在")
            return False
        
        try:
            with open(pubspec_file, 'r', encoding='utf-8') as f:
                content = f.read()
            
            # 查找并更新 supported-locales 部分
            if 'supported-locales:' in content:
                print("📋 更新 pubspec.yaml 中的支持语言列表")
                
                # 这里需要手动更新，因为 YAML 格式比较复杂
                print("⚠️ 请手动在 pubspec.yaml 中添加以下语言支持:")
                print("flutter:")
                print("  generate: true")
                print("flutter_intl:")
                print("  enabled: true")
                print("  class_name: S")
                print("  main_locale: zh")
                print("  arb_dir: lib/l10n")
                print("  output_dir: lib/generated")
                print("  supported-locales:")
                print("    - zh")
                print("    - en")
                print("    - ja")
                print("    - ko")
            else:
                print("⚠️ 未找到 supported-locales 配置，请手动添加语言支持")
            
            return True
            
        except Exception as e:
            print(f"❌ 更新 pubspec.yaml 失败: {e}")
            return False
    
    def process_english_arb(self):
        """处理英文 ARB 文件，移除 metadata"""
        en_file = self.l10n_dir / 'app_en.arb'

        if not en_file.exists():
            print(f"⚠️ 英文 ARB 文件不存在: {en_file}")
            return True

        print(f"📋 处理英文 ARB 文件: {en_file}")

        # 加载文件
        arb_data = self.load_arb_file(en_file)
        if arb_data is None:
            return False

        print(f"📊 原始文件包含 {len(arb_data)} 个项目")

        # 1. 删除 metadata
        arb_data = self.remove_metadata(arb_data)

        # 2. 删除重复键值
        arb_data = self.remove_duplicates(arb_data)

        # 3. 对键值进行排序
        arb_data = self.sort_keys(arb_data)

        # 保存处理后的文件
        if self.save_arb_file(en_file, arb_data):
            print(f"✅ 英文 ARB 文件处理完成，最终包含 {len(arb_data)} 个项目")
            return True
        else:
            return False

    def process_all(self):
        """处理所有 ARB 文件"""
        print("🎯 开始处理 ARB 文件")
        print("="*60)

        # 1. 处理中文 ARB 文件
        zh_data = self.process_chinese_arb()
        if zh_data is None:
            print("❌ 中文 ARB 文件处理失败")
            return False

        print()

        # 1.5. 处理英文 ARB 文件
        if not self.process_english_arb():
            print("❌ 英文 ARB 文件处理失败")
            return False

        print()

        # 2. 创建日语 ARB 文件
        if not self.create_japanese_arb(zh_data):
            print("❌ 日语 ARB 文件创建失败")
            return False

        print()

        # 3. 创建韩语 ARB 文件
        if not self.create_korean_arb(zh_data):
            print("❌ 韩语 ARB 文件创建失败")
            return False

        print()

        # 4. 更新支持的语言列表
        self.update_supported_locales()

        print()
        print("🎉 ARB 文件处理完成！")
        print("="*60)
        print("📁 生成的文件:")
        print(f"  - {self.l10n_dir / 'app_zh.arb'} (已处理)")
        print(f"  - {self.l10n_dir / 'app_en.arb'} (已处理)")
        print(f"  - {self.l10n_dir / 'app_ja.arb'} (新建)")
        print(f"  - {self.l10n_dir / 'app_ko.arb'} (新建)")
        print()
        print("📋 后续步骤:")
        print("1. 运行 'flutter packages get' 更新依赖")
        print("2. 运行 'flutter gen-l10n' 生成本地化代码")
        print("3. 请专业翻译人员翻译日语和韩语内容")
        print("4. 在应用中测试多语言功能")

        return True

def main():
    """主函数"""
    try:
        processor = ARBProcessor()
        success = processor.process_all()
        
        if success:
            print("\n✅ 所有操作完成成功！")
        else:
            print("\n❌ 部分操作失败，请检查错误信息")
            sys.exit(1)
            
    except KeyboardInterrupt:
        print("\n\n👋 用户中断操作")
    except Exception as e:
        print(f"\n❌ 程序出错: {e}")
        sys.exit(1)

if __name__ == '__main__':
    main()
