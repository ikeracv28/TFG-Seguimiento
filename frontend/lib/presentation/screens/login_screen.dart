import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';
import 'dashboard_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NexusColors.surfaceAlt,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(NexusSizes.space2XL),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const _NexusLogo(),
                const SizedBox(height: NexusSizes.space2XL),
                const _LoginCard(),
                const SizedBox(height: NexusSizes.spaceLG),
                Text(
                  'CampusFP · Nexus v1.0',
                  style: NexusText.caption.copyWith(color: NexusColors.inkTertiary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Logo: red de nodos con letras A, T, A, E

class _NexusLogo extends StatelessWidget {
  const _NexusLogo();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: 96,
          height: 96,
          child: CustomPaint(painter: _NexusNetworkPainter()),
        ),
        const SizedBox(height: NexusSizes.spaceMD),
        const Text('Nexus', style: NexusText.heading1),
        const SizedBox(height: NexusSizes.spaceXS),
        Text(
          'Gestión de Prácticas Académicas',
          style: NexusText.small.copyWith(color: NexusColors.inkSecondary),
        ),
      ],
    );
  }
}

class _NexusNetworkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Nodos: centro + 4 extremos (A=Alumno, T=Tutor, A=Admin, E=Empresa)
    final center    = Offset(w * 0.50, h * 0.50);
    final nodeTop   = Offset(w * 0.50, h * 0.07); // T — Tutor
    final nodeRight = Offset(w * 0.93, h * 0.50); // A — Admin
    final nodeBot   = Offset(w * 0.50, h * 0.93); // E — Empresa
    final nodeLeft  = Offset(w * 0.07, h * 0.50); // A — Alumno

    // Pincel de lineas
    final linePaint = Paint()
      ..color = NexusColors.primary.withAlpha(60)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    // Lineas entre nodos extremos (cuadrado exterior)
    canvas.drawLine(nodeLeft, nodeTop, linePaint);
    canvas.drawLine(nodeTop, nodeRight, linePaint);
    canvas.drawLine(nodeRight, nodeBot, linePaint);
    canvas.drawLine(nodeBot, nodeLeft, linePaint);

    // Lineas hub (centro a cada extremo)
    final hubPaint = Paint()
      ..color = NexusColors.primary.withAlpha(110)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    for (final node in [nodeTop, nodeRight, nodeBot, nodeLeft]) {
      canvas.drawLine(center, node, hubPaint);
    }

    // Nodo central (relleno azul)
    canvas.drawCircle(
      center,
      5.5,
      Paint()..color = NexusColors.primary,
    );

    // Nodos extremos con letra
    _drawLabeledNode(canvas, nodeLeft,  'A', w * 0.135);
    _drawLabeledNode(canvas, nodeTop,   'T', w * 0.135);
    _drawLabeledNode(canvas, nodeRight, 'A', w * 0.135);
    _drawLabeledNode(canvas, nodeBot,   'E', w * 0.135);
  }

  void _drawLabeledNode(Canvas canvas, Offset center, String letter, double radius) {
    const r = 11.0;

    // Fondo blanco del nodo
    canvas.drawCircle(center, r, Paint()..color = NexusColors.surface);

    // Borde azul del nodo
    canvas.drawCircle(
      center,
      r,
      Paint()
        ..color = NexusColors.primary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Letra centrada
    final tp = TextPainter(
      text: TextSpan(
        text: letter,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: NexusColors.primary,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Card del formulario de login

class _LoginCard extends StatefulWidget {
  const _LoginCard();

  @override
  State<_LoginCard> createState() => _LoginCardState();
}

class _LoginCardState extends State<_LoginCard> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;

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
    if (success) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    } else {
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
    return Container(
      padding: const EdgeInsets.all(NexusSizes.space3XL),
      decoration: BoxDecoration(
        color: NexusColors.surface,
        border: Border.all(color: NexusColors.border, width: NexusSizes.borderWidth),
        borderRadius: BorderRadius.circular(NexusSizes.radiusLG),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Iniciar sesión', style: NexusText.heading3),
            const SizedBox(height: NexusSizes.spaceXS),
            Text(
              'Accede con tu cuenta institucional',
              style: NexusText.caption.copyWith(color: NexusColors.inkTertiary),
            ),
            const SizedBox(height: NexusSizes.space2XL),

            // Campo email
            _FieldLabel(label: 'Correo electrónico'),
            const SizedBox(height: NexusSizes.spaceXS),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              style: NexusText.small,
              decoration: const InputDecoration(
                hintText: 'nombre@centro.edu',
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Campo obligatorio';
                if (!v.contains('@')) return 'Introduce un email valido';
                return null;
              },
            ),
            const SizedBox(height: NexusSizes.spaceLG),

            // Campo contraseña
            _FieldLabel(label: 'Contraseña'),
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
                if (v.length < 6) return 'Minimo 6 caracteres';
                return null;
              },
            ),
            const SizedBox(height: NexusSizes.space2XL),

            // Boton de acceso
            Consumer<AuthProvider>(
              builder: (context, auth, _) {
                return SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: auth.isLoading ? null : _handleLogin,
                    child: auth.isLoading
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Acceder'),
                  ),
                );
              },
            ),
          ],
        ),
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
      style: NexusText.label.copyWith(
        color: NexusColors.inkSecondary,
        letterSpacing: 0.3,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
