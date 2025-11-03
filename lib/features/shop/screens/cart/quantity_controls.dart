import 'package:flutter/material.dart';


class QuantityControls extends StatelessWidget {
  const QuantityControls({
    super.key,
    required this.quantity,
    required this.onIncrement,
    required this.onDecrement,
    this.enabled = true,
    this.color,
    this.compact = false,
  });

  final int quantity;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final bool enabled;
  final Color? color;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = color ?? Colors.green.shade600;
    final bg = theme.brightness == Brightness.dark ? Colors.grey[850] : Colors.white;
    final disabledColor = Colors.grey.shade400;
    final size = compact ? 34.0 : 40.0;
    final iconSize = compact ? 16.0 : 18.0;
    final textStyle = theme.textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w600,
      color: enabled ? (theme.brightness == Brightness.dark ? Colors.white : Colors.black) : disabledColor,
    );

    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 6 : 8, vertical: compact ? 4 : 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Decrement
          GestureDetector(
            onTap: enabled && quantity > 0 ? onDecrement : null,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: enabled && quantity > 0 ? primary.withOpacity(0.08) : Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.remove_rounded,
                size: iconSize,
                color: enabled && quantity > 0 ? primary : disabledColor,
              ),
            ),
          ),

          // Quantity
          Padding(
            padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 12),
            child: Text(
              quantity.toString(),
              style: textStyle,
            ),
          ),

          // Increment
          GestureDetector(
            onTap: enabled ? onIncrement : null,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: enabled ? primary.withOpacity(0.12) : Colors.grey.shade100,
                shape: BoxShape.circle,
                boxShadow: enabled
                    ? [
                        BoxShadow(
                          color: primary.withOpacity(0.12),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                Icons.add_rounded,
                size: iconSize,
                color: enabled ? primary : disabledColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}