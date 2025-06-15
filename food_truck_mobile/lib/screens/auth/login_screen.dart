import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../customer/customer_main_screen.dart';
import '../owner/owner_main_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  final String role;

  const LoginScreen({super.key, required this.role});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login as ${widget.role == 'customer' ? 'Customer' : 'Food Truck Owner'}'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Role icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: Icon(
                    widget.role == 'customer' ? Icons.person : Icons.business,
                    size: 40,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 32),

                // Email field
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!value.contains('@')) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Password field
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Login button
                Consumer<AuthProvider>(
                  builder: (context, authProvider, child) {
                    return SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: authProvider.isLoading ? null : _login,
                        child: authProvider.isLoading
                            ? const CircularProgressIndicator()
                            : const Text('Login'),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),

                // Register link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Don\'t have an account? '),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => RegisterScreen(role: widget.role),
                          ),
                        );
                      },
                      child: const Text('Register'),
                    ),
                  ],
                ),

                // Demo login buttons for testing
                const SizedBox(height: 32),
                const Divider(),
                const SizedBox(height: 16),
                Text(
                  'Demo Login (for testing)',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _demoLogin('customer'),
                        child: const Text('Demo Customer'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _demoLogin('owner'),
                        child: const Text('Demo Owner'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.login(
      _emailController.text.trim(),
      _passwordController.text,
      widget.role,
    );

    if (!mounted) return;

    if (success) {
      // Navigate to appropriate main screen
      if (widget.role == 'customer') {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const CustomerMainScreen()),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const OwnerMainScreen()),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Login failed. Please check your credentials.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _demoLogin(String role) async {
    // For demo purposes, create a mock login
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    // Skip actual API call for demo, create mock user data
    if (!mounted) return;

    // Navigate directly to main screen
    if (role == 'customer') {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const CustomerMainScreen()),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const OwnerMainScreen()),
      );
    }
  }
} 