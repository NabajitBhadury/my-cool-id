// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

void showAttendanceModeValidateDialog(BuildContext context, String text) {
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
                    onPressed: () async {
                      final Uri uri = Uri.parse('https://www.mcid.in/atreg');
                      try {
                        await launchUrl(uri);
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Could not launch url'),
                          ),
                        );
                      }
                    },
                    child: const Row(
                      children: [
                        Icon(Icons.launch),
                        SizedBox(width: 8),
                        Text('Click to register'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      });
}
