import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _arcAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _scaleAnimation;

  static const String leftPart = 'Split';
  static const String rightPart = 'Smart';
  static const double wordGap = 24; // Space between 'Split' and 'Smart'

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1800), // 1.8s for animation
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _fadeAnimation = CurvedAnimation(
      parent: _controller, 
      curve: const Interval(0.0, 0.3, curve: Curves.easeInOut)
    );
    _arcAnimation = CurvedAnimation(
      parent: _controller, 
      curve: const Interval(0.2, 0.8, curve: Curves.easeInOut)
    );
    _scaleAnimation = CurvedAnimation(
      parent: _controller, 
      curve: const Interval(0.4, 1.0, curve: Curves.elasticOut)
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    _controller.forward();
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.primary,
              colorScheme.secondary,
              colorScheme.tertiary,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Main Logo Container
                AnimatedBuilder(
                  animation: _scaleAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _scaleAnimation.value,
                      child: Container(
                        width: 350,
                        height: 180,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Animated 'Split' from left and 'Smart' from right with a gap
                            AnimatedBuilder(
                              animation: _controller,
                              builder: (context, child) {
                                final animValue = Curves.easeInOutCubic.transform(_controller.value);
                                final textStyle = GoogleFonts.inter(
                                  textStyle: const TextStyle(
                                    fontSize: 48,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 2,
                                    shadows: [
                                      Shadow(
                                        blurRadius: 12,
                                        color: Colors.black26,
                                        offset: Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                );
                                // 'Split' slides from left, 'Smart' from right
                                final splitOffset = Offset(-120 * (1 - animValue), 0);
                                final smartOffset = Offset(120 * (1 - animValue), 0);
                                return Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Opacity(
                                      opacity: 1.0 - animValue,
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Transform.translate(
                                            offset: splitOffset,
                                            child: Text('Split', style: textStyle),
                                          ),
                                          const SizedBox(width: 24),
                                          Transform.translate(
                                            offset: smartOffset,
                                            child: Text('Smart', style: textStyle),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Opacity(
                                      opacity: animValue,
                                      child: Text('SplitSmart', style: textStyle),
                                    ),
                                  ],
                                );
                              },
                            ),
                            // Arc animation
                            AnimatedBuilder(
                              animation: _arcAnimation,
                              builder: (context, child) {
                                return CustomPaint(
                                  size: const Size(350, 120),
                                  painter: ArcPainter(progress: _arcAnimation.value),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: 60),
                
                // App Icon with pulse animation
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _pulseAnimation.value,
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withOpacity(0.3),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.account_balance_wallet_rounded,
                          size: 60,
                          color: Colors.white,
                        ),
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: 40),
                
                // Loading indicator
                AnimatedBuilder(
                  animation: _fadeAnimation,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _fadeAnimation.value,
                      child: Column(
                        children: [
                          SizedBox(
                            width: 40,
                            height: 40,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 3,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Loading...',
                            style: GoogleFonts.inter(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: 80),
                
                // Tagline
                AnimatedBuilder(
                  animation: _fadeAnimation,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _fadeAnimation.value,
                      child: Text(
                        'Smart expense splitting for everyone',
                        style: GoogleFonts.inter(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ArcPainter extends CustomPainter {
  final double progress; // 0.0 to 1.0
  ArcPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final arcRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2 + 10),
      width: size.width * 0.9,
      height: size.height * 0.8,
    );
    final startAngle = 5 * 3.1416 / 4; // Start from left-bottom
    final sweepAngle = 3.1416 / 2 * progress; // Sweep to right-bottom
    final paint = Paint()
      ..color = Colors.white // Maximum brightness
      ..strokeWidth = 6 // Very thin line
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16); // Strongest glow

    if (progress > 0.01) {
      canvas.drawArc(arcRect, startAngle, sweepAngle, false, paint);
    }
  }

  @override
  bool shouldRepaint(covariant ArcPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
} 