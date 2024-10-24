// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

void showUrlDialog(BuildContext context, String url, Function onDialogClose,
    Function onDialogOpen) {
  onDialogOpen();
  showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Center(child: Text(url)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      final Uri uri = Uri.parse(url);
                      try {
                        await launchUrl(uri);
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Could not launch url'),
                          ),
                        );
                      }
                      Navigator.of(context).pop();
                    },
                    child: const Row(
                      children: [
                        Icon(Icons.launch),
                        SizedBox(width: 8),
                        Text('Open Link'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: url));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Link copied to clipboard'),
                          ),
                        );
                      },
                      icon: const Icon(Icons.copy),
                    ),
                    const Text('Copy'),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        Share.share(url);
                      },
                      icon: const Icon(Icons.share),
                    ),
                    const Text('Share'),
                  ],
                ),
              ],
            ),
          ],
        );
      }).then((_) => onDialogClose());
}
