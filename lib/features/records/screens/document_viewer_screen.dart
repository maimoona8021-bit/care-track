import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';

import 'package:sehatfile/core/theme/app_colors.dart';

class DocumentViewerScreen extends StatelessWidget {
  final String documentUrl;
  final String documentName;
  final String documentType;

  const DocumentViewerScreen({
    super.key,
    required this.documentUrl,
    required this.documentName,
    required this.documentType,
  });

  bool get _isPdf {
    final String type = documentType.toLowerCase();
    final String name = documentName.toLowerCase();

    return type == 'application/pdf' ||
        name.endsWith('.pdf');
  }

  bool get _isImage {
    final String type = documentType.toLowerCase();
    final String name = documentName.toLowerCase();

    return type.startsWith('image/') ||
        name.endsWith('.jpg') ||
        name.endsWith('.jpeg') ||
        name.endsWith('.png');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          documentName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),

      body: SafeArea(
        child: _buildViewer(),
      ),
    );
  }

  Widget _buildViewer() {
    if (_isPdf) {
      return PdfViewer.uri(
        Uri.parse(documentUrl),
      );
    }

    if (_isImage) {
      return Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.black,
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 5,
          child: Center(
            child: Image.network(
              documentUrl,
              fit: BoxFit.contain,

              loadingBuilder: (
                  context,
                  child,
                  loadingProgress,
                  ) {
                if (loadingProgress == null) {
                  return child;
                }

                return const Center(
                  child: CircularProgressIndicator(),
                );
              },

              errorBuilder: (
                  context,
                  error,
                  stackTrace,
                  ) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Unable to load this image.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.insert_drive_file_outlined,
              size: 60,
              color: AppColors.primary,
            ),

            const SizedBox(
              height: 16,
            ),

            const Text(
              'This file type cannot be previewed.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}