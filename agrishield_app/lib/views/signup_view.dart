import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../controllers/language_controller.dart';
import 'home_screen.dart';

class SignupView extends StatelessWidget {
  SignupView({super.key});

  final _nameController = TextEditingController();
  final _enrollmentController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(l10n.createAccount),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => LanguageController.showLanguageBottomSheet(context),
            icon: const Icon(Icons.translate_rounded),
            tooltip: l10n.selectLanguage,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'AgriShield AI 🌾',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.registerForAgriShield,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(height: 26),

                // ── Name ──
                TextFormField(
                  controller: _nameController,
                  validator: (val) {
                    if (val == null || val.isEmpty) return l10n.enterFullName;
                    return null;
                  },
                  decoration: _inputDecoration(l10n.fullName, Icons.person_rounded),
                ),
                const SizedBox(height: 16),

                // ── Enrollment ID (PM-KISAN) ──
                TextFormField(
                  controller: _enrollmentController,
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Enter Enrollment ID (e.g. PM-KISAN)';
                    return null;
                  },
                  decoration: _inputDecoration('PM-KISAN ID', Icons.badge_rounded),
                ),
                const SizedBox(height: 16),

                // ── Mobile Number ──
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  validator: (val) {
                    if (val == null || val.isEmpty) return l10n.enterPhoneNumber;
                    final cleaned = val.replaceAll(RegExp(r'[^0-9]'), '');
                    if (cleaned.length != 10) return 'Enter valid 10-digit number';
                    return null;
                  },
                  decoration: InputDecoration(
                    labelText: l10n.phoneNumber,
                    prefixIcon: const Icon(Icons.phone_rounded, color: Color(0xFF2E7D32)),
                    prefixText: '+91 ',
                    prefixStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: Colors.grey.shade200, width: 1),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // ── Email ──
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: (val) {
                    if (val == null || val.isEmpty) return l10n.enterEmail;
                    if (!GetUtils.isEmail(val)) return 'Enter valid email';
                    return null;
                  },
                  decoration: _inputDecoration(l10n.email, Icons.email_rounded),
                ),
                const SizedBox(height: 16),

                // ── Password ──
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  validator: (val) {
                    if (val == null || val.isEmpty) return l10n.enterPassword;
                    if (val.length < 6) return 'Minimum 6 characters';
                    return null;
                  },
                  decoration: _inputDecoration(l10n.password, Icons.lock_rounded),
                ),
                const SizedBox(height: 16),

                // ── Confirm Password ──
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  validator: (val) {
                    if (val == null || val.isEmpty) return l10n.enterPassword;
                    if (val != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                  decoration: _inputDecoration(
                      'Confirm Password', Icons.lock_outline_rounded),
                ),
                const SizedBox(height: 24),

                // ── Sign Up Button ──
                Obx(() => SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: auth.isLoading.value
                            ? null
                            : () async {
                                if (_formKey.currentState!.validate()) {
                                  bool success = await auth.signup(
                                    name: _nameController.text,
                                    phone: _phoneController.text.trim(),
                                    email: _emailController.text,
                                    password: _passwordController.text,
                                    enrollmentId: _enrollmentController.text.trim(),
                                  );
                                  if (success) {
                                    Get.offAll(() => HomeScreen());
                                  }
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D32),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 3,
                        ),
                        child: auth.isLoading.value
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2),
                              )
                            : Text(l10n.signUp,
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w600)),
                      ),
                    )),
                const SizedBox(height: 18),

                // ── Already have account ──
                Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text('${l10n.alreadyHaveAccount} ',
                        style: TextStyle(color: Colors.grey[600])),
                    GestureDetector(
                      onTap: () => Get.back(),
                      child: Text(
                        l10n.login,
                        style: const TextStyle(
                          color: Color(0xFF2E7D32),
                          fontWeight: FontWeight.bold,
                        ),
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

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: const Color(0xFF2E7D32)),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 2),
      ),
    );
  }
}
