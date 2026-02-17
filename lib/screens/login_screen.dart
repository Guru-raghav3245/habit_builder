import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;
<<<<<<< HEAD
  // Initialize GoogleSignIn as a class member
  final GoogleSignIn _googleSignIn = GoogleSignIn();
=======
>>>>>>> 04f3ca18835184e4d0699148f9c8d4abef065edd

  @override
  void initState() {
    super.initState();
<<<<<<< HEAD
=======
    _initGoogleSignIn();
  }

  Future<void> _initGoogleSignIn() async {
    try {
      await GoogleSignIn.instance.initialize();
    } catch (e) {
      debugPrint('Google Sign-In initialization failed: $e');
    }
>>>>>>> 04f3ca18835184e4d0699148f9c8d4abef065edd
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);

    try {
<<<<<<< HEAD
      // The 'initialize' method is removed as it is not defined for GoogleSignIn
      // Standard signIn() handles the flow on Android/iOS
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        debugPrint('User cancelled Google sign in');
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      if (googleAuth.idToken == null) {
        throw Exception('No idToken received from Google');
      }

      final credential = GoogleAuthProvider.credential(
=======
      final GoogleSignInAccount? googleUser = await GoogleSignIn.instance.authenticate();
      
      final GoogleSignInAuthentication googleAuth = await googleUser!.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: null, 
>>>>>>> 04f3ca18835184e4d0699148f9c8d4abef065edd
        idToken: googleAuth.idToken,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);
<<<<<<< HEAD
      // Success is handled by the StreamBuilder in main.dart
    } on FirebaseAuthException catch (e) {
      debugPrint('FirebaseAuth error: ${e.code} - ${e.message}');
      _showError('Firebase Error: ${e.message ?? "Unknown error"}');
    } catch (e) {
      debugPrint('Google sign-in error: $e');
      _showError('Sign in failed: $e');
=======
      
    } on FirebaseAuthException catch (e) {
      _showError('Firebase Error: ${e.message}');
    } catch (e) {
      if (e.toString().contains('canceled')) {
        debugPrint('User canceled sign in');
      } else {
        _showError('Login Failed: $e');
      }
>>>>>>> 04f3ca18835184e4d0699148f9c8d4abef065edd
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
<<<<<<< HEAD
                Icons.lock_person_rounded,
                size: 80,
                color: Colors.deepPurple,
=======
                Icons.lock_person_rounded, 
                size: 80, 
                color: Colors.deepPurple
>>>>>>> 04f3ca18835184e4d0699148f9c8d4abef065edd
              ),
              const SizedBox(height: 24),
              const Text(
                'Welcome to HabitIt',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                'Sign in to sync your habits',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 48),
<<<<<<< HEAD
=======
              
>>>>>>> 04f3ca18835184e4d0699148f9c8d4abef065edd
              if (_isLoading)
                const CircularProgressIndicator()
              else
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _signInWithGoogle,
                    icon: const Icon(Icons.login),
                    label: const Text('Sign in with Google'),
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}