import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:aisyiyah_smartlife/modules/splash_screen/controllers/splashscreen_controller.dart';

class Splashscreen_view extends GetView<Splashscreen_controller> {
  const Splashscreen_view({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            const Icon(Icons.spa, size: 100, color: Color(0xFF4A9D9C)),

            const SizedBox(height: 24),

            const Text('Aisyiyah Smart Life', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF4A9D9C))),

            const SizedBox(height: 12),

            const Text('Organisasi Perempuan Berkemajuan', style: TextStyle(fontSize: 16, color: Colors.black54)),
            const SizedBox(height: 32),

            Obx(() => Column(
              children: [
                SizedBox(width   : 24, height  : 24,
                  child   : CircularProgressIndicator(strokeWidth : 2, valueColor  : AlwaysStoppedAnimation<Color>(const Color(0xFF4A9D9C).withOpacity(0.7))),
                ),

                const SizedBox(height: 16),

                Text(controller.statusMessage.value, style: const TextStyle(fontSize: 14, color: Colors.black54), textAlign: TextAlign.center),
              ],
            )),
          ],
        ),
      ),
    );
  }
}