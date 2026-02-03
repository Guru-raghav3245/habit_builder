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

  @override
  void initState() {
    super.initState();
    // 1. Initialize GoogleSignIn (Required in v7+)
    _initGoogleSignIn();
  }

  Future<void> _initGoogleSignIn() async {
    try {
      // Required to setup the plugin before use
      await GoogleSignIn.instance.initialize();
    } catch (e) {
      debugPrint('Google Sign-In initialization failed: $e');
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);

    try {
      // 2. Use 'authenticate()' instead of 'signIn()'
      // In v7, this throws an exception if the user cancels, instead of returning null.
      final GoogleSignInAccount? googleUser = await GoogleSignIn.instance.authenticate();
      
      // 3. Get auth details (Note: accessToken is GONE in v7)
      final GoogleSignInAuthentication googleAuth = await googleUser!.authentication;

      // 4. Create credential using ONLY idToken
      // Firebase only needs idToken to verify identity. 
      // accessToken is null because we didn't ask for extra permissions (like Drive/Calendar).
      final credential = GoogleAuthProvider.credential(
        accessToken: null, 
        idToken: googleAuth.idToken,
      );

      // 5. Sign in to Firebase
      await FirebaseAuth.instance.signInWithCredential(credential);
      
    } on FirebaseAuthException catch (e) {
      _showError('Firebase Error: ${e.message}');
    } catch (e) {
      // Ignore "canceled" errors (user closed the popup)
      if (e.toString().contains('canceled')) {
        debugPrint('User canceled sign in');
      } else {
        _showError('Login Failed: $e');
      }
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
                Icons.lock_person_rounded, 
                size: 80, 
                color: Colors.deepPurple
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