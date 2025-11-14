import 'package:charasgem/presentation/widgets/practice/export/export_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';

void main() {
  group('ExportService.resolvePageFormatForPage', () {
  const baseFormat = PdfPageFormat.a4;

    test('uses default orientation when auto detection is disabled', () {
      final format = ExportService.resolvePageFormatForPage(
        baseFormat: baseFormat,
        defaultLandscape: true,
        autoDetectOrientation: false,
        pageOrientationOverrides: const {},
        pageIndex: 0,
      );

      expect(format.width, baseFormat.landscape.width);
      expect(format.height, baseFormat.landscape.height);
    });

    test('uses overrides when auto detection is enabled', () {
      final overrides = <int, bool>{0: false, 1: true};

      final portraitFormat = ExportService.resolvePageFormatForPage(
        baseFormat: baseFormat,
        defaultLandscape: true,
        autoDetectOrientation: true,
        pageOrientationOverrides: overrides,
        pageIndex: 0,
      );

      expect(portraitFormat.width, baseFormat.portrait.width);
      expect(portraitFormat.height, baseFormat.portrait.height);

      final landscapeFormat = ExportService.resolvePageFormatForPage(
        baseFormat: baseFormat,
        defaultLandscape: false,
        autoDetectOrientation: true,
        pageOrientationOverrides: overrides,
        pageIndex: 1,
      );

      expect(landscapeFormat.width, baseFormat.landscape.width);
      expect(landscapeFormat.height, baseFormat.landscape.height);
    });

    test('falls back to default when override is missing', () {
      final format = ExportService.resolvePageFormatForPage(
        baseFormat: baseFormat,
        defaultLandscape: false,
        autoDetectOrientation: true,
        pageOrientationOverrides: const {},
        pageIndex: 5,
      );

      expect(format.width, baseFormat.portrait.width);
      expect(format.height, baseFormat.portrait.height);
    });
  });
}
