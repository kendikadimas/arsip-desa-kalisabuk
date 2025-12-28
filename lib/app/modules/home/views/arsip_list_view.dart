import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:kalisabuk_arsip_desa/app/data/menu_config.dart';
import '../controllers/home_controller.dart';
import 'arsip_form_view.dart';

class ArsipListView extends GetView<HomeController> {
  final MenuItem menuItem;

  const ArsipListView({Key? key, required this.menuItem}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Determine the main identifier field (usually the first one after No)
    // We'll use this for the list title.
    final titleField = menuItem.fields.isNotEmpty ? menuItem.fields[0] : 'Data';
    final subtitleField = menuItem.fields.length > 1 ? menuItem.fields[1] : '';

    // Trigger fetch on load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.fetchData(menuItem.sheetTitle);
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(menuItem.title),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () => controller.fetchData(menuItem.sheetTitle),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(child: CircularProgressIndicator());
        }

        if (controller.currentDataList.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.folder_off, size: 60, color: Colors.grey),
                SizedBox(height: 10),
                Text('Belum ada data arsip.'),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(10),
          itemCount: controller.currentDataList.length,
          itemBuilder: (context, index) {
            // Data is reversed to show newest first if typical append
            // But let's keep it simple: index 0 is first row.
            // To show newest first, we can reverse access:
            final data = controller
                .currentDataList[controller.currentDataList.length - 1 - index];

            return Card(
              elevation: 2,
              margin: EdgeInsets.symmetric(vertical: 5),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blue[100],
                  child: Text(data['No'] ?? '#'),
                ),
                title: Text(
                  data[titleField] ?? '-',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (subtitleField.isNotEmpty)
                      Text('$subtitleField: ${data[subtitleField] ?? '-'}'),

                    // Show dates if any field has "tanggal"
                    ...menuItem.fields
                        .where(
                          (f) =>
                              f.toLowerCase().contains('tanggal') &&
                              f != subtitleField,
                        )
                        .map(
                          (f) => Text(
                            '$f: ${data[f] ?? '-'}',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (data['Link Foto'] != null && data['Link Foto'] != '-')
                      IconButton(
                        icon: Icon(Icons.open_in_new, color: Colors.blue),
                        onPressed: () => _launchURL(data['Link Foto']!),
                      ),
                    Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                  ],
                ),
                onTap: () {
                  // Show detail dialog
                  _showDetailDialog(context, data);
                },
              ),
            );
          },
        );
      }),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Get.to(() => ArsipFormView(menuItem: menuItem));
          // Refresh after coming back
          controller.fetchData(menuItem.sheetTitle);
        },
        label: Text('Tambah Data'),
        icon: Icon(Icons.add),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
      ),
    );
  }

  void _showDetailDialog(BuildContext context, Map<String, String> data) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Padding(
          padding: EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Detail Data',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                Divider(),
                ...data.entries.map((e) {
                  if (e.key == 'Link Foto') return SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            e.key,
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          flex: 3,
                          child: Text(
                            e.value,
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                SizedBox(height: 20),
                if (data['Link Foto'] != null && data['Link Foto'] != '-')
                  ElevatedButton.icon(
                    onPressed: () => _launchURL(data['Link Foto']!),
                    icon: Icon(Icons.image),
                    label: Text('Lihat Foto / Dokumen'),
                  ),
                SizedBox(height: 10),
                OutlinedButton(
                  onPressed: () => Get.back(),
                  child: Text('Tutup'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      Get.snackbar('Error', 'Could not launch $url');
    }
  }
}
