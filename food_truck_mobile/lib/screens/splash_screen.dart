import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/user.dart';
import 'auth/role_selection_screen.dart';
import 'customer/customer_main_screen.dart';
import 'owner/owner_main_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_animationController);

    _animationController.forward();
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    // Wait for animation to complete
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    // TEMPORARY: Set fake user for testing favorites
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    authProvider.setFakeUserForTesting();

    // Navigate directly to customer main screen
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const CustomerMainScreen()),
    );

    /* ORIGINAL CODE - COMMENTED OUT FOR TESTING
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.checkAuthStatus();

    if (!mounted) return;

    if (authProvider.isAuthenticated) {
      // Navigate based on user role
      if (authProvider.user?.role == 'owner') {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const OwnerMainScreen()),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const CustomerMainScreen()),
        );
      }
    } else {
      // Navigate to role selection
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
      );
    }
    */
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Food truck icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(60),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.local_shipping,
                  size: 60,
                  color: Color(0xFFFF6B35),
                ),
              ),
              const SizedBox(height: 32),
              // App title
              const Text(
                'Food Truck',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                'Tracker',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w300,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Find & Track Food Trucks',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 48),
              // Loading indicator
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 