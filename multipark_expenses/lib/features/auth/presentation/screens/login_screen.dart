import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../bloc/auth_bloc.dart';
import '../widgets/login_form.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.white),
                    const SizedBox(width: 12),
                    Expanded(child: Text(state.message)),
                  ],
                ),
                backgroundColor: AppTheme.errorColor,
                behavior: SnackBarBehavior.floating,
                margin: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            );
          }
        },
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 60),
                  // Logo e Título
                  _buildHeader(),
                  const SizedBox(height: 48),
                  // Formulário de Login
                  const LoginForm(),
                  const SizedBox(height: 32),
                  // Versão
                  _buildFooter(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // Logo Container
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Icon(
            Icons.local_parking_rounded,
            size: 56,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 24),
        // Título
        const Text(
          'MultiPark',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        // Subtítulo
        Text(
          'Módulo de Despesas',
          style: TextStyle(
            fontSize: 16,
            color: AppTheme.textSecondary.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        children: [
          Text(
            'MultiPark v1.0.0',
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textHint.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '© 2024 MultiPark. Todos os direitos reservados.',
            style: TextStyle(
              fontSize: 10,
              color: AppTheme.textHint.withOpacity(0.4),
            ),
          ),
        ],
      ),
    );
  }
}
