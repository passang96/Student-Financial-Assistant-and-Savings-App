// frontend/lib/screens/auth/login_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/social_login_button.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    final ok = await authProvider.login(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (!mounted) return;

    if (!ok && authProvider.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(authProvider.errorMessage!)),
      );
    }
  }

  Future<void> _handleGoogleLogin() async {
    final authProvider = context.read<AuthProvider>();
    final ok = await authProvider.loginWithGoogle();

    if (!mounted) return;

    if (!ok && authProvider.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(authProvider.errorMessage!)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final isLoading = authProvider.status == AuthStatus.loading;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 32),
                const Icon(
                  Icons.account_balance_wallet_outlined,
                  size: 64,
                  color: AppColors.primaryTeal,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Welcome Back',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Log in to keep tracking your goals',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 32),
                CustomTextField(
                  label: 'Email',
                  hint: 'Enter your email',
                  icon: Icons.mail_outline,
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || !value.contains('@')) {
                      return 'Enter a valid email address';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 18),
                CustomTextField(
                  label: 'Password',
                  hint: 'Enter your password',
                  icon: Icons.lock_outline,
                  controller: _passwordController,
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Password is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Checkbox(
                      value: _rememberMe,
                      activeColor: AppColors.primaryTeal,
                      onChanged: (value) {
                        setState(() => _rememberMe = value ?? true);
                      },
                    ),
                    const Text('Remember me'),
                    const Spacer(),
                    TextButton(
                      onPressed: () {},
                      child: const Text('Forgot Password?'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                GradientButton(
                  label: 'Log in',
                  isLoading: isLoading,
                  onPressed: _handleLogin,
                ),
                const SizedBox(height: 28),
                Row(
                  children: const [
                    Expanded(child: Divider()),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'Or continue with',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                    Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SocialLoginButton(
                      icon: Icons.g_mobiledata,
                      onPressed: _handleGoogleLogin,
                    ),
                    const SizedBox(width: 16),
                    SocialLoginButton(icon: Icons.apple, onPressed: () {}),
                    const SizedBox(width: 16),
                    SocialLoginButton(icon: Icons.mail_outline, onPressed: () {}),
                  ],
                ),
                const SizedBox(height: 28),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Don't have an account? "),
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const RegisterScreen()),
                        );
                      },
                      child: const Text(
                        'Sign Up',
                        style: TextStyle(
                          color: AppColors.primaryTeal,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
