// ignore_for_file: use_build_context_synchronously

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;

class DraggableSheet extends StatefulWidget {
  final MobileScannerController mobileScannerController;
  final ValueChanged<bool> onSwitchChanged;
  final String? androidId;

  const DraggableSheet({
    super.key,
    required this.mobileScannerController,
    required this.onSwitchChanged,
    required this.androidId,
  });

  @override
  State<DraggableSheet> createState() => _DraggableSheetState();
}

class _DraggableSheetState extends State<DraggableSheet> {
  bool isEnabled = false;
  bool isSwitched = false;
  bool isTrochOn = false;
  final AudioPlayer player = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      isSwitched = prefs.getBool('scanSound') ?? false;
      isTrochOn = prefs.getBool('torchState') ?? false;
    });
  }

  Future<void> _saveTorchState(bool value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('torchState', value);
  }

  void toggleSwitch(bool value) {
    setState(() {
      isSwitched = value;
    });
  }

  void toggleButton() async {
    await _attendanceModeValidate();
    setState(() {
      isEnabled = !isEnabled;
    });
  }

  void toggleTorch() {
    setState(() {
      isTrochOn = !isTrochOn;
    });
    widget.mobileScannerController.toggleTorch();
    _saveTorchState(isTrochOn);
  }

  Future<void> _attendanceModeValidate() async {
    String? androidId = widget.androidId;
    if (androidId != null) {
      final url = 'https://mcid.in/app/att.php?param=VALID~$androidId';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final Map<String, dynamic> result = jsonDecode(response.body);

        if (result['result'] != null) {
          final parsedResult = result['result'].toString();

          if (parsedResult.contains('N~1~')) {
            final soundUrl = parsedResult.split('~')[2];
            _playSound(soundUrl);
          } else if (parsedResult.contains('P~')) {
            final soundUrl = parsedResult.split('~')[2];
            _playSound(soundUrl);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(parsedResult.split('~')[1]),
              ),
            );
          }
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cannot connect to server'),
          ),
        );
      }
    }
  }

  Future<void> _playSound(String url) async {
    try {
      final correctedUrl = url
          .replaceAll(r'\\', '/')
          .replaceAll(r'\/', '/')
          .replaceFirst('https:/', 'https://');

      await player.setAudioSource(
        AudioSource.uri(
          Uri.parse(correctedUrl),
        ),
      );
      await player.play();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot play the sound'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.21,
      minChildSize: 0.2,
      maxChildSize: 0.5,
      builder: (BuildContext context, ScrollController scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color.fromARGB(255, 31, 29, 29),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(50),
              topRight: Radius.circular(50),
            ),
          ),
          child: Column(
            children: [
              Container(
                width: 50,
                height: 5,
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.all(1.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Column(
                            children: [
                              IconButton(
                                onPressed: () {
                                  SystemNavigator.pop();
                                },
                                icon: Image.asset(
                                  'assets/button_close.png',
                                  width:
                                      MediaQuery.of(context).size.width * 0.15,
                                  height:
                                      MediaQuery.of(context).size.width * 0.15,
                                ),
                              ),
                              const Text(
                                'Close\nApp',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.cyan),
                              ),
                            ],
                          ),
                          Column(
                            children: [
                              IconButton(
                                onPressed: () async {
                                  final Uri uri = Uri(
                                      host: 'mycoolid.com', scheme: 'https');
                                  try {
                                    await launchUrl(uri,
                                        mode: LaunchMode.externalApplication);
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Error: $e'),
                                      ),
                                    );
                                  }
                                },
                                icon: Image.asset(
                                  'assets/button_open_mcid.png',
                                  width:
                                      MediaQuery.of(context).size.width * 0.15,
                                  height:
                                      MediaQuery.of(context).size.width * 0.15,
                                ),
                              ),
                              const Text(
                                'Open\nMyCool ID',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.cyan),
                              ),
                            ],
                          ),
                          Column(
                            children: [
                              IconButton(
                                onPressed: () {
                                  toggleButton();
                                },
                                icon: Image.asset(
                                  isEnabled
                                      ? 'assets/button_my_school.png'
                                      : 'assets/button_my_school_disable.png',
                                  width:
                                      MediaQuery.of(context).size.width * 0.15,
                                  height:
                                      MediaQuery.of(context).size.width * 0.15,
                                ),
                              ),
                              const Text(
                                'Switch To\nAttendance',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.cyan),
                              ),
                            ],
                          ),
                          Column(
                            children: [
                              IconButton(
                                onPressed: () {
                                  toggleTorch();
                                },
                                icon: Image.asset(
                                  'assets/button_flash_light.png',
                                  width:
                                      MediaQuery.of(context).size.width * 0.15,
                                  height:
                                      MediaQuery.of(context).size.width * 0.15,
                                ),
                              ),
                              const Text(
                                'Mobile\nFlash Light',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.cyan),
                              ),
                            ],
                          ),
                          Column(
                            children: [
                              PopupMenuButton<String>(
                                onSelected: (String value) {},
                                itemBuilder: (BuildContext context) => [
                                  PopupMenuItem<String>(
                                    value: 'Switch',
                                    child: StatefulBuilder(
                                      builder: (BuildContext context,
                                          StateSetter setState) {
                                        return Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(isSwitched
                                                ? 'Scan Sound On'
                                                : 'Scan Sound Off'),
                                            Switch(
                                              value: isSwitched,
                                              onChanged: (bool value) {
                                                setState(() {
                                                  isSwitched = value;
                                                });
                                                toggleSwitch(value);
                                                widget.onSwitchChanged(value);
                                                Navigator.of(context).pop();
                                              },
                                              activeColor: Colors.cyan,
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                                  ),
                                ],
                                icon: Image.asset(
                                  'assets/button_more.png',
                                  width:
                                      MediaQuery.of(context).size.width * 0.15,
                                  height:
                                      MediaQuery.of(context).size.width * 0.15,
                                ),
                              ),
                              const Text(
                                'More\nFeatures',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.cyan),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
