import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
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
  final String baseUrl = 'https://orderko-server.onrender.com';
  List<Map<String, dynamic>> products = [];
  bool isLoading = true;
  bool isRefreshing = false;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
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
      final response = await http.get(Uri.parse('$baseUrl/products'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          products = List<Map<String, dynamic>>.from(data);
          isLoading = false;
          isRefreshing = false;
          errorMessage = '';
        });
      } else {
        setState(() {
          isLoading = false;
          isRefreshing = false;
          errorMessage = 'Failed to fetch products. Please try again.';
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

  void _navigateToSettingsPage() {
    Navigator.push(
      context,
      CupertinoPageRoute(builder: (context) => SettingsPage(user: widget.user)),
    );
  }

  void _navigateToOrdersPage() {
    Navigator.push(
      context,
      CupertinoPageRoute(builder: (context) => EmployeeOrdersPage(user: widget.user)),
    );
  }

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

  void _showEditProductModal(Map<String, dynamic> product) {
    if (product['id'] == null) {
      _showErrorDialog('Error: Product ID is missing');
      return;
    }
    showCupertinoModalPopup(
      context: context,
      builder: (context) => EditProductModal(
        baseUrl: baseUrl,
        product: product,
        onProductUpdated: (updatedProduct) {
          setState(() {
            int index = products.indexWhere((p) => p['id'] == updatedProduct['id']);
            if (index != -1) {
              products[index] = updatedProduct;
            }
          });
        },
      ),
    );
  }

  void _confirmDeleteProduct(Map<String, dynamic> product) {
    if (product['id'] == null) {
      _showErrorDialog('Error: Product ID is missing');
      return;
    }
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text('Delete ${product['name']}'),
        content: const Text('Are you sure you want to delete this product? This action cannot be undone.'),
        actions: [
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('Delete'),
            onPressed: () {
              Navigator.pop(context);
              _deleteProduct(product);
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

  Future<void> _deleteProduct(Map<String, dynamic> product) async {
    final productId = product['id'];
    if (productId == null) {
      _showErrorDialog('Error: Product ID is missing');
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.delete(Uri.parse('$baseUrl/products/$productId'));
      if (response.statusCode == 200) {
        setState(() {
          products.removeWhere((p) => p['id'] == productId);
          isLoading = false;
        });
        _showSuccessDialog('Product deleted successfully');
      } else {
        setState(() {
          isLoading = false;
        });
        _showErrorDialog('Failed to delete product. Please try again.');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      _showErrorDialog('Network error. Please check your connection.');
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

  void _showSuccessDialog(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Success'),
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

  // Only showing the part that needs to be fixed - the _buildProductItem method

  Widget _buildProductItem(Map<String, dynamic> product) {
    final name = product['name'] ?? 'No Name';
    final price = product['price'] != null ? (product['price'] as num).toDouble() : 0.0;
    final stock = product['stock'] ?? 0;
    final imageUrl = product['imgUrl'] ?? '';

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
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Product image
            Container(
              width: 70, // Reduced from 80
              height: 70, // Reduced from 80
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: CupertinoColors.systemGrey6,
              ),
              child: imageUrl.isNotEmpty
                  ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Center(
                    child: Icon(
                      CupertinoIcons.photo,
                      color: CupertinoColors.systemGrey,
                      size: 30,
                    ),
                  ),
                ),
              )
                  : const Center(
                child: Icon(
                  CupertinoIcons.photo,
                  color: CupertinoColors.systemGrey,
                  size: 30,
                ),
              ),
            ),
            const SizedBox(width: 12), // Reduced from 16
            // Product details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // Wrap the row in a Wrap widget to handle overflow
                  Wrap(
                    spacing: 8, // horizontal space between items
                    runSpacing: 8, // vertical space between lines
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black87.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '₱${price.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: stock > 0
                              ? Colors.grey.withOpacity(0.1)
                              : CupertinoColors.systemRed.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Stock: $stock',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: stock > 0
                                ? Colors.grey
                                : CupertinoColors.systemRed,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Action buttons - make them more compact
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  minSize: 0, // Reduce minimum size
                  child: Container(
                    padding: const EdgeInsets.all(6), // Reduced from 8
                    decoration: BoxDecoration(
                      color: Colors.teal.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      CupertinoIcons.pencil,
                      color: Colors.teal,
                      size: 16, // Reduced from 18
                    ),
                  ),
                  onPressed: () => _showEditProductModal(product),
                ),
                const SizedBox(width: 4),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  minSize: 0, // Reduce minimum size
                  child: Container(
                    padding: const EdgeInsets.all(6), // Reduced from 8
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemRed.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      CupertinoIcons.delete,
                      color: CupertinoColors.systemRed,
                      size: 16, // Reduced from 18
                    ),
                  ),
                  onPressed: () => _confirmDeleteProduct(product),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            CupertinoIcons.cube_box,
            size: 70,
            color: CupertinoColors.systemGrey,
          ),
          const SizedBox(height: 16),
          const Text(
            'No Products Found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'There are no products to display at this time',
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
            onPressed: _showAddProductModal,
            child: const Text(
              'Add Product',
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
            onPressed: _fetchProducts,
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

  Widget _buildProductSummary() {
    int totalProducts = products.length;
    int totalStock = products.fold(0, (sum, product) => sum + (product['stock'] as int? ?? 0));
    double totalValue = products.fold(0.0, (sum, product) {
      double price = product['price'] != null ? (product['price'] as num).toDouble() : 0.0;
      int stock = product['stock'] as int? ?? 0;
      return sum + (price * stock);
    });

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
                      'Inventory Summary',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$totalProducts product${totalProducts != 1 ? 's' : ''} • $totalStock item${totalStock != 1 ? 's' : ''} in stock',
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
                      'Inventory Value',
                      style: TextStyle(
                        fontSize: 14,
                        color: CupertinoColors.systemGrey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₱${totalValue.toStringAsFixed(2)}',
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
            Row(
              children: [
                Expanded(
                  child: CupertinoButton(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    color: Colors.teal,
                    borderRadius: BorderRadius.circular(12),
                    onPressed: _showAddProductModal,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          CupertinoIcons.add,
                          color: CupertinoColors.white,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Add Product',
                          style: TextStyle(
                            color: CupertinoColors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CupertinoButton(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(12),
                    onPressed: _navigateToOrdersPage,
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
                          'View Orders',
                          style: TextStyle(
                            color: CupertinoColors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Product Inventory'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CupertinoButton(
              padding: EdgeInsets.zero,
              child: const Icon(
                CupertinoIcons.refresh,
                color: Colors.teal,
              ),
              onPressed: _fetchProducts,
            ),
            CupertinoButton(
              padding: EdgeInsets.zero,
              child: const Icon(
                CupertinoIcons.settings,
                color: Colors.teal,
              ),
              onPressed: _navigateToSettingsPage,
            ),
          ],
        ),
      ),
      child: SafeArea(
        child: isLoading
            ? const Center(child: CupertinoActivityIndicator())
            : errorMessage.isNotEmpty
            ? _buildErrorState()
            : products.isEmpty
            ? _buildEmptyState()
            : Stack(
          children: [
            // Products list
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
                      await _fetchProducts();
                    },
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.only(top: 8, bottom: 20),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                            (context, index) => _buildProductItem(products[index]),
                        childCount: products.length,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Product summary
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildProductSummary(),
            ),
          ],
        ),
      ),
    );
  }
}

// Add Product Modal: posts new product data to the server (POST /products).
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
  final TextEditingController _stockController = TextEditingController();
  bool _isSubmitting = false;

  Future<void> _addProduct() async {
    final String name = _nameController.text.trim();
    final String priceText = _priceController.text.trim();
    final String imageLink = _imageLinkController.text.trim();
    final String stockText = _stockController.text.trim();

    // All fields are required.
    if (name.isEmpty || priceText.isEmpty || imageLink.isEmpty || stockText.isEmpty) {
      _showErrorDialog('All fields are required.');
      return;
    }

    final double? price = double.tryParse(priceText);
    final int? stock = int.tryParse(stockText);
    if (price == null || price <= 0) {
      _showErrorDialog('Please enter a valid price.');
      return;
    }
    if (stock == null || stock < 0) {
      _showErrorDialog('Please enter a valid stock value.');
      return;
    }

    // Prepare product data.
    final Map<String, dynamic> productData = {
      'name': name,
      'imgUrl': imageLink,
      'price': price,
      'stock': stock,
    };

    setState(() {
      _isSubmitting = true;
    });

    try {
      final response = await http.post(
        Uri.parse('${widget.baseUrl}/products'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(productData),
      );

      setState(() {
        _isSubmitting = false;
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        final newProduct = jsonDecode(response.body);
        widget.onProductAdded(newProduct);
        Navigator.pop(context);
        _showSuccessDialog();
      } else {
        _showErrorDialog('Failed to add product. (${response.statusCode})');
      }
    } catch (e) {
      setState(() {
        _isSubmitting = false;
      });
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
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Add Product'),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Text('Cancel'),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      child: SafeArea(
        child: _isSubmitting
            ? const Center(child: CupertinoActivityIndicator())
            : SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              // Product Name
              const Text(
                'Product Name',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: CupertinoColors.systemGrey,
                ),
              ),
              const SizedBox(height: 8),
              CupertinoTextField(
                controller: _nameController,
                placeholder: 'Enter product name',
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: CupertinoColors.systemGrey4),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(height: 20),

              // Price
              const Text(
                'Price (₱)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: CupertinoColors.systemGrey,
                ),
              ),
              const SizedBox(height: 8),
              CupertinoTextField(
                controller: _priceController,
                placeholder: 'Enter price',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                padding: const EdgeInsets.all(12),
                prefix: const Padding(
                  padding: EdgeInsets.only(left: 12),
                  child: Text('₱', style: TextStyle(color: CupertinoColors.systemGrey)),
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: CupertinoColors.systemGrey4),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(height: 20),

              // Stock
              const Text(
                'Stock',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: CupertinoColors.systemGrey,
                ),
              ),
              const SizedBox(height: 8),
              CupertinoTextField(
                controller: _stockController,
                placeholder: 'Enter stock quantity',
                keyboardType: TextInputType.number,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: CupertinoColors.systemGrey4),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(height: 20),

              // Image URL
              const Text(
                'Image URL',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: CupertinoColors.systemGrey,
                ),
              ),
              const SizedBox(height: 8),
              CupertinoTextField(
                controller: _imageLinkController,
                placeholder: 'Enter image URL',
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: CupertinoColors.systemGrey4),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(height: 30),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: CupertinoButton(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  color: Colors.teal,
                  borderRadius: BorderRadius.circular(12),
                  onPressed: _addProduct,
                  child: const Text(
                    'Add Product',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Edit Product Modal: updates product data using PUT /products/:id.
class EditProductModal extends StatefulWidget {
  final String baseUrl;
  final Map<String, dynamic> product;
  final Function(Map<String, dynamic>) onProductUpdated;

  const EditProductModal({
    Key? key,
    required this.baseUrl,
    required this.product,
    required this.onProductUpdated,
  }) : super(key: key);

  @override
  _EditProductModalState createState() => _EditProductModalState();
}

class _EditProductModalState extends State<EditProductModal> {
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _imageLinkController;
  late TextEditingController _stockController;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product['name'] ?? '');
    _priceController = TextEditingController(text: widget.product['price'].toString());
    _imageLinkController = TextEditingController(text: widget.product['imgUrl'] ?? '');
    _stockController = TextEditingController(text: widget.product['stock'].toString());
  }

  Future<void> _updateProduct() async {
    final String name = _nameController.text.trim();
    final String priceText = _priceController.text.trim();
    final String imageLink = _imageLinkController.text.trim();
    final String stockText = _stockController.text.trim();

    if (name.isEmpty || priceText.isEmpty || imageLink.isEmpty || stockText.isEmpty) {
      _showErrorDialog('All fields are required.');
      return;
    }

    final double? price = double.tryParse(priceText);
    final int? stock = int.tryParse(stockText);
    if (price == null || price <= 0) {
      _showErrorDialog('Please enter a valid price.');
      return;
    }
    if (stock == null || stock < 0) {
      _showErrorDialog('Please enter a valid stock value.');
      return;
    }

    final Map<String, dynamic> updatedData = {
      'name': name,
      'imgUrl': imageLink,
      'price': price,
      'stock': stock,
    };

    final productId = widget.product['id'];
    if (productId == null) {
      _showErrorDialog('Product ID is missing. Cannot update product.');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final response = await http.put(
        Uri.parse('${widget.baseUrl}/products/$productId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(updatedData),
      );

      setState(() {
        _isSubmitting = false;
      });

      if (response.statusCode == 200) {
        final updatedProduct = jsonDecode(response.body);
        widget.onProductUpdated(updatedProduct);
        Navigator.pop(context);
        _showSuccessDialog();
      } else {
        _showErrorDialog('Failed to update product. (${response.statusCode})');
      }
    } catch (e) {
      setState(() {
        _isSubmitting = false;
      });
      _showErrorDialog('Failed to update product. Please try again.');
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
        content: const Text('Product updated successfully.'),
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
        middle: const Text('Edit Product'),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Text('Cancel'),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      child: SafeArea(
        child: _isSubmitting
            ? const Center(child: CupertinoActivityIndicator())
            : SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              // Product Name
              const Text(
                'Product Name',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: CupertinoColors.systemGrey,
                ),
              ),
              const SizedBox(height: 8),
              CupertinoTextField(
                controller: _nameController,
                placeholder: 'Enter product name',
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: CupertinoColors.systemGrey4),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(height: 20),

              // Price
              const Text(
                'Price (₱)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: CupertinoColors.systemGrey,
                ),
              ),
              const SizedBox(height: 8),
              CupertinoTextField(
                controller: _priceController,
                placeholder: 'Enter price',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                padding: const EdgeInsets.all(12),
                prefix: const Padding(
                  padding: EdgeInsets.only(left: 12),
                  child: Text('₱', style: TextStyle(color: CupertinoColors.systemGrey)),
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: CupertinoColors.systemGrey4),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(height: 20),

              // Stock
              const Text(
                'Stock',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: CupertinoColors.systemGrey,
                ),
              ),
              const SizedBox(height: 8),
              CupertinoTextField(
                controller: _stockController,
                placeholder: 'Enter stock quantity',
                keyboardType: TextInputType.number,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: CupertinoColors.systemGrey4),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(height: 20),

              // Image URL
              const Text(
                'Image URL',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: CupertinoColors.systemGrey,
                ),
              ),
              const SizedBox(height: 8),
              CupertinoTextField(
                controller: _imageLinkController,
                placeholder: 'Enter image URL',
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: CupertinoColors.systemGrey4),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(height: 30),

              // Preview Image
              if (_imageLinkController.text.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Image Preview',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: CupertinoColors.systemGrey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 150,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        border: Border.all(color: CupertinoColors.systemGrey4),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(7),
                        child: Image.network(
                          _imageLinkController.text,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => const Center(
                            child: Icon(
                              CupertinoIcons.exclamationmark_triangle,
                              color: CupertinoColors.systemGrey,
                              size: 40,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: CupertinoButton(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  color: Colors.teal,
                  borderRadius: BorderRadius.circular(12),
                  onPressed: _updateProduct,
                  child: const Text(
                    'Save Changes',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}