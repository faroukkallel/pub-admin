import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
// ignore: undefined_prefixed_name
import 'dart:ui_web' as ui_web;
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_animate/flutter_animate.dart';

class Perfume {
  final String id;
  final String name;
  final String description;
  final Map<String, double> sizes;
  final String image;
  final bool inStock;

  Perfume({
    required this.id,
    required this.name,
    required this.description,
    required this.sizes,
    required this.image,
    required this.inStock,
  });

  factory Perfume.fromFirestore(Map<String, dynamic> data, String docId) {
    return Perfume(
      id: docId,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      sizes: Map<String, double>.from(data['sizes'] ?? {}),
      image: data['image'] ?? '',
      inStock: data['inStock'] ?? true,
    );
  }
}

class CartItem {
  final Perfume perfume;
  int quantity;
  String selectedSize;

  CartItem({
    required this.perfume,
    this.quantity = 1,
    required this.selectedSize,
  });

  double get price => perfume.sizes[selectedSize] ?? 0.0;

  Map<String, dynamic> toMap() {
    return {
      'perfumeId': perfume.id,
      'name': perfume.name,
      'price': price,
      'quantity': quantity,
      'image': perfume.image,
      'size': selectedSize,
    };
  }
}

class PaymentService {
  static const String apiKey = '67c1bcaef845be25313e341b:g06wZc2eiSuCEPMThLBb';
  static const String baseUrl = 'https://api.preprod.konnect.network/api/v2';

  Future<Map<String, dynamic>> initiatePayment(
      double amount, String orderId) async {
    final url = Uri.parse('$baseUrl/payments/init-payment');
    final headers = {'x-api-key': apiKey, 'Content-Type': 'application/json'};
    final body = jsonEncode({
      "receiverWalletId": "67c1bcaef845be25313e3421",
      "token": "TND",
      "amount": (amount * 1000).toInt(),
      "type": "immediate",
      "description": "Perfume Purchase",
      "acceptedPaymentMethods": ["bank_card", "e-DINAR"],
      "lifespan": 10,
      "checkoutForm": true,
      "addPaymentFeesToAmount": false,
      "orderId": orderId,
      "theme": "dark"
    });

    final response = await http.post(url, headers: headers, body: body);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception(
        'Payment initiation failed with status: ${response.statusCode}, body: ${response.body}');
  }

  Future<Map<String, dynamic>> getPaymentDetails(String paymentId) async {
    final url = Uri.parse('$baseUrl/payments/$paymentId');
    final headers = {'x-api-key': apiKey};
    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception(
        'Failed to get payment details with status: ${response.statusCode}, body: ${response.body}');
  }
}

class PaymentWebView extends StatefulWidget {
  final String url;
  final String paymentRef;
  final PaymentService paymentService;

  const PaymentWebView({
    Key? key,
    required this.url,
    required this.paymentRef,
    required this.paymentService,
  }) : super(key: key);

  @override
  _PaymentWebViewState createState() => _PaymentWebViewState();
}

class _PaymentWebViewState extends State<PaymentWebView> {
  late String viewID;
  Timer? _timer;
  int _attempts = 0;

  @override
  void initState() {
    super.initState();
    viewID = 'iframe-${DateTime.now().millisecondsSinceEpoch}';

    if (kIsWeb) {
      // Register the view factory for web platform
      ui_web.platformViewRegistry.registerViewFactory(viewID, (int viewId) {
        final html.IFrameElement element = html.IFrameElement();
        element.src = widget.url;
        element.style.border = 'none';
        return element;
      });
    }

    _startPolling();
  }

  void _startPolling() {
    const pollingInterval = Duration(seconds: 5);
    const maxAttempts = 12;

    _timer = Timer.periodic(pollingInterval, (timer) async {
      _attempts++;

      try {
        final details =
        await widget.paymentService.getPaymentDetails(widget.paymentRef);
        final status = details['payment']['status'];

        if (status != 'pending' || _attempts >= maxAttempts) {
          _timer?.cancel();
          if (mounted) {
            Navigator.pop(context, status);
          }
        }
      } catch (e) {
        _timer?.cancel();
        if (mounted) {
          Navigator.pop(context, 'error');
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: HtmlElementView(viewType: viewID),
    );
  }
}

class ResponsiveBuilder extends StatelessWidget {
  final Widget mobile;
  final Widget tablet;
  final Widget desktop;

  const ResponsiveBuilder({
    Key? key,
    required this.mobile,
    required this.tablet,
    required this.desktop,
  }) : super(key: key);

  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 650;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= 650 &&
          MediaQuery.of(context).size.width < 1100;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 1100;

  @override
  Widget build(BuildContext context) {
    if (isDesktop(context)) {
      return desktop;
    } else if (isTablet(context)) {
      return tablet;
    } else {
      return mobile;
    }
  }
}

class ShopScreen extends StatefulWidget {
  final String? id;

  const ShopScreen({Key? key, this.id}) : super(key: key);

  @override
  _ShopScreenState createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  final cartNotifier = ValueNotifier<List<CartItem>>([]);
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final PaymentService _paymentService = PaymentService();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  bool _isHovering = false;
  int _hoveredIndex = -1;

  static const Color darkBase = Color(0xFF151515);
  static const Color darkMid = Color(0xFF222222);
  static const Color darkLight = Color(0xFF2D2D2D);
  static const Color goldPrimary = Color(0xFFD4AF37);
  static const Color goldLight = Color(0xFFE5C158);
  static const Color goldDark = Color(0xFFB8860B);
  static const Color textPrimary = Color(0xFFF5F5F5);
  static const Color textSecondary = Color(0xFFE0E0E0);

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..forward();

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    cartNotifier.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _addToCart(Perfume perfume, {int quantity = 1, required String size}) {
    final cartItems = cartNotifier.value;
    final existingItemIndex = cartItems.indexWhere(
            (item) => item.perfume.id == perfume.id && item.selectedSize == size);

    if (existingItemIndex >= 0) {
      final updatedItem = cartItems[existingItemIndex];
      updatedItem.quantity += quantity;
      cartNotifier.value = List.from(cartItems)
        ..[existingItemIndex] = updatedItem;
    } else {
      cartNotifier.value = List.from(cartItems)
        ..add(
            CartItem(perfume: perfume, quantity: quantity, selectedSize: size));
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: goldPrimary),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                "${perfume.name} ($size) added to cart",
                style: GoogleFonts.playfairDisplay(color: textPrimary),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        action: SnackBarAction(
          label: 'VIEW',
          textColor: goldPrimary,
          onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: darkMid.withOpacity(0.95),
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: goldPrimary.withOpacity(0.3), width: 1),
        ),
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _removeFromCart(int index) {
    final cartItems = cartNotifier.value;
    cartNotifier.value = List.from(cartItems)..removeAt(index);
  }

  void _updateQuantity(int index, int newQuantity) {
    if (newQuantity > 0) {
      final cartItems = cartNotifier.value;
      final updatedItem = cartItems[index];
      updatedItem.quantity = newQuantity;
      cartNotifier.value = List.from(cartItems)..[index] = updatedItem;
    }
  }

  Future<void> _saveOrderToFirebase(String paymentRef, double total,
      List<CartItem> cartItems, Map<String, String> deliveryInfo) async {
    final orderData = {
      'paymentRef': paymentRef,
      'total': total,
      'items': cartItems.map((item) => item.toMap()).toList(),
      'timestamp': FieldValue.serverTimestamp(),
      'status': 'completed',
      'deliveryInfo': deliveryInfo,
    };

    await FirebaseFirestore.instance.collection('orders').add(orderData);
  }

  Future<void> _showDeliveryInfoDialog() async {
    final cartItems = cartNotifier.value;
    if (cartItems.isEmpty) return;

    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth > 650;

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: darkMid,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: goldPrimary.withOpacity(0.5), width: 2),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.local_shipping_outlined, color: goldPrimary),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                "Delivery Information",
                style: GoogleFonts.cinzel(
                    color: goldPrimary, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
        content: Container(
          width: isLargeScreen ? screenWidth * 0.4 : screenWidth * 0.8,
          constraints: BoxConstraints(maxWidth: 500),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildFormField(
                    controller: _nameController,
                    label: "Full Name",
                    icon: Icons.person,
                    validator: (value) => value!.isEmpty ? "Required" : null,
                  ),
                  SizedBox(height: 16),
                  _buildFormField(
                    controller: _emailController,
                    label: "Email",
                    icon: Icons.email,
                    validator: (value) => value!.isEmpty || !value.contains('@')
                        ? "Valid email required"
                        : null,
                  ),
                  SizedBox(height: 16),
                  _buildFormField(
                    controller: _phoneController,
                    label: "Phone Number",
                    icon: Icons.phone,
                    validator: (value) => value!.isEmpty ? "Required" : null,
                  ),
                  SizedBox(height: 16),
                  _buildFormField(
                    controller: _addressController,
                    label: "Delivery Address",
                    icon: Icons.home,
                    validator: (value) => value!.isEmpty ? "Required" : null,
                    maxLines: 3,
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          isLargeScreen
              ? Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  foregroundColor: goldPrimary,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.arrow_back, size: 16),
                    SizedBox(width: 4),
                    Text(
                      "Return to Cart",
                      style: GoogleFonts.playfairDisplay(
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    Navigator.pop(context, {
                      'name': _nameController.text,
                      'email': _emailController.text,
                      'phone': _phoneController.text,
                      'address': _addressController.text,
                    });
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: goldPrimary,
                  padding:
                  EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Proceed to Payment",
                      style: GoogleFonts.playfairDisplay(
                          color: Colors.black,
                          fontWeight: FontWeight.bold),
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.arrow_forward,
                        size: 16, color: Colors.black),
                  ],
                ),
              ),
            ],
          )
              : Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    Navigator.pop(context, {
                      'name': _nameController.text,
                      'email': _emailController.text,
                      'phone': _phoneController.text,
                      'address': _addressController.text,
                    });
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: goldPrimary,
                  padding:
                  EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  minimumSize: Size(double.infinity, 45),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Proceed to Payment",
                      style: GoogleFonts.playfairDisplay(
                          color: Colors.black,
                          fontWeight: FontWeight.bold),
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.arrow_forward,
                        size: 16, color: Colors.black),
                  ],
                ),
              ),
              SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  foregroundColor: goldPrimary,
                  minimumSize: Size(double.infinity, 45),
                ),
                child: Text(
                  "Return to Cart",
                  style: GoogleFonts.playfairDisplay(
                      fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (result != null) {
      await _initiateCheckout(result);
    }
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String? Function(String?) validator,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      style: TextStyle(color: textPrimary),
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.playfairDisplay(color: textSecondary),
        prefixIcon: Icon(icon, color: goldPrimary, size: 20),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: goldPrimary.withOpacity(0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: goldPrimary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red.shade400),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red.shade400, width: 2),
        ),
        filled: true,
        fillColor: darkLight,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      validator: validator,
    );
  }

  Future<void> _initiateCheckout(Map<String, String> deliveryInfo) async {
    final cartItems = cartNotifier.value;
    final total = cartItems.fold<double>(
        0, (sum, item) => sum + item.price * item.quantity);
    final orderId = DateTime.now().millisecondsSinceEpoch.toString();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: darkMid,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(goldPrimary),
              strokeWidth: 3,
            ),
            SizedBox(height: 20),
            Text(
              "Processing your payment...",
              style:
              GoogleFonts.playfairDisplay(color: textPrimary, fontSize: 16),
            )
          ],
        ),
      ),
    );

    try {
      final paymentResponse =
      await _paymentService.initiatePayment(total, orderId);
      final paymentUrl = paymentResponse['payUrl'];
      final paymentRef = paymentResponse['paymentRef'];

      final status = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentWebView(
            url: paymentUrl,
            paymentRef: paymentRef,
            paymentService: _paymentService,
          ),
        ),
      );

      Navigator.pop(context);

      if (status == 'completed') {
        await _saveOrderToFirebase(paymentRef, total, cartItems, deliveryInfo);
        cartNotifier.value = [];
        _showPaymentSuccessDialog(total);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red.shade300),
                SizedBox(width: 8),
                Text(
                  "Payment failed: $status",
                  style:
                  GoogleFonts.playfairDisplay(color: Colors.red.shade200),
                ),
              ],
            ),
            backgroundColor: darkMid.withOpacity(0.95),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.red.shade700, width: 1),
            ),
          ),
        );
      }
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red.shade300),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Checkout failed. Please try again.",
                  style:
                  GoogleFonts.playfairDisplay(color: Colors.red.shade200),
                ),
              ),
            ],
          ),
          backgroundColor: darkMid.withOpacity(0.95),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.red.shade700, width: 1),
          ),
        ),
      );
    }
  }

  void _showPaymentSuccessDialog(double total) {
    final isLargeScreen = MediaQuery.of(context).size.width > 650;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          width: isLargeScreen ? 450 : 320,
          padding: EdgeInsets.all(isLargeScreen ? 24 : 16),
          decoration: BoxDecoration(
            color: darkMid,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: goldPrimary.withOpacity(0.3),
                spreadRadius: 1,
                blurRadius: 20,
                offset: Offset(0, 0),
              ),
            ],
            border: Border.all(
              color: goldPrimary.withOpacity(0.5),
              width: 2,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.green.withOpacity(0.2),
                  border: Border.all(
                    color: Colors.green.shade400,
                    width: 2,
                  ),
                ),
                child: Icon(
                  Icons.check,
                  color: Colors.green.shade400,
                  size: isLargeScreen ? 50 : 40,
                ),
              ).animate().scale(
                duration: 600.ms,
                curve: Curves.elasticOut,
                begin: Offset(0.5, 0.5),
                end: Offset(1, 1),
              ),
              SizedBox(height: isLargeScreen ? 24 : 16),
              Text(
                "Payment Successful!",
                style: GoogleFonts.cinzel(
                  fontSize: isLargeScreen ? 22 : 18,
                  fontWeight: FontWeight.bold,
                  color: goldPrimary,
                ),
                textAlign: TextAlign.center,
              ).animate().fade(duration: 600.ms, delay: 300.ms),
              SizedBox(height: isLargeScreen ? 16 : 12),
              Text(
                "Your order has been placed and will be processed shortly.",
                style: GoogleFonts.playfairDisplay(
                  fontSize: isLargeScreen ? 16 : 14,
                  color: textSecondary,
                ),
                textAlign: TextAlign.center,
              ).animate().fade(duration: 600.ms, delay: 600.ms),
              SizedBox(height: isLargeScreen ? 24 : 16),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: darkLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: goldPrimary.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Total: ",
                      style: GoogleFonts.playfairDisplay(
                        fontSize: isLargeScreen ? 16 : 14,
                        color: textPrimary,
                      ),
                    ),
                    Text(
                      "TND ${total.toStringAsFixed(2)}",
                      style: GoogleFonts.cinzel(
                        fontSize: isLargeScreen ? 18 : 16,
                        fontWeight: FontWeight.bold,
                        color: goldPrimary,
                      ),
                    ),
                  ],
                ),
              ).animate().fade(duration: 600.ms, delay: 900.ms),
              SizedBox(height: isLargeScreen ? 24 : 20),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: goldPrimary,
                  padding: EdgeInsets.symmetric(
                    horizontal: isLargeScreen ? 32 : 24,
                    vertical: isLargeScreen ? 14 : 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                ),
                child: Text(
                  "Continue Shopping",
                  style: GoogleFonts.playfairDisplay(
                    fontSize: isLargeScreen ? 16 : 14,
                    fontWeight: FontWeight.bold,
                    color: darkBase,
                  ),
                ),
              ).animate().fade(duration: 600.ms, delay: 1200.ms),
            ],
          ),
        ).animate().scale(
          duration: 400.ms,
          curve: Curves.easeOutBack,
          begin: Offset(0.8, 0.8),
          end: Offset(1, 1),
        ),
      ),
    );
  }

  void _showDetailDialog(Perfume perfume) {
    int _quantity = 1;
    String _selectedSize =
    perfume.sizes.keys.isNotEmpty ? perfume.sizes.keys.first : '';
    final isLargeScreen = MediaQuery.of(context).size.width > 800;

    if (isLargeScreen) {
      showDialog(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setStateDialog) => Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Container(
              width: 900,
              height: 600,
              decoration: BoxDecoration(
                color: darkBase,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: goldPrimary.withOpacity(0.2),
                    blurRadius: 20,
                    spreadRadius: 1,
                  ),
                ],
                border: Border.all(
                  color: goldPrimary.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 5,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(20),
                          bottomLeft: Radius.circular(20),
                        ),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            darkLight.withOpacity(0.6),
                            darkBase,
                          ],
                        ),
                      ),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Center(
                            child: Hero(
                              tag: 'perfume-${perfume.id}',
                              child: GestureDetector(
                                onTap: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => Dialog(
                                      backgroundColor: Colors.transparent,
                                      child: GestureDetector(
                                        onTap: () => Navigator.pop(context),
                                        child: InteractiveViewer(
                                          panEnabled: true,
                                          minScale: 0.5,
                                          maxScale: 4.0,
                                          child: Image.network(
                                            perfume.image,
                                            fit: BoxFit.contain,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                                child: Image.network(
                                  perfume.image,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 16,
                            left: 16,
                            child: GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Container(
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: darkMid.withOpacity(0.7),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: goldPrimary.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Icon(
                                  Icons.close,
                                  color: textPrimary,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 5,
                    child: Container(
                      decoration: BoxDecoration(
                        color: darkMid,
                        borderRadius: BorderRadius.only(
                          topRight: Radius.circular(20),
                          bottomRight: Radius.circular(20),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: SingleChildScrollView(
                              padding: EdgeInsets.all(24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          perfume.name,
                                          style: GoogleFonts.cinzel(
                                            fontSize: 28,
                                            fontWeight: FontWeight.bold,
                                            color: goldPrimary,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: perfume.inStock
                                              ? Colors.green.withOpacity(0.2)
                                              : Colors.red.withOpacity(0.2),
                                          borderRadius:
                                          BorderRadius.circular(20),
                                          border: Border.all(
                                            color: perfume.inStock
                                                ? Colors.green.shade400
                                                : Colors.red.shade400,
                                            width: 1,
                                          ),
                                        ),
                                        child: Text(
                                          perfume.inStock
                                              ? "In Stock"
                                              : "Out of Stock",
                                          style: GoogleFonts.playfairDisplay(
                                            color: perfume.inStock
                                                ? Colors.green.shade400
                                                : Colors.red.shade400,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 24),
                                  Container(
                                    padding: EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          darkMid,
                                          darkLight.withOpacity(0.5),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: goldPrimary.withOpacity(0.3),
                                        width: 1,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Select Size",
                                          style: GoogleFonts.playfairDisplay(
                                            fontSize: 18,
                                            color: textPrimary,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        SizedBox(height: 16),
                                        Wrap(
                                          spacing: 12,
                                          runSpacing: 12,
                                          children:
                                          perfume.sizes.keys.map((size) {
                                            return GestureDetector(
                                              onTap: () => setStateDialog(
                                                      () => _selectedSize = size),
                                              child: AnimatedContainer(
                                                duration:
                                                Duration(milliseconds: 200),
                                                padding: EdgeInsets.symmetric(
                                                    horizontal: 16,
                                                    vertical: 10),
                                                decoration: BoxDecoration(
                                                  gradient: _selectedSize ==
                                                      size
                                                      ? LinearGradient(
                                                    colors: [
                                                      goldDark,
                                                      goldPrimary
                                                    ],
                                                    begin:
                                                    Alignment.topLeft,
                                                    end: Alignment
                                                        .bottomRight,
                                                  )
                                                      : null,
                                                  color: _selectedSize == size
                                                      ? null
                                                      : darkLight,
                                                  borderRadius:
                                                  BorderRadius.circular(12),
                                                  border: Border.all(
                                                    color: _selectedSize == size
                                                        ? goldPrimary
                                                        : goldPrimary
                                                        .withOpacity(0.3),
                                                    width: _selectedSize == size
                                                        ? 2
                                                        : 1,
                                                  ),
                                                  boxShadow: _selectedSize ==
                                                      size
                                                      ? [
                                                    BoxShadow(
                                                      color: goldPrimary
                                                          .withOpacity(
                                                          0.3),
                                                      spreadRadius: 1,
                                                      blurRadius: 8,
                                                      offset:
                                                      Offset(0, 2),
                                                    )
                                                  ]
                                                      : null,
                                                ),
                                                child: Column(
                                                  children: [
                                                    Text(
                                                      size,
                                                      style: GoogleFonts.cinzel(
                                                        fontSize: 16,
                                                        fontWeight:
                                                        FontWeight.bold,
                                                        color: _selectedSize ==
                                                            size
                                                            ? darkBase
                                                            : textPrimary,
                                                      ),
                                                    ),
                                                    SizedBox(height: 4),
                                                    Text(
                                                      "TND ${perfume.sizes[size]!.toStringAsFixed(2)}",
                                                      style: GoogleFonts
                                                          .playfairDisplay(
                                                        fontSize: 14,
                                                        color: _selectedSize ==
                                                            size
                                                            ? darkBase
                                                            : goldLight,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                        SizedBox(height: 24),
                                        Text(
                                          "Quantity",
                                          style: GoogleFonts.playfairDisplay(
                                            fontSize: 18,
                                            color: textPrimary,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        SizedBox(height: 16),
                                        Container(
                                          decoration: BoxDecoration(
                                            color: darkLight,
                                            borderRadius:
                                            BorderRadius.circular(12),
                                            border: Border.all(
                                              color:
                                              goldPrimary.withOpacity(0.3),
                                              width: 1,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                            children: [
                                              _buildQuantityButton(
                                                icon: Icons.remove,
                                                onTap: () => setStateDialog(() {
                                                  if (_quantity > 1)
                                                    _quantity--;
                                                }),
                                              ),
                                              Text(
                                                _quantity.toString(),
                                                style: GoogleFonts.cinzel(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold,
                                                  color: textPrimary,
                                                ),
                                              ),
                                              _buildQuantityButton(
                                                icon: Icons.add,
                                                onTap: () => setStateDialog(() {
                                                  _quantity++;
                                                }),
                                              ),
                                            ],
                                          ),
                                        ),
                                        SizedBox(height: 24),
                                        Row(
                                          mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              "Price:",
                                              style:
                                              GoogleFonts.playfairDisplay(
                                                fontSize: 18,
                                                color: textPrimary,
                                              ),
                                            ),
                                            Text(
                                              "TND ${(perfume.sizes[_selectedSize] ?? 0.0).toStringAsFixed(2)}",
                                              style: GoogleFonts.cinzel(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: goldPrimary,
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (_quantity > 1) ...[
                                          SizedBox(height: 8),
                                          Row(
                                            mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                "Total:",
                                                style:
                                                GoogleFonts.playfairDisplay(
                                                  fontSize: 18,
                                                  color: textPrimary,
                                                ),
                                              ),
                                              Text(
                                                "TND ${(perfume.sizes[_selectedSize]! * _quantity).toStringAsFixed(2)}",
                                                style: GoogleFonts.cinzel(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold,
                                                  color: goldPrimary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: 28),
                                  Container(
                                    padding: EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: darkMid,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: goldPrimary.withOpacity(0.2),
                                        width: 1,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Description",
                                          style: GoogleFonts.cinzel(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: goldPrimary,
                                          ),
                                        ),
                                        Divider(
                                          color: goldPrimary.withOpacity(0.3),
                                          thickness: 1,
                                          height: 24,
                                        ),
                                        Text(
                                          perfume.description,
                                          style: GoogleFonts.playfairDisplay(
                                            fontSize: 16,
                                            height: 1.8,
                                            color: textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 24, vertical: 16),
                            decoration: BoxDecoration(
                              color: darkMid,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 10,
                                  offset: Offset(0, -3),
                                ),
                              ],
                              border: Border(
                                top: BorderSide(
                                  color: goldPrimary.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                            ),
                            child: ElevatedButton(
                              onPressed: perfume.inStock
                                  ? () {
                                _addToCart(
                                  perfume,
                                  quantity: _quantity,
                                  size: _selectedSize,
                                );
                                Navigator.pop(context);
                              }
                                  : null,
                              style: ElevatedButton.styleFrom(
                                padding: EdgeInsets.symmetric(vertical: 18),
                                backgroundColor: goldPrimary,
                                disabledBackgroundColor: Colors.grey.shade700,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 8,
                                shadowColor: goldPrimary.withOpacity(0.5),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.shopping_bag_outlined,
                                    color: darkBase,
                                    size: 24,
                                  ),
                                  SizedBox(width: 12),
                                  Text(
                                    "Add to Cart",
                                    style: GoogleFonts.cinzel(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: darkBase,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        barrierColor: Colors.black.withOpacity(0.8),
        builder: (context) => StatefulBuilder(
          builder: (context, setStateDialog) => DraggableScrollableSheet(
            initialChildSize: 0.92,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            builder: (_, controller) => Container(
              decoration: BoxDecoration(
                color: darkBase,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                boxShadow: [
                  BoxShadow(
                    color: goldPrimary.withOpacity(0.2),
                    blurRadius: 20,
                    spreadRadius: 1,
                  ),
                ],
                border: Border.all(
                  color: goldPrimary.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Container(
                    margin: EdgeInsets.symmetric(vertical: 12),
                    height: 5,
                    width: 50,
                    decoration: BoxDecoration(
                      color: goldPrimary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: controller,
                      child: Column(
                        children: [
                          Stack(
                            children: [
                              Container(
                                height: 300,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      darkLight.withOpacity(0.6),
                                      darkBase,
                                    ],
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 0,
                                right: 0,
                                left: 0,
                                child: Hero(
                                  tag: 'perfume-${perfume.id}',
                                  child: GestureDetector(
                                    onTap: () {
                                      showDialog(
                                        context: context,
                                        builder: (context) => Dialog(
                                          backgroundColor: Colors.transparent,
                                          child: GestureDetector(
                                            onTap: () => Navigator.pop(context),
                                            child: InteractiveViewer(
                                              panEnabled: true,
                                              minScale: 0.5,
                                              maxScale: 4.0,
                                              child: Image.network(
                                                perfume.image,
                                                fit: BoxFit.contain,
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                    child: Container(
                                      height: 250,
                                      child: Image.network(
                                        perfume.image,
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 16,
                                right: 16,
                                child: GestureDetector(
                                  onTap: () => Navigator.pop(context),
                                  child: Container(
                                    padding: EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: darkMid.withOpacity(0.7),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: goldPrimary.withOpacity(0.3),
                                        width: 1,
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.close,
                                      color: textPrimary,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: EdgeInsets.all(24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        perfume.name,
                                        style: GoogleFonts.cinzel(
                                          fontSize: 28,
                                          fontWeight: FontWeight.bold,
                                          color: goldPrimary,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: perfume.inStock
                                            ? Colors.green.withOpacity(0.2)
                                            : Colors.red.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: perfume.inStock
                                              ? Colors.green.shade400
                                              : Colors.red.shade400,
                                          width: 1,
                                        ),
                                      ),
                                      child: Text(
                                        perfume.inStock
                                            ? "In Stock"
                                            : "Out of Stock",
                                        style: GoogleFonts.playfairDisplay(
                                          color: perfume.inStock
                                              ? Colors.green.shade400
                                              : Colors.red.shade400,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 24),
                                Container(
                                  padding: EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        darkMid,
                                        darkLight.withOpacity(0.5),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: goldPrimary.withOpacity(0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Select Size",
                                        style: GoogleFonts.playfairDisplay(
                                          fontSize: 18,
                                          color: textPrimary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      SizedBox(height: 16),
                                      Wrap(
                                        spacing: 12,
                                        runSpacing: 12,
                                        children:
                                        perfume.sizes.keys.map((size) {
                                          return GestureDetector(
                                            onTap: () => setStateDialog(
                                                    () => _selectedSize = size),
                                            child: AnimatedContainer(
                                              duration:
                                              Duration(milliseconds: 200),
                                              padding: EdgeInsets.symmetric(
                                                  horizontal: 16, vertical: 10),
                                              decoration: BoxDecoration(
                                                gradient: _selectedSize == size
                                                    ? LinearGradient(
                                                  colors: [
                                                    goldDark,
                                                    goldPrimary
                                                  ],
                                                  begin:
                                                  Alignment.topLeft,
                                                  end: Alignment
                                                      .bottomRight,
                                                )
                                                    : null,
                                                color: _selectedSize == size
                                                    ? null
                                                    : darkLight,
                                                borderRadius:
                                                BorderRadius.circular(12),
                                                border: Border.all(
                                                  color: _selectedSize == size
                                                      ? goldPrimary
                                                      : goldPrimary
                                                      .withOpacity(0.3),
                                                  width: _selectedSize == size
                                                      ? 2
                                                      : 1,
                                                ),
                                                boxShadow: _selectedSize == size
                                                    ? [
                                                  BoxShadow(
                                                    color: goldPrimary
                                                        .withOpacity(0.3),
                                                    spreadRadius: 1,
                                                    blurRadius: 8,
                                                    offset: Offset(0, 2),
                                                  )
                                                ]
                                                    : null,
                                              ),
                                              child: Column(
                                                children: [
                                                  Text(
                                                    size,
                                                    style: GoogleFonts.cinzel(
                                                      fontSize: 16,
                                                      fontWeight:
                                                      FontWeight.bold,
                                                      color:
                                                      _selectedSize == size
                                                          ? darkBase
                                                          : textPrimary,
                                                    ),
                                                  ),
                                                  SizedBox(height: 4),
                                                  Text(
                                                    "TND ${perfume.sizes[size]!.toStringAsFixed(2)}",
                                                    style: GoogleFonts
                                                        .playfairDisplay(
                                                      fontSize: 14,
                                                      color:
                                                      _selectedSize == size
                                                          ? darkBase
                                                          : goldLight,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                      SizedBox(height: 24),
                                      Text(
                                        "Quantity",
                                        style: GoogleFonts.playfairDisplay(
                                          fontSize: 18,
                                          color: textPrimary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      SizedBox(height: 16),
                                      Container(
                                        decoration: BoxDecoration(
                                          color: darkLight,
                                          borderRadius:
                                          BorderRadius.circular(12),
                                          border: Border.all(
                                            color: goldPrimary.withOpacity(0.3),
                                            width: 1,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                          children: [
                                            _buildQuantityButton(
                                              icon: Icons.remove,
                                              onTap: () => setStateDialog(() {
                                                if (_quantity > 1) _quantity--;
                                              }),
                                            ),
                                            Text(
                                              _quantity.toString(),
                                              style: GoogleFonts.cinzel(
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                                color: textPrimary,
                                              ),
                                            ),
                                            _buildQuantityButton(
                                              icon: Icons.add,
                                              onTap: () => setStateDialog(() {
                                                _quantity++;
                                              }),
                                            ),
                                          ],
                                        ),
                                      ),
                                      SizedBox(height: 24),
                                      Row(
                                        mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            "Price:",
                                            style: GoogleFonts.playfairDisplay(
                                              fontSize: 18,
                                              color: textPrimary,
                                            ),
                                          ),
                                          Text(
                                            "TND ${(perfume.sizes[_selectedSize] ?? 0.0).toStringAsFixed(2)}",
                                            style: GoogleFonts.cinzel(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: goldPrimary,
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (_quantity > 1) ...[
                                        SizedBox(height: 8),
                                        Row(
                                          mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              "Total:",
                                              style:
                                              GoogleFonts.playfairDisplay(
                                                fontSize: 18,
                                                color: textPrimary,
                                              ),
                                            ),
                                            Text(
                                              "TND ${(perfume.sizes[_selectedSize]! * _quantity).toStringAsFixed(2)}",
                                              style: GoogleFonts.cinzel(
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                                color: goldPrimary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                SizedBox(height: 28),
                                Container(
                                  padding: EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: darkMid,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: goldPrimary.withOpacity(0.2),
                                      width: 1,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Description",
                                        style: GoogleFonts.cinzel(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: goldPrimary,
                                        ),
                                      ),
                                      Divider(
                                        color: goldPrimary.withOpacity(0.3),
                                        thickness: 1,
                                        height: 24,
                                      ),
                                      Text(
                                        perfume.description,
                                        style: GoogleFonts.playfairDisplay(
                                          fontSize: 16,
                                          height: 1.8,
                                          color: textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    decoration: BoxDecoration(
                      color: darkMid,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          offset: Offset(0, -3),
                        ),
                      ],
                      border: Border(
                        top: BorderSide(
                          color: goldPrimary.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                    ),
                    child: ElevatedButton(
                      onPressed: perfume.inStock
                          ? () {
                        _addToCart(
                          perfume,
                          quantity: _quantity,
                          size: _selectedSize,
                        );
                        Navigator.pop(context);
                      }
                          : null,
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 18),
                        backgroundColor: goldPrimary,
                        disabledBackgroundColor: Colors.grey.shade700,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 8,
                        shadowColor: goldPrimary.withOpacity(0.5),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.shopping_bag_outlined,
                            color: darkBase,
                            size: 24,
                          ),
                          SizedBox(width: 12),
                          Text(
                            "Add to Cart",
                            style: GoogleFonts.cinzel(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: darkBase,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
  }

  Widget _buildQuantityButton(
      {required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: darkMid,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: goldPrimary.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Icon(
          icon,
          color: goldPrimary,
          size: 24,
        ),
      ),
    );
  }

  Widget _buildCartDrawer() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth > 800;
    final drawerWidth = isLargeScreen ? 400.0 : screenWidth * 0.85;

    return Container(
      width: drawerWidth,
      child: Drawer(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: darkBase,
            boxShadow: [
              BoxShadow(
                color: goldPrimary.withOpacity(0.2),
                blurRadius: 16,
                offset: Offset(-5, 0),
              ),
            ],
            border: Border(
              left: BorderSide(
                color: goldPrimary.withOpacity(0.3),
                width: 1,
              ),
            ),
          ),
          child: SafeArea(
            child: ValueListenableBuilder<List<CartItem>>(
              valueListenable: cartNotifier,
              builder: (context, cartItems, child) => Column(
                children: [
                  Container(
                    padding: EdgeInsets.fromLTRB(24, 24, 16, 24),
                    decoration: BoxDecoration(
                      color: darkMid,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          offset: Offset(0, 3),
                        ),
                      ],
                      border: Border(
                        bottom: BorderSide(
                          color: goldPrimary.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.shopping_bag,
                              color: goldPrimary,
                              size: 28,
                            ),
                            SizedBox(width: 16),
                            Text(
                              "Your Shopping Bag",
                              style: GoogleFonts.cinzel(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: goldPrimary,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: Icon(Icons.close, color: textPrimary),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: cartItems.isEmpty
                        ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: goldPrimary.withOpacity(0.3),
                                width: 2,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.shopping_bag_outlined,
                              size: 60,
                              color: goldPrimary.withOpacity(0.5),
                            ),
                          ),
                          SizedBox(height: 24),
                          Text(
                            "Your bag is empty",
                            style: GoogleFonts.cinzel(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: textPrimary,
                            ),
                          ),
                          SizedBox(height: 16),
                          Text(
                            "Add items to begin shopping",
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 16,
                              color: textSecondary,
                            ),
                          ),
                          SizedBox(height: 32),
                          OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                  color: goldPrimary, width: 2),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              padding: EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                            ),
                            child: Text(
                              "Browse Collection",
                              style: GoogleFonts.playfairDisplay(
                                fontSize: 16,
                                color: goldPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                        : Scrollbar(
                      child: AnimationLimiter(
                        child: ListView.builder(
                          physics: BouncingScrollPhysics(),
                          padding: EdgeInsets.all(16),
                          itemCount: cartItems.length,
                          itemBuilder: (context, index) =>
                              AnimationConfiguration.staggeredList(
                                position: index,
                                duration: Duration(milliseconds: 400),
                                child: SlideAnimation(
                                  verticalOffset: 30,
                                  child: FadeInAnimation(
                                    child: Container(
                                      margin: EdgeInsets.only(bottom: 16),
                                      decoration: BoxDecoration(
                                        color: darkMid,
                                        borderRadius:
                                        BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                            Colors.black.withOpacity(0.2),
                                            blurRadius: 5,
                                            offset: Offset(0, 2),
                                          ),
                                        ],
                                        border: Border.all(
                                          color: goldPrimary.withOpacity(0.2),
                                          width: 1,
                                        ),
                                      ),
                                      child: Padding(
                                        padding: EdgeInsets.all(12),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 70,
                                              height: 70,
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                BorderRadius.circular(12),
                                                border: Border.all(
                                                  color: goldPrimary
                                                      .withOpacity(0.3),
                                                  width: 1,
                                                ),
                                              ),
                                              child: ClipRRect(
                                                borderRadius:
                                                BorderRadius.circular(11),
                                                child: Image.network(
                                                  cartItems[index]
                                                      .perfume
                                                      .image,
                                                  fit: BoxFit.contain,
                                                ),
                                              ),
                                            ),
                                            SizedBox(width: 16),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    cartItems[index]
                                                        .perfume
                                                        .name,
                                                    style: GoogleFonts.cinzel(
                                                      fontWeight:
                                                      FontWeight.bold,
                                                      color: textPrimary,
                                                    ),
                                                    maxLines: 1,
                                                    overflow:
                                                    TextOverflow.ellipsis,
                                                  ),
                                                  SizedBox(height: 4),
                                                  Text(
                                                    "Size: ${cartItems[index].selectedSize}",
                                                    style: GoogleFonts
                                                        .playfairDisplay(
                                                      fontSize: 14,
                                                      color: textSecondary,
                                                    ),
                                                  ),
                                                  SizedBox(height: 8),
                                                  Row(
                                                    children: [
                                                      GestureDetector(
                                                        onTap: () =>
                                                            _updateQuantity(
                                                              index,
                                                              cartItems[index]
                                                                  .quantity -
                                                                  1,
                                                            ),
                                                        child: Container(
                                                          padding:
                                                          EdgeInsets.all(
                                                              4),
                                                          decoration:
                                                          BoxDecoration(
                                                            color: darkLight,
                                                            borderRadius:
                                                            BorderRadius
                                                                .circular(
                                                                4),
                                                          ),
                                                          child: Icon(
                                                            Icons.remove,
                                                            color:
                                                            goldPrimary,
                                                            size: 16,
                                                          ),
                                                        ),
                                                      ),
                                                      Padding(
                                                        padding: EdgeInsets
                                                            .symmetric(
                                                            horizontal:
                                                            12),
                                                        child: Text(
                                                          "${cartItems[index].quantity}",
                                                          style: GoogleFonts
                                                              .cinzel(
                                                            fontSize: 16,
                                                            fontWeight:
                                                            FontWeight
                                                                .bold,
                                                            color:
                                                            textPrimary,
                                                          ),
                                                        ),
                                                      ),
                                                      GestureDetector(
                                                        onTap: () =>
                                                            _updateQuantity(
                                                              index,
                                                              cartItems[index]
                                                                  .quantity +
                                                                  1,
                                                            ),
                                                        child: Container(
                                                          padding:
                                                          EdgeInsets.all(
                                                              4),
                                                          decoration:
                                                          BoxDecoration(
                                                            color: darkLight,
                                                            borderRadius:
                                                            BorderRadius
                                                                .circular(
                                                                4),
                                                          ),
                                                          child: Icon(
                                                            Icons.add,
                                                            color:
                                                            goldPrimary,
                                                            size: 16,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Column(
                                              crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                              children: [
                                                IconButton(
                                                  icon: Icon(
                                                    Icons.delete_outline,
                                                    color:
                                                    Colors.red.shade400,
                                                  ),
                                                  onPressed: () =>
                                                      _removeFromCart(index),
                                                  padding: EdgeInsets.zero,
                                                  constraints:
                                                  BoxConstraints(),
                                                ),
                                                SizedBox(height: 8),
                                                Text(
                                                  "TND ${(cartItems[index].price * cartItems[index].quantity).toStringAsFixed(2)}",
                                                  style: GoogleFonts.cinzel(
                                                    fontSize: 14,
                                                    fontWeight:
                                                    FontWeight.bold,
                                                    color: goldPrimary,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                        ),
                      ),
                    ),
                  ),
                  if (cartItems.isNotEmpty)
                    Container(
                      padding: EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: darkMid,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 10,
                            offset: Offset(0, -3),
                          ),
                        ],
                        border: Border(
                          top: BorderSide(
                            color: goldPrimary.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Subtotal:",
                                style: GoogleFonts.playfairDisplay(
                                  fontSize: 16,
                                  color: textSecondary,
                                ),
                              ),
                              Text(
                                "TND ${cartItems.fold<double>(0, (sum, item) => sum + item.price * item.quantity).toStringAsFixed(2)}",
                                style: GoogleFonts.cinzel(
                                  fontSize: 16,
                                  color: textPrimary,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Shipping:",
                                style: GoogleFonts.playfairDisplay(
                                  fontSize: 16,
                                  color: textSecondary,
                                ),
                              ),
                              Text(
                                "Free",
                                style: GoogleFonts.cinzel(
                                  fontSize: 16,
                                  color: Colors.green.shade400,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Divider(
                            color: goldPrimary.withOpacity(0.3),
                            thickness: 1,
                          ),
                          SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Total:",
                                style: GoogleFonts.cinzel(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: textPrimary,
                                ),
                              ),
                              Text(
                                "TND ${cartItems.fold<double>(0, (sum, item) => sum + item.price * item.quantity).toStringAsFixed(2)}",
                                style: GoogleFonts.cinzel(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: goldPrimary,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: _showDeliveryInfoDialog,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: goldPrimary,
                              foregroundColor: darkBase,
                              padding: EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 8,
                              shadowColor: goldPrimary.withOpacity(0.5),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.lock,
                                  size: 20,
                                ),
                                SizedBox(width: 12),
                                Text(
                                  "Secure Checkout",
                                  style: GoogleFonts.cinzel(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHomePage() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('perfumes-${widget.id ?? "default"}')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError)
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  color: Colors.red.shade400,
                  size: 60,
                ),
                SizedBox(height: 16),
                Text(
                  "Error loading collection",
                  style: GoogleFonts.playfairDisplay(
                    color: textPrimary,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          );

        if (snapshot.connectionState == ConnectionState.waiting)
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 60,
                  height: 60,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(goldPrimary),
                    strokeWidth: 3,
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  "Loading collection...",
                  style: GoogleFonts.playfairDisplay(
                    color: goldLight,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          );

        final perfumes = snapshot.data!.docs
            .map((doc) => Perfume.fromFirestore(
            doc.data() as Map<String, dynamic>, doc.id))
            .toList();

        return CustomScrollView(
          physics: BouncingScrollPhysics(),
          slivers: [
            SliverAppBar(
              expandedHeight: ResponsiveBuilder.isMobile(context) ? 300 : 400,
              floating: false,
              pinned: true,
              backgroundColor: darkBase,
              elevation: 0,
              stretch: true,
              flexibleSpace: FlexibleSpaceBar(
                background: _buildHeroSection(),
                stretchModes: [
                  StretchMode.zoomBackground,
                  StretchMode.blurBackground,
                ],
              ),
              actions: [
                Padding(
                  padding: EdgeInsets.only(right: 16),
                  child: ValueListenableBuilder<List<CartItem>>(
                    valueListenable: cartNotifier,
                    builder: (context, cartItems, child) => Stack(
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.shopping_bag_outlined,
                            color: textPrimary,
                            size: 28,
                          ),
                          onPressed: () =>
                              _scaffoldKey.currentState?.openEndDrawer(),
                        )
                            .animate(
                          onPlay: (controller) =>
                              controller.repeat(reverse: true),
                        )
                            .shimmer(
                          duration: 2.seconds,
                          color: goldPrimary,
                        ),
                        if (cartItems.isNotEmpty)
                          Positioned(
                            right: 0,
                            top: 4,
                            child: Container(
                              padding: EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.red.shade400,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.red.shade400.withOpacity(0.4),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              child: Text(
                                "${cartItems.length}",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ).animate().scale(
                              duration: 300.ms,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            SliverToBoxAdapter(
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 30, horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          height: 40,
                          width: 5,
                          decoration: BoxDecoration(
                            color: goldPrimary,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: FadeTransition(
                            opacity: _fadeController,
                            child: Text(
                              "Exquisite Collection",
                              style: GoogleFonts.cinzel(
                                fontSize: ResponsiveBuilder.isMobile(context)
                                    ? 24
                                    : 28,
                                fontWeight: FontWeight.bold,
                                color: textPrimary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Text(
                      "Discover our exclusive limited edition fragrances",
                      style: GoogleFonts.playfairDisplay(
                        fontSize: ResponsiveBuilder.isMobile(context) ? 14 : 16,
                        fontStyle: FontStyle.italic,
                        color: textSecondary,
                      ),
                    ),
                    SizedBox(height: 24),
                    Container(
                      height: 2,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            goldPrimary.withOpacity(0.1),
                            goldPrimary,
                            goldPrimary.withOpacity(0.1),
                          ],
                          stops: [0.0, 0.5, 1.0],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (perfumes.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: EdgeInsets.all(30),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: goldPrimary.withOpacity(0.3),
                            width: 2,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.nature,
                          size: 80,
                          color: goldPrimary.withOpacity(0.7),
                        ),
                      ),
                      SizedBox(height: 24),
                      Text(
                        "Coming Soon",
                        style: GoogleFonts.cinzel(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: goldPrimary,
                        ),
                      ),
                      SizedBox(height: 12),
                      Text(
                        "Our collection is being curated",
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 18,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ResponsiveBuilder(
                mobile: SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  sliver: AnimationLimiter(
                    child: SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.7,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                      ),
                      delegate: SliverChildBuilderDelegate(
                            (context, index) =>
                            AnimationConfiguration.staggeredGrid(
                              position: index,
                              columnCount: 2,
                              duration: Duration(milliseconds: 600),
                              delay: Duration(milliseconds: 150 * index),
                              child: SlideAnimation(
                                verticalOffset: 50,
                                child: FadeInAnimation(
                                  child: _buildProductCard(perfumes[index], index),
                                ),
                              ),
                            ),
                        childCount: perfumes.length,
                      ),
                    ),
                  ),
                ),
                tablet: SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  sliver: AnimationLimiter(
                    child: SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        childAspectRatio: 0.75,
                        mainAxisSpacing: 24,
                        crossAxisSpacing: 24,
                      ),
                      delegate: SliverChildBuilderDelegate(
                            (context, index) =>
                            AnimationConfiguration.staggeredGrid(
                              position: index,
                              columnCount: 3,
                              duration: Duration(milliseconds: 600),
                              delay: Duration(milliseconds: 100 * index),
                              child: SlideAnimation(
                                verticalOffset: 50,
                                child: FadeInAnimation(
                                  child: _buildProductCard(perfumes[index], index),
                                ),
                              ),
                            ),
                        childCount: perfumes.length,
                      ),
                    ),
                  ),
                ),
                desktop: SliverToBoxAdapter(
                  child: Container(
                    height: 500,
                    margin: EdgeInsets.only(top: 20, bottom: 40),
                    child: AnimationLimiter(
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: EdgeInsets.symmetric(horizontal: 24),
                        itemCount: perfumes.length,
                        itemBuilder: (context, index) =>
                            AnimationConfiguration.staggeredList(
                              position: index,
                              duration: Duration(milliseconds: 600),
                              delay: Duration(milliseconds: 150 * index),
                              child: SlideAnimation(
                                horizontalOffset: 100,
                                child: FadeInAnimation(
                                  child: Container(
                                    width: 300,
                                    margin: EdgeInsets.only(right: 30),
                                    child:
                                    _buildProductCard(perfumes[index], index),
                                  ),
                                ),
                              ),
                            ),
                      ),
                    ),
                  ),
                ),
              ),
            SliverToBoxAdapter(
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 60),
                child: Column(
                  children: [
                    Container(
                      height: 2,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            goldPrimary.withOpacity(0.1),
                            goldPrimary,
                            goldPrimary.withOpacity(0.1),
                          ],
                          stops: [0.0, 0.5, 1.0],
                        ),
                      ),
                    ),
                    SizedBox(height: 40),
                    ResponsiveBuilder(
                      mobile: Column(
                        children: [
                          _buildFeature(
                            icon: Icons.local_shipping_outlined,
                            title: "Premium Delivery",
                            subtitle: "Free for orders above TND 150",
                          ),
                          SizedBox(height: 30),
                          _buildFeature(
                            icon: Icons.verified_outlined,
                            title: "Authenticity",
                            subtitle: "100% authentic products",
                          ),
                          SizedBox(height: 30),
                          _buildFeature(
                            icon: Icons.support_agent,
                            title: "Customer Support",
                            subtitle: "Available 24/7",
                          ),
                        ],
                      ),
                      tablet: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildFeature(
                            icon: Icons.local_shipping_outlined,
                            title: "Premium Delivery",
                            subtitle: "Free for orders above TND 150",
                          ),
                          SizedBox(width: 30),
                          _buildFeature(
                            icon: Icons.verified_outlined,
                            title: "Authenticity",
                            subtitle: "100% authentic products",
                          ),
                          SizedBox(width: 30),
                          _buildFeature(
                            icon: Icons.support_agent,
                            title: "Customer Support",
                            subtitle: "Available 24/7",
                          ),
                        ],
                      ),
                      desktop: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildFeature(
                            icon: Icons.local_shipping_outlined,
                            title: "Premium Delivery",
                            subtitle: "Free for orders above TND 150",
                          ),
                          SizedBox(width: 40),
                          _buildFeature(
                            icon: Icons.verified_outlined,
                            title: "Authenticity",
                            subtitle: "100% authentic products",
                          ),
                          SizedBox(width: 40),
                          _buildFeature(
                            icon: Icons.support_agent,
                            title: "Customer Support",
                            subtitle: "Available 24/7",
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFeature(
      {required IconData icon,
        required String title,
        required String subtitle}) {
    final isLargeScreen = MediaQuery.of(context).size.width > 650;

    return isLargeScreen
        ? Expanded(
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(
                color: goldPrimary.withOpacity(0.3),
                width: 2,
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: goldPrimary,
              size: 32,
            ),
          ),
          SizedBox(height: 12),
          Text(
            title,
            style: GoogleFonts.cinzel(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: goldPrimary,
            ),
          ),
          SizedBox(height: 4),
          Text(
            subtitle,
            style: GoogleFonts.playfairDisplay(
              fontSize: 14,
              color: textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    )
        :
    // Add what should be returned for small screens
    Column(
      children: [
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(
              color: goldPrimary.withOpacity(0.3),
              width: 1.5,
            ),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: goldPrimary,
            size: 24,
          ),
        ),
        SizedBox(height: 8),
        Text(
          title,
          style: GoogleFonts.cinzel(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: goldPrimary,
          ),
        ),
        SizedBox(height: 2),
        Text(
          subtitle,
          style: GoogleFonts.playfairDisplay(
            fontSize: 12,
            color: textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildHeroSection() {
    final isLargeScreen = MediaQuery.of(context).size.width > 650;

    return Stack(
      fit: StackFit.expand,
      children: [
        Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: NetworkImage(
                "https://images.unsplash.com/photo-1590736592503-684f468a4ed0",
              ),
              fit: BoxFit.cover,
              colorFilter: ColorFilter.mode(
                Colors.black.withOpacity(0.6),
                BlendMode.darken,
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  darkBase.withOpacity(0.3),
                  darkBase.withOpacity(0.7),
                  darkBase,
                ],
                stops: [0.0, 0.5, 0.8, 1.0],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: isLargeScreen ? 60 : 40,
          left: 0,
          right: 0,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FadeTransition(
                  opacity: _fadeController,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: goldPrimary,
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      "LUXURY COLLECTION",
                      style: GoogleFonts.cinzel(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: goldPrimary,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 16),
                SlideTransition(
                  position: Tween<Offset>(
                    begin: Offset(0, 0.5),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: _slideController,
                      curve: Curves.easeOut,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Opulent Fragrances",
                        style: GoogleFonts.cinzel(
                          color: Colors.white,
                          fontSize: isLargeScreen ? 40 : 32,
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.5),
                              blurRadius: 10,
                              offset: Offset(2, 2),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 8),
                      Container(
                        height: 4,
                        width: 60,
                        decoration: BoxDecoration(
                          color: goldPrimary,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        "Indulge in our exquisite collection of opulent scents",
                        style: GoogleFonts.playfairDisplay(
                          color: textSecondary,
                          fontSize: isLargeScreen ? 18 : 16,
                          height: 1.5,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.5),
                              blurRadius: 5,
                              offset: Offset(1, 1),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 24),
                      OutlinedButton(
                        onPressed: () {
                          final scrollController =
                          PrimaryScrollController.of(context);
                          scrollController.animateTo(
                            isLargeScreen ? 400 : 300,
                            duration: Duration(milliseconds: 800),
                            curve: Curves.easeOutQuint,
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: goldPrimary, width: 2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: isLargeScreen ? 24 : 16,
                            vertical: isLargeScreen ? 16 : 12,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "Explore Collection",
                              style: GoogleFonts.playfairDisplay(
                                fontSize: isLargeScreen ? 16 : 14,
                                color: goldPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(
                              Icons.arrow_downward,
                              size: isLargeScreen ? 18 : 16,
                              color: goldPrimary,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProductCard(Perfume perfume, int index) {
    final lowestPrice = perfume.sizes.values.isNotEmpty
        ? perfume.sizes.values.reduce((a, b) => a < b ? a : b)
        : 0.0;

    return StatefulBuilder(
      builder: (context, setState) {
        return MouseRegion(
          onEnter: (_) => setState(() {
            _isHovering = true;
            _hoveredIndex = index;
          }),
          onExit: (_) => setState(() {
            _isHovering = false;
            _hoveredIndex = -1;
          }),
          child: GestureDetector(
            onTap: () => _showDetailDialog(perfume),
            child: Container(
              decoration: BoxDecoration(
                color: darkMid,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: _isHovering && _hoveredIndex == index
                        ? goldPrimary.withOpacity(0.2)
                        : Colors.black.withOpacity(0.3),
                    blurRadius: _isHovering && _hoveredIndex == index ? 15 : 8,
                    offset: Offset(0, 5),
                  ),
                ],
                border: Border.all(
                  color: _isHovering && _hoveredIndex == index
                      ? goldPrimary.withOpacity(0.5)
                      : goldPrimary.withOpacity(0.2),
                  width: _isHovering && _hoveredIndex == index ? 2 : 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 7,
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius:
                          BorderRadius.vertical(top: Radius.circular(18)),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  darkLight.withOpacity(0.8),
                                  darkMid.withOpacity(0.8),
                                ],
                              ),
                            ),
                            child: Center(
                              child: Hero(
                                tag: 'perfume-${perfume.id}',
                                child: Image.network(
                                  perfume.image,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      child: Icon(
                                        Icons.image_not_supported,
                                        color: darkLight,
                                        size: 40,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 12,
                          right: 12,
                          child: AnimatedOpacity(
                            duration: Duration(milliseconds: 200),
                            opacity: _isHovering && _hoveredIndex == index
                                ? 1.0
                                : 0.0,
                            child: Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: darkBase.withOpacity(0.7),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: goldPrimary.withOpacity(0.5),
                                  width: 1,
                                ),
                              ),
                              child: Icon(
                                Icons.visibility,
                                color: goldPrimary,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                        if (perfume.inStock)
                          Positioned(
                            bottom: 12,
                            right: 12,
                            child: AnimatedOpacity(
                              duration: Duration(milliseconds: 200),
                              opacity: _isHovering && _hoveredIndex == index
                                  ? 1.0
                                  : 0.0,
                              child: GestureDetector(
                                onTap: () {
                                  _addToCart(
                                    perfume,
                                    size: perfume.sizes.keys.first,
                                  );
                                },
                                child: Container(
                                  padding: EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [goldDark, goldPrimary],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: goldPrimary.withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    Icons.add_shopping_cart,
                                    color: darkBase,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 4,
                    child: Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: darkMid,
                        borderRadius: BorderRadius.vertical(
                          bottom: Radius.circular(18),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                perfume.name,
                                style: GoogleFonts.cinzel(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: textPrimary,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 8),
                              Text(
                                perfume.description,
                                style: GoogleFonts.playfairDisplay(
                                  fontSize: 12,
                                  color: textSecondary,
                                  fontStyle: FontStyle.italic,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    "From ",
                                    style: GoogleFonts.playfairDisplay(
                                      fontSize: 12,
                                      color: textSecondary,
                                    ),
                                  ),
                                  Text(
                                    "TND ${lowestPrice.toStringAsFixed(2)}",
                                    style: GoogleFonts.cinzel(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: goldPrimary,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: perfume.inStock
                                      ? Colors.green.withOpacity(0.2)
                                      : Colors.red.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: perfume.inStock
                                        ? Colors.green.shade400.withOpacity(0.5)
                                        : Colors.red.shade400.withOpacity(0.5),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  perfume.inStock ? "In Stock" : "Sold Out",
                                  style: GoogleFonts.playfairDisplay(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                    color: perfume.inStock
                                        ? Colors.green.shade400
                                        : Colors.red.shade400,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            )
                .animate(
              target: _isHovering && _hoveredIndex == index ? 1 : 0,
            )
                .scale(
              begin: Offset(1.0, 1.0),
              end: Offset(1.05, 1.05),
              duration: 300.ms,
              curve: Curves.easeOutQuint,
            )
                .elevation(
              begin: 4,
              end: 16,
              curve: Curves.easeOutQuint,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: darkBase,
      endDrawer: _buildCartDrawer(),
      body: _buildHomePage(),
    );
  }
}