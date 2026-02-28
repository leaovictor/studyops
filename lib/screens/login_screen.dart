import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../controllers/auth_controller.dart';
import '../widgets/landing_components.dart';

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
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim =
        CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic);
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
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: LandingTheme.background,
      body: Stack(
        children: [
          // Background Glows
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: LandingTheme.primary.withValues(alpha: 0.1),
              ),
            ),
          ),
          Positioned(
            bottom: -150,
            left: -150,
            child: Container(
              width: 500,
              height: 500,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: LandingTheme.secondary.withValues(alpha: 0.1),
              ),
            ),
          ),

          FadeTransition(
            opacity: _fadeAnim,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Container(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 64),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Brand Logo/Header
                          GestureDetector(
                            onTap: () => context.go('/'),
                            child: Hero(
                              tag: 'brand_logo',
                              child: Text(
                                'StudyOps',
                                style: GoogleFonts.inter(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: -1.5,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 48),

                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 450),
                            child: GlassCard(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16, // Reduced on mobile if needed
                                vertical: 40,
                              ),
                              borderColor:
                                  LandingTheme.primary.withValues(alpha: 0.2),
                              child: Form(
                                key: _formKey,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 24),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Text(
                                        _isSignUp
                                            ? 'Criar conta'
                                            : 'Acesse sua conta',
                                        style: GoogleFonts.inter(
                                          fontSize: 24,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        _isSignUp
                                            ? 'Inicie sua jornada na engenharia de aprendizado.'
                                            : 'Bem-vindo de volta à orquestração do seu sucesso.',
                                        style: GoogleFonts.inter(
                                          color: LandingTheme.textSecondary,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 40),

                                      // Email
                                      _buildTextField(
                                        controller: _emailController,
                                        label: 'E-mail',
                                        icon: Icons.email_outlined,
                                        keyboardType:
                                            TextInputType.emailAddress,
                                        validator: (v) =>
                                            (v?.contains('@') ?? false)
                                                ? null
                                                : 'E-mail inválido',
                                      ),
                                      const SizedBox(height: 20),

                                      // Password
                                      _buildTextField(
                                        controller: _passwordController,
                                        label: 'Senha',
                                        icon: Icons.lock_outline_rounded,
                                        obscureText: _obscurePassword,
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            _obscurePassword
                                                ? Icons.visibility_off_outlined
                                                : Icons.visibility_outlined,
                                            color: LandingTheme.textSecondary,
                                            size: 20,
                                          ),
                                          onPressed: () => setState(() =>
                                              _obscurePassword =
                                                  !_obscurePassword),
                                        ),
                                        validator: (v) => (v?.length ?? 0) >= 6
                                            ? null
                                            : 'Mínimo 6 caracteres',
                                      ),
                                      const SizedBox(height: 32),

                                      // Submit
                                      ElevatedButton(
                                        onPressed: isLoading ? null : _submit,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: LandingTheme.primary,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 20),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          elevation: 0,
                                        ),
                                        child: isLoading
                                            ? const SizedBox(
                                                width: 20,
                                                height: 20,
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  color: Colors.white,
                                                ),
                                              )
                                            : Text(
                                                _isSignUp
                                                    ? 'Criar conta gratuita'
                                                    : 'Entrar no StudyOps',
                                                style: GoogleFonts.inter(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                              ),
                                      ),
                                      const SizedBox(height: 24),

                                      // Divider
                                      Row(
                                        children: [
                                          Expanded(
                                              child: Divider(
                                                  color: LandingTheme.border
                                                      .withValues(alpha: 0.5))),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 16),
                                            child: Text(
                                              'ou',
                                              style: GoogleFonts.inter(
                                                color: LandingTheme.textMuted,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                              child: Divider(
                                                  color: LandingTheme.border
                                                      .withValues(alpha: 0.5))),
                                        ],
                                      ),
                                      const SizedBox(height: 24),

                                      // Google Sign In
                                      OutlinedButton.icon(
                                        onPressed: isLoading
                                            ? null
                                            : () async {
                                                try {
                                                  await _googleSignIn();
                                                } catch (e) {
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                    SnackBar(
                                                      content:
                                                          Text(e.toString()),
                                                      backgroundColor:
                                                          Colors.redAccent,
                                                    ),
                                                  );
                                                }
                                              },
                                        icon: const Icon(Icons.login_rounded,
                                            size: 18),
                                        label:
                                            const Text('Continuar com Google'),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 16),
                                          side: BorderSide(
                                              color: LandingTheme.border),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 32),

                                      // Toggle
                                      Center(
                                        child: TextButton(
                                          onPressed: () => setState(
                                              () => _isSignUp = !_isSignUp),
                                          child: RichText(
                                            text: TextSpan(
                                              text: _isSignUp
                                                  ? 'Já tem uma conta? '
                                                  : 'Ainda não tem conta? ',
                                              style: GoogleFonts.inter(
                                                color:
                                                    LandingTheme.textSecondary,
                                                fontSize: 14,
                                              ),
                                              children: [
                                                TextSpan(
                                                  text: _isSignUp
                                                      ? 'Entrar'
                                                      : 'Criar agora',
                                                  style: const TextStyle(
                                                    color: LandingTheme.primary,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 40),
                          TextButton.icon(
                            onPressed: () => context.go('/'),
                            icon: const Icon(Icons.arrow_back, size: 16),
                            label: Text(
                              'Voltar para a home',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: TextButton.styleFrom(
                              foregroundColor: LandingTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          style: GoogleFonts.inter(color: Colors.white, fontSize: 16),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: LandingTheme.textSecondary, size: 20),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.05),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  BorderSide(color: Colors.white.withValues(alpha: 0.1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: LandingTheme.primary, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.redAccent),
            ),
            hintText: 'Digite seu ${label.toLowerCase()}',
            hintStyle:
                GoogleFonts.inter(color: LandingTheme.textMuted, fontSize: 14),
          ),
          validator: validator,
        ),
      ],
    );
  }
}
