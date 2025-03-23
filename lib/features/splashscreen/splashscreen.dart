import 'package:flutter/material.dart';
import 'package:lokconnect/features/login/ui/login.dart';
import 'package:video_player/video_player.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset("assets/splash_video.mp4")
      ..initialize().then((_) {
        setState(() {}); 
        _controller.play(); 
        Future.delayed(const Duration(seconds: 1), () {
          _controller.pause(); 
           Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => Login()));
        });
        _controller.setLooping(false); 
      });
  }

  @override
  void dispose() {
    _controller.dispose(); 
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xfff1efe7),
      body: Center(
        child:
         _controller.value.isInitialized
            ? AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: VideoPlayer(_controller),
              )
            : 
            CircularProgressIndicator(), 
      ),
    );
  }
}