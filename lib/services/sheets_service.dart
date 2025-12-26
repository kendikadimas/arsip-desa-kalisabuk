import 'package:gsheets/gsheets.dart';
import 'google_auth_service.dart';

class SheetsService {
  final GoogleAuthService _authService;
  GSheets? _gsheets;
  Spreadsheet? _spreadsheet;
  Worksheet? _worksheet;

  // Constructor requires an instance of Auth Service
  SheetsService(this._authService);

  /// Initialize GSheets with the same client from AuthService
  Future<void> init(String spreadsheetId) async {
    if (_authService.client == null) {
      throw Exception('Google Auth Service not initialized');
    }

    _gsheets = GSheets(_authService.client);
    
    // Open the spreadsheet by ID
    _spreadsheet = await _gsheets!.spreadsheet(spreadsheetId);
    
    // Get the first worksheet (default) or create one if needed
    _worksheet = _spreadsheet!.worksheetByTitle('DataArsip');
    if (_worksheet == null) {
      // Create new worksheet if not exists
      _worksheet = await _spreadsheet!.addWorksheet('DataArsip');
      // Add headers
      await _worksheet!.values.insertRow(1, ['No', 'Nomor Surat', 'Perihal', 'Tanggal', 'Link Foto']);
    }
  }

  /// Insert a new row of data
  /// [data] expected keys: 'noSurat', 'perihal', 'tanggal', 'linkFoto'
  Future<bool> insertArsip(Map<String, dynamic> data) async {
    if (_worksheet == null) throw Exception('Sheets Service not initialized');

    try {
      // Get current row count to generate auto-increment No (simple logic)
      final lastRow = await _worksheet!.values.lastRow();
      final newNo = (lastRow == null || lastRow.isEmpty || lastRow[0] == 'No') 
          ? 1 
          : int.parse(lastRow[0]) + 1;

      // Prepare row data: No, Nomor Surat, Perihal, Tanggal, Link Foto
      final row = [
        newNo,
        data['noSurat'] ?? '-',
        data['perihal'] ?? '-',
        data['tanggal'] ?? '-',
        data['linkFoto'] ?? '-',
      ];

      return await _worksheet!.values.appendRow(row);
    } catch (e) {
      print('Error inserting to Sheets: $e');
      return false;
    }
  }
}
