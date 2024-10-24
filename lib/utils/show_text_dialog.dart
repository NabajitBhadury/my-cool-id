import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

void showTextDialog(BuildContext context, String text, Function onDialogClose,
    Function onDialogOpen) {
  onDialogOpen();
  showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Center(child: Text(text)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: text));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Text copied to clipboard'),
                        ),
                      );
                    },
                    child: const Row(
                      children: [
                        Icon(Icons.copy),
                        SizedBox(width: 8),
                        Text('Copy'),
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
                      onPressed: () async {
                        final String query = Uri.encodeComponent(text);
                        final Uri searchUrl =
                            Uri.parse('https://www.google.com/search?q=$query');
                        try {
                          await launchUrl(searchUrl);
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Could not launch url'),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.search),
                    ),
                    const Text('Search'),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        Share.share(text);
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
      }).then(
    (_) => onDialogClose(),
  );
}
