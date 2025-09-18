import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';

class RecordVideoPage extends StatefulWidget {
  const RecordVideoPage({super.key});

  @override
  State<RecordVideoPage> createState() => _RecordVideoPageState();
}

class _RecordVideoPageState extends State<RecordVideoPage> {
  CameraController? controller;
  bool isRecording = false;
  String? videoPath;
  Timer? timer;
  int countdown = 15;
  VideoPlayerController? _videoController;

  @override
  void initState() {
    super.initState();
    initCamera();
  }

  Future<void> initCamera() async {
    final cameras = await availableCameras();
    controller = CameraController(cameras.first, ResolutionPreset.high);
    await controller!.initialize();
    if (mounted) setState(() {});
  }

  Future<void> startRecording() async {
    if (controller == null || controller!.value.isRecordingVideo) return;
    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/${DateTime.now().millisecondsSinceEpoch}.mp4';

    await controller!.startVideoRecording();
    setState(() {
      isRecording = true;
      countdown = 15;
    });

    timer = Timer.periodic(const Duration(seconds: 1), (t) async {
      if (countdown == 0) {
        await stopRecording();
        t.cancel();
      } else {
        setState(() => countdown--);
      }
    });
  }

  Future<void> stopRecording() async {
    if (controller == null || !controller!.value.isRecordingVideo) return;
    final file = await controller!.stopVideoRecording();
    setState(() {
      isRecording = false;
      videoPath = file.path;
    });

    _videoController = VideoPlayerController.file(File(videoPath!))
      ..initialize().then((_) {
        setState(() {});
        _videoController!.play();
        _videoController!.setLooping(true);
      });
  }

  @override
  void dispose() {
    controller?.dispose();
    timer?.cancel();
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (controller == null || !controller!.value.isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: CameraPreview(controller!)),
          if (isRecording)
            Positioned(
              top: 50,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  "$countdown s",
                  style: const TextStyle(
                    fontSize: 32,
                    color: Colors.redAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: isRecording ? null : startRecording,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isRecording ? Colors.redAccent : Colors.white,
                    border: Border.all(color: Colors.grey.shade800, width: 4),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}