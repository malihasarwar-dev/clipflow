import 'package:flutter/material.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms & Conditions'),
      ),
      body: const Padding(
        padding: EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Terms of Service',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              Text(
                'Welcome to ClipFlow. By using our website and services, you agree to comply with and be bound by the following terms and conditions. Please read them carefully.\n\n'
                '1. Use of Service: You agree to use this tool only for lawful purposes and content that you own or have the explicit legal right to process.\n\n'
                '2. Copyright: We do not claim ownership of any YouTube content processed through our platform. Users are solely responsible for the clips they generate and publish.\n\n'
                '3. Limitation of Liability: The service is provided "as is" without warranties of any kind.',
                style: TextStyle(fontSize: 16, height: 1.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}