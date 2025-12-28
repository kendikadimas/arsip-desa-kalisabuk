import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis/sheets/v4.dart' as sheets;
import 'package:googleapis_auth/auth_io.dart';

import 'package:path/path.dart' as p;

class GoogleAuthService {
  static const _scopes = [
    drive.DriveApi.driveFileScope,
    sheets.SheetsApi.spreadsheetsScope,
  ];

  AutoRefreshingAuthClient? _client;
  drive.DriveApi? _driveApi;
  String? _credentialsJson;

  // Getter for the authenticated client to be used by GSheets
  AutoRefreshingAuthClient? get client => _client;

  // Getter for raw credentials JSON string (for gsheets library)
  String? get credentialsJson => _credentialsJson;

  /// Initialize the Service Account with credentials
  Future<void> init() async {
    try {
      // Load credentials from assets
      print('Loading assets/credentials.json...');
      _credentialsJson = await rootBundle.loadString('assets/credentials.json');
      print('Loaded credentialsJson length: ${_credentialsJson!.length}');
      print(
        'First 100 chars: ${_credentialsJson!.substring(0, _credentialsJson!.length > 100 ? 100 : _credentialsJson!.length)}',
      );

      print('Raw content length: ${_credentialsJson!.length}');

      // 1. Sanitize: Remove BOM if present (often causes issues on mobile)
      if (_credentialsJson!.isNotEmpty &&
          _credentialsJson!.codeUnitAt(0) == 0xFEFF) {
        print('Detected BOM, removing it...');
        _credentialsJson = _credentialsJson!.substring(1);
      }

      // 2. Explicit Decode to inspect structure
      final dynamic decoded = jsonDecode(_credentialsJson!);
      print('Decoded type: ${decoded.runtimeType}');

      if (decoded is! Map) {
        throw Exception(
          'JSON content is not a Map, it is: ${decoded.runtimeType}',
        );
      }

      // 3. Cast to Map<String, dynamic> explicitly to satisfy strict typing
      final Map<String, dynamic> credsMap = Map<String, dynamic>.from(
        decoded as Map,
      );

      // 4. Pass the Map (not string) to fromJson
      final accountCredentials = ServiceAccountCredentials.fromJson(credsMap);

      // Create authenticated client
      _client = await clientViaServiceAccount(accountCredentials, _scopes);

      // Initialize Drive API
      _driveApi = drive.DriveApi(_client!);

      print('Google Auth Service Initialized Successfully');
    } catch (e, stackTrace) {
      print('Error initializing Google Auth Service: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Uploads a file to Google Drive
  /// Returns the Web Content Link (for downloading/viewing) or ID
  Future<String?> uploadToDrive(File file, {String? folderId}) async {
    if (_driveApi == null) await init();

    try {
      final fileName = p.basename(file.path);
      var media = drive.Media(file.openRead(), file.lengthSync());

      var driveFile = drive.File();
      driveFile.name = fileName;

      // If folderId is provided, upload to that folder
      if (folderId != null) {
        driveFile.parents = [folderId];
      }

      final result = await _driveApi!.files.create(
        driveFile,
        uploadMedia: media,
        $fields: 'id, webViewLink, webContentLink',
      );

      print('File uploaded. ID: ${result.id}');
      // Return the webViewLink (viewable link) or webContentLink (download link)
      // Usually for "viewing" via URL, webViewLink is better,
      // but for direct image embedding, you might need to tweaking permissions public.
      // For now returning webViewLink.
      return result.webViewLink;
    } catch (e) {
      print('Error uploading to Drive: $e');
      return null;
    }
  }
}
