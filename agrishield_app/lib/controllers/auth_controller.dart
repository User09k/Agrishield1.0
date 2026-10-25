import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get_storage/get_storage.dart';

class AuthController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final _storage = GetStorage();

  var isLoading = false.obs;
  var currentUser = Rxn<User>();

  @override
  void onInit() {
    super.onInit();
    // Listen to auth state changes
    currentUser.bindStream(_auth.authStateChanges());
  }

  bool get isLoggedIn => currentUser.value != null;

  // ── Sign Up ──────────────────────────────────────────────
  Future<bool> signup({
    required String name,
    required String phone,
    required String email,
    required String password,
    required String enrollmentId,
  }) async {
    isLoading(true);
    try {
      UserCredential cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      // Update display name
      await cred.user?.updateDisplayName(name.trim());
      await cred.user?.reload();
      currentUser.value = _auth.currentUser;

      // Format phone with +91 prefix
      final cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
      final fullPhone = '+91$cleanPhone';

      // Save user data to Firestore
      await _db.collection('users').doc(cred.user!.uid).set({
        'name': name.trim(),
        'phone': fullPhone,
        'email': email.trim(),
        'enrollment_id': enrollmentId.trim(),
        'created_at': DateTime.now().toIso8601String(),
        'location': 'Madhya Pradesh, India',
        'farm_size': '5 Acre',
      });

      // Save to local storage for ProfileController
      _storage.write('farmer_name', name.trim());
      _storage.write('farmer_phone', fullPhone);
      _storage.write('farmer_email', email.trim());
      _storage.write('enrollment_id', enrollmentId.trim());

      Get.snackbar('✅ Account Created', 'Welcome to AgriShield AI!',
          snackPosition: SnackPosition.BOTTOM);
      return true;
    } on FirebaseAuthException catch (e) {
      String msg = 'Something went wrong';
      switch (e.code) {
        case 'email-already-in-use':
          msg = 'This email is already registered';
          break;
        case 'weak-password':
          msg = 'Password is too weak (min 6 characters)';
          break;
        case 'invalid-email':
          msg = 'Invalid email address';
          break;
      }
      Get.snackbar('❌ Signup Failed', msg,
          snackPosition: SnackPosition.BOTTOM);
      return false;
    } catch (e) {
      Get.snackbar('❌ Error', e.toString(),
          snackPosition: SnackPosition.BOTTOM);
      return false;
    } finally {
      isLoading(false);
    }
  }

  // ── Login ────────────────────────────────────────────────
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    isLoading(true);
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // Fetch user data from Firestore and save locally
      final uid = _auth.currentUser?.uid;
      if (uid != null) {
        final doc = await _db.collection('users').doc(uid).get();
        if (doc.exists) {
          final data = doc.data()!;
          _storage.write('farmer_name', data['name'] ?? '');
          _storage.write('farmer_phone', data['phone'] ?? '');
          _storage.write('farmer_email', data['email'] ?? email.trim());
          _storage.write('farmer_location', data['location'] ?? 'Madhya Pradesh, India');
          _storage.write('farm_size', data['farm_size'] ?? '5 Acre');
          _storage.write('enrollment_id', data['enrollment_id'] ?? '');
        }
      }

      Get.snackbar('✅ Welcome Back!', 'Logged in successfully',
          snackPosition: SnackPosition.BOTTOM);
      return true;
    } on FirebaseAuthException catch (e) {
      String msg = 'Something went wrong';
      switch (e.code) {
        case 'user-not-found':
          msg = 'No account found with this email';
          break;
        case 'wrong-password':
          msg = 'Incorrect password';
          break;
        case 'invalid-email':
          msg = 'Invalid email address';
          break;
        case 'invalid-credential':
          msg = 'Invalid email or password';
          break;
      }
      Get.snackbar('❌ Login Failed', msg,
          snackPosition: SnackPosition.BOTTOM);
      return false;
    } catch (e) {
      Get.snackbar('❌ Error', e.toString(),
          snackPosition: SnackPosition.BOTTOM);
      return false;
    } finally {
      isLoading(false);
    }
  }

  // ── Forgot Password ──────────────────────────────────────
  Future<bool> forgotPassword({required String email}) async {
    isLoading(true);
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      Get.snackbar('📧 Email Sent', 'Check your inbox for reset link',
          snackPosition: SnackPosition.BOTTOM);
      return true;
    } on FirebaseAuthException catch (e) {
      String msg = 'Something went wrong';
      if (e.code == 'user-not-found') {
        msg = 'No account found with this email';
      }
      Get.snackbar('❌ Error', msg, snackPosition: SnackPosition.BOTTOM);
      return false;
    } catch (e) {
      Get.snackbar('❌ Error', e.toString(),
          snackPosition: SnackPosition.BOTTOM);
      return false;
    } finally {
      isLoading(false);
    }
  }

  // ── Logout ───────────────────────────────────────────────
  Future<void> logout() async {
    await _auth.signOut();
    Get.snackbar('👋 Logged Out', 'See you later!',
        snackPosition: SnackPosition.BOTTOM);
  }
}
