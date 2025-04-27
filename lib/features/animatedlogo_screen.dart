import 'package:flutter/material.dart';

class AnimatedLogoScreen extends StatefulWidget {
  @override
  _AnimatedLogoScreenState createState() => _AnimatedLogoScreenState();
}

class _AnimatedLogoScreenState extends State<AnimatedLogoScreen>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  late AnimationController _opacityController;
  late Animation<double> _opacityAnimation;

  late AnimationController _fullScreenScaleController;
  late Animation<double> _fullScreenScaleAnimation;

  bool _showLogo = false;
  bool _animateFullScreen = false;
  bool _navigationDone = false;

  @override
  void initState() {
    super.initState();

    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    )..addListener(() {
      setState(() {});
    });
    _scaleController.forward();

    _opacityController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _opacityController, curve: Curves.easeOut),
    )..addListener(() {
      setState(() {});
    });

    _fullScreenScaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fullScreenScaleAnimation = Tween<double>(begin: 1.0, end: 20.0).animate(
      CurvedAnimation(
        parent: _fullScreenScaleController,
        curve: Curves.easeInOut,
      ),
    )..addListener(() {
      setState(() {});
    });

    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        _showLogo = true;
        _opacityController.forward();
      });
    });

    Future.delayed(const Duration(seconds: 1, milliseconds: 500), () {
      setState(() {
        _showLogo = false;
        _opacityController.reverse();
        _fullScreenScaleController.forward();
        _animateFullScreen = true;
      });
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (!_navigationDone) {
        _navigationDone = true;
        Navigator.of(context).pushReplacementNamed('/home');
      }
    });
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _opacityController.dispose();
    _fullScreenScaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final initialSize = 150.0 * (_scaleAnimation.value); // Fixed value

    return Scaffold(
      backgroundColor: _animateFullScreen ? Colors.blue : Colors.white,
      body: Center(
        // Center widget added
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (!_animateFullScreen)
              Container(
                width: initialSize,
                height: initialSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.blue,
                ),
              ),
            if (_showLogo)
              Opacity(
                opacity: _opacityAnimation.value,
                child: Container(
                  width: 115,
                  height: 115,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.blue,
                  ),
                  child: Center(
                    child: Image.asset(
                      'assets/logop.png', // Make sure the image path is correct
                      width: 100,
                      height: 100,
                    ),
                  ),
                ),
              ),
            if (_animateFullScreen)
              Transform.scale(
                scale: _fullScreenScaleAnimation.value,
                child: Container(
                  width: initialSize,
                  height: initialSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.blue,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
