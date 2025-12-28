import 'package:gsheets/gsheets.dart';
import 'google_auth_service.dart';

class SheetsService {
  final GoogleAuthService _authService;
  GSheets? _gsheets;
  Spreadsheet? _spreadsheet;

  // Constructor requires an instance of Auth Service
  SheetsService(this._authService);

  /// Initialize GSheets with the same client from AuthService
  Future<void> init(String spreadsheetId) async {
    // Ensure Auth Service is initialized
    if (_authService.client == null || _authService.credentialsJson == null) {
      throw Exception('Google Auth Service not initialized');
    }

    // Initialize GSheets with the credentials JSON string
    // IMPORTANT: GSheets constructor expects credentials (String or Map), usually not the Client object directly
    _gsheets = GSheets(_authService.credentialsJson);

    // Open the spreadsheet by ID
    _spreadsheet = await _gsheets!.spreadsheet(spreadsheetId);
  }

  /// Get or Create a Worksheet
  Future<Worksheet> _getWorksheet(String title, List<String> headers) async {
    if (_spreadsheet == null) throw Exception('Spreadsheet not initialized');

    var sheet = _spreadsheet!.worksheetByTitle(title);
    if (sheet == null) {
      // Create new worksheet if not exists
      sheet = await _spreadsheet!.addWorksheet(title);
      // Add standard headers (No + [Custom Fields] + Link Foto)
      final allHeaders = ['No', ...headers, 'Link Foto'];
      await sheet!.values.insertRow(1, allHeaders);
    }
    return sheet;
  }

  /// Insert a new row of data dynamically
  /// [sheetTitle]: Target tab name
  /// [headers]: The list of field names defined in configuration
  /// [data]: Map of data where keys match headers
  Future<bool> insertArsip(
    String sheetTitle,
    List<String> headers,
    Map<String, dynamic> data,
  ) async {
    try {
      final sheet = await _getWorksheet(sheetTitle, headers);

      // Get current row count to generate auto-increment No
      final lastRow = await sheet.values.lastRow();
      final newNo = (lastRow == null || lastRow.isEmpty || lastRow[0] == 'No')
          ? 1
          : int.parse(lastRow[0]) + 1;

      // Prepare row data dynamically in order of keys
      // 1. 'No' column
      final List<dynamic> row = [newNo];

      // 2. Custom Fields
      for (var header in headers) {
        row.add(data[header] ?? '-');
      }

      // 3. 'Link Foto' column
      row.add(data['Link Foto'] ?? '-');

      return await sheet.values.appendRow(row);
    } catch (e) {
      print('Error inserting to Sheets ($sheetTitle): $e');
      return false;
    }
  }

  /// Fetch all rows from a specific sheet
  /// Returns a list of Maps, where keys are the headers
  Future<List<Map<String, String>>> fetchArsip(String sheetTitle) async {
    try {
      if (_spreadsheet == null) throw Exception('Spreadsheet not initialized');

      var sheet = _spreadsheet!.worksheetByTitle(sheetTitle);
      if (sheet == null) {
        return []; // Sheet doesn't exist yet, return empty
      }

      final rows = await sheet.values.map.allRows();
      return rows ?? [];
    } catch (e) {
      print('Error fetching from Sheets ($sheetTitle): $e');
      return [];
    }
  }
}
