// ignore_for_file: use_build_context_synchronously

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:mycoolid/screens/components/custom_border.dart';
import 'package:mycoolid/screens/components/draggable_sheet.dart';
import 'package:mycoolid/utils/text_dialog.dart';
import 'package:mycoolid/utils/url_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'components/scanner_clipper.dart';

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

  @override
  void initState() {
    super.initState();
    _mobileScannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
    );
    _loadScanSoundState();
    _getDeviceInfo();
  }

  @override
  void dispose() {
    _mobileScannerController.dispose();
    super.dispose();
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

  void onDetect(BarcodeCapture scan) {
    var barcode = scan.barcodes;
    if (barcode.isEmpty) {
      return;
    }

    for (var code in barcode) {
      var raw = code.rawValue;
      if (raw != null) {
        if (isScanSoundOn) {
          AudioPlayer()
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid Image'),
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
          DraggableSheet(
            mobileScannerController: _mobileScannerController,
            onSwitchChanged: _updateScanSound,
            androidId: androidId,
          ),
        ],
      ),
    );
  }
}
