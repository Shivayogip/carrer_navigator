import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'resume_service.dart';

class FileUploadService {
  static Future<bool> pickAndStoreResume(BuildContext context) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'txt'],
      withData: true,
    );

    if (result != null) {
      final file = result.files.single;
      final bytes = file.bytes;

      if (bytes == null) return false;

      String text = "";

      try {
        if (file.name.endsWith(".pdf")) {
          final PdfDocument document = PdfDocument(inputBytes: bytes);

          PdfTextExtractor extractor = PdfTextExtractor(document);

          for (int i = 0; i < document.pages.count; i++) {
            text += extractor.extractText(startPageIndex: i);
          }

          document.dispose();
        } else if (file.name.endsWith(".txt")) {
          text = String.fromCharCodes(bytes);
        }

        ResumeService().setResume(text);

        return true; // ✅ SUCCESS
      } catch (e) {
        return false; // ❌ FAIL
      }
    }

    return false;
  }
}