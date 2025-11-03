import 'package:flutter/material.dart';

class HeureButton extends StatelessWidget {
  final String label;
  final String heure;
  final VoidCallback onTap;
  final Color? couleur;

  const HeureButton({
    super.key,
    required this.label,
    required this.heure,
    required this.onTap,
    this.couleur,
  });

  @override
  Widget build(BuildContext context) {
    final Color effectiveColor = couleur ?? Theme.of(context).primaryColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: effectiveColor.withOpacity(0.3)),
              borderRadius: BorderRadius.circular(10),
              color: effectiveColor.withOpacity(0.1),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  heure,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: effectiveColor,
                  ),
                ),
                Icon(
                  Icons.access_time,
                  size: 20,
                  color: effectiveColor,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
