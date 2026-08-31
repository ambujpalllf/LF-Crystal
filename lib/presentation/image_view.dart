import 'dart:io';
import 'package:flutter/material.dart';
import 'package:lf_crystal/model/image_entity_model.dart';
import 'package:photo_view/photo_view.dart';

class ImageViewPage extends StatelessWidget {
  final ImageEntity imageData;

  const ImageViewPage({super.key, required this.imageData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: PhotoView(
        imageProvider: FileImage(File(imageData.imagePath)),
        backgroundDecoration: const BoxDecoration(color: Colors.black),
        minScale: PhotoViewComputedScale.contained,
        maxScale: PhotoViewComputedScale.covered * 3.0,
        enableRotation: false,
      ),
    );
  }
}
