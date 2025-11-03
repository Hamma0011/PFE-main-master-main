import 'package:flutter/material.dart';

class NoResultsState extends StatelessWidget {
  const NoResultsState({super.key, required this.currentFilter});
  final String currentFilter;

  @override
  Widget build(BuildContext context) {
    return  Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 50, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              'Aucun établissement trouvé pour "$currentFilter".',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
