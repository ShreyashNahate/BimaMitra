import 'package:flutter/material.dart';
import 'dart:async';
import 'language_screen.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _popController;
  late AnimationController _rippleController;

  late Animation<double> _logoScaleAnimation;
  late Animation<double> _logoFadeAnimation;
  late Animation<double> _popScaleAnimation;
  late Animation<double> _popFadeAnimation;
  late Animation<double> _rippleAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _startAnimationSequence();
  }

  void _initAnimations() {
    // Logo animation controller (entrance)
    _logoController = AnimationController(
      duration: Duration(milliseconds: 1200),
      vsync: this,
    );

    // Pop animation controller (exit with pop effect)
    _popController = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );

    // Ripple effect controller
    _rippleController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    // Logo entrance animations
    _logoScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );

    _logoFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    // Pop exit animations
    _popScaleAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _popController, curve: Curves.easeInBack),
    );

    _popFadeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _popController, curve: Curves.easeIn));

    // Ripple animation
    _rippleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _rippleController, curve: Curves.easeOut),
    );

    // Slide animation for next screen
    _slideAnimation = Tween<Offset>(begin: Offset(0, 1), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _popController, curve: Curves.easeOutCubic),
        );
  }

  void _startAnimationSequence() async {
    // Start logo entrance
    await Future.delayed(Duration(milliseconds: 300));
    _logoController.forward();

    // Wait for logo to settle
    await Future.delayed(Duration(milliseconds: 2000));

    // Start pop exit animation
    _popController.forward();

    // Navigate to language screen with slide transition
    await Future.delayed(Duration(milliseconds: 400));
    _navigateToLanguageScreen();
  }

  void _navigateToLanguageScreen() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            LanguageScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(begin: Offset(0, 1), end: Offset.zero)
                .animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                ),
            child: child,
          );
        },
        transitionDuration: Duration(milliseconds: 500),
      ),
    );
  }

  @override
  void dispose() {
    _logoController.dispose();
    _popController.dispose();
    _rippleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF2563EB), // Primary blue
              Color(0xFF1E40AF), // Darker blue
              Color(0xFF1E3A8A), // Even darker blue
            ],
          ),
        ),
        child: Stack(
          children: [
            // Animated ripple effects in background
            _buildRippleEffect(),

            // Main content
            Center(
              child: ScaleTransition(
                scale: _popScaleAnimation,
                child: FadeTransition(
                  opacity: _popFadeAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo with pop animation
                      ScaleTransition(
                        scale: _logoScaleAnimation,
                        child: FadeTransition(
                          opacity: _logoFadeAnimation,
                          child: _buildLogo(),
                        ),
                      ),

                      SizedBox(height: 32),

                      // App name with fade
                      FadeTransition(
                        opacity: _logoFadeAnimation,
                        child: Text(
                          'BimaMitra',
                          style: TextStyle(
                            fontSize: 42,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1.5,
                            shadows: [
                              Shadow(
                                color: Colors.black.withOpacity(0.2),
                                offset: Offset(0, 4),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                        ),
                      ),

                      SizedBox(height: 12),

                      // Tagline
                      FadeTransition(
                        opacity: _logoFadeAnimation,
                        child: Text(
                          'Your AI Insurance Assistant',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withOpacity(0.9),
                            fontWeight: FontWeight.w400,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Loading indicator at bottom
            Positioned(
              bottom: 80,
              left: 0,
              right: 0,
              child: FadeTransition(
                opacity: _logoFadeAnimation,
                child: Center(
                  child: Column(
                    children: [
                      SizedBox(
                        width: 32,
                        height: 32,
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white.withOpacity(0.8),
                          ),
                          strokeWidth: 3,
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Initializing...',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRippleEffect() {
    return AnimatedBuilder(
      animation: _rippleAnimation,
      builder: (context, child) {
        return Stack(
          children: [
            _buildSingleRipple(_rippleAnimation.value, 0.0),
            _buildSingleRipple(_rippleAnimation.value, 0.33),
            _buildSingleRipple(_rippleAnimation.value, 0.66),
          ],
        );
      },
    );
  }

  Widget _buildSingleRipple(double value, double delay) {
    double adjustedValue = (value + delay) % 1.0;

    return Center(
      child: Container(
        width: 300 * adjustedValue,
        height: 300 * adjustedValue,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withOpacity((1 - adjustedValue) * 0.3),
            width: 2,
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
          BoxShadow(
            color: Color(0xFF2563EB).withOpacity(0.4),
            blurRadius: 40,
            offset: Offset(0, 0),
          ),
        ],
      ),
      child: Center(
        child: Icon(Icons.shield_outlined, size: 64, color: Color(0xFF2563EB)),
      ),
    );
  }
}
