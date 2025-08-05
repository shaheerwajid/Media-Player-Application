import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class StatusOverlays {
  static Widget seek({required BuildContext context, required double offset}) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.85),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Text(
          '${offset > 0 ? '+' : ''}${offset.round()}s',
          style: GoogleFonts.poppins(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  static Widget volume({
    required BuildContext context,
    required double volume,
  }) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.85),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.volume_up,
              color: Theme.of(context).colorScheme.primary,
              size: 32,
            ),
            Text(
              '${(volume * 100).round()}%',
              style: GoogleFonts.poppins(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget brightness(BuildContext context, double level) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.85),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.brightness_6,
              color: Theme.of(context).colorScheme.primary,
              size: 40,
            ),
            const SizedBox(height: 8),
            Text(
              '${(level * 100).toInt()}%',
              style: GoogleFonts.poppins(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget aspectRatio(BuildContext context, String text) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.85),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Text(
          text,
          style: GoogleFonts.poppins(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
