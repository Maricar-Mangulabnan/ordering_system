// customer-products.dart

import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:ordering_system/settings.dart';

class CustomerProductsPage extends StatefulWidget {
  final Map<String, dynamic> user;

  const CustomerProductsPage({Key? key, required this.user}) : super(key: key);

  @override
  _CustomerProductsPageState createState() => _CustomerProductsPageState();
}

class _CustomerProductsPageState extends State<CustomerProductsPage> {
  // Your production server base URL
  final String baseUrl = 'https://orderko-server.onrender.com';
  List<Map<String, dynamic>> products = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  // Fetch products from the server (GET /products)
  Future<void> _fetchProducts() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/products'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          products = List<Map<String, dynamic>>.from(data);
          isLoading = false;
        });
      } else {
        print('Failed to fetch products. Status: ${response.statusCode}');
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching products: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  // Navigate to the Settings page
  void _navigateToSettingsPage() {
    Navigator.push(
      context,
      CupertinoPageRoute(builder: (context) => SettingsPage(user: widget.user)),
    );
  }

  // Show product details and offer Add to Cart
  void _showProductDialog(Map<String, dynamic> product) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(product['name']),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Price: ₱${(product['price'] as num).toStringAsFixed(2)}'),
            Text('Stock: ${product['stock']}'),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Close'),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('Add to Cart'),
            onPressed: () {
              Navigator.pop(context);
              _addToCart(product);
            },
          ),
        ],
      ),
    );
  }

  // Add product to cart by creating an order record (POST /orders)
  Future<void> _addToCart(Map<String, dynamic> product) async {
    // Prepare order data with count = 1 (default)
    final orderData = {
      'userId': widget.user['id'],
      'productId': product['id'],
      'count': 1,
    };

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/orders'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(orderData),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        _showAddToCartSuccessDialog(product);
      } else {
        _showErrorDialog('Failed to add to cart. (${response.statusCode})');
      }
    } catch (e) {
      _showErrorDialog('Failed to add to cart. Please try again.');
    }
  }

  void _showAddToCartSuccessDialog(Map<String, dynamic> product) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Added to Cart'),
        content: Text('${product['name']} has been added to your cart.'),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Customer Products'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.settings),
          onPressed: _navigateToSettingsPage,
        ),
      ),
      child: SafeArea(
        child: isLoading
            ? const Center(child: CupertinoActivityIndicator())
            : ListView.builder(
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index];
            return CupertinoListTile(
              onTap: () => _showProductDialog(product),
              leading: Image.network(
                product['imgUrl'], // use the server key 'imgUrl'
                width: 60,
                height: 60,
                fit: BoxFit.cover,
              ),
              title: Text(product['name']),
              subtitle: Text('₱${(product['price'] as num).toStringAsFixed(2)}'),
            );
          },
        ),
      ),
    );
  }
}