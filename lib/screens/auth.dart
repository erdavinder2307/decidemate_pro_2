import 'package:firebase_auth/firebase_auth.dart';
import 'package:decidemate_pro/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';


class AuthScreen extends StatefulWidget {
  const AuthScreen({Key? key}) : super(key: key);

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isSignIn = true;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeFirebase();
  }

  Future<void> _initializeFirebase() async {
    try {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    } catch (_) {}
  }

  void _toggleForm() {
    setState(() {
      _isSignIn = !_isSignIn;
      _errorMessage = null;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      if (_isSignIn) {
        // Sign in
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      } else {
        // Sign up
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      }
      setState(() { _isLoading = false; });
      Navigator.of(context).pushReplacementNamed('/dashboard');
    } on FirebaseAuthException catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.message;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'An unexpected error occurred.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;
    final errorColor = isDark ? CupertinoColors.systemRed : CupertinoColors.destructiveRed;
    final textColor = isDark ? CupertinoColors.white : CupertinoColors.black;
    final bgColor = isDark ? CupertinoColors.systemGrey6.darkColor : CupertinoColors.systemGrey6;
    return CupertinoPageScaffold(
      backgroundColor: bgColor,
      navigationBar: CupertinoNavigationBar(
        middle: Text(_isSignIn ? 'Sign In' : 'Sign Up', style: TextStyle(color: textColor)),
        border: null,
      ),
      child: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDark ? CupertinoColors.darkBackgroundGray : CupertinoColors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: CupertinoColors.systemGrey.withOpacity(0.15),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Logo or App Title
                      Padding(
                        padding: const EdgeInsets.only(bottom: 24.0),
                        child: Column(
                          children: [
                            Icon(CupertinoIcons.person_crop_circle, size: 64, color: CupertinoTheme.of(context).primaryColor),
                            const SizedBox(height: 8),
                            Text('DecideMate Pro', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor)),
                          ],
                        ),
                      ),
                      // Sign In / Sign Up Segmented Control
                      Padding(
                        padding: const EdgeInsets.only(bottom: 20.0),
                        child: CupertinoSlidingSegmentedControl<bool>(
                          groupValue: _isSignIn,
                          children: const {
                            true: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: Text('Sign In'),
                            ),
                            false: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: Text('Sign Up'),
                            ),
                          },
                          onValueChanged: (val) {
                            if (val != null) _toggleForm();
                          },
                        ),
                      ),
                      if (_errorMessage != null) ...[
                        Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: errorColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(CupertinoIcons.exclamationmark_circle, color: errorColor, size: 20),
                              const SizedBox(width: 8),
                              Expanded(child: Text(_errorMessage!, style: TextStyle(color: errorColor, fontSize: 15))),
                            ],
                          ),
                        ),
                      ],
                      CupertinoTextFormFieldRow(
                        controller: _emailController,
                        placeholder: 'Email',
                        keyboardType: TextInputType.emailAddress,
                        style: TextStyle(color: textColor),
                        prefix: const Icon(CupertinoIcons.mail, size: 20),
                        validator: (value) => value != null && value.contains('@') ? null : 'Enter a valid email',
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      const SizedBox(height: 12),
                      CupertinoTextFormFieldRow(
                        controller: _passwordController,
                        placeholder: 'Password',
                        obscureText: true,
                        style: TextStyle(color: textColor),
                        prefix: const Icon(CupertinoIcons.lock, size: 20),
                        validator: (value) => value != null && value.length >= 6 ? null : 'Password must be at least 6 characters',
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      if (!_isSignIn) ...[
                        const SizedBox(height: 12),
                        CupertinoTextFormFieldRow(
                          controller: _confirmPasswordController,
                          placeholder: 'Confirm Password',
                          obscureText: true,
                          style: TextStyle(color: textColor),
                          prefix: const Icon(CupertinoIcons.lock_shield, size: 20),
                          validator: (value) => value == _passwordController.text ? null : 'Passwords do not match',
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: bgColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      _isLoading
                        ? const CupertinoActivityIndicator(radius: 16)
                        : CupertinoButton.filled(
                            borderRadius: BorderRadius.circular(12),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            onPressed: _submit,
                            child: Text(_isSignIn ? 'Sign In' : 'Sign Up', style: const TextStyle(fontSize: 18)),
                          ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
