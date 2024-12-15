// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:mycoolid/screens/components/custom_border.dart';
import 'package:mycoolid/screens/components/draggable_sheet.dart';
import 'package:mycoolid/utils/show_text_dialog.dart';
import 'package:mycoolid/utils/show_url_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'components/scanner_clipper.dart';
import 'package:http/http.dart' as http;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late MobileScannerController _mobileScannerController;
  final ImagePicker _picker = ImagePicker();
  bool isScanSoundOn = false;
  String? androidId = 'Unknown';
  double _zoomLevel = 1.0;
  late String scanTime;
  final AudioPlayer player = AudioPlayer();
  final ValueNotifier<bool> isAttendanceEnabledNotifier = ValueNotifier(false);
  final List<String> _lastThreeScanTimes = [];

  @override
  void initState() {
    super.initState();
    _mobileScannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
    );
    _loadScanSoundState();
    _getDeviceInfo();
    isAttendanceEnabledNotifier.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _mobileScannerController.dispose();
    super.dispose();
  }

  void _addScanTime(String time) {
    setState(() {
      _lastThreeScanTimes.insert(0, time);
      if (_lastThreeScanTimes.length > 5) {
        _lastThreeScanTimes.removeLast();
      }
    });
  }

  Future<void> _loadScanSoundState() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      isScanSoundOn = prefs.getBool('isScanSoundOn') ?? false;
    });
  }

  Future<void> _saveScanSoundState() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isScanSoundOn', isScanSoundOn);
  }

  void _updateScanSound(bool value) {
    setState(() {
      isScanSoundOn = value;
      _saveScanSoundState();
    });
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

  void onDetect(BarcodeCapture scan) async {
    var barcode = scan.barcodes;
    if (barcode.isEmpty) {
      return;
    }

    for (var code in barcode) {
      var raw = code.rawValue;
      if (raw != null) {
        if (isAttendanceEnabledNotifier.value) {
          final isValidUrl = raw.startsWith('https://mcid.in/') ||
              raw.startsWith('https://mycoolid.com/');
          if (!isValidUrl) {
            player
              ..setAsset('assets/warning.mp3')
              ..play();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Row(
                  children: [
                    Icon(Icons.error, color: Colors.white),
                    SizedBox(width: 10),
                    Text(
                      'Invalid QR Code',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
                backgroundColor: Colors.redAccent,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                margin: EdgeInsets.only(
                  bottom: MediaQuery.of(context).size.height * 0.8,
                  left: 10,
                  right: 10,
                ),
                duration: const Duration(seconds: 2),
              ),
            );
            return;
          } else {
            const url = 'https://mcid.in/app/att2.php';
            final response = await http.post(
              Uri.parse(url),
              headers: {'Content-Type': 'application/x-www-form-urlencoded'},
              body: {
                'param': 'ATTEN~$androidId~$raw',
              },
            );

            if (response.statusCode == 200) {
              final Map<String, dynamic> result = jsonDecode(response.body);
              final resultParts = result['result'].split('~');
              scanTime = resultParts[1].replaceFirst('current time: ', '');
              String time = "Scanned at $scanTime";
              _addScanTime(time);
              // String soundUrl = resultParts[2];
              // _playSound(soundUrl);

              // valid qr code playing sound
              player
                ..setAsset('assets/blip.mp3')
                ..play();
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Row(
                    children: [
                      Icon(Icons.error, color: Colors.white),
                      SizedBox(width: 10),
                      Text(
                        'Cannot load the attendance',
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                  backgroundColor: Colors.redAccent,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  margin: EdgeInsets.only(
                    bottom: MediaQuery.of(context).size.height * 0.8,
                    left: 10,
                    right: 10,
                  ),
                  duration: const Duration(seconds: 2),
                ),
              );
            }
            return;
          }
        }

        if (isScanSoundOn) {
          player
            ..setAsset('assets/sound.mp3')
            ..play();
        }
        final uri = Uri.parse(raw);
        if (uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https')) {
          showUrlDialog(context, raw, _mobileScannerController.start,
              _mobileScannerController.stop);
        } else {
          showTextDialog(context, raw, _mobileScannerController.start,
              _mobileScannerController.stop);
        }
      }
    }

    setState(() {
      _zoomLevel = 0.0;
      _mobileScannerController.setZoomScale(_zoomLevel);
    });
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) {
      return;
    } else {
      final result = await _mobileScannerController.analyzeImage(image.path);
      if (result == null) {
        player
          ..setAsset('assets/warning.mp3')
          ..play();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 10),
                Text(
                  'Invalid Image',
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: EdgeInsets.only(
              bottom: MediaQuery.of(context).size.height * 0.8,
              left: 10,
              right: 10,
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        onDetect(result);
      }
    }
  }

  Future<String?> _getDeviceInfo() async {
    DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();
    AndroidDeviceInfo androidDeviceInfo = await deviceInfoPlugin.androidInfo;
    setState(() {
      androidId = androidDeviceInfo.id;
    });

    return androidId;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          MobileScanner(
            controller: _mobileScannerController,
            onDetect: onDetect,
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              final size = constraints.maxWidth * 0.7;
              return Stack(
                children: [
                  Container(
                    color: Colors.black.withOpacity(0.5),
                  ),
                  Center(
                    child: CustomBorder(size: size),
                  ),
                  Positioned.fill(
                    child: IgnorePointer(
                      child: ClipPath(
                        clipper: ScannerClipper(size),
                        child: Container(
                          color: Colors.black.withOpacity(0.5),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 200,
                    left: 60,
                    right: 60,
                    child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.cyan),
                        onPressed: () {
                          _pickImage();
                        },
                        child: const Row(
                          children: [
                            Icon(
                              Icons.photo_library,
                              color: Colors.black,
                            ),
                            SizedBox(
                              width: 8,
                            ),
                            Text(
                              'Upload from Gallery',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        )),
                  ),
                ],
              );
            },
          ),
          Positioned(
            bottom: 155,
            left: 20,
            right: 20,
            child: Slider(
              value: _zoomLevel,
              activeColor: Colors.cyan,
              inactiveColor: Colors.grey,
              onChanged: (value) {
                setState(() {
                  _zoomLevel = value;
                  _mobileScannerController.setZoomScale(_zoomLevel);
                });
              },
            ),
          ),
          Positioned(
            top: 30,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: _lastThreeScanTimes.asMap().entries.map((entry) {
                  int index = entry.key;
                  String time = entry.value;
                  double deviceWidth = MediaQuery.of(context).size.width;
                  double fontSize = deviceWidth * 0.065;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 5),
                    padding: const EdgeInsets.all(5),
                    width: double.infinity,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: index % 2 == 0
                          ? Colors.cyan.withOpacity(0.3)
                          : Colors.grey[800]?.withOpacity(0.3),
                    ),
                    child: Text(
                      time,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: fontSize,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          DraggableSheet(
            mobileScannerController: _mobileScannerController,
            onSwitchChanged: _updateScanSound,
            androidId: androidId,
            isAttendanceEnabledNotifier: isAttendanceEnabledNotifier,
          ),
        ],
      ),
    );
  }
}
