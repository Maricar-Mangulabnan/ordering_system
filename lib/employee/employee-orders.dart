import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;

class EmployeeOrdersPage extends StatefulWidget {
  final Map<String, dynamic> user;

  const EmployeeOrdersPage({Key? key, required this.user}) : super(key: key);

  @override
  _EmployeeOrdersPageState createState() => _EmployeeOrdersPageState();
}

class _EmployeeOrdersPageState extends State<EmployeeOrdersPage> {
  final String baseUrl = 'https://orderko-server.onrender.com';
  List<Map<String, dynamic>> orders = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/orders'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Expecting the data to be a List of order objects
        setState(() {
          orders = List<Map<String, dynamic>>.from(data);
          isLoading = false;
        });
      } else {
        print('Failed to fetch orders. Status code: ${response.statusCode}');
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching orders: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  // Calculate total for each order item if needed (server usually calculates totalAmount)
  double calculateTotal(double price, int count) {
    return price * count;
  }

  // Build a summary of all orders
  Widget _buildOrderSummary() {
    double grandTotal = orders.fold(0.0, (sum, order) {
      double total = order['totalAmount'] != null
          ? (order['totalAmount'] as num).toDouble()
          : 0.0;
      return sum + total;
    });

    int totalItems = orders.fold(0, (sum, order) => sum + (order['count'] as int? ?? 0));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey5,
        border: const Border(top: BorderSide(color: CupertinoColors.systemGrey4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Total Items: $totalItems', style: const TextStyle(fontSize: 16)),
          Text('Grand Total: ₱${grandTotal.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: CupertinoColors.activeGreen)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Order Summary'),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      child: SafeArea(
        child: isLoading
            ? const Center(child: CupertinoActivityIndicator())
            : Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: orders.length,
                itemBuilder: (context, index) {
                  final order = orders[index];
                  // Extract product details from the nested 'product' object returned by the server
                  final productName = order['product'] != null ? order['product']['name'] : 'No Name';
                  final count = order['count'] as int? ?? 0;
                  final price = order['product'] != null ? (order['product']['price'] as num).toDouble() : 0.0;
                  final total = order['totalAmount'] != null
                      ? (order['totalAmount'] as num).toDouble()
                      : calculateTotal(price, count);

                  return CupertinoListTile(
                    title: Text(productName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Quantity: $count'),
                        Text('Price: ₱${price.toStringAsFixed(2)}'),
                        Text('Total: ₱${total.toStringAsFixed(2)}',
                            style: const TextStyle(color: CupertinoColors.activeGreen)),
                      ],
                    ),
                    trailing: const Icon(CupertinoIcons.cube_box_fill, color: CupertinoColors.systemGrey),
                  );
                },
              ),
            ),
            _buildOrderSummary(),
          ],
        ),
      ),
    );
  }
}