// ignore_for_file: use_build_context_synchronously

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:mycoolid/screens/about_app_screen.dart';
import 'package:mycoolid/utils/show_attendance_mode_validate_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;

class DraggableSheet extends StatefulWidget {
  final MobileScannerController mobileScannerController;
  final ValueChanged<bool> onSwitchChanged;
  final String? androidId;
  final ValueNotifier<bool> isAttendanceEnabledNotifier;
  final Function(bool) onCameraToggle;

  const DraggableSheet({
    super.key,
    required this.mobileScannerController,
    required this.onSwitchChanged,
    required this.androidId,
    required this.isAttendanceEnabledNotifier,
    required this.onCameraToggle,
  });

  @override
  State<DraggableSheet> createState() => _DraggableSheetState();
}

class _DraggableSheetState extends State<DraggableSheet> {
  bool isSwitched = false;
  bool isTorchOn = false;
  final AudioPlayer player = AudioPlayer();
  final ValueNotifier<String?> schoolNameNotifier =
      ValueNotifier<String?>(null);
  bool isFrontCamera = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      isSwitched = prefs.getBool('scanSound') ?? false;
      isFrontCamera = prefs.getBool('isFrontCamera') ?? true;
      isTorchOn = prefs.getBool('torchState') ?? false;
      widget.isAttendanceEnabledNotifier.value =
          prefs.getBool('attendanceEnabled') ?? false;

      schoolNameNotifier.value = prefs.getString('schoolName');
    });
  }

  Future<void> _saveTorchState(bool value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('torchState', value);
  }

  Future<void> _saveAttendanceMode(bool value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('attendanceEnabled', value);
  }

  void toggleCamera(bool value) async {
    setState(() {
      isFrontCamera = value;
    });
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isFrontCamera', value);
    widget.onCameraToggle(value);
  }

  void toggleSwitch(bool value) {
    setState(() {
      isSwitched = value;
    });
  }

  void toggleTorch() {
    setState(() {
      isTorchOn = !isTorchOn;
    });
    widget.mobileScannerController.toggleTorch();
    _saveTorchState(isTorchOn);
  }

  Future<void> _attendanceModeValidate() async {
    String? androidId = widget.androidId;
    if (androidId != null) {
      const url = 'https://mcid.in/app/att2.php';
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {'param': 'VALID~$androidId'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> result = jsonDecode(response.body);

        if (result['result'] != null) {
          final parsedResult = result['result'].toString();

          // Parse result to extract school name
          if (parsedResult.startsWith('N~')) {
            final parts = parsedResult.split('~');
            if (parts.length > 1) {
              final schoolName = parts[1];
              schoolNameNotifier.value = schoolName;

              // Save schoolName to SharedPreferences
              SharedPreferences prefs = await SharedPreferences.getInstance();
              await prefs.setString('schoolName', schoolName);

              player
                ..setAsset('assets/blip.mp3')
                ..play();
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Unexpected response format')),
              );
            }
          } else if (parsedResult.contains('P~')) {
            player
              ..setAsset('assets/2message.mp3')
              ..play();

            showAttendanceModeValidateDialog(
                context, parsedResult.split('~')[1]);
          }
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cannot connect to server')),
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

      await player.setAudioSource(AudioSource.uri(Uri.parse(correctedUrl)));
      await player.play();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot play the sound')),
      );
    }
  }

  void toggleAttendanceMode() async {
    if (!widget.isAttendanceEnabledNotifier.value) {
      await _attendanceModeValidate();

      setState(() {
        widget.isAttendanceEnabledNotifier.value = true;
      });
      _saveAttendanceMode(true);
    } else {
      setState(() {
        widget.isAttendanceEnabledNotifier.value = false;
        schoolNameNotifier.value = null;
      });

      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove('schoolName');

      _saveAttendanceMode(false);
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
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.5),
            borderRadius: const BorderRadius.only(
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
              ValueListenableBuilder<String?>(
                valueListenable: schoolNameNotifier,
                builder: (context, schoolName, child) {
                  return schoolName != null
                      ? Padding(
                          padding: const EdgeInsets.symmetric(vertical: 1.0),
                          child: Text(
                            schoolName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      : const SizedBox.shrink();
                },
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
                          _buildIconButton(
                            'assets/button_close.png',
                            'Close\nApp',
                            () => SystemNavigator.pop(),
                          ),
                          _buildIconButton(
                            'assets/button_open_mcid.png',
                            'Open\nMyCool ID',
                            () async {
                              final Uri uri =
                                  Uri(host: 'mycoolid.com', scheme: 'https');
                              try {
                                await launchUrl(uri,
                                    mode: LaunchMode.externalApplication);
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error: $e')),
                                );
                              }
                            },
                          ),
                          _buildIconButton(
                            widget.isAttendanceEnabledNotifier.value
                                ? 'assets/button_my_school.png'
                                : 'assets/button_my_school_disable.png',
                            'Switch To\nAttendance',
                            toggleAttendanceMode,
                          ),
                          _buildIconButton(
                            'assets/button_flash_light.png',
                            'Mobile\nFlash Light',
                            toggleTorch,
                          ),
                          Column(
                            children: [
                              PopupMenuButton<String>(
                                onSelected: (String value) {},
                                itemBuilder: (BuildContext context) => [
                                  PopupMenuItem<String>(
                                    value: 'Switch',
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        ValueListenableBuilder<bool>(
                                          valueListenable:
                                              ValueNotifier(isSwitched),
                                          builder: (context, value, _) {
                                            return Text(value
                                                ? 'Scan Sound On'
                                                : 'Scan Sound Off');
                                          },
                                        ),
                                        Switch(
                                          value: isSwitched,
                                          onChanged: (bool value) async {
                                            setState(() {
                                              isSwitched = value;
                                            });
                                            toggleSwitch(value);
                                            widget.onSwitchChanged(value);

                                            SharedPreferences prefs =
                                                await SharedPreferences
                                                    .getInstance();
                                            await prefs.setBool(
                                                'scanSound', value);

                                            Navigator.of(context).pop();
                                          },
                                          activeColor: Colors.cyan,
                                        ),
                                      ],
                                    ),
                                  ),
                                  PopupMenuItem<String>(
                                    value: 'Camera',
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        ValueListenableBuilder<bool>(
                                          valueListenable:
                                              ValueNotifier(isFrontCamera),
                                          builder: (context, value, _) {
                                            return Text(value
                                                ? 'Front Camera'
                                                : 'Back Camera');
                                          },
                                        ),
                                        Switch(
                                          value: isFrontCamera,
                                          onChanged: (bool value) async {
                                            setState(() {
                                              isFrontCamera = value;
                                            });
                                            toggleCamera(value);

                                            SharedPreferences prefs =
                                                await SharedPreferences
                                                    .getInstance();
                                            await prefs.setBool(
                                                'isFrontCamera', value);

                                            Navigator.of(context).pop();
                                          },
                                          activeColor: Colors.cyan,
                                        ),
                                      ],
                                    ),
                                  ),
                                  PopupMenuItem<String>(
                                    value: 'Camera',
                                    child: TextButton(
                                      onPressed: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                const AboutAppScreen(),
                                          ),
                                        );
                                      },
                                      child: const Text(
                                        'About App',
                                        style: TextStyle(color: Colors.black),
                                      ),
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

  Widget _buildIconButton(
      String assetPath, String label, VoidCallback onPressed) {
    return Column(
      children: [
        IconButton(
          onPressed: onPressed,
          icon: Image.asset(
            assetPath,
            width: MediaQuery.of(context).size.width * 0.15,
            height: MediaQuery.of(context).size.width * 0.15,
          ),
        ),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.cyan),
        ),
      ],
    );
  }
}
