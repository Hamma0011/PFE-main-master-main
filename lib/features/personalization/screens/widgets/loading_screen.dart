import 'package:flutter/material.dart';

class LoadingScreen extends StatelessWidget {
  final String screenName;

  const LoadingScreen({super.key, required this.screenName});

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              "Chargement des $screenName...",
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
}
