import 'package:flutter/material.dart';

class MenuItem {
  final String title;
  final String sheetTitle; // Tab name in Google Sheets
  final List<String> fields; // Column headers (excluding 'No' and 'Link Foto')
  final IconData icon;
  final Color color; // Added for customized card color

  const MenuItem({
    required this.title,
    required this.sheetTitle,
    required this.fields,
    required this.icon,
    this.color = Colors.blue,
  });
}

// Simplified: We don't strictly need MenuCategory nesting anymore if we just have 2 main items,
// but to keep compatibility with existing Controllers that expect structure, we can adapt.
// However, User asked for "2 Menu Utama" which behave like Categories.
// Let's redefine MenuConfig to just expose these 2 Main Items directly.

class MenuConfig {
  static const List<MenuItem> mainMenus = [
    MenuItem(
      title: 'Administrasi Umum',
      sheetTitle: 'AdminUmum',
      // Fields corresponding to: no_surat, tanggal_surat, pengirim, perihal, jenis
      fields: [
        'No. Surat',
        'Tanggal Surat',
        'Pengirim',
        'Perihal',
        'Jenis Surat',
      ],
      icon: Icons.mark_email_unread_outlined,
      color: Colors.blue,
    ),
    MenuItem(
      title: 'Layanan Kependudukan',
      sheetTitle: 'Kependudukan',
      // Fields corresponding to: nik, nama_warga, jenis_layanan, tanggal, keterangan
      fields: ['NIK', 'Nama Warga', 'Jenis Layanan', 'Tanggal', 'Keterangan'],
      icon: Icons.groups_outlined,
      color: Colors.green,
    ),
  ];
}
