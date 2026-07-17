import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../providers/auth_provider.dart';
import '../providers/product_provider.dart';
import '../services/language_provider.dart';
import '../services/notification_service.dart';
import '../services/currency_provider.dart';

import '../providers/cms_provider.dart';

class PostAdScreen extends StatefulWidget {
  final ProductModel? productToEdit;
  const PostAdScreen({super.key, this.productToEdit});

  @override
  State<PostAdScreen> createState() => _PostAdScreenState();
}

class _PostAdScreenState extends State<PostAdScreen> {
  int _step = 0;
  bool _isSubmitting = false;

  // Step 1 – category
  String? _selectedCategory;

  // Step 2 – details
  late TextEditingController _titleCtrl;
  late TextEditingController _priceCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _whatsAppCtrl; // NEW
  late TextEditingController _cityCtrl; // NEW
  late TextEditingController _villageCtrl; // NEW
  String _condition = 'Sale';
  String _sellerType = 'Personal';
  String _location = 'Pakistan'; // Changed from Doha

  // Auction / Bidding
  bool _isAuction = false;
  DateTime? _auctionEndTime;

  // Cash on Delivery
  bool _acceptsCOD = false;
  late TextEditingController _codLocationCtrl;
  late TextEditingController _codContactCtrl;

  // Jobs
  late TextEditingController _companyCtrl;
  String _jobType = 'Full-time';
  late TextEditingController _salaryCtrl;

  // Step 3 – photos
  final List<File> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();

  final _steps = ['Category', 'Details', 'Photos', 'Preview'];

  @override
  void initState() {
    super.initState();
    final p = widget.productToEdit;
    _titleCtrl = TextEditingController(text: p?.title ?? '');
    _priceCtrl = TextEditingController(text: p?.price.toString() ?? '');
    _descCtrl = TextEditingController(text: p?.description ?? '');
    _phoneCtrl = TextEditingController(text: p?.sellerPhone ?? '+92 ');
    _whatsAppCtrl = TextEditingController(text: p?.whatsAppNumber ?? '+92 '); // NEW
    _cityCtrl = TextEditingController(text: p?.city ?? ''); // NEW
    _villageCtrl = TextEditingController(text: p?.village ?? ''); // NEW
    
    // COD
    _codLocationCtrl = TextEditingController(text: p?.codDeliveryLocation ?? '');
    _codContactCtrl = TextEditingController(text: p?.codContactNumber ?? '');
    if (p != null) _acceptsCOD = p.acceptsCOD;
    // Jobs
    _companyCtrl = TextEditingController(text: p?.companyName ?? '');
    _salaryCtrl = TextEditingController(text: p?.salaryRange ?? '');
    
    if (p != null) {
      _selectedCategory = p.category;
      _condition = p.condition;
      _sellerType = p.sellerType;
      _location = p.location;
      _isAuction = p.isAuction;
      _auctionEndTime = p.auctionEndTime;
      _jobType = p.jobType ?? 'Full-time';
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _priceCtrl.dispose();
    _descCtrl.dispose();
    _phoneCtrl.dispose();
    _whatsAppCtrl.dispose(); // NEW
    _cityCtrl.dispose(); // NEW
    _villageCtrl.dispose(); // NEW
    _codLocationCtrl.dispose();
    _codContactCtrl.dispose();
    _companyCtrl.dispose();
    _salaryCtrl.dispose();
    super.dispose();
  }

  // Reset all form fields back to step 0 — never pops the screen.
  void _resetForm() {
    if (!mounted) return;
    setState(() {
      _step = 0;
      _selectedCategory = null;
      _titleCtrl.clear();
      _priceCtrl.clear();
      _descCtrl.clear();
      _phoneCtrl.text = '+92 ';
      _whatsAppCtrl.text = '+92 '; // NEW
      _cityCtrl.clear(); // NEW
      _villageCtrl.clear(); // NEW
      _condition = 'Sale';
      _sellerType = 'Personal';
      _location = 'Pakistan'; // Changed from Doha
      _selectedImages.clear();
      _isAuction = false;
      _auctionEndTime = null;
      _acceptsCOD = false;
      _codLocationCtrl.clear();
      _codContactCtrl.clear();
      _companyCtrl.clear();
      _salaryCtrl.clear();
      _jobType = 'Full-time';
    });
  }


  Future<void> _pickImage() async {
    if (_selectedImages.length >= 2) {
      _snack('Photo limit reached. You can only upload up to 02 photos.', AppColors.orange);
      return;
    }
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70, // Optimize for free tier storage
    );
    if (image != null) {
      setState(() {
        _selectedImages.add(File(image.path));
      });
    }
  }

  void _nextStep() {
    final t = context.read<LanguageProvider>().t;
    if (_step == 0 && _selectedCategory == null) {
      _snack(t['select_category_error'] ?? 'Please select a category first', AppColors.orange);
      return;
    }
    if (_step == 1) {
      final isJob = _selectedCategory == 'Jobs Center';
      if (isJob && _companyCtrl.text.trim().isEmpty) {
        _snack(t['enter_company_error'] ?? 'Please enter company name', AppColors.orange);
        return;
      }
      if (_titleCtrl.text.trim().isEmpty) {
        _snack(t['enter_title_error'] ?? 'Please enter a title', AppColors.orange);
        return;
      }
      if (!isJob && _priceCtrl.text.trim().isEmpty) {
        _snack(t['enter_price_error'] ?? 'Please enter a price (or 0 for free)', AppColors.orange);
        return;
      }
      if (_isAuction && _auctionEndTime == null) {
        _snack(t['select_auction_end_error'] ?? 'Please select auction end date', AppColors.orange);
        return;
      }
    }

    if (_step < _steps.length - 1) setState(() => _step++);
  }

  void _prevStep() {
    if (_step > 0) setState(() => _step--);
  }

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: color,
      duration: const Duration(seconds: 2),
    ));
  }

  Future<void> _submit() async {
    final auth = context.read<AuthProvider>();
    final cms = context.read<CMSProvider>();
    final t = context.read<LanguageProvider>().t;

    if (!auth.isAuthenticated) {
      _snack('Please sign in to post an ad', AppColors.orange);
      return;
    }

    if (auth.userModel?.isAdminApproved == false) {
      _snack('Your account is suspended', AppColors.orange);
      return;
    }

    // Check ID Verification if required
    if (cms.requireIdVerification && 
        auth.userModel?.idVerificationStatus != 'verified' && 
        auth.userModel?.idVerificationStatus != 'approved') {
      _snack('ID Verification is required to post ads. Please verify your account in settings.', AppColors.orange);
      return;
    }

    final user = auth.firebaseUser;
    if (user == null) {
      _snack('User session not found. Please sign in again.', AppColors.orange);
      return;
    }

    if (_selectedCategory == null) {
      _snack('Please select a category', AppColors.orange);
      return;
    }

    setState(() => _isSubmitting = true);
    
    try {
      final p = widget.productToEdit;
      final isJob = _selectedCategory == 'Jobs Center';
      final currencyProvider = context.read<CurrencyProvider>();
      
      final productData = ProductModel(
        id: p?.id ?? '',
        title: _titleCtrl.text.trim().isEmpty ? 'My Ad' : _titleCtrl.text.trim(),
        price: double.tryParse(_priceCtrl.text.trim()) ?? 0,
        currency: p?.currency ?? currencyProvider.selectedCurrency,
        category: _selectedCategory!,
        condition: _condition,
        sellerType: _sellerType,
        sellerId: user.uid,
        sellerName: auth.userModel?.name ?? 'Anonymous',
        sellerPhone: _phoneCtrl.text.trim(),
        whatsAppNumber: _whatsAppCtrl.text.trim(), // NEW
        location: _location,
        city: _cityCtrl.text.trim(), // NEW
        village: _villageCtrl.text.trim(), // NEW
        description: _descCtrl.text.trim(),
        createdAt: p?.createdAt ?? DateTime.now(),
        views: p?.views ?? 0,
        isFeatured: p?.isFeatured ?? false,
        imageUrls: p?.imageUrls ?? [],
        // COD
        acceptsCOD: _acceptsCOD,
        codDeliveryLocation: _acceptsCOD ? _codLocationCtrl.text.trim() : null,
        codContactNumber: _acceptsCOD ? _codContactCtrl.text.trim() : null,
        // Bidding
        isAuction: _isAuction,
        auctionEndTime: _auctionEndTime,
        // Job
        isJob: isJob,
        companyName: isJob ? _companyCtrl.text.trim() : null,
        jobType: isJob ? _jobType : null,
        salaryRange: isJob ? _salaryCtrl.text.trim() : null,
        // Initial status
        status: p?.status ?? 'approved', // Ads show immediately without admin review
      );


      if (p == null) {
        await context.read<ProductProvider>().addProduct(productData, _selectedImages);
        // Send notification to seller that ad is pending review
        await NotificationService.system(
          userId: user.uid,
          title: t['ad_submitted'] ?? 'Ad Submitted 📝',
          body: t['ad_pending_review'] ?? 'Your "${productData.title}" ad has been submitted and is pending admin review.',
        );
      } else {
        await context.read<ProductProvider>().updateProduct(productData, _selectedImages);
      }

      if (mounted) {
        setState(() => _isSubmitting = false);
        _showSuccessDialog();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        _snack('Error posting ad: $e', Colors.redAccent);
      }
    }
  }

  void _showSuccessDialog() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: isDark ? AppColors.primaryDark : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                  color: AppColors.green, shape: BoxShape.circle),
              child: const Icon(Icons.check, color: Colors.white, size: 40),
            ),
            const SizedBox(height: 20),
            Text(
              widget.productToEdit == null ? 'Ad Posted Successfully! 🎉' : 'Ad Updated Successfully! 🎉',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: theme.textTheme.bodyLarge?.color,
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              widget.productToEdit == null 
                  ? 'Your ad has been submitted and is pending admin review. You will be notified once it is live.'
                  : 'Your changes have been saved successfully.',
              textAlign: TextAlign.center,
              style:
              TextStyle(color: isDark ? AppColors.textSecondary : AppColors.textSecondaryLightMode, fontSize: 13),
            ),
            const SizedBox(height: 24),

            // ── FIX: "Done" now only closes the dialog and resets the
            // form back to step 0. It NEVER calls Navigator.pop(context)
            // on the outer screen, because PostAdScreen lives inside the
            // HomeScreen IndexedStack and popping it would remove
            // HomeScreen from the navigator, causing a black screen.
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext); // close dialog only
                _resetForm();                 // go back to step 0
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text(
                'Done',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 8),

            // "Post Another Ad" also just closes the dialog + resets.
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext); // close dialog only
                _resetForm();                 // go back to step 0
              },
              child: const Text(
                'Post Another Ad',
                style: TextStyle(color: AppColors.gold, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = context.watch<LanguageProvider>().t;
    final steps = [
      t['step_category'] ?? 'Category',
      t['step_details'] ?? 'Details',
      t['step_photos'] ?? 'Photos',
      t['step_preview'] ?? 'Preview'
    ];

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.productToEdit != null ? (t['edit_ad'] ?? 'Edit Ad') : (t['nav_post_ad'] ?? 'Post Ad'),
          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        actions: [
          if (_step > 0)
            TextButton(
              onPressed: _resetForm,
              child: Text(t['reset'] ?? 'Reset', style: const TextStyle(color: AppColors.gold)),
            ),
        ],
      ),
      body: _isSubmitting
          ? _buildSubmittingState(t)
          : Column(
              children: [
                _buildStepIndicator(steps),
                Expanded(
                  child: _buildCurrentStep(),
                ),
                _buildNavButtons(t),
              ],
            ),
    );
  }

  Widget _buildCurrentStep() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: child),
      child: KeyedSubtree(
        key: ValueKey(_step),
        child: _step == 0
            ? _buildCategoryStep()
            : _step == 1
                ? _buildDetailsStep()
                : _step == 2
                    ? _buildPhotosStep()
                    : _buildPreviewStep(),
      ),
    );
  }

  Widget _buildSubmittingState(Map<String, String> t) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: AppColors.gold),
          const SizedBox(height: 24),
          Text(t['submitting_ad'] ?? 'Submitting your ad...',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  // ── Step indicator ────────────────────────────────────────────────────────
  Widget _buildStepIndicator(List<String> steps) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
      color: isDark ? AppColors.primaryDark : AppColors.primary,
      child: Row(
        children: steps.asMap().entries.map((e) {
          final i = e.key;
          final isActive = i == _step;
          final isDone = i < _step;
          return Expanded(
            child: Row(
              children: [
                if (i > 0)
                  Expanded(
                    child: Container(
                      height: 2,
                      color: isDone ? AppColors.gold : (isDark ? AppColors.divider : Colors.white24),
                    ),
                  ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDone
                            ? AppColors.gold
                            : isActive
                                ? AppColors.primary
                                : (isDark ? theme.cardTheme.color : Colors.white.withValues(alpha: 0.1)),
                        border: Border.all(
                          color: isActive ? AppColors.gold : (isDark ? AppColors.divider : Colors.white24),
                          width: isActive ? 2 : 1,
                        ),
                      ),
                      child: Center(
                        child: isDone
                            ? const Icon(Icons.check, size: 14, color: Colors.white)
                            : Text('${i + 1}',
                                style: TextStyle(
                                  color: isActive ? AppColors.gold : (isDark ? AppColors.textMuted : Colors.white70),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                )),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(e.value,
                        style: TextStyle(
                            color: isActive ? AppColors.gold : (isDark ? AppColors.textMuted : Colors.white70),
                            fontSize: 10)),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Step 1: Category ──────────────────────────────────────────────────────
  Widget _buildCategoryStep() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final t = context.watch<LanguageProvider>().t;
    final cms = context.watch<CMSProvider>();
    final cats = cms.categories.isNotEmpty
        ? cms.categories.map((c) => {
            'n': c['name']?.toString() ?? '',
            'i': c['icon']?.toString() ?? '',
          }).toList()
        : [
            {'n': 'Vehicles', 'i': '🚗'},
            {'n': 'Properties', 'i': '🏠'},
            {'n': 'Electronics', 'i': '⚡'},
            {'n': 'Furniture & Décor', 'i': '🪑'},
            {'n': 'WaterCrafts', 'i': '⛵'},
            {'n': 'Jewellery', 'i': '💎'},
            {'n': 'Lifestyle', 'i': '🛍️'},
            {'n': 'Market', 'i': '🛒'},
            {'n': 'Outdoor & Leisure', 'i': '⛺'},
            {'n': 'Special Numbers', 'i': '🔢'},
            {'n': 'Heavy Equipments', 'i': '🏗️'},
            {'n': 'Jobs Center', 'i': '💼'},
            {'n': 'Super Ads', 'i': '⭐'},
          ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
          child: Text(t['select_category'] ?? 'Select Category',
              style: TextStyle(
                  color: theme.textTheme.bodyLarge?.color,
                  fontSize: 18,
                  fontWeight: FontWeight.w600)),
        ),
        Expanded(
          child: GridView.count(
            crossAxisCount: 3,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.85,
            children: cats.map((c) {
              final sel = _selectedCategory == c['n'];
              final label = t[c['n']!.toLowerCase().replaceAll(' ', '_')] ?? c['n']!;
              return GestureDetector(
                onTap: () => setState(() => _selectedCategory = c['n']),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  decoration: BoxDecoration(
                    color: sel ? AppColors.primary : theme.cardTheme.color,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: sel
                          ? AppColors.gold
                          : (isDark ? AppColors.divider : AppColors.dividerLightMode).withValues(alpha: 0.5),
                      width: sel ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(c['i']!, style: const TextStyle(fontSize: 34)),
                      const SizedBox(height: 8),
                      Text(label,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: sel ? Colors.white : theme.textTheme.bodyLarge?.color,
                              fontSize: 12,
                              fontWeight:
                              sel ? FontWeight.bold : FontWeight.normal)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // ── Step 2: Details ───────────────────────────────────────────────────────
  Widget _buildDetailsStep() {
    final theme = Theme.of(context);
    final t = context.watch<LanguageProvider>().t;
    final isJob = _selectedCategory == 'Jobs Center';
    final isAuctionable = _selectedCategory == 'Vehicles' || _selectedCategory == 'Properties';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t['ad_details'] ?? 'Ad Details',
              style: TextStyle(
                  color: theme.textTheme.bodyLarge?.color,
                  fontSize: 18,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          
          if (isJob) ...[
            _field('Company Name *', 'e.g. Pakistan International Airlines', _companyCtrl),
            const SizedBox(height: 12),
            _dropdown('Job Type *', 
                ['Full-time', 'Part-time', 'Contract', 'Temporary'], 
                _jobType, 
                (v) => setState(() => _jobType = v!)),
            const SizedBox(height: 12),
            _field('Salary Range', 'e.g. 50,000 - 80,000 Rs.', _salaryCtrl),
            const SizedBox(height: 12),
          ],

          _field('${t['title'] ?? "Title"} *', isJob ? 'e.g. Senior Accountant' : 'e.g. iPhone 14 Pro 256GB', _titleCtrl),
          const SizedBox(height: 12),
          
          if (!isJob) ...[
            _field('${t['price'] ?? "Price"} (Rs.)', 'e.g. 50000 (enter 0 if free)', _priceCtrl,
                isNumber: true),
            const SizedBox(height: 12),
          ],

          if (isAuctionable) ...[
            SwitchListTile(
              title: const Text('List as Auction/Bidding', style: TextStyle(fontSize: 14)),
              subtitle: const Text('Allow users to bid on this item', style: TextStyle(fontSize: 12)),
              value: _isAuction,
              activeThumbColor: AppColors.gold,
              onChanged: (v) => setState(() => _isAuction = v),
              contentPadding: EdgeInsets.zero,
            ),
            if (_isAuction) ...[
              const SizedBox(height: 8),
              ListTile(
                title: const Text('Auction End Date', style: TextStyle(fontSize: 14)),
                subtitle: Text(_auctionEndTime == null ? 'Not set' : _auctionEndTime!.toString().split(' ')[0], style: const TextStyle(fontSize: 12)),
                trailing: const Icon(Icons.calendar_today, size: 18),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now().add(const Duration(days: 7)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 30)),
                  );
                  if (date != null) setState(() => _auctionEndTime = date);
                },
              ),
              const SizedBox(height: 12),
            ],
          ],

          // Cash on Delivery
          if (!isJob) ...[
            SwitchListTile(
              title: const Text('Accept Cash on Delivery', style: TextStyle(fontSize: 14)),
              subtitle: const Text('Buyers can pay in cash upon delivery', style: TextStyle(fontSize: 12)),
              value: _acceptsCOD,
              activeThumbColor: AppColors.green,
              onChanged: (v) => setState(() => _acceptsCOD = v),
              contentPadding: EdgeInsets.zero,
            ),
            if (_acceptsCOD) ...[
              const SizedBox(height: 8),
              _field('Delivery Location', 'e.g. Lahore, Gulberg', _codLocationCtrl),
              const SizedBox(height: 12),
              _field('Contact Number', '+92 XXX XXXXXXX', _codContactCtrl, isNumber: true),
              const SizedBox(height: 12),
            ],
          ],

          _dropdown('${t['condition'] ?? "Condition"} *', 
              ['Sale', 'Rent', 'Exchange', 'Free'].map((x) => t[x.toLowerCase()] ?? x).toList(),
              t[_condition.toLowerCase()] ?? _condition, 
              (v) {
                // Find original value from translated value
                final original = ['Sale', 'Rent', 'Exchange', 'Free'].firstWhere((x) => (t[x.toLowerCase()] ?? x) == v, orElse: () => 'Sale');
                setState(() => _condition = original);
              }),
          const SizedBox(height: 12),
          _dropdown(t['seller_type'] ?? 'Seller Type', 
              ['Personal', 'Business'].map((x) => t[x.toLowerCase()] ?? x).toList(), 
              t[_sellerType.toLowerCase()] ?? _sellerType,
              (v) {
                final original = ['Personal', 'Business'].firstWhere((x) => (t[x.toLowerCase()] ?? x) == v, orElse: () => 'Personal');
                setState(() => _sellerType = original);
              }),
          const SizedBox(height: 12),
          _field(
              t['description'] ?? 'Description', 'Describe your item in detail…', _descCtrl,
              maxLines: 4),
          const SizedBox(height: 12),
          _dropdown(t['location'] ?? 'Location',
              ['Pakistan', 'GCC Countries'].map((x) => t[x.toLowerCase().replaceAll(' ', '_')] ?? x).toList(),
              t[_location.toLowerCase().replaceAll(' ', '_')] ?? _location, 
              (v) {
                final original = ['Pakistan', 'GCC Countries'].firstWhere((x) => (t[x.toLowerCase().replaceAll(' ', '_')] ?? x) == v, orElse: () => 'Pakistan');
                setState(() => _location = original);
              }),
          const SizedBox(height: 12),
          if (_location == 'Pakistan') ...[
            _field('City *', 'e.g. Lahore', _cityCtrl),
            const SizedBox(height: 12),
            _field('Village/Area', 'e.g. Gulberg III', _villageCtrl),
            const SizedBox(height: 12),
          ],
          _field('${t['phone_number'] ?? "Phone Number"} *', '+92 XXX XXXXXXX', _phoneCtrl,
              isNumber: true),
          const SizedBox(height: 12),
          _field('WhatsApp Number', '+92 XXX XXXXXXX (optional)', _whatsAppCtrl,
              isNumber: true),
          const SizedBox(height: 80),
        ],
      ),
    );
  }


  Widget _field(
      String label,
      String hint,
      TextEditingController ctrl, {
        bool isNumber = false,
        int maxLines = 1,
      }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                color: isDark ? AppColors.textSecondary : AppColors.textSecondaryLightMode, fontSize: 13)),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          keyboardType:
          isNumber ? TextInputType.number : TextInputType.text,
          maxLines: maxLines,
          style: TextStyle(color: theme.textTheme.bodyLarge?.color),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: isDark ? AppColors.textMuted : AppColors.textSecondaryLightMode),
            filled: true,
            fillColor: theme.cardTheme.color,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }

  Widget _dropdown(String label, List<String> opts, String val,
      ValueChanged<String?> onChange) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                color: isDark ? AppColors.textSecondary : AppColors.textSecondaryLightMode, fontSize: 13)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
              color: theme.cardTheme.color,
              borderRadius: BorderRadius.circular(10)),
          child: DropdownButton<String>(
            value: val,
            isExpanded: true,
            dropdownColor: theme.cardTheme.color,
            underline: const SizedBox(),
            style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontSize: 15),
            items: opts
                .map((o) => DropdownMenuItem(value: o, child: Text(o)))
                .toList(),
            onChanged: onChange,
          ),
        ),
      ],
    );
  }

  // ── Step 3: Photos ────────────────────────────────────────────────────────
  Widget _buildPhotosStep() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Upload Photos',
              style: TextStyle(
                  color: theme.textTheme.bodyLarge?.color,
                  fontSize: 18,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text('Add up to 10 photos of your product',
              style: TextStyle(color: isDark ? AppColors.textMuted : AppColors.textSecondaryLightMode, fontSize: 13)),
          const SizedBox(height: 20),
          SizedBox(
            height: 300,
            child: GridView.count(
              crossAxisCount: 3,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              children: [
                if (_selectedImages.length < 10)
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.gold, width: 1.5),
                      ),
                      child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate_outlined,
                                color: AppColors.gold, size: 32),
                            SizedBox(height: 6),
                            Text('Add Photo',
                                style: TextStyle(
                                    color: AppColors.gold, fontSize: 11)),
                          ]),
                    ),
                  ),
                ..._selectedImages.asMap().entries.map(
                      (entry) => Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.surface : AppColors.backgroundLightMode,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: (isDark ? AppColors.divider : AppColors.dividerLightMode).withValues(alpha: 0.5)),
                          image: DecorationImage(
                            image: FileImage(entry.value),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedImages.removeAt(entry.key)),
                          child: Container(
                            width: 22,
                            height: 22,
                            decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle),
                            child: const Icon(Icons.close,
                                size: 13, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.only(top: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: theme.cardTheme.color,
                borderRadius: BorderRadius.circular(10)),
            child: Row(children: [
              const Icon(Icons.lightbulb_outline,
                  color: AppColors.gold, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Tip: Well-lit photos from multiple angles help your ad get up to 3× more views.',
                  style: TextStyle(
                      color: isDark ? AppColors.textSecondary : AppColors.textSecondaryLightMode, fontSize: 12),
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  // ── Step 4: Preview ───────────────────────────────────────────────────────
  Widget _buildPreviewStep() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currencyProvider = context.watch<CurrencyProvider>();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Preview Your Ad',
              style: TextStyle(
                  color: theme.textTheme.bodyLarge?.color,
                  fontSize: 18,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.cardTheme.color,
              borderRadius: BorderRadius.circular(14),
              border:
              Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                            color: isDark ? AppColors.surface : AppColors.backgroundLightMode,
                            borderRadius: BorderRadius.circular(10)),
                        child: Center(
                          child: Text(
                            _catEmoji(_selectedCategory ?? ''),
                            style: const TextStyle(fontSize: 40),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _titleCtrl.text.isEmpty
                                  ? 'Your Ad Title'
                                  : _titleCtrl.text,
                              style: TextStyle(
                                  color: theme.textTheme.bodyLarge?.color,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _priceCtrl.text.isEmpty
                                  ? 'Price not set'
                                  : currencyProvider.formatPrice(double.tryParse(_priceCtrl.text) ?? 0),
                              style: const TextStyle(
                                  color: AppColors.gold,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Row(children: [
                              Icon(Icons.location_on,
                                  size: 12,
                                  color: isDark ? AppColors.textMuted : AppColors.textSecondaryLightMode),
                              const SizedBox(width: 2),
                              Text(_location,
                                  style: TextStyle(
                                      color: isDark ? AppColors.textMuted : AppColors.textSecondaryLightMode,
                                      fontSize: 12)),
                            ]),
                          ],
                        ),
                      ),
                    ]),
                if (_descCtrl.text.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Divider(color: isDark ? AppColors.divider : AppColors.dividerLightMode),
                  const SizedBox(height: 8),
                  Text(_descCtrl.text,
                      style: TextStyle(
                          color: isDark ? AppColors.textSecondary : AppColors.textSecondaryLightMode,
                          fontSize: 13,
                          height: 1.5),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis),
                ],
                const SizedBox(height: 12),
                Wrap(spacing: 8, runSpacing: 6, children: [
                  _PreviewTag(
                      _selectedCategory ?? 'No category',
                      Icons.category_outlined),
                  if (_isAuction)
                    const _PreviewTag('Auction', Icons.gavel_outlined),
                  if (_acceptsCOD)
                    const _PreviewTag('COD Available', Icons.money_outlined),
                  if (_selectedCategory == 'Jobs Center')
                    _PreviewTag(_jobType, Icons.work_outline),
                  _PreviewTag(_condition, Icons.sell_outlined),
                  _PreviewTag(_sellerType, Icons.person_outline),
                  _PreviewTag(
                      '${_selectedImages.length} photo${_selectedImages.length == 1 ? '' : 's'}',
                      Icons.photo_library_outlined),
                ]),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _ChecklistItem('Category selected', _selectedCategory != null),
          if (_selectedCategory == 'Jobs Center')
            _ChecklistItem('Company name provided', _companyCtrl.text.isNotEmpty),
          _ChecklistItem('Title provided', _titleCtrl.text.isNotEmpty),
          if (_selectedCategory != 'Jobs Center')
            _ChecklistItem('Price set', _priceCtrl.text.isNotEmpty),
          if (_isAuction)
            _ChecklistItem('Auction date set', _auctionEndTime != null),
          _ChecklistItem(
              'Description added', _descCtrl.text.trim().length > 10),
          _ChecklistItem('Photos added (${_selectedImages.length})', _selectedImages.isNotEmpty),
          const SizedBox(height: 80),
        ],
      ),
    );
  }


  String _catEmoji(String cat) {
    const map = {
      'Vehicles': '🚗',
      'Properties': '🏠',
      'Electronics': '⚡',
      'Furniture & Décor': '🪑',
      'WaterCrafts': '⛵',
      'Jewellery': '💎',
      'Lifestyle': '🛍️',
      'Market': '🛒',
      'Outdoor & Leisure': '⛺',
      'Special Numbers': '🔢',
      'Heavy Equipments': '🏗️',
      'Jobs Center': '💼',
      'Super Ads': '⭐',
    };
    return map[cat] ?? '🛍️';
  }

  // ── Bottom nav buttons ────────────────────────────────────────────────────
  Widget _buildNavButtons(Map<String, String> t) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.primaryDark : Colors.white,
        border:
        Border(top: BorderSide(color: (isDark ? AppColors.divider : AppColors.dividerLightMode).withValues(alpha: 0.5), width: 0.5)),
      ),
      child: Row(children: [
        if (_step > 0) ...[
          Expanded(
            child: OutlinedButton(
              onPressed: _prevStep,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: isDark ? AppColors.divider : AppColors.dividerLightMode),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(t['back'] ?? 'Back',
                  style: TextStyle(color: isDark ? Colors.white : AppColors.primary)),
            ),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          flex: 2,
          child: _step == 3 // Last step is Preview
              ? ElevatedButton(
            onPressed: _isSubmitting ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.green,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: _isSubmitting
                ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white))
                : Text(t['submit_ad'] ?? 'Submit Ad',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600)),
          )
              : ElevatedButton(
            onPressed: _nextStep,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.gold,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              _step == 2 ? (t['preview_ad'] ?? 'Preview Ad') : '${t['next'] ?? "Next"} →',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ]),
    );
  }
}

// ── Helper widgets ────────────────────────────────────────────────────────────
class _PreviewTag extends StatelessWidget {
  final String label;
  final IconData icon;
  const _PreviewTag(this.label, this.icon);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: (isDark ? AppColors.divider : Colors.grey).withValues(alpha: 0.2)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 12, color: AppColors.textMuted),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(
                color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7) ?? AppColors.textSecondary, fontSize: 11)),
      ]),
    );
  }
}

class _ChecklistItem extends StatelessWidget {
  final String label;
  final bool done;
  const _ChecklistItem(this.label, this.done);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(children: [
        Icon(
          done ? Icons.check_circle : Icons.radio_button_unchecked,
          size: 18,
          color: done ? AppColors.green : AppColors.textMuted,
        ),
        const SizedBox(width: 10),
        Text(label,
            style: TextStyle(
                color:
                done ? theme.textTheme.bodyLarge?.color ?? Colors.white : AppColors.textMuted,
                fontSize: 14)),
      ]),
    );
  }
}

