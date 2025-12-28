import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kalisabuk_arsip_desa/app/data/menu_config.dart';
import 'package:kalisabuk_arsip_desa/app/modules/home/controllers/home_controller.dart';
import 'package:kalisabuk_arsip_desa/app/modules/home/views/arsip_list_view.dart';
import 'package:url_launcher/url_launcher.dart';

class GlobalSearchDelegate extends SearchDelegate {
  final HomeController controller = Get.find<HomeController>();

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildResultsList(context, true);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 80, color: Colors.grey[300]),
            Text(
              'Cari Nama, NIK, Surat, atau Menu...',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }
    return _buildResultsList(context, false);
  }

  Widget _buildResultsList(BuildContext context, bool isResultView) {
    final q = query.toLowerCase();

    // 1. Search Categories (Navigation Suggestions)
    final menuMatches = MenuConfig.mainMenus.where((menu) {
      // Search by Title, or by known keywords in that category
      final titleMatch = menu.title.toLowerCase().contains(q);
      final fieldsMatch = menu.fields.any((f) => f.toLowerCase().contains(q));

      // Keywords mapping (Hardcoded or smart)
      // e.g. "KK" -> Kependudukan
      bool keywordMatch = false;
      if (menu.title.contains('Kependudukan')) {
        if (q.contains('kk') ||
            q.contains('ktp') ||
            q.contains('mati') ||
            q.contains('sktm')) {
          keywordMatch = true;
        }
      } else if (menu.title.contains('Administrasi')) {
        if (q.contains('surat') ||
            q.contains('undangan') ||
            q.contains('disposisi')) {
          keywordMatch = true;
        }
      }

      return titleMatch || fieldsMatch || keywordMatch;
    }).toList();

    // Only fetch actual data if user pressed enter (buildResults) or query is long enough to avoid spam
    // For now, let's fetch data async in FutureBuilder if isResultView is true.
    // If it's suggestions, maybe just show Menu matches + "Press enter to search data".

    return ListView(
      padding: EdgeInsets.all(10),
      children: [
        // --- Navigation Suggestions ---
        if (menuMatches.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Menu / Input Data',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
            ),
          ),
          ...menuMatches.map(
            (menu) => Card(
              child: ListTile(
                leading: Icon(menu.icon, color: menu.color),
                title: Text(menu.title),
                subtitle: Text('Buka halaman ini untuk input/lihat data'),
                trailing: Icon(Icons.arrow_forward),
                onTap: () {
                  close(context, null);
                  Get.to(() => ArsipListView(menuItem: menu));
                },
              ),
            ),
          ),
          Divider(),
        ],

        // --- Data Search Results ---
        if (isResultView) ...[
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Hasil Pencarian Data',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ),
          FutureBuilder<List<SearchResult>>(
            future: controller.searchGlobal(query),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              }
              final results = snapshot.data ?? [];
              if (results.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Text(
                    'Tidak ditemukan data arsip dengan kata kunci "$query".',
                  ),
                );
              }

              return Column(
                children: results.map((res) {
                  final data = res.data;
                  // Try to find a good "Title"
                  String title =
                      data['Nama Warga'] ??
                      data['Perihal'] ??
                      data['No. Surat'] ??
                      'Data';
                  String subtitle =
                      data['NIK'] ??
                      data['Pengirim'] ??
                      data['No. Surat'] ??
                      '';
                  String date = data['Tanggal'] ?? data['Tanggal Surat'] ?? '-';

                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 5),
                    child: ListTile(
                      leading: Icon(
                        res.menuItem.icon,
                        color: res.menuItem.color,
                      ),
                      title: Text(
                        title,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${res.sourceCategory} • $date'),
                          if (subtitle.isNotEmpty)
                            Text(subtitle, style: TextStyle(fontSize: 12)),
                        ],
                      ),
                      trailing:
                          (data['Link Foto'] != null &&
                              data['Link Foto'] != '-')
                          ? Icon(Icons.image, color: Colors.blue)
                          : null,
                      onTap: () {
                        // We can reuse the detail dialog logic from ArsipListView if we refactor it,
                        // or just show a simple dialog here.
                        _showDetailDialog(context, data);
                      },
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ] else ...[
          // If in suggestion mode, suggest searching
          ListTile(
            leading: Icon(Icons.search),
            title: Text('Cari data "$query"...'),
            onTap: () {
              showResults(context);
            },
          ),
        ],
      ],
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
                  'Detail Pencarian',
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
                            style: TextStyle(color: Colors.grey[700]),
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
                    onPressed: () async {
                      final uri = Uri.parse(data['Link Foto']!);
                      if (!await launchUrl(
                        uri,
                        mode: LaunchMode.externalApplication,
                      )) {
                        Get.snackbar('Error', 'Could not launch url');
                      }
                    },
                    icon: Icon(Icons.image),
                    label: Text('Lihat Dokumen'),
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
}
