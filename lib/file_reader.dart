import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pdfrx/pdfrx.dart';

class FileReadException implements Exception {
  final String message;
  FileReadException(this.message);
  @override
  String toString() => message;
}

class FileReader {
  static const int maxBytes = 10 * 1024 * 1024; // 10 MB

  /// Lets the user pick a .txt / .docx / .pdf file and returns its text.
  /// Returns null if the user cancelled.
  static Future<String?> pickAndRead() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['txt', 'docx', 'pdf'],
    );
    if (result == null || result.files.isEmpty) return null;

    final path = result.files.single.path;
    if (path == null) {
      throw FileReadException('Could not open this file.');
    }
    final file = File(path);
    if (await file.length() > maxBytes) {
      throw FileReadException('This file is too large (max 10 MB).');
    }

    final ext = path.split('.').last.toLowerCase();
    String text;
    try {
      if (ext == 'txt') {
        text = utf8.decode(await file.readAsBytes(), allowMalformed: true);
      } else if (ext == 'docx') {
        text = _readDocx(await file.readAsBytes());
      } else if (ext == 'pdf') {
        text = await _readPdf(path);
      } else {
        throw FileReadException('Only .txt, .docx and .pdf files are supported.');
      }
    } on FileReadException {
      rethrow;
    } catch (_) {
      throw FileReadException('Could not read this file. It may be damaged.');
    }

    text = text.trim();
    if (text.isEmpty) {
      throw FileReadException(
          'No text found in this file. Scanned (image-only) files are not supported.');
    }
    return text;
  }

  static String _readDocx(List<int> bytes) {
    final archive = ZipDecoder().decodeBytes(bytes);
    ArchiveFile? doc;
    for (final f in archive.files) {
      if (f.name == 'word/document.xml') {
        doc = f;
        break;
      }
    }
    if (doc == null) throw FileReadException('This is not a valid .docx file.');

    var xml = utf8.decode(doc.content as List<int>, allowMalformed: true);
    xml = xml
        .replaceAll(RegExp(r'<w:tab\s*/>'), ' ')
        .replaceAll(RegExp(r'<w:br\s*/>'), '\n')
        .replaceAll('</w:p>', '\n')
        .replaceAll(RegExp(r'<[^>]+>'), '')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&apos;', "'");
    return xml.replaceAll(RegExp(r'\n{3,}'), '\n\n');
  }

  static Future<String> _readPdf(String path) async {
    final doc = await PdfDocument.openFile(path);
    final buf = StringBuffer();
    try {
      for (final page in doc.pages) {
        final dynamic pageText = await page.loadText();
        final String? full = pageText?.fullText as String?;
        if (full != null && full.trim().isNotEmpty) {
          buf.writeln(full.trim());
          buf.writeln();
        }
      }
    } finally {
      doc.dispose();
    }
    return buf.toString();
  }
}
