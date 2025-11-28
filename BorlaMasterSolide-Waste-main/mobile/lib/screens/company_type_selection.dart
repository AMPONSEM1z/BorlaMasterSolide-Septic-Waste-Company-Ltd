import 'package:flutter/material.dart';

class CompanyTypeSelectionScreen extends StatefulWidget {
  const CompanyTypeSelectionScreen({super.key});

  @override
  State<CompanyTypeSelectionScreen> createState() =>
      _CompanyTypeSelectionScreenState();
}

class _CompanyTypeSelectionScreenState
    extends State<CompanyTypeSelectionScreen> {
  String? selectedType;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Select Collection Type"),
        backgroundColor: Colors.green,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "What type of collection do you handle?",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),

            // Solid Waste
            RadioListTile<String>(
              value: "solid",
              groupValue: selectedType,
              onChanged: (value) => setState(() => selectedType = value),
              title: const Text("Solid Waste Collection"),
            ),

            // Septic Waste
            RadioListTile<String>(
              value: "septic",
              groupValue: selectedType,
              onChanged: (value) => setState(() => selectedType = value),
              title: const Text("Septic Waste Collection"),
            ),

            const SizedBox(height: 40),

            ElevatedButton(
              onPressed: selectedType == null
                  ? null
                  : () {
                      Navigator.pushNamed(
                        context,
                        '/register_company',
                        arguments: selectedType,
                      );
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                minimumSize: const Size(double.infinity, 60),
              ),
              child: const Text(
                "Continue",
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}