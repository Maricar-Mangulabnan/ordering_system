//employee-products.dart



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
  // Use your production URL here.
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

  // Navigate to the Settings page.
  void _navigateToSettingsPage() {
    Navigator.push(
      context,
      CupertinoPageRoute(builder: (context) => SettingsPage(user: widget.user)),
    );
  }

  // Navigate to the Orders page.
  void _navigateToOrdersPage() {
    Navigator.push(
      context,
      CupertinoPageRoute(builder: (context) => EmployeeOrdersPage(user: widget.user)),
    );
  }

  // Show the Add Product modal.
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

  // Show the Edit Product modal.
  void _showEditProductModal(Map<String, dynamic> product) {
    if (product['id'] == null) {
      print("Error: Product id is missing in product object: $product");
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

  // Show confirmation modal for deletion of a product.
  void _confirmDeleteProduct(Map<String, dynamic> product) {
    if (product['id'] == null) {
      print("Error: Product id is missing in product object: $product");
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

  // Delete product by sending DELETE request.
  Future<void> _deleteProduct(Map<String, dynamic> product) async {
    final productId = product['id'];
    if (productId == null) {
      print("Error: Product id is missing. Cannot delete product.");
      return;
    }
    try {
      final response = await http.delete(Uri.parse('$baseUrl/products/$productId'));
      if (response.statusCode == 200) {
        setState(() {
          products.removeWhere((p) => p['id'] == productId);
        });
      } else {
        print('Failed to delete product: ${response.statusCode}');
      }
    } catch (e) {
      print('Error deleting product: $e');
    }
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
                    product['imgUrl'] ?? '',
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                  ),
                  title: Text(product['name'] ?? 'No Name'),
                  subtitle: Text('â‚±${(product['price'] as num?)?.toStringAsFixed(2) ?? '0.00'} | Stock: ${product['stock'] ?? 0}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        child: const Icon(CupertinoIcons.pencil, size: 20),
                        onPressed: () => _showEditProductModal(product),
                      ),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        child: const Icon(CupertinoIcons.delete, size: 20, color: CupertinoColors.destructiveRed),
                        onPressed: () => _confirmDeleteProduct(product),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          // Floating Buttons for adding product and viewing order logs.
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
        padding: const EdgeInsets.fromLTRB(20.0, 120.0, 20.0, 60.0),
        child: SingleChildScrollView(
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
              const SizedBox(height: 16),
              CupertinoTextField(
                controller: _stockController,
                placeholder: 'Stock',
                keyboardType: TextInputType.number,
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

  @override
  void initState() {
    super.initState();
    // Verify that the product has an id.
    if (widget.product['id'] == null) {
      print("Error: Product id is missing in the product object: ${widget.product}");
    } else {
      print("Editing product with id: ${widget.product['id']}");
    }
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
      _showErrorDialog('Product id is missing. Cannot update product.');
      return;
    }

    final String url = '${widget.baseUrl}/products/$productId';
    print("PUT URL: $url");

    try {
      final response = await http.put(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(updatedData),
      );

      if (response.statusCode == 200) {
        final updatedProduct = jsonDecode(response.body);
        widget.onProductUpdated(updatedProduct);
        Navigator.pop(context);
        _showSuccessDialog();
      } else {
        _showErrorDialog('Failed to update product. (${response.statusCode})');
      }
    } catch (e) {
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
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Edit Product'),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20.0, 120.0, 20.0, 60.0),
        child: SingleChildScrollView(
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
              const SizedBox(height: 16),
              CupertinoTextField(
                controller: _stockController,
                placeholder: 'Stock',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 24),
              CupertinoButton.filled(
                onPressed: _updateProduct,
                child: const Text('Save Changes'),
              ),
              CupertinoButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


