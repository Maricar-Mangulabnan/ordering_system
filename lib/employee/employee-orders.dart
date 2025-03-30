import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

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
  bool isRefreshing = false;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    if (isRefreshing) {
      setState(() {
        isRefreshing = true;
      });
    } else {
      setState(() {
        isLoading = true;
        errorMessage = '';
      });
    }

    try {
      final response = await http.get(Uri.parse('$baseUrl/orders'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Expecting the data to be a List of order objects
        setState(() {
          orders = List<Map<String, dynamic>>.from(data);
          orders.sort((a, b) {
            // Sort by createdAt date if available, newest first
            DateTime dateA = a['createdAt'] != null
                ? DateTime.parse(a['createdAt'])
                : DateTime.now();
            DateTime dateB = b['createdAt'] != null
                ? DateTime.parse(b['createdAt'])
                : DateTime.now();
            return dateB.compareTo(dateA);
          });
          isLoading = false;
          isRefreshing = false;
          errorMessage = '';
        });
      } else {
        setState(() {
          isLoading = false;
          isRefreshing = false;
          errorMessage = 'Failed to fetch orders. Please try again.';
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        isRefreshing = false;
        errorMessage = 'Network error. Please check your connection.';
      });
    }
  }

  // Calculate total for each order item if needed (server usually calculates totalAmount)
  double calculateTotal(double price, int count) {
    return price * count;
  }

  // Format date from ISO string
  String formatDate(String? dateString) {
    if (dateString == null) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('MMM d, yyyy • h:mm a').format(date);
    } catch (e) {
      return 'N/A';
    }
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
    int totalOrders = orders.length;

    return Container(
      padding: const EdgeInsets.all(20),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Order Summary',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$totalOrders order${totalOrders != 1 ? 's' : ''} • $totalItems item${totalItems != 1 ? 's' : ''}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: CupertinoColors.systemGrey,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Grand Total',
                      style: TextStyle(
                        fontSize: 14,
                        color: CupertinoColors.systemGrey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₱${grandTotal.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            CupertinoButton(
              padding: const EdgeInsets.symmetric(vertical: 12),
              color: Colors.teal,
              borderRadius: BorderRadius.circular(12),
              onPressed: _generateReport,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    CupertinoIcons.doc_text,
                    color: CupertinoColors.white,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Generate Report',
                    style: TextStyle(
                      color: CupertinoColors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _generateReport() {
    // This would be implemented to generate and export a report
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Generate Report'),
        content: const Text('This feature will generate a detailed sales report. Would you like to continue?'),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('Generate'),
            onPressed: () {
              Navigator.pop(context);
              _showReportGeneratedMessage();
            },
          ),
        ],
      ),
    );
  }

  void _showReportGeneratedMessage() {
    showCupertinoModalPopup(
      context: context,
      barrierDismissible: true,
      builder: (context) => CupertinoPopupSurface(
        child: Container(
          padding: const EdgeInsets.all(20),
          width: double.infinity,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                CupertinoIcons.doc_checkmark,
                color: Colors.teal,
                size: 50,
              ),
              const SizedBox(height: 16),
              const Text(
                'Report Generated',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Your sales report has been generated successfully.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: CupertinoColors.systemGrey,
                ),
              ),
              const SizedBox(height: 20),
              CupertinoButton(
                padding: EdgeInsets.zero,
                child: const Text(
                  'Close',
                  style: TextStyle(color: Colors.teal),
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderItem(Map<String, dynamic> order, int index) {
    // Extract product details from the nested 'product' object returned by the server
    final productName = order['product'] != null ? order['product']['name'] : 'No Name';
    final count = order['count'] as int? ?? 0;
    final price = order['product'] != null ? (order['product']['price'] as num).toDouble() : 0.0;
    final total = order['totalAmount'] != null
        ? (order['totalAmount'] as num).toDouble()
        : calculateTotal(price, count);
    final dateString = order['createdAt'];
    final formattedDate = formatDate(dateString);
    final customerName = order['user'] != null ? order['user']['username'] : 'Unknown';

    // Determine order status (you might want to adjust this based on your actual data model)
    final String orderStatus = order['status'] ?? 'Completed';
    final bool isCompleted = orderStatus == 'Completed';

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order header with date and status
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.teal.withOpacity(0.05),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order #${order['id'] ?? index + 1}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        formattedDate,
                        style: const TextStyle(
                          fontSize: 12,
                          color: CupertinoColors.systemGrey,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? Colors.teal.withOpacity(0.1)
                        : CupertinoColors.systemYellow.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    orderStatus,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isCompleted
                          ? Colors.teal
                          : CupertinoColors.systemYellow.darkColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Order details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Customer info
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.teal.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        CupertinoIcons.person,
                        color: Colors.teal,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      customerName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Product info
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product image placeholder
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: CupertinoColors.systemGrey6,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Icon(
                          CupertinoIcons.cube_box,
                          color: CupertinoColors.systemGrey,
                          size: 24,
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
                            productName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '₱${price.toStringAsFixed(2)} × $count',
                            style: const TextStyle(
                              fontSize: 14,
                              color: CupertinoColors.systemGrey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Total amount
                    Text(
                      '₱${total.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            CupertinoIcons.doc_text,
            size: 70,
            color: CupertinoColors.systemGrey,
          ),
          const SizedBox(height: 16),
          const Text(
            'No Orders Found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'There are no orders to display at this time',
            style: TextStyle(
              fontSize: 16,
              color: CupertinoColors.systemGrey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            color: Colors.teal,
            borderRadius: BorderRadius.circular(12),
            onPressed: _fetchOrders,
            child: const Text(
              'Refresh',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            CupertinoIcons.exclamationmark_circle,
            size: 70,
            color: CupertinoColors.systemRed,
          ),
          const SizedBox(height: 16),
          const Text(
            'Error',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              errorMessage,
              style: const TextStyle(
                fontSize: 16,
                color: CupertinoColors.systemGrey,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            color: Colors.teal,
            borderRadius: BorderRadius.circular(12),
            onPressed: _fetchOrders,
            child: const Text(
              'Try Again',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Order Summary'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(
            CupertinoIcons.refresh,
            color: Colors.teal,
          ),
          onPressed: () => _fetchOrders(),
        ),
      ),
      child: SafeArea(
        child: isLoading
            ? const Center(child: CupertinoActivityIndicator())
            : errorMessage.isNotEmpty
            ? _buildErrorState()
            : orders.isEmpty
            ? _buildEmptyState()
            : Stack(
          children: [
            // Orders list
            Positioned.fill(
              bottom: 140, // Space for the summary section
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  CupertinoSliverRefreshControl(
                    onRefresh: () async {
                      setState(() {
                        isRefreshing = true;
                      });
                      await _fetchOrders();
                    },
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.only(top: 8, bottom: 20),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                            (context, index) => _buildOrderItem(orders[index], index),
                        childCount: orders.length,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Order summary
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildOrderSummary(),
            ),
          ],
        ),
      ),
    );
  }
}

