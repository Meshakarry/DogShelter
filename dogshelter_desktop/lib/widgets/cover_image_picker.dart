import 'dart:io';

import 'package:flutter/material.dart';

import 'dashed_dropzone.dart';

/// Cover-image dropzone used on the Psi/Dogadjaj/Obavijest forms - shows the existing image
/// (or a picked-but-not-yet-uploaded one), a "Zamijeni sliku" button once an image is set, and
/// an inline validation error.
class CoverImagePicker extends StatelessWidget {
  const CoverImagePicker({super.key, this.existingUrl, this.newImage, required this.onPick, this.errorText});

  final String? existingUrl;
  final File? newImage;
  final VoidCallback onPick;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final hasImage = newImage != null || existingUrl != null;
    return Column(
      children: [
        DashedDropzone(
          width: 240,
          height: 160,
          onTap: onPick,
          borderColor: errorText != null ? Theme.of(context).colorScheme.error : null,
          child: newImage != null
              ? Image.file(newImage!, fit: BoxFit.cover, width: 240, height: 160)
              : existingUrl != null
                  ? Image.network(
                      existingUrl!,
                      fit: BoxFit.cover,
                      width: 240,
                      height: 160,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Theme.of(context).colorScheme.secondaryContainer,
                        child: const Icon(Icons.broken_image_outlined),
                      ),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_photo_alternate_outlined,
                            size: 32, color: Theme.of(context).colorScheme.onSurfaceVariant),
                        const SizedBox(height: 8),
                        Text(
                          '+ Dodaj fotografiju',
                          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
        ),
        if (hasImage) ...[
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: onPick,
            icon: const Icon(Icons.upload_outlined, size: 18),
            label: const Text('Zamijeni sliku'),
          ),
        ],
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(errorText!, style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 13)),
          ),
      ],
    );
  }
}
