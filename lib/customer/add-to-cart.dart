import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
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
  bool _isCheckingOut = false;

  // Adjust the count for a cart item using minus/plus buttons.
  void _updateCount(int index, int delta) {
    setState(() {
      int newCount = cartItems[index]['count'] + delta;
      if (newCount < 1) newCount = 1;
      if (newCount > cartItems[index]['stock']) newCount = cartItems[index]['stock'];
      cartItems[index]['count'] = newCount;
      cartItems[index]['totalAmount'] =
          (cartItems[index]['price'] as num).toDouble() * newCount;
    });
  }

  // Remove an item from the cart
  void _removeItem(int index) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Remove Item'),
        content: Text('Remove ${cartItems[index]['name']} from your cart?'),
        actions: [
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('Remove'),
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                cartItems.removeAt(index);
              });
            },
          ),
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  // Compute the overall total amount.
  double get overallTotal {
    double total = 0;
    for (var item in cartItems) {
      total += (item['totalAmount'] as num).toDouble();
    }
    return total;
  }

  // Get the total number of items
  int get totalItems {
    int count = 0;
    for (var item in cartItems) {
      count += item['count'] as int;
    }
    return count;
  }

  // Checkout: For each cart item, send a POST request to create an order.
  Future<void> _checkout() async {
    if (cartItems.isEmpty) {
      _showMessage('Cart Empty', 'Please add items to your cart before checking out.');
      return;
    }

    setState(() {
      _isCheckingOut = true;
    });

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

    setState(() {
      _isCheckingOut = false;
    });

    if (allSuccess) {
      _showOrderSuccess();
    } else {
      _showMessage('Error', 'Failed to place order. Please try again.');
    }
  }

  void _showOrderSuccess() {
    showCupertinoModalPopup(
      context: context,
      barrierDismissible: true, // Allow dismissing by tapping outside
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: CupertinoColors.systemBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle to drag the modal
            Center(
              child: Container(
                width: 40,
                height: 5,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGrey4,
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),
            ),
            const Icon(
              CupertinoIcons.check_mark_circled,
              size: 60,
              color: Colors.teal,
            ),
            const SizedBox(height: 16),
            const Text(
              'Order Placed Successfully!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your order of $totalItems item${totalItems > 1 ? 's' : ''} has been placed.',
              style: const TextStyle(
                fontSize: 16,
                color: CupertinoColors.systemGrey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            CupertinoButton(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
              color: Colors.teal,
              borderRadius: BorderRadius.circular(12),
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
              child: const Text(
                'Continue Shopping',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showMessage(String title, String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(title),
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
        middle: Text(cartItems.isEmpty ? 'Your Cart' : 'Cart (${cartItems.length})'),
      ),
      child: SafeArea(
        child: cartItems.isEmpty
            ? _buildEmptyCart()
            : Stack(
          children: [
            // Cart items list
            Positioned.fill(
              bottom: 140, // Space for the checkout section
              child: ListView.builder(
                padding: const EdgeInsets.only(bottom: 20),
                itemCount: cartItems.length,
                itemBuilder: (context, index) => _buildCartItem(index),
              ),
            ),
            // Checkout section
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemBackground,
                  boxShadow: [
                    BoxShadow(
                      color: CupertinoColors.systemGrey.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: Column(
                    children: [
                      // Order summary
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Order Summary',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '$totalItems item${totalItems > 1 ? 's' : ''}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: CupertinoColors.systemGrey,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Total amount
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total Amount',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '₱${overallTotal.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.teal,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Checkout button
                      SizedBox(
                        width: double.infinity,
                        child: CupertinoButton(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          color: Colors.teal,
                          borderRadius: BorderRadius.circular(12),
                          onPressed: _isCheckingOut ? null : _checkout,
                          child: _isCheckingOut
                              ? const CupertinoActivityIndicator(color: CupertinoColors.white)
                              : const Text(
                            'Checkout',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            CupertinoIcons.cart,
            size: 80,
            color: CupertinoColors.systemGrey,
          ),
          const SizedBox(height: 16),
          const Text(
            'Your cart is empty',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add items to your cart to get started',
            style: TextStyle(
              fontSize: 16,
              color: CupertinoColors.systemGrey,
            ),
          ),
          const SizedBox(height: 24),
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            color: Colors.teal,
            borderRadius: BorderRadius.circular(12),
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text(
              'Browse Products',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItem(int index) {
    final item = cartItems[index];
    final bool isLowStock = item['stock'] < 5;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.systemGrey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product image placeholder
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemGrey6,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: (item['imgUrl'] != null && item['imgUrl'].toString().isNotEmpty)
                        ? Image.network(
                      item['imgUrl'],
                      fit: BoxFit.cover,
                    )
                        : const Icon(
                      CupertinoIcons.photo,
                      size: 50, // Adjust size as needed
                      color: CupertinoColors.systemGrey,
                    ),
                  ),

                ),
                const SizedBox(width: 12),
                // Product details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['name'],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₱${(item['price'] as num).toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isLowStock
                                  ? CupertinoColors.systemYellow.withOpacity(0.2)
                                  : Colors.teal.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Stock: ${item['stock']}',
                              style: TextStyle(
                                fontSize: 12,
                                color: isLowStock
                                    ? CupertinoColors.systemYellow.darkColor
                                    : Colors.teal,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Remove button
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  child: const Icon(
                    CupertinoIcons.delete,
                    color: CupertinoColors.systemGrey,
                    size: 20,
                  ),
                  onPressed: () => _removeItem(index),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Divider
            Container(
              height: 1,
              color: CupertinoColors.systemGrey6,
            ),
            const SizedBox(height: 12),
            // Quantity controls and total
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Quantity controls
                Row(
                  children: [
                    const Text(
                      'Quantity: ',
                      style: TextStyle(
                        fontSize: 14,
                        color: CupertinoColors.systemGrey,
                      ),
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.teal.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          CupertinoIcons.minus,
                          color: Colors.teal,
                          size: 16,
                        ),
                      ),
                      onPressed: () => _updateCount(index, -1),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        '${item['count']}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.teal.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          CupertinoIcons.plus,
                          color: Colors.teal,
                          size: 16,
                        ),
                      ),
                      onPressed: () => _updateCount(index, 1),
                    ),
                  ],
                ),
                // Item total
                Text(
                  '₱${(item['totalAmount'] as num).toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.teal,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

