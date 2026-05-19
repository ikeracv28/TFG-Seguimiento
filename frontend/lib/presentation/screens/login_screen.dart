import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/nexus_logo.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (!auth.sessionChecked) {
      return const Scaffold(
        backgroundColor: NexusColors.surfaceAlt,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              NexusIcon(size: 48, variant: NexusLogoVariant.dark),
              SizedBox(height: 24),
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: NexusColors.primary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 800) {
          return const _DesktopLogin();
        }
        return const _MobileLogin();
      },
    );
  }
}

// ── Desktop: panel izquierdo azul + panel derecho blanco ────────────────────

class _DesktopLogin extends StatelessWidget {
  const _DesktopLogin();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.nxt.surface,
      body: Row(
        children: [
          // Panel izquierdo — branding
          Expanded(
            child: Container(
              color: NexusColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 56, vertical: 64),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Wordmark en blanco
                  const NexusLogo(height: 36, variant: NexusLogoVariant.light),
                  const SizedBox(height: 8),
                  Text(
                    'Plataforma de Prácticas FCT',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Colors.white.withAlpha(200),
                    ),
                  ),
                  const Spacer(),
                  // Features
                  ...[
                    ('Seguimiento en tiempo real', 'Partes de trabajo, incidencias y chat con el tutor.'),
                    ('Gestión centralizada', 'Empresas, alumnos y convenios en un solo lugar.'),
                    ('Informes automáticos', 'Exporta el historial en PDF y Excel con un clic.'),
                  ].map((f) => _FeatureBullet(title: f.$1, desc: f.$2)),
                  const Spacer(),
                  Text(
                    'CampusFP · Nexus v1.0',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: Colors.white.withAlpha(130),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Panel derecho — formulario
          Expanded(
            child: Container(
              color: context.nxt.surface,
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(48),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 380),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const NexusLogo(height: 44),
                        const SizedBox(height: 32),
                        Text(
                          'Bienvenido de nuevo',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            color: context.nxt.ink,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Accede con tu cuenta institucional',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            color: context.nxt.inkSecondary,
                          ),
                        ),
                        const SizedBox(height: 32),
                        const _LoginForm(),
                        const SizedBox(height: 24),
                        _ThemeToggle(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureBullet extends StatelessWidget {
  final String title;
  final String desc;
  const _FeatureBullet({required this.title, required this.desc});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 3),
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(180),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    color: Colors.white.withAlpha(180),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Mobile: card centrada ────────────────────────────────────────────────────

class _MobileLogin extends StatelessWidget {
  const _MobileLogin();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.nxt.surfaceAlt,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(NexusSizes.space2XL),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const NexusLogo(height: 48),
                const SizedBox(height: NexusSizes.space2XL),
                Container(
                  padding: const EdgeInsets.all(NexusSizes.space3XL),
                  decoration: BoxDecoration(
                    color: context.nxt.surface,
                    border: Border.all(color: context.nxt.border, width: NexusSizes.borderWidth),
                    borderRadius: BorderRadius.circular(NexusSizes.radiusLG),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Iniciar sesión',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: context.nxt.ink,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Accede con tu cuenta institucional',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          color: context.nxt.inkTertiary,
                        ),
                      ),
                      const SizedBox(height: NexusSizes.space2XL),
                      const _LoginForm(),
                    ],
                  ),
                ),
                const SizedBox(height: NexusSizes.spaceLG),
                _ThemeToggle(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Formulario compartido ────────────────────────────────────────────────────

class _LoginForm extends StatefulWidget {
  const _LoginForm();

  @override
  State<_LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<_LoginForm> {
  final _emailController    = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey            = GlobalKey<FormState>();
  bool _obscurePassword     = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final success = await auth.login(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );
    if (!mounted) return;
    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage ?? 'Error al conectar con el servidor'),
          backgroundColor: NexusColors.danger,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(NexusSizes.radiusMD)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _FieldLabel(label: 'Correo electrónico'),
          const SizedBox(height: NexusSizes.spaceXS),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            style: NexusText.small,
            decoration: const InputDecoration(hintText: 'nombre@centro.edu'),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Campo obligatorio';
              if (!v.contains('@')) return 'Introduce un email válido';
              return null;
            },
          ),
          const SizedBox(height: NexusSizes.spaceLG),

          const _FieldLabel(label: 'Contraseña'),
          const SizedBox(height: NexusSizes.spaceXS),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            style: NexusText.small,
            decoration: InputDecoration(
              hintText: '••••••••',
              suffixIcon: GestureDetector(
                onTap: () => setState(() => _obscurePassword = !_obscurePassword),
                child: Icon(
                  _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  size: 18,
                  color: NexusColors.inkTertiary,
                ),
              ),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Campo obligatorio';
              if (v.length < 6) return 'Mínimo 6 caracteres';
              return null;
            },
          ),
          const SizedBox(height: NexusSizes.space2XL),

          Consumer<AuthProvider>(
            builder: (context, auth, _) => SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: auth.isLoading ? null : _handleLogin,
                child: auth.isLoading
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Acceder'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String label;
  const _FieldLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: NexusColors.inkSecondary,
      ),
    );
  }
}

class _ThemeToggle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'CampusFP · Nexus v1.0',
          style: TextStyle(fontSize: 12, color: NexusColors.inkTertiary),
        ),
        const SizedBox(width: NexusSizes.spaceSM),
        GestureDetector(
          onTap: () => context.read<ThemeProvider>().toggle(),
          child: Icon(
            isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
            size: 16,
            color: NexusColors.inkTertiary,
          ),
        ),
      ],
    );
  }
}
