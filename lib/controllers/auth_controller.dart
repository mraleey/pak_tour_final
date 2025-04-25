import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:pak_tour_final/utils/app_colors.dart';
import '../models/user_model.dart';
import '../app_constants.dart';
import '../views/home_screen.dart';
import '../views/auth/login_screen.dart';
import '../utils/ui_helpers.dart';

class AuthController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Rx<User?> firebaseUser = Rx<User?>(null);
  Rx<UserModel?> userModel = Rx<UserModel?>(null);
  RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    firebaseUser.bindStream(_auth.authStateChanges());
    ever(firebaseUser, _setInitialScreen);
  }

  _setInitialScreen(User? user) async {
    if (user == null) {
      Get.offAll(() => LoginScreen());
    } else {
      await _getUserData(user.uid);
      Get.offAll(() => HomeScreen());
    }
  }

  Future<void> _getUserData(String uid) async {
    try {
      isLoading.value = true;
      DocumentSnapshot doc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .get();

      if (doc.exists) {
        userModel.value = UserModel.fromMap(doc.data() as Map<String, dynamic>);

        // Update last login
        await _firestore
            .collection(AppConstants.usersCollection)
            .doc(uid)
            .update({'lastLogin': DateTime.now()});
      }
    } catch (e) {
      UIHelpers.showErrorSnackBar('Error fetching user data');
      print('Error fetching user data: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> signupWithEmailPassword(
      String name, String email, String password) async {
    try {
      isLoading.value = true;
      final credential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Optional: Update display name
      await credential.user?.updateDisplayName(name);

      // Optional: Save user to Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(credential.user!.uid)
          .set({
        'uid': credential.user!.uid,
        'name': name,
        'email': email,
        'createdAt': DateTime.now().toIso8601String(),
      });

      Get.snackbar('Success', 'Account created successfully',
          backgroundColor: Colors.green, colorText: Colors.white);

      // Navigate or do something after signup
      Get.off(() => HomeScreen());
    } on FirebaseAuthException catch (e) {
      throw e.message ?? 'Signup failed';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> login({required String email, required String password}) async {
    try {
      isLoading.value = true;
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      // Optionally store user data or navigate to home
      Get.off(() => HomeScreen());
    } on FirebaseAuthException catch (e) {
      Get.snackbar(
        'Login Failed',
        e.message ?? 'Unknown error occurred',
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Logout
  Future<void> logout() async {
    try {
      await _auth.signOut();
      userModel.value = null;
      UIHelpers.showSuccessSnackBar("Successfully signed out.");
    } catch (e) {
      UIHelpers.showErrorSnackBar('Error signing out');
      print('Error signing out: $e');
    }
  }

  /// Check if user is logged in
  bool get isLoggedIn => firebaseUser.value != null;

  void resetPassword({required String email}) async {
    try {
      final cleanedEmail = email.trim();
      print("[RESET] Initiated for: $cleanedEmail");

      // Early check for email validation
      if (cleanedEmail.isEmpty || !GetUtils.isEmail(cleanedEmail)) {
        print("[RESET] Invalid email: $cleanedEmail");
        Get.snackbar(
          'Error',
          'Please enter a valid email address.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.errorColor,
          colorText: AppColors.surfaceColor,
        );
        return; // Exit early if email is invalid
      }

      isLoading.value = true;

      // Sending password reset email
      await _auth.sendPasswordResetEmail(email: cleanedEmail);

      isLoading.value = false;
      print("[RESET] Email sent to: $cleanedEmail");

      Get.snackbar(
        'Success',
        'Password reset email sent successfully.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.successColor,
        colorText: AppColors.surfaceColor,
      );
    } on FirebaseAuthException catch (e) {
      isLoading.value = false;
      print("[RESET] FirebaseAuthException: ${e.code} - ${e.message}");

      // Handle different FirebaseAuthException codes
      String errorMessage = 'Failed to reset password';
      if (e.code == 'user-not-found') {
        errorMessage = 'No user found for this email.';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'The email address is badly formatted.';
      }

      Get.snackbar(
        'Error',
        e.message ?? errorMessage,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.errorColor,
        colorText: AppColors.surfaceColor,
      );
    } catch (e) {
      isLoading.value = false;
      print("[RESET] General Error: $e");

      Get.snackbar(
        'Error',
        'Something went wrong. Please try again later.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.errorColor,
        colorText: AppColors.surfaceColor,
      );
    }
  }
}
