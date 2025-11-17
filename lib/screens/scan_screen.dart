// lib/screens/scan_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:unipantry/screens/manual_entry_screen.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:http/http.dart' as http;

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  bool _isProcessing = false;

  // This function calls the OpenFoodFacts API
  Future<String?> _fetchProductName(String barcode) async {
    final uri = Uri.parse(
        'https://world.openfoodfacts.org/api/v0/product/$barcode.json?fields=product_name');
    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 1) {
          return data['product']['product_name'];
        }
      }
    } catch (e) {
      // Handle error (e.g., no internet)
      print(e);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Barcode')),
      body: Stack(
        children: [
          MobileScanner(
            // This function is called when a barcode is detected
            onDetect: (capture) async {
              if (_isProcessing) return;

              setState(() {
                _isProcessing = true;
              });

              final barcode = capture.barcodes.first.rawValue;
              if (barcode == null) return;

              // 1. Fetch the product name from the API
              final productName = await _fetchProductName(barcode);

              // 2. Navigate to the ManualEntryScreen, pre-filling the name
              if (mounted) {
                Navigator.pop(context); // Pop the scanner
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ManualEntryScreen(
                      scannedItemName: productName,
                    ),
                  ),
                );
              }
            },
          ),
          // A simple overlay
          Center(
            child: Container(
              width: 250,
              height: 150,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.red, width: 2),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          // Loading indicator
          if (_isProcessing)
            const Center(
              child: Card(
                color: Colors.black54,
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Fetching product...',
                          style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}