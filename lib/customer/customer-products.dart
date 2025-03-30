import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:ordering_system/settings.dart';
import 'add-to-cart.dart'; // Make sure this file is in your project structure

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

  // Add product to local cart (using global cartItems from add_to_cart.dart)
  void _addToCart(Map<String, dynamic> product) {
    // Check if product already exists in the cart
    int index = cartItems.indexWhere((item) => item['id'] == product['id']);
    if (index == -1) {
      cartItems.add({
        'id': product['id'],
        'name': product['name'],
        'price': product['price'],
        'stock': product['stock'],
        'count': 1,
        'totalAmount': product['price']
      });
    } else {
      cartItems[index]['count'] += 1;
      cartItems[index]['totalAmount'] =
          cartItems[index]['price'] * cartItems[index]['count'];
    }
    _showAddToCartSuccessDialog(product);
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

  // Navigate to the Add To Cart page
  void _navigateToCartPage() {
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => AddToCartPage(user: widget.user, baseUrl: baseUrl),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Customer Products'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CupertinoButton(
              padding: EdgeInsets.zero,
              child: const Icon(CupertinoIcons.shopping_cart),
              onPressed: _navigateToCartPage,
            ),
            CupertinoButton(
              padding: EdgeInsets.zero,
              child: const Icon(CupertinoIcons.settings),
              onPressed: _navigateToSettingsPage,
            ),
          ],
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
                product['imgUrl'],
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











// 
