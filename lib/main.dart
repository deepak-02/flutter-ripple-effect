import 'dart:async';
import 'dart:ui' as ui;
import 'dart:ui';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: RippleScreen(),
    );
  }
}

class RippleScreen extends StatefulWidget {
  const RippleScreen({super.key});

  @override
  State<RippleScreen> createState() => _RippleScreenState();
}

class _RippleScreenState extends State<RippleScreen> with SingleTickerProviderStateMixin {
  FragmentProgram? _program;
  ui.Image? _backgroundImage;
  late AnimationController _controller;
  final List<Ripple> _ripples = [];

  @override
  void initState() {
    super.initState();
    _loadResources();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..addListener(() {
      setState(() {
        for (var r in _ripples) {
          r.radius += 0.005;
          r.intensity = (r.intensity - 0.01).clamp(0.0, 1.0);
        }
        _ripples.removeWhere((r) => r.intensity <= 0);
      });
    });

    _controller.repeat();
  }

  // Load both the shader and the network image
  Future<void> _loadResources() async {
    final program = await FragmentProgram.fromAsset('shaders/ripple.frag');

    // Replace this URL with whatever image you want
    final image = await _fetchNetworkImage('https://images.unsplash.com/photo-1587591389045-7486f45d1dbb?q=80&w=987&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D');

    if (mounted) {
      setState(() {
        _program = program;
        _backgroundImage = image;
      });
    }
  }

  // Helper method to convert a Network URL into a dart:ui Image
  Future<ui.Image> _fetchNetworkImage(String url) async {
    final Completer<ui.Image> completer = Completer();
    final ImageStream stream = NetworkImage(url).resolve(ImageConfiguration.empty);

    stream.addListener(ImageStreamListener((ImageInfo info, bool _) {
      completer.complete(info.image);
    }, onError: (dynamic error, StackTrace? stackTrace) {
      debugPrint('Error loading image: $error');
    }));

    return completer.future;
  }

  void _addRipple(Offset position) {
    if (_ripples.length >= 5) {
      _ripples.removeAt(0);
    }
    _ripples.add(Ripple(position));
  }

  @override
  Widget build(BuildContext context) {
    // Wait until both the shader and the image are loaded
    if (_program == null || _backgroundImage == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    return GestureDetector(
      onPanUpdate: (details) => _addRipple(details.localPosition),
      onTapDown: (details) => _addRipple(details.localPosition),
      child: Scaffold(
        body: CustomPaint(
          size: Size.infinite,
          painter: ShaderRipplePainter(
            _program!.fragmentShader(),
            _ripples,
            _backgroundImage!, // Pass the loaded image down
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class Ripple {
  Offset center;
  double radius = 0.0;
  double intensity = 1.0;
  Ripple(this.center);
}

class ShaderRipplePainter extends CustomPainter {
  final FragmentShader shader;
  final List<Ripple> ripples;
  final ui.Image image;

  ShaderRipplePainter(this.shader, this.ripples, this.image);

  @override
  void paint(Canvas canvas, Size size) {
    shader.setFloat(0, size.width);
    shader.setFloat(1, size.height);

    int offset = 2;
    for (int i = 0; i < 5; i++) {
      if (i < ripples.length) {
        final r = ripples[i];
        shader.setFloat(offset++, r.center.dx);
        shader.setFloat(offset++, r.center.dy);
        shader.setFloat(offset++, r.radius);
        shader.setFloat(offset++, r.intensity);
      } else {
        shader.setFloat(offset++, 0);
        shader.setFloat(offset++, 0);
        shader.setFloat(offset++, 0);
        shader.setFloat(offset++, 0);
      }
    }

    // Set the image texture at index 0
    shader.setImageSampler(0, image);

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..shader = shader,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}