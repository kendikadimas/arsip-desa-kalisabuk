import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'app/modules/home/views/home_view.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Arsip Desa',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: HomeView(),
      debugShowCheckedModeBanner: false,
    );
  }
}
