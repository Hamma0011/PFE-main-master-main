/*import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/signup/verify_otp_controller.dart';

class OtpScreen extends StatelessWidget {
  final String email;
  const OtpScreen({super.key, required this.email});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(OTPVerificationController());

    return Scaffold(
      appBar: AppBar(title: const Text("Vérification OTP")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text("Un code OTP a été envoyé à : $email"),
            const SizedBox(height: 20),
            TextField(
              controller: controller.otpCode,
              decoration: const InputDecoration(
                labelText: "Code OTP",
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => controller.verifyOtp(email),
              child: const Text("Vérifier"),
            ),
          ],
        ),
      ),
    );
  }
}
*/
