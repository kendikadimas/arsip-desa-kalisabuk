import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/auth_io.dart';
import 'package:gsheets/gsheets.dart';
import 'package:path/path.dart' as p;

class GoogleAuthService {
  static const _scopes = [
    drive.DriveApi.driveFileScope,
    GSheets.spreadsheetsScope,
  ];

  AutoRefreshingAuthClient? _client;
  drive.DriveApi? _driveApi;

  // Getter for the authenticated client to be used by GSheets
  AutoRefreshingAuthClient? get client => _client;

  /// Initialize the Service Account with credentials
  Future<void> init() async {
    try {
      // Load credentials from assets
      final credentialsJson = await rootBundle.loadString('assets/credentials.json');
      final accountCredentials = ServiceAccountCredentials.fromJson(credentialsJson);

      // Create authenticated client
      _client = await clientViaServiceAccount(accountCredentials, _scopes);

      // Initialize Drive API
      _driveApi = drive.DriveApi(_client!);
      
      print('Google Auth Service Initialized Successfully');
    } catch (e) {
      print('Error initializing Google Auth Service: $e');
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
