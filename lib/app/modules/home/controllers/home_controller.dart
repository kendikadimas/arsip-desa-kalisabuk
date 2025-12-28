import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:kalisabuk_arsip_desa/config/app_config.dart';
import 'package:kalisabuk_arsip_desa/services/google_auth_service.dart';
import 'package:kalisabuk_arsip_desa/services/sheets_service.dart';
import 'package:kalisabuk_arsip_desa/app/data/menu_config.dart';

import 'package:kalisabuk_arsip_desa/app/data/menu_config.dart';
import 'package:google_mlkit_document_scanner/google_mlkit_document_scanner.dart';

class SearchResult {
  final Map<String, String> data;
  final String sourceCategory; // 'Administrasi Umum' or 'Layanan Kependudukan'
  final MenuItem menuItem;

  SearchResult(this.data, this.sourceCategory, this.menuItem);
}

class HomeController extends GetxController {
  // Services
  final GoogleAuthService _authService = GoogleAuthService();
  late SheetsService _sheetsService;

  // Dynamic Form Controllers
  final Map<String, TextEditingController> formControllers = {};

  // State
  var selectedImage = Rx<File?>(null);
  var isLoading = false.obs;
  var statusMessage = ''.obs;

  // Data State
  var currentDataList = <Map<String, String>>[].obs;

  @override
  void onInit() {
    super.onInit();
    _sheetsService = SheetsService(_authService);
    // Initialize services
    _initServices();
  }

  // ... onClose ...

  // Fetch Data for List View
  Future<void> fetchData(String sheetTitle) async {
    try {
      isLoading.value = true;
      currentDataList.clear();

      final data = await _sheetsService.fetchArsip(sheetTitle);
      currentDataList.assignAll(data);
    } catch (e) {
      Get.snackbar('Error', 'Gagal mengambil data: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Dispose controllers when not needed?
  // actually GetX handles controller memory usually if we close the page,
  // but since this is a global controller kept alive, we might want to clear them.
  // For now simple map management.
  @override
  void onClose() {
    for (var c in formControllers.values) {
      c.dispose();
    }
    super.onClose();
  }

  Future<void> _initServices() async {
    try {
      statusMessage.value = 'Initializing Google Services...';
      await _authService.init();
      await _sheetsService.init(AppConfig.spreadsheetId);
      statusMessage.value = '';
    } catch (e, stack) {
      statusMessage.value = 'Error initializing: $e';
      print(e);
      print(stack);

      Get.defaultDialog(
        title: 'Error Debugging',
        titleStyle: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
        content: Container(
          height: 400,
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Error:', style: TextStyle(fontWeight: FontWeight.bold)),
                SelectableText(e.toString()),
                Divider(),
                Text(
                  'Stack Trace:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SelectableText(stack.toString()),
              ],
            ),
          ),
        ),
        textConfirm: 'OK',
        confirmTextColor: Colors.white,
        onConfirm: () => Get.back(),
        barrierDismissible: false,
      );
    }
  }

  // Get or Create Controller for a specific field name
  TextEditingController getControllerFor(String fieldName) {
    if (!formControllers.containsKey(fieldName)) {
      formControllers[fieldName] = TextEditingController();
    }
    return formControllers[fieldName]!;
  }

  // Pick Image
  Future<void> pickImage(ImageSource source) async {
    if (source == ImageSource.camera) {
      // Use Google ML Kit Document Scanner
      try {
        final options = DocumentScannerOptions(
          mode: ScannerMode.full, // Full scanner UI
          isGalleryImport: true, // Allow importing from gallery inside scanner
          pageLimit: 1, // Limit to 1 page for now
        );

        final scanner = DocumentScanner(options: options);
        final result = await scanner.scanDocument();

        // Handle result
        if (result.images.isNotEmpty) {
          // Result gives us absolute paths
          selectedImage.value = File(result.images.first);
        }
      } catch (e) {
        // If user cancels, it throws an error or just returns empty depending on plugin version.
        // Usually cancellation isn't an 'error' to show, but actual failures are.
        print('Scanner Error or Cancel: $e');
        if (!e.toString().contains('canceled')) {
          Get.snackbar('Error', 'Gagal scan dokumen: $e');
        }
      }
    } else {
      // Use Standard Gallery Picker via ImagePicker
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: source);

      if (pickedFile != null) {
        selectedImage.value = File(pickedFile.path);
      }
    }
  }

  // Submit Dynamic Form
  Future<void> submitDynamicArsip(MenuItem menuItem) async {
    // 1. Validate Fields
    for (var field in menuItem.fields) {
      if (getControllerFor(field).text.isEmpty) {
        Get.snackbar('Error', 'Field "$field" harus diisi');
        return;
      }
    }

    if (selectedImage.value == null) {
      Get.snackbar('Error', 'Harap pilih foto surat/dokumen');
      return;
    }

    try {
      isLoading.value = true;

      // 2. Upload to Drive
      statusMessage.value = 'Uploading to Drive...';
      final driveLink = await _authService.uploadToDrive(
        selectedImage.value!,
        folderId: AppConfig.driveFolderId,
      );

      if (driveLink == null) {
        throw Exception('Gagal upload ke Google Drive');
      }

      // 3. Prepare Data for Sheets
      statusMessage.value = 'Saving to Sheets...';

      final Map<String, dynamic> data = {};
      for (var field in menuItem.fields) {
        data[field] = getControllerFor(field).text;
      }
      data['Link Foto'] = driveLink;

      // 4. Insert to Sheets
      final success = await _sheetsService.insertArsip(
        menuItem.sheetTitle,
        menuItem.fields,
        data,
      );

      if (success) {
        Get.snackbar(
          'Success',
          'Data "${menuItem.title}" berhasil disimpan!',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        _resetForm();
        Get.back(); // Return to dashboard
      } else {
        throw Exception('Gagal menyimpan ke Google Sheets');
      }
    } catch (e, stack) {
      // Show Detailed Error Dialog
      Get.defaultDialog(
        title: 'Upload Failed',
        titleStyle: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
        content: Container(
          height: 300,
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Error Message:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SelectableText(e.toString()),
                Divider(),
                Text(
                  'Stack Trace:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SelectableText(stack.toString()),
              ],
            ),
          ),
        ),
        textConfirm: 'Tutup',
        confirmTextColor: Colors.white,
        onConfirm: () => Get.back(),
      );
      print(e);
      print(stack);
    } finally {
      isLoading.value = false;
      statusMessage.value = '';
    }
  }

  void _resetForm() {
    for (var c in formControllers.values) {
      c.clear();
    }
    selectedImage.value = null;
  }

  // --- Global Search Logic ---
  Future<List<SearchResult>> searchGlobal(String query) async {
    if (query.trim().isEmpty) return [];

    final results = <SearchResult>[];
    final q = query.toLowerCase();

    // 1. Fetch from all configured menus in parallel
    // We strictly have 2 menus now: Admin Umum & Kependudukan
    final futures = MenuConfig.mainMenus.map((menu) async {
      // Fetch full list (this might be heavy if thousands of rows, but ok for small village archives)
      final rows = await _sheetsService.fetchArsip(menu.sheetTitle);

      // Filter rows
      final matches = rows.where((row) {
        // Check all values in the row
        return row.values.any(
          (val) => val.toString().toLowerCase().contains(q),
        );
      }).toList();

      return matches.map((row) => SearchResult(row, menu.title, menu)).toList();
    });

    // 2. Wait for all to complete
    final fetchedLists = await Future.wait(futures);

    // 3. Flatten
    for (var list in fetchedLists) {
      results.addAll(list);
    }

    return results;
  }
}
