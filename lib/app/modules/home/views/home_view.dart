import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/home_controller.dart';
import 'package:image_picker/image_picker.dart';

class HomeView extends GetView<HomeController> {
  @override
  Widget build(BuildContext context) {
    // Inject Controller
    Get.put(HomeController());

    return Scaffold(
      appBar: AppBar(title: Text('Input Arsip Desa'), centerTitle: true),
      body: Obx(() {
        // Loading Overlay
        return Stack(
          children: [
            SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Status Init Check
                  if (controller.statusMessage.value.isNotEmpty &&
                      !controller.isLoading.value)
                    Container(
                      padding: EdgeInsets.all(10),
                      color: Colors.amber.withOpacity(0.2),
                      child: Text(controller.statusMessage.value),
                    ),

                  SizedBox(height: 10),

                  // Form Fields
                  TextField(
                    controller: controller.noSuratC,
                    decoration: InputDecoration(
                      labelText: 'Nomor Surat',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.numbers),
                    ),
                  ),
                  SizedBox(height: 15),

                  TextField(
                    controller: controller.perihalC,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: 'Perihal / Keterangan',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.description),
                    ),
                  ),
                  SizedBox(height: 15),

                  TextField(
                    controller: controller.tanggalC,
                    readOnly: true,
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (date != null) {
                        controller.setDate(date);
                      }
                    },
                    decoration: InputDecoration(
                      labelText: 'Tanggal Surat',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.calendar_today),
                      suffixIcon: Icon(Icons.arrow_drop_down),
                    ),
                  ),

                  SizedBox(height: 25),

                  // Image Picker Section
                  Text(
                    'Foto Dokumen:',
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

                  // Submit Button
                  ElevatedButton.icon(
                    onPressed: controller.isLoading.value
                        ? null
                        : () => controller.submitArsip(),
                    icon: Icon(Icons.cloud_upload),
                    label: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      child: Text(
                        'SIMPAN ARSIP',
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

            // Loading Indicator
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
