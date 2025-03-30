import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'customer-products.dart';  // Import your customer products page

// Global cart list to hold items added to cart.
// Each cart item is a Map with keys: id, name, price, stock, count, totalAmount.
List<Map<String, dynamic>> cartItems = [];

class AddToCartPage extends StatefulWidget {
  final Map<String, dynamic> user;
  final String baseUrl;

  const AddToCartPage({Key? key, required this.user, required this.baseUrl})
      : super(key: key);

  @override
  _AddToCartPageState createState() => _AddToCartPageState();
}

class _AddToCartPageState extends State<AddToCartPage> {
  // Adjust the count for a cart item using minus/plus buttons.
  void _updateCount(int index, int delta) {
    setState(() {
      int newCount = cartItems[index]['count'] + delta;
      if (newCount < 1) newCount = 1;
      cartItems[index]['count'] = newCount;
      cartItems[index]['totalAmount'] =
          (cartItems[index]['price'] as num).toDouble() * newCount;
    });
  }

  // Compute the overall total amount.
  double get overallTotal {
    double total = 0;
    for (var item in cartItems) {
      total += (item['totalAmount'] as num).toDouble();
    }
    return total;
  }

  // Checkout: For each cart item, send a POST request to create an order.
  Future<void> _checkout() async {
    // Extract userId properly: if widget.user contains nested user data, use that.
    final String userId = widget.user.containsKey('user')
        ? widget.user['user']['id']
        : widget.user['id'];

    bool allSuccess = true;
    for (var item in cartItems) {
      final orderData = {
        'userId': userId, // must be a non-null string
        'productId': item['id'],
        'count': item['count'],
      };
      try {
        final response = await http.post(
          Uri.parse('${widget.baseUrl}/orders'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(orderData),
        );
        if (!(response.statusCode == 200 || response.statusCode == 201)) {
          allSuccess = false;
        }
      } catch (e) {
        allSuccess = false;
      }
    }
    if (allSuccess) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Success'),
          content: const Text('Your order has been placed successfully.'),
          actions: [
            CupertinoDialogAction(
              child: const Text('OK'),
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  cartItems.clear();
                });
                // Redirect to the CustomerProductsPage to refresh product list.
                Navigator.pushReplacement(
                  context,
                  CupertinoPageRoute(
                    builder: (context) => CustomerProductsPage(user: widget.user),
                  ),
                );
              },
            ),
          ],
        ),
      );
    } else {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Error'),
          content: const Text('Failed to place order. Please try again.'),
          actions: [
            CupertinoDialogAction(
              child: const Text('OK'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Cart'),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // List of cart items.
            Expanded(
              child: ListView.builder(
                itemCount: cartItems.length,
                itemBuilder: (context, index) {
                  final item = cartItems[index];
                  return CupertinoListTile(
                    title: Text(item['name']),
                    subtitle: Text(
                        'Price: ₱${(item['price'] as num).toStringAsFixed(2)} | Stock: ${item['stock']}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          child: const Icon(CupertinoIcons.minus),
                          onPressed: () => _updateCount(index, -1),
                        ),
                        Text('${item['count']}'),
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          child: const Icon(CupertinoIcons.add),
                          onPressed: () => _updateCount(index, 1),
                        ),
                        const SizedBox(width: 8),
                        Text(
                            'Total: ₱${(item['totalAmount'] as num).toStringAsFixed(2)}'),
                      ],
                    ),
                  );
                },
              ),
            ),
            // Overall total and checkout button.
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text('Overall Total: ₱${overallTotal.toStringAsFixed(2)}'),
                  const SizedBox(height: 16),
                  CupertinoButton.filled(
                    onPressed: _checkout,
                    child: const Text('Checkout'),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}



