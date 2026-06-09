import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:video_player/video_player.dart';
import '../components/app_scaffold.dart';
import 'splash_controller.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final SplashScreenController splashController =
      Get.put(SplashScreenController());

  late final VideoPlayerController _videoController;
  bool _initialized = false;
  bool _finishedNotified = false;

  @override
  void initState() {
    super.initState();
    _videoController =
        VideoPlayerController.asset('assets/IMG_8356.MP4')
          ..setLooping(false)
          ..addListener(_onVideoTick);

    _videoController.initialize().then((_) {
      _videoController.setVolume(1.0);
      _videoController.play();
      if (mounted) setState(() => _initialized = true);
    }).catchError((_) {
      // Video couldn't load — let navigation proceed.
      _notifyFinished();
    });
  }

  void _onVideoTick() {
    final value = _videoController.value;
    if (value.hasError) {
      _notifyFinished();
      return;
    }
    if (value.isInitialized &&
        value.duration > Duration.zero &&
        value.position >= value.duration) {
      _notifyFinished();
    }
  }

  void _notifyFinished() {
    if (_finishedNotified) return;
    _finishedNotified = true;
    splashController.onVideoFinished();
  }

  @override
  void dispose() {
    _videoController.removeListener(_onVideoTick);
    _videoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      hideAppBar: true,
      scaffoldBackgroundColor: Colors.black,
      body: _initialized
          ? SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _videoController.value.size.width,
                  height: _videoController.value.size.height,
                  child: VideoPlayer(_videoController),
                ),
              ),
            )
          : const SizedBox.expand(),
    );
  }
}
