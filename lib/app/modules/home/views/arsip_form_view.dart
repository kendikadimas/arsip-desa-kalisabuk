import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:kalisabuk_arsip_desa/app/data/menu_config.dart';
import '../controllers/home_controller.dart';

class ArsipFormView extends GetView<HomeController> {
  final MenuItem menuItem;

  const ArsipFormView({Key? key, required this.menuItem}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Reset form and prepare controllers for this specific menu item whenever opened
    // Ideally this should be done in controller, but for simplicity triggering it here
    // or ensuring controller has a method to setup.
    // However, since we are reusing the controller, we need to make sure we don't conflicting state.
    // A better approach: call a setup method in Controller when entering this page.

    // We will assume the controller is already put in HomeView.

    return Scaffold(
      appBar: AppBar(title: Text(menuItem.title), centerTitle: true),
      body: Obx(() {
        return Stack(
          children: [
            SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Dynamic Fields
                  ...menuItem.fields.map((field) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 15.0),
                      child: _buildField(field, context),
                    );
                  }).toList(),

                  SizedBox(height: 10),

                  // Image Picker
                  Text(
                    'Foto Dokumen / Bukti:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  GestureDetector(
                    onTap: () => _showPicker(context),
                    child: Container(
                      height: 200,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.grey[100],
                      ),
                      child: controller.selectedImage.value == null
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.camera_alt,
                                  size: 50,
                                  color: Colors.grey,
                                ),
                                Text('Tap untuk ambil/pilih foto'),
                              ],
                            )
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.file(
                                controller.selectedImage.value!,
                                fit: BoxFit.cover,
                                width: double.infinity,
                              ),
                            ),
                    ),
                  ),

                  SizedBox(height: 30),

                  // Submit
                  ElevatedButton.icon(
                    onPressed: controller.isLoading.value
                        ? null
                        : () => controller.submitDynamicArsip(menuItem),
                    icon: Icon(Icons.cloud_upload),
                    label: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      child: Text(
                        'SIMPAN DATA',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[800],
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            // Loading
            if (controller.isLoading.value)
              Container(
                color: Colors.black45,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 20),
                      Text(
                        controller.statusMessage.value,
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      }),
    );
  }

  Widget _buildField(String fieldName, BuildContext context) {
    // 1. Handle Simplified Dropdowns
    if (fieldName == 'Jenis Surat') {
      return _buildDropdown(fieldName, [
        'Surat Masuk',
        'Surat Keluar',
        'Undangan',
      ]);
    } else if (fieldName == 'Jenis Layanan') {
      return _buildDropdown(fieldName, [
        'Surat Pengantar',
        'SKTM',
        'Ket. Usaha',
        'Lainnya',
      ]);
    } else if (fieldName.contains('Keterangan') &&
        !fieldName.contains('Surat')) {
      // Just Text Area for Keterangan
    }

    // 2. Determine input type based on keywords
    final isDate = fieldName.toLowerCase().contains('tanggal');

    final isNumber =
        fieldName.toLowerCase().contains(
          'nomor',
        ) || // No. Surat usually alphanumeric but checking
        fieldName.toLowerCase().contains('nik') ||
        fieldName.toLowerCase().contains('nilai');

    final isLongText =
        fieldName.toLowerCase().contains('perihal') ||
        fieldName.toLowerCase().contains('keterangan');

    return TextField(
      controller: controller.getControllerFor(fieldName),
      readOnly: fieldName.toLowerCase().contains(
        'tanggal',
      ), // Only strict dates are read-only Picker
      maxLines: isLongText ? 3 : 1,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      onTap: fieldName.toLowerCase().contains('tanggal')
          ? () => _pickDate(context, fieldName)
          : null,
      decoration: InputDecoration(
        labelText: fieldName,
        border: OutlineInputBorder(),
        prefixIcon: fieldName.toLowerCase().contains('tanggal')
            ? Icon(Icons.calendar_today)
            : (isNumber ? Icon(Icons.numbers) : Icon(Icons.text_fields)),
      ),
    );
  }

  Widget _buildDropdown(String fieldName, List<String> items) {
    // Ensure controller has text if not empty
    final textCtrl = controller.getControllerFor(fieldName);

    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: fieldName,
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.arrow_drop_down_circle),
      ),
      value: textCtrl.text.isEmpty ? null : textCtrl.text,
      items: items
          .map((item) => DropdownMenuItem(value: item, child: Text(item)))
          .toList(),
      onChanged: (val) {
        if (val != null) {
          textCtrl.text = val;
        }
      },
      validator: (val) => val == null ? 'Harap pilih $fieldName' : null,
    );
  }

  Future<void> _pickDate(BuildContext context, String fieldName) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (date != null) {
      final formatted = DateFormat(
        'yyyy-MM-dd',
      ).format(date); // Or just yyyy for year

      // If just 'Tahun', maybe we just want year? But for simplicity keeping full date format
      // or letting user type if they want specific format.
      // Modifying logic: If field is strictly 'Tahun' maybe show YearPicker?
      // For now standard DatePicker is safer.

      controller.getControllerFor(fieldName).text = formatted;
    }
  }

  void _showPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: Icon(Icons.photo_library),
                title: Text('Galeri'),
                onTap: () {
                  controller.pickImage(ImageSource.gallery);
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_camera),
                title: Text('Kamera'),
                onTap: () {
                  controller.pickImage(ImageSource.camera);
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
