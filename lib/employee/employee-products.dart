// employee-products.dart

import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:ordering_system/settings.dart';
import 'package:ordering_system/employee/employee-orders.dart';

class EmployeeProductsPage extends StatefulWidget {
  final Map<String, dynamic> user;

  const EmployeeProductsPage({Key? key, required this.user}) : super(key: key);

  @override
  _EmployeeProductsPageState createState() => _EmployeeProductsPageState();
}

class _EmployeeProductsPageState extends State<EmployeeProductsPage> {
  // Use your production URL here
  final String baseUrl = 'https://orderko-server.onrender.com';
  List<Map<String, dynamic>> products = [];

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  // Fetch the list of products from the server (GET /products)
  Future<void> _fetchProducts() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/products'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          products = List<Map<String, dynamic>>.from(data);
        });
      } else {
        print('Failed to fetch products: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching products: $e');
    }
  }

  // Navigate to the Settings page
  void _navigateToSettingsPage() {
    Navigator.push(
      context,
      CupertinoPageRoute(builder: (context) => SettingsPage(user: widget.user)),
    );
  }

  // Navigate to the Orders page (EmployeeOrdersPage)
  void _navigateToOrdersPage() {
    Navigator.push(
      context,
      CupertinoPageRoute(builder: (context) => EmployeeOrdersPage(user: widget.user)),
    );
  }

  // Show the Add Product modal to post new product data
  void _showAddProductModal() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => AddProductModal(
        baseUrl: baseUrl,
        onProductAdded: (newProduct) {
          setState(() {
            products.add(newProduct);
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Products'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.settings),
          onPressed: _navigateToSettingsPage,
        ),
      ),
      child: Stack(
        children: [
          SafeArea(
            child: ListView.builder(
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                return CupertinoListTile(
                  leading: Image.network(
                    product['imgUrl'], // using key 'imgUrl' from the server
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                  ),
                  title: Text(product['name']),
                  subtitle: Text(
                    '₱${(product['price'] as num).toStringAsFixed(2)} | Stock: ${product['stock']}',
                  ),
                );
              },
            ),
          ),
          // Floating Buttons for adding product and viewing order logs
          Positioned(
            bottom: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CupertinoButton.filled(
                  onPressed: _showAddProductModal,
                  child: const Text('Add Product'),
                ),
                const SizedBox(width: 10),
                CupertinoButton.filled(
                  onPressed: _navigateToOrdersPage,
                  child: const Text('Logs'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Add Product Modal: posts new product data to the server (POST /products)
class AddProductModal extends StatefulWidget {
  final Function(Map<String, dynamic>) onProductAdded;
  final String baseUrl;

  const AddProductModal({
    Key? key,
    required this.onProductAdded,
    required this.baseUrl,
  }) : super(key: key);

  @override
  _AddProductModalState createState() => _AddProductModalState();
}

class _AddProductModalState extends State<AddProductModal> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _imageLinkController = TextEditingController();

  Future<void> _addProduct() async {
    final String name = _nameController.text.trim();
    final String priceText = _priceController.text.trim();
    final String imageLink = _imageLinkController.text.trim();

    if (name.isEmpty || priceText.isEmpty || imageLink.isEmpty) {
      _showErrorDialog('All fields are required.');
      return;
    }

    final double? price = double.tryParse(priceText);
    if (price == null || price <= 0) {
      _showErrorDialog('Please enter a valid price.');
      return;
    }

    // Prepare product data (keys must match what the server expects)
    final Map<String, dynamic> productData = {
      'name': name,
      'imgUrl': imageLink,
      'price': price,
      'stock': 0, // default stock can be set to 0
    };

    try {
      final response = await http.post(
        Uri.parse('${widget.baseUrl}/products'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(productData),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final newProduct = jsonDecode(response.body);
        widget.onProductAdded(newProduct);
        Navigator.pop(context);
        _showSuccessDialog();
      } else {
        _showErrorDialog('Failed to add product. (${response.statusCode})');
      }
    } catch (e) {
      _showErrorDialog('Failed to add product. Please try again.');
    }
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

  void _showSuccessDialog() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Success'),
        content: const Text('Product added successfully.'),
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
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Add Product'),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CupertinoTextField(
              controller: _nameController,
              placeholder: 'Product Name',
            ),
            const SizedBox(height: 16),
            CupertinoTextField(
              controller: _priceController,
              placeholder: 'Price',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            CupertinoTextField(
              controller: _imageLinkController,
              placeholder: 'Image Link (URL)',
            ),
            const SizedBox(height: 24),
            CupertinoButton.filled(
              onPressed: _addProduct,
              child: const Text('Add Product'),
            ),
            CupertinoButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }
}