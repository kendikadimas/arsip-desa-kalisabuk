import 'package:googleapis/sheets/v4.dart' as sheets;
import 'google_auth_service.dart';

class SheetsService {
  final GoogleAuthService _authService;
  sheets.SheetsApi? _sheetsApi;
  String? _spreadsheetId;

  // Constructor requires an instance of Auth Service
  SheetsService(this._authService);

  /// Initialize Sheets API with the authenticated client
  Future<void> init(String spreadsheetId) async {
    if (_authService.client == null) {
      throw Exception('Google Auth Service not initialized');
    }

    _spreadsheetId = spreadsheetId;
    _sheetsApi = sheets.SheetsApi(_authService.client!);
    
    // Verify spreadsheet exists and is accessible
    try {
      await _sheetsApi!.spreadsheets.get(spreadsheetId);
      print('Successfully connected to spreadsheet');
    } catch (e) {
      print('Error accessing spreadsheet: $e');
      rethrow;
    }
  }

  /// Insert a new row of data to the DataArsip sheet
  /// [data] expected keys: 'noSurat', 'perihal', 'tanggal', 'linkFoto'
  Future<bool> insertArsip(Map<String, dynamic> data) async {
    if (_sheetsApi == null || _spreadsheetId == null) {
      throw Exception('Sheets Service not initialized');
    }

    try {
      const sheetName = 'DataArsip';
      
      // Get current values to determine next row number
      final response = await _sheetsApi!.spreadsheets.values.get(
        _spreadsheetId!,
        '$sheetName!A:A',
      );
      
      final currentRows = response.values?.length ?? 0;
      final newNo = currentRows; // Will be row 1 if header exists, or 0 if empty
      
      // Prepare row data: No, Nomor Surat, Perihal, Tanggal, Link Foto
      final row = [
        newNo,
        data['noSurat'] ?? '-',
        data['perihal'] ?? '-',
        data['tanggal'] ?? '-',
        data['linkFoto'] ?? '-',
      ];

      final valueRange = sheets.ValueRange.fromJson({
        'values': [row],
      });

      await _sheetsApi!.spreadsheets.values.append(
        valueRange,
        _spreadsheetId!,
        '$sheetName!A:E',
        valueInputOption: 'RAW',
      );
      
      print('Row inserted successfully');
      return true;
    } catch (e) {
      print('Error inserting to Sheets: $e');
      return false;
    }
  }
}
