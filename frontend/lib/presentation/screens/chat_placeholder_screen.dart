import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class ChatPlaceholderScreen extends StatelessWidget {
  const ChatPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NexusColors.surfaceAlt,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(NexusSizes.space3XL),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: NexusColors.primaryLight,
                  borderRadius: BorderRadius.circular(NexusSizes.radiusLG),
                ),
                child: const Icon(
                  Icons.chat_bubble_outline,
                  size: 32,
                  color: NexusColors.primary,
                ),
              ),
              const SizedBox(height: NexusSizes.space2XL),
              Text(
                'Chat en tiempo real',
                style: NexusText.heading3,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: NexusSizes.spaceSM),
              Text(
                'Comunicacion directa con tu tutor del centro.\nDisponible en el Hito 3.',
                style: NexusText.caption,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: NexusSizes.space2XL),
              nexusEstadoBadge(
                'Proximo — Hito 3',
                bg: NexusColors.primaryLight,
                textColor: NexusColors.primaryText,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
