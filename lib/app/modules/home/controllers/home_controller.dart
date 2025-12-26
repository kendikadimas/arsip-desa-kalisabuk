import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../../config/app_config.dart';
import '../../../services/google_auth_service.dart';
import '../../../services/sheets_service.dart';

class HomeController extends GetxController {
  // Services
  final GoogleAuthService _authService = GoogleAuthService();
  late SheetsService _sheetsService;

  // Form Controllers
  final noSuratC = TextEditingController();
  final perihalC = TextEditingController();
  final tanggalC = TextEditingController();

  // State
  var selectedImage = Rx<File?>(null);
  var isLoading = false.obs;
  var statusMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _sheetsService = SheetsService(_authService);
    // Initialize services
    _initServices();
  }

  Future<void> _initServices() async {
    try {
      statusMessage.value = 'Initializing Google Services...';
      await _authService.init();
      await _sheetsService.init(AppConfig.spreadsheetId);
      statusMessage.value = '';
    } catch (e) {
      statusMessage.value = 'Error initializing: $e';
      print(e);
      Get.snackbar('Error', 'Failed to connect to Google Services. Check Config & Credentials.',
          backgroundColor: Colors.redAccent, colorText: Colors.white);
    }
  }

  // Pick Image
  Future<void> pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      selectedImage.value = File(pickedFile.path);
    }
  }

  // Set Date
  void setDate(DateTime date) {
    tanggalC.text = DateFormat('yyyy-MM-dd').format(date);
  }

  // Submit Form
  Future<void> submitArsip() async {
    if (noSuratC.text.isEmpty || perihalC.text.isEmpty || tanggalC.text.isEmpty) {
      Get.snackbar('Error', 'Semua field (No Surat, Perihal, Tanggal) harus diisi');
      return;
    }

    if (selectedImage.value == null) {
      Get.snackbar('Error', 'Harap pilih foto surat/dokumen');
      return;
    }

    // Check config
    if (AppConfig.spreadsheetId == 'YOUR_SPREADSHEET_ID_HERE' || 
        AppConfig.driveFolderId == 'YOUR_DRIVE_FOLDER_ID_HERE') {
      Get.snackbar('Config Error', 'Harap update AppConfig dengan ID yang benar!');
      return;
    }

    try {
      isLoading.value = true;
      
      // 1. Upload to Drive
      statusMessage.value = 'Uploading to Drive...';
      final driveLink = await _authService.uploadToDrive(
        selectedImage.value!, 
        folderId: AppConfig.driveFolderId
      );

      if (driveLink == null) {
        throw Exception('Gagal upload ke Google Drive');
      }

      // 2. Insert to Sheets
      statusMessage.value = 'Saving to Sheets...';
      final success = await _sheetsService.insertArsip({
        'noSurat': noSuratC.text,
        'perihal': perihalC.text,
        'tanggal': tanggalC.text,
        'linkFoto': driveLink,
      });

      if (success) {
        Get.snackbar('Success', 'Data berhasil diawetan!',
            backgroundColor: Colors.green, colorText: Colors.white);
        _resetForm();
      } else {
        throw Exception('Gagal menyimpan ke Google Sheets');
      }

    } catch (e) {
      Get.snackbar('Error', 'Terjadi kesalahan: $e',
          backgroundColor: Colors.red, colorText: Colors.white);
      print(e);
    } finally {
      isLoading.value = false;
      statusMessage.value = '';
    }
  }

  void _resetForm() {
    noSuratC.clear();
    perihalC.clear();
    tanggalC.clear();
    selectedImage.value = null;
  }
}
