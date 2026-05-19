import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../providers/perfil_provider.dart';

class PerfilScreen extends StatelessWidget {
  const PerfilScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Usa el PerfilProvider global (registrado en main.dart)
    return const _PerfilView();
  }
}

class _PerfilView extends StatelessWidget {
  const _PerfilView();

  @override
  Widget build(BuildContext context) {
    final nxt = context.nxt;
    return Scaffold(
      backgroundColor: nxt.surfaceAlt,
      appBar: AppBar(
        backgroundColor: nxt.surface,
        foregroundColor: nxt.ink,
        elevation: 0,
        title: Text('Mi perfil',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: nxt.ink)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: nxt.border),
        ),
      ),
      body: Consumer<PerfilProvider>(
        builder: (context, prov, _) {
          if (prov.isLoading) {
            return Center(
              child: CircularProgressIndicator(
                  color: NexusColors.primary, strokeWidth: 2),
            );
          }
          if (prov.error != null && prov.usuario == null) {
            return Center(
              child: Text(prov.error!,
                  style: NexusText.small.copyWith(color: NexusColors.danger)),
            );
          }
          return _PerfilContent(prov: prov);
        },
      ),
    );
  }
}

class _PerfilContent extends StatelessWidget {
  final PerfilProvider prov;
  const _PerfilContent({required this.prov});

  @override
  Widget build(BuildContext context) {
    final nxt = context.nxt;
    final usuario = prov.usuario!;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(NexusSizes.space2XL),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _AvatarSection(prov: prov),
              const SizedBox(height: NexusSizes.space3XL),

              // Mensajes de feedback
              if (prov.error != null)
                _Banner(text: prov.error!, isError: true, onClose: prov.clearMessages),
              if (prov.successMsg != null)
                _Banner(text: prov.successMsg!, isError: false, onClose: prov.clearMessages),

              const SizedBox(height: 4),
              _InfoCard(
                children: [
                  _InfoRow(label: 'Nombre', value: usuario.nombreCompleto, nxt: nxt),
                  _Divider(nxt: nxt),
                  _InfoRow(label: 'Email', value: usuario.email, nxt: nxt),
                  _Divider(nxt: nxt),
                  _InfoRow(
                    label: 'Roles',
                    value: usuario.roles
                        .map(_rolLabel)
                        .join(', '),
                    nxt: nxt,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _rolLabel(String r) => switch (r) {
        'ROLE_ALUMNO' => 'Alumno',
        'ROLE_TUTOR_CENTRO' => 'Tutor de centro',
        'ROLE_TUTOR_EMPRESA' => 'Tutor de empresa',
        'ROLE_ADMIN' => 'Administrador',
        _ => r,
      };
}

class _AvatarSection extends StatelessWidget {
  final PerfilProvider prov;
  const _AvatarSection({required this.prov});

  @override
  Widget build(BuildContext context) {
    final nxt = context.nxt;
    final usuario = prov.usuario!;
    final initials = _initials(usuario.nombreCompleto);

    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            CircleAvatar(
              radius: 56,
              backgroundColor: nxt.primaryLight,
              backgroundImage:
                  prov.fotoBytes != null ? MemoryImage(prov.fotoBytes!) : null,
              child: prov.fotoBytes == null
                  ? Text(
                      initials,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: nxt.primaryColor,
                      ),
                    )
                  : null,
            ),
            _EditAvatarBtn(prov: prov),
          ],
        ),
        const SizedBox(height: NexusSizes.spaceMD),
        Text(
          usuario.nombreCompleto,
          style: NexusText.heading2.copyWith(color: nxt.ink),
        ),
        const SizedBox(height: NexusSizes.spaceXS),
        Text(
          usuario.email,
          style: NexusText.small.copyWith(color: nxt.inkSecondary),
        ),
      ],
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    if (parts.isNotEmpty && parts[0].isNotEmpty) return parts[0][0].toUpperCase();
    return '?';
  }
}

class _EditAvatarBtn extends StatelessWidget {
  final PerfilProvider prov;
  const _EditAvatarBtn({required this.prov});

  @override
  Widget build(BuildContext context) {
    if (prov.isUploading) {
      return Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: NexusColors.primary,
        ),
        child: const Padding(
          padding: EdgeInsets.all(8),
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.white,
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () => prov.seleccionarYSubirFoto(),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: NexusColors.primary,
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: const Icon(Icons.camera_alt, size: 18, color: Colors.white),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final List<Widget> children;
  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) {
    final nxt = context.nxt;
    return Container(
      decoration: BoxDecoration(
        color: nxt.surface,
        borderRadius: BorderRadius.circular(NexusSizes.radiusLG),
        border: Border.all(color: nxt.border, width: NexusSizes.borderWidth),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final NexusThemeExt nxt;
  const _InfoRow({required this.label, required this.value, required this.nxt});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: NexusSizes.spaceLG, vertical: NexusSizes.spaceMD),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label,
                style: NexusText.small.copyWith(
                    color: nxt.inkSecondary, fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Text(value, style: NexusText.body.copyWith(color: nxt.ink)),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  final NexusThemeExt nxt;
  const _Divider({required this.nxt});

  @override
  Widget build(BuildContext context) =>
      Divider(height: 1, thickness: NexusSizes.borderWidth, color: nxt.border,
          indent: NexusSizes.spaceLG, endIndent: NexusSizes.spaceLG);
}

class _Banner extends StatelessWidget {
  final String text;
  final bool isError;
  final VoidCallback onClose;
  const _Banner({required this.text, required this.isError, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final bg = isError ? NexusColors.dangerLight : NexusColors.successLight;
    final fg = isError ? NexusColors.dangerText : NexusColors.successText;
    return Container(
      margin: const EdgeInsets.only(bottom: NexusSizes.spaceLG),
      padding: const EdgeInsets.symmetric(
          horizontal: NexusSizes.spaceMD, vertical: NexusSizes.spaceSM),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(NexusSizes.radiusMD),
        border: Border.all(
            color: isError ? NexusColors.danger : NexusColors.success,
            width: NexusSizes.borderWidth),
      ),
      child: Row(
        children: [
          Expanded(child: Text(text, style: NexusText.small.copyWith(color: fg))),
          GestureDetector(
            onTap: onClose,
            child: Icon(Icons.close, size: 16, color: fg),
          ),
        ],
      ),
    );
  }
}
