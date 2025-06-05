import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:trekxo_travels/views/auth/login_screen.dart';
import '../../controllers/auth_controller.dart';
import '../../utils/app_colors.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';
import '../../widgets/loading_indicator.dart';

class ForgotPasswordScreen extends StatelessWidget {
  final AuthController _authController = Get.find<AuthController>();
  final TextEditingController _emailController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() {
        return _authController.isLoading.value
            ? LoadingIndicator()
            : _buildForgotPasswordForm(context);
      }),
    );
  }

  Widget _buildForgotPasswordForm(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 50),
              _buildHeader(),
              const SizedBox(height: 40),
              CustomTextField(
                controller: _emailController,
                hintText: 'Email',
                prefixIcon: Icons.email_outlined,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  if (!GetUtils.isEmail(value)) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 30),
              CustomButton(
                text: "Send Reset Email",
                  onPressed: () {
                    print("[UI] Reset button pressed");
                    if (_formKey.currentState!.validate()) {
                      print("[UI] Email field valid: ${_emailController.text}");
                      _authController.resetPassword(email: _emailController.text);
                    } else {
                      print("[UI] Email validation failed");
                    }
                  }

              ),
              const SizedBox(height: 20),
          TextButton(
            onPressed: () => Get.off(() => LoginScreen()),
            child: Text('Back to Login'),
          ),

          ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Icon(
          Icons.lock_reset,
          size: 80,
          color: AppColors.primaryColor,
        ),
        const SizedBox(height: 20),
        Text(
          'Forgot Password?',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryColor,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Enter your email to receive reset instructions',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
        ),
      ],
    );
  }
}
