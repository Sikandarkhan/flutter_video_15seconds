import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_trimmer/video_trimmer.dart';
import 'package:video_player/video_player.dart';

class PickVideoPage extends StatefulWidget {
  const PickVideoPage({super.key});

  @override
  State<PickVideoPage> createState() => _PickVideoPageState();
}

class _PickVideoPageState extends State<PickVideoPage> {
  final Trimmer _trimmer = Trimmer();
  bool _isLoaded = false;
  String? _savedPath;
  VideoPlayerController? _videoController;

  Future<void> pickVideo() async {
    final picker = ImagePicker();
    final picked = await picker.pickVideo(source: ImageSource.gallery);
    if (picked != null) {
      await _trimmer.loadVideo(videoFile: File(picked.path));
      setState(() => _isLoaded = true);
    }
  }

  Future<void> saveTrimmed() async {
    await _trimmer.saveTrimmedVideo(
      startValue: 0,
      endValue: 15 * 1000, // 15s in ms
      onSave: (path) {
        if (path != null) {
          setState(() {
            _savedPath = path;
            _videoController = VideoPlayerController.file(File(_savedPath!))
              ..initialize().then((_) {
                setState(() {});
                _videoController!.play();
                _videoController!.setLooping(true);
              });
          });
        }
      },
    );
  }

  @override
  void initState() {
    super.initState();
    pickVideo();
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Pick & Trim Video")),
      body: _savedPath != null
          ? Column(
        children: [
          Expanded(
            child: _videoController != null && _videoController!.value.isInitialized
                ? AspectRatio(
              aspectRatio: _videoController!.value.aspectRatio,
              child: VideoPlayer(_videoController!),
            )
                : const Center(child: CircularProgressIndicator()),
          ),
          ElevatedButton(
            onPressed: () {
              _videoController!.value.isPlaying
                  ? _videoController!.pause()
                  : _videoController!.play();
              setState(() {});
            },
            child: Text(
              _videoController!.value.isPlaying ? "Pause" : "Play",
            ),
          ),
        ],
      )
          : _isLoaded
          ? Column(
        children: [
          Expanded(child: VideoViewer(trimmer: _trimmer)),
          TrimViewer(
            trimmer: _trimmer,
            viewerHeight: 50,
            viewerWidth: MediaQuery.of(context).size.width,
            maxVideoLength: const Duration(seconds: 15),
            durationStyle: DurationStyle.FORMAT_MM_SS,
            editorProperties: const TrimEditorProperties(
              borderPaintColor: Colors.purpleAccent,
              borderWidth: 4,
              borderRadius: 12,
            ),
          ),
          ElevatedButton(
            onPressed: saveTrimmed,
            child: const Text("Save & Preview"),
          ),
        ],
      )
          : const Center(child: CircularProgressIndicator()),
    );
  }
}