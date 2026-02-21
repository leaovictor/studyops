import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/auth_controller.dart';
import '../core/theme/app_theme.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSignUp = false;
  bool _obscurePassword = true;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final controller = ref.read(authControllerProvider.notifier);
    if (_isSignUp) {
      await controller.signUpWithEmail(
        _emailController.text.trim(),
        _passwordController.text,
      );
    } else {
      await controller.signInWithEmail(
        _emailController.text.trim(),
        _passwordController.text,
      );
    }
  }

  Future<void> _googleSignIn() async {
    await ref.read(authControllerProvider.notifier).signInWithGoogle();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;

    ref.listen(authControllerProvider, (_, next) {
      if (next.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error.toString()),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    });

    return Scaffold(
      body: FadeTransition(
        opacity: _fadeAnim,
        child: Row(
          children: [
            // Left panel — shown on desktop
            if (MediaQuery.of(context).size.width >= 800)
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppTheme.bg0, AppTheme.bg1],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(48),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                AppTheme.primary,
                                AppTheme.primaryVariant
                              ],
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.school_rounded,
                              color: Colors.white, size: 30),
                        ),
                        const SizedBox(height: 32),
                        RichText(
                          text: const TextSpan(
                            children: [
                              TextSpan(
                                text: 'Study',
                                style: TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontSize: 40,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              TextSpan(
                                text: 'Ops',
                                style: TextStyle(
                                  color: AppTheme.primary,
                                  fontSize: 40,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Sistema inteligente de\nperformance para estudos.',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 18,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 48),
                        ...[
                          const _Feature(
                            icon: Icons.auto_awesome_rounded,
                            text: 'Cronograma gerado automaticamente',
                          ),
                          const _Feature(
                            icon: Icons.timer_rounded,
                            text: 'Pomodoro integrado no checklist',
                          ),
                          const _Feature(
                            icon: Icons.repeat_rounded,
                            text: 'Revisão espaçada inteligente',
                          ),
                          const _Feature(
                            icon: Icons.bar_chart_rounded,
                            text: 'Métricas de performance em tempo real',
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),

            // Right panel — form
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(32),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            _isSignUp ? 'Criar conta' : 'Entrar',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _isSignUp
                                ? 'Crie sua conta e comece a estudar com método'
                                : 'Bem-vindo de volta ao StudyOps',
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Email
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'E-mail',
                              prefixIcon: Icon(Icons.email_outlined),
                            ),
                            validator: (v) => (v?.contains('@') ?? false)
                                ? null
                                : 'E-mail inválido',
                          ),
                          const SizedBox(height: 16),

                          // Password
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: 'Senha',
                              prefixIcon:
                                  const Icon(Icons.lock_outline_rounded),
                              suffixIcon: IconButton(
                                icon: Icon(_obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined),
                                onPressed: () => setState(
                                    () => _obscurePassword = !_obscurePassword),
                              ),
                            ),
                            validator: (v) => (v?.length ?? 0) >= 6
                                ? null
                                : 'Mínimo 6 caracteres',
                          ),
                          const SizedBox(height: 24),

                          // Submit
                          FilledButton(
                            onPressed: isLoading ? null : _submit,
                            style: FilledButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(_isSignUp ? 'Criar conta' : 'Entrar'),
                          ),
                          const SizedBox(height: 16),

                          // Divider
                          const Row(
                            children: [
                              Expanded(child: Divider()),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16),
                                child: Text('ou',
                                    style:
                                        TextStyle(color: AppTheme.textMuted)),
                              ),
                              Expanded(child: Divider()),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Google Sign In
                          OutlinedButton.icon(
                            onPressed: isLoading ? null : _googleSignIn,
                            icon: const Icon(Icons.login_rounded, size: 18),
                            label: const Text('Entrar com Google'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Toggle
                          Center(
                            child: TextButton(
                              onPressed: () =>
                                  setState(() => _isSignUp = !_isSignUp),
                              child: Text(
                                _isSignUp
                                    ? 'Já tem conta? Entrar'
                                    : 'Não tem conta? Criar',
                                style: const TextStyle(color: AppTheme.primary),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Feature extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Feature({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppTheme.primary, size: 16),
          ),
          const SizedBox(width: 12),
          Text(text, style: const TextStyle(color: AppTheme.textSecondary)),
        ],
      ),
    );
  }
}
