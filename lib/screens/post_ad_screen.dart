import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../main.dart';
import '../widgets/common_widgets.dart';

class PostAdScreen extends StatefulWidget {
  const PostAdScreen({super.key});

  @override
  State<PostAdScreen> createState() => _PostAdScreenState();
}

class _PostAdScreenState extends State<PostAdScreen> {
  int _step = 0;
  bool _isSubmitting = false;

  // Step 1 – category
  String? _selectedCategory;

  // Step 2 – details
  final _titleCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController(text: '+974 ');
  String _condition = 'Sale';
  String _sellerType = 'Personal';
  String _location = 'Doha';

  // Step 3 – photos
  int _photoCount = 0;

  final _steps = ['Category', 'Details', 'Photos', 'Preview'];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _priceCtrl.dispose();
    _descCtrl.dispose();
    _phoneCtrl.dispose();
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
      _phoneCtrl.text = '+974 ';
      _condition = 'Sale';
      _sellerType = 'Personal';
      _location = 'Doha';
      _photoCount = 0;
    });
  }

  void _nextStep() {
    if (_step == 0 && _selectedCategory == null) {
      _snack('Please select a category first', AppColors.orange);
      return;
    }
    if (_step == 1) {
      if (_titleCtrl.text.trim().isEmpty) {
        _snack('Please enter a title', AppColors.orange);
        return;
      }
      if (_priceCtrl.text.trim().isEmpty) {
        _snack('Please enter a price (or 0 for free)', AppColors.orange);
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
    setState(() => _isSubmitting = true);
    await Future.delayed(const Duration(milliseconds: 1500));

    if (!mounted) return;

    final newAd = ProductModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleCtrl.text.trim().isEmpty ? 'My Ad' : _titleCtrl.text.trim(),
      price: double.tryParse(_priceCtrl.text.trim()) ?? 0,
      category: _selectedCategory!,
      condition: _condition,
      sellerType: _sellerType,
      sellerPhone: _phoneCtrl.text.trim(),
      location: _location,
      description: _descCtrl.text.trim(),
      postedTime: 'Just now',
      views: 0,
      isFeatured: false,
    );

    AppState().addMyAd(newAd);

    setState(() => _isSubmitting = false);
    _showSuccessDialog();
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.primaryDark,
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
            const Text(
              'Ad Posted Successfully! 🎉',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your ad is now live and visible to buyers.',
              textAlign: TextAlign.center,
              style:
              TextStyle(color: AppColors.textSecondary, fontSize: 13),
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

  // ── Discard confirmation ──────────────────────────────────────────────────
  // PostAdScreen is a tab — "close" means reset, not pop. We only pop when
  // it was pushed as a standalone route (e.g. from the drawer). Detect this
  // by checking whether there is a previous route we can pop back to.
  void _confirmDiscard() {
    // If nothing has been entered, just reset silently.
    if (_step == 0 && _selectedCategory == null) {
      _resetForm();
      return;
    }
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.primaryDark,
        title:
        const Text('Discard Ad?', style: TextStyle(color: Colors.white)),
        content: const Text('Your progress will be lost.',
            style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Keep Editing',
                  style: TextStyle(color: AppColors.gold))),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx); // close dialog
              _resetForm();       // reset to step 0 — never pop the screen
            },
            child: const Text('Discard',
                style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        automaticallyImplyLeading: false,
        title: const AppLogo(),
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: _confirmDiscard,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildStepIndicator(),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              transitionBuilder: (child, anim) =>
                  FadeTransition(opacity: anim, child: child),
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
            ),
          ),
          _buildNavButtons(),
        ],
      ),
    );
  }

  // ── Step indicator ────────────────────────────────────────────────────────
  Widget _buildStepIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
      color: AppColors.primaryDark,
      child: Row(
        children: _steps.asMap().entries.map((e) {
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
                      color: isDone ? AppColors.gold : AppColors.divider,
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
                            : AppColors.card,
                        border: Border.all(
                          color:
                          isActive ? AppColors.gold : AppColors.divider,
                          width: isActive ? 2 : 1,
                        ),
                      ),
                      child: Center(
                        child: isDone
                            ? const Icon(Icons.check,
                            size: 14, color: Colors.white)
                            : Text('${i + 1}',
                            style: TextStyle(
                              color: isActive
                                  ? AppColors.gold
                                  : AppColors.textMuted,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            )),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(e.value,
                        style: TextStyle(
                            color: isActive
                                ? AppColors.gold
                                : AppColors.textMuted,
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
    final cats = [
      {'n': 'Vehicles', 'i': '🚗'},
      {'n': 'Properties', 'i': '🏠'},
      {'n': 'Mobile & Tablets', 'i': '📱'},
      {'n': 'Electronics', 'i': '⚡'},
      {'n': 'Furniture & Décor', 'i': '🪑'},
      {'n': 'Jewellery', 'i': '💎'},
      {'n': 'Clothes', 'i': '👕'},
      {'n': 'Jobs Center', 'i': '💼'},
      {'n': 'Services', 'i': '🔧'},
      {'n': 'WaterCrafts', 'i': '⛵'},
      {'n': 'Computers & Parts', 'i': '💻'},
      {'n': 'Video Games', 'i': '🎮'},
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 20, 16, 12),
          child: Text('Select Category',
              style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600)),
        ),
        Expanded(
          child: GridView.count(
            crossAxisCount: 3,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.9,
            children: cats.map((c) {
              final sel = _selectedCategory == c['n'];
              return GestureDetector(
                onTap: () => setState(() => _selectedCategory = c['n']),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  decoration: BoxDecoration(
                    color: sel ? AppColors.primary : AppColors.card,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: sel
                          ? AppColors.gold
                          : AppColors.divider.withOpacity(0.5),
                      width: sel ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(c['i']!, style: const TextStyle(fontSize: 34)),
                      const SizedBox(height: 8),
                      Text(c['n']!,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: sel
                                ? AppColors.gold
                                : AppColors.textPrimary,
                            fontSize: 11,
                            fontWeight: sel
                                ? FontWeight.w600
                                : FontWeight.normal,
                          )),
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Ad Details',
              style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          _field('Title *', 'e.g. iPhone 14 Pro 256GB', _titleCtrl),
          const SizedBox(height: 12),
          _field('Price (Q.R)', 'e.g. 2000 (enter 0 if free)', _priceCtrl,
              isNumber: true),
          const SizedBox(height: 12),
          _dropdown('Condition *', ['Sale', 'Rent', 'Exchange', 'Free'],
              _condition, (v) => setState(() => _condition = v!)),
          const SizedBox(height: 12),
          _dropdown('Seller Type', ['Personal', 'Business'], _sellerType,
                  (v) => setState(() => _sellerType = v!)),
          const SizedBox(height: 12),
          _field(
              'Description', 'Describe your item in detail…', _descCtrl,
              maxLines: 4),
          const SizedBox(height: 12),
          _dropdown('Location',
              ['Doha', 'Al Rayyan', 'Al Wakra', 'Al Khor', 'Lusail', 'West Bay'],
              _location, (v) => setState(() => _location = v!)),
          const SizedBox(height: 12),
          _field('Phone Number *', '+974 XXXX XXXX', _phoneCtrl,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 13)),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          keyboardType:
          isNumber ? TextInputType.number : TextInputType.text,
          maxLines: maxLines,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: AppColors.textMuted),
            filled: true,
            fillColor: AppColors.card,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 13)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(10)),
          child: DropdownButton<String>(
            value: val,
            isExpanded: true,
            dropdownColor: AppColors.card,
            underline: const SizedBox(),
            style: const TextStyle(color: Colors.white, fontSize: 15),
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
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Text('Add Photos',
                style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600)),
            const Spacer(),
            Text('$_photoCount / 10',
                style: TextStyle(
                    color: _photoCount > 0
                        ? AppColors.gold
                        : AppColors.textMuted,
                    fontSize: 13,
                    fontWeight: FontWeight.w500)),
          ]),
          const SizedBox(height: 6),
          const Text('Add up to 10 photos. Clear photos get more views.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
          const SizedBox(height: 16),
          Expanded(
            child: GridView.count(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              children: [
                if (_photoCount < 10)
                  GestureDetector(
                    onTap: () {
                      setState(() => _photoCount++);
                      _snack('Photo added!', AppColors.green);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(10),
                        border:
                        Border.all(color: AppColors.gold, width: 1.5),
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
                ...List.generate(
                  _photoCount,
                      (i) => Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: AppColors.divider.withOpacity(0.5)),
                        ),
                        child: Center(
                          child: Icon(
                            _selectedCategory != null
                                ? Icons.image
                                : Icons.image_outlined,
                            color: AppColors.textMuted,
                            size: 36,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => setState(() => _photoCount--),
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
                color: AppColors.card,
                borderRadius: BorderRadius.circular(10)),
            child: const Row(children: [
              Icon(Icons.lightbulb_outline,
                  color: AppColors.gold, size: 18),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Tip: Well-lit photos from multiple angles help your ad get up to 3× more views.',
                  style: TextStyle(
                      color: AppColors.textSecondary, fontSize: 12),
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Preview Your Ad',
              style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(14),
              border:
              Border.all(color: AppColors.gold.withOpacity(0.3)),
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
                            color: AppColors.surface,
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
                              style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _priceCtrl.text.isEmpty
                                  ? 'Price not set'
                                  : '${_priceCtrl.text} Q.R',
                              style: const TextStyle(
                                  color: AppColors.gold,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Row(children: [
                              const Icon(Icons.location_on,
                                  size: 12,
                                  color: AppColors.textMuted),
                              const SizedBox(width: 2),
                              Text(_location,
                                  style: const TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 12)),
                            ]),
                          ],
                        ),
                      ),
                    ]),
                if (_descCtrl.text.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Divider(color: AppColors.divider),
                  const SizedBox(height: 8),
                  Text(_descCtrl.text,
                      style: const TextStyle(
                          color: AppColors.textSecondary,
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
                  _PreviewTag(_condition, Icons.sell_outlined),
                  _PreviewTag(_sellerType, Icons.person_outline),
                  _PreviewTag(
                      '$_photoCount photo${_photoCount == 1 ? '' : 's'}',
                      Icons.photo_library_outlined),
                ]),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _ChecklistItem('Category selected', _selectedCategory != null),
          _ChecklistItem('Title provided', _titleCtrl.text.isNotEmpty),
          _ChecklistItem('Price set', _priceCtrl.text.isNotEmpty),
          _ChecklistItem(
              'Description added', _descCtrl.text.trim().length > 10),
          _ChecklistItem('Photos added ($_photoCount)', _photoCount > 0),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  String _catEmoji(String cat) {
    const map = {
      'Vehicles': '🚗',
      'Properties': '🏠',
      'Mobile & Tablets': '📱',
      'Electronics': '⚡',
      'Furniture & Décor': '🪑',
      'Jewellery': '💎',
      'Clothes': '👕',
      'Jobs Center': '💼',
      'Services': '🔧',
      'WaterCrafts': '⛵',
      'Computers & Parts': '💻',
      'Video Games': '🎮',
    };
    return map[cat] ?? '🛍️';
  }

  // ── Bottom nav buttons ────────────────────────────────────────────────────
  Widget _buildNavButtons() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: const BoxDecoration(
        color: AppColors.primaryDark,
        border:
        Border(top: BorderSide(color: AppColors.divider, width: 0.5)),
      ),
      child: Row(children: [
        if (_step > 0) ...[
          Expanded(
            child: OutlinedButton(
              onPressed: _prevStep,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.divider),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Back',
                  style: TextStyle(color: Colors.white)),
            ),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          flex: 2,
          child: _step == _steps.length - 1
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
                : const Text('Submit Ad',
                style: TextStyle(
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
              _step == _steps.length - 2 ? 'Preview Ad' : 'Next →',
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider.withOpacity(0.5)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 12, color: AppColors.textMuted),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 11)),
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
                done ? AppColors.textPrimary : AppColors.textMuted,
                fontSize: 14)),
      ]),
    );
  }
}