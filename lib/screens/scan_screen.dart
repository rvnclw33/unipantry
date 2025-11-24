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

  // UPDATED: Return a Map instead of just a String
  Future<Map<String, dynamic>?> _fetchProductDetails(String barcode) async {
    // We request specific fields: name, brands, quantity, and generic_name (description)
    final uri = Uri.parse(
        'https://world.openfoodfacts.org/api/v0/product/$barcode.json?fields=product_name,brands,quantity,generic_name');
    
    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 1) {
          final product = data['product'];
          
          return {
            'name': product['product_name'] as String?,
            'brand': product['brands'] as String?,
            'description': product['generic_name'] as String?, // Often holds the description
            'quantity': product['quantity'] as String?, // e.g. "500g"
          };
        }
      }
    } catch (e) {
      print("Error fetching product: $e");
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
            onDetect: (capture) async {
              if (_isProcessing) return;

              setState(() {
                _isProcessing = true;
              });

              final barcode = capture.barcodes.first.rawValue;
              if (barcode == null) {
                setState(() => _isProcessing = false);
                return;
              }

              // 1. Fetch all details
              final productData = await _fetchProductDetails(barcode);

              if (mounted) {
                Navigator.pop(context); // Close scanner
                
                // 2. Navigate to Entry Screen with ALL data
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ManualEntryScreen(
                      scannedItemName: productData?['name'],
                      scannedBrand: productData?['brand'],
                      scannedBarcode: barcode,
                      // We combine quantity and description for the notes field if available
                      scannedDescription: _formatDescription(productData), 
                    ),
                  ),
                );
              }
            },
          ),
          
           if (_isProcessing)
            const Center(
              child: Card(
                color: Colors.black54,
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: Colors.white),
                      SizedBox(height: 16),
                      Text('Fetching product details...',
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

  // Helper to combine generic name and quantity into a useful description
  String? _formatDescription(Map<String, dynamic>? data) {
    if (data == null) return null;
    
    final desc = data['description'];
    final qty = data['quantity'];

    if (desc != null && qty != null) return '$desc ($qty)';
    if (desc != null) return desc;
    if (qty != null) return 'Size: $qty';
    
    return null;
  }
}