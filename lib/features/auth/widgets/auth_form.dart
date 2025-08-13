import 'package:flutter/material.dart';
import '../../../core/utils/constants.dart';

class AuthForm extends StatelessWidget {
  final bool isLogin;
  final Function(String email, String password) onSubmit;
  final bool isLoading;

  const AuthForm({
    super.key,
    this.isLogin = true,
    required this.onSubmit,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final _formKey = GlobalKey<FormState>();
    final _emailController = TextEditingController();
    final _passwordController = TextEditingController();

    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Email',
              hintText: AppConstants.emailPlaceholder,
            ),
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your email';
              }
              return null;
            },
          ),
          const SizedBox(height: AppConstants.defaultPadding),
          TextFormField(
            controller: _passwordController,
            decoration: const InputDecoration(
              labelText: 'Password',
              hintText: AppConstants.passwordPlaceholder,
            ),
            obscureText: true,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your password';
              }
              return null;
            },
          ),
          const SizedBox(height: AppConstants.largePadding),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () {
                      if (_formKey.currentState!.validate()) {
                        onSubmit(
                          _emailController.text.trim(),
                          _passwordController.text,
                        );
                      }
                    },
              child: isLoading
                  ? const CircularProgressIndicator()
                  : Text(isLogin ? 'Login' : 'Sign Up'),
            ),
          ),
        ],
      ),
    );
  }
} 