import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import '../../services/listing_service.dart';
import '../../theme/app_theme.dart';

/// Halaman admin: kelola item yang DIJUAL (tabel listings).
/// Admin membuat listing dari item katalog (weapons/foods) lalu atur harga/stok.
class ManageListingsPage extends StatefulWidget {
  const ManageListingsPage({super.key});

  @override
  State<ManageListingsPage> createState() => _ManageListingsPageState();
}

class _ManageListingsPageState extends State<ManageListingsPage> {
  List<Map<String, dynamic>> _listings = [];
  bool _loading = true;
  String? _error;

  // Mode tampilan: 'all' = semua, 'weapon' = senjata saja, 'food' = makanan saja.
  String _viewMode = 'all';

  /// Listing yang tampil sesuai view mode terpilih.
  List<Map<String, dynamic>> get _visibleListings {
    if (_viewMode == 'all') return _listings;
    return _listings.where((l) => l['item_type'] == _viewMode).toList();
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await ListingService.list();
      if (!mounted) return;
      setState(() {
        _listings = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = "Failed to load listings.";
        _loading = false;
      });
    }
  }

  void _showSnack(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  int _asInt(dynamic v) => v is int ? v : int.tryParse('${v ?? 0}') ?? 0;

  /// Warna indikator stok relatif ke stok awal:
  /// - hijau saat stok masih > 50% stok awal
  /// - kuning saat sudah ≤ 50% (ambang 50% dibulatkan ke ATAS)
  /// - merah saat sudah ≤ 20% (ambang 20% dibulatkan ke BAWAH)
  Color _stockColor(int stock, int initial) {
    if (initial <= 0) return Colors.red.shade600;
    final yellowAt = (initial * 0.5).ceil(); // 50% bulat ke atas
    final redAt = (initial * 0.2).floor(); // 20% bulat ke bawah
    if (stock <= redAt) return Colors.red.shade600;
    if (stock <= yellowAt) return const Color(0xFFE0A100); // kuning/amber
    return Colors.green.shade600;
  }

  /// Buka pemilih katalog → form → create. Reload bila berhasil.
  Future<void> _createListing() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const CatalogPickerPage()),
    );
    if (created == true) {
      _showSnack("Listing added.", isError: false);
      _load();
    }
  }

  Future<void> _editListing(Map<String, dynamic> listing) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => ListingFormPage(listing: listing)),
    );
    if (saved == true) {
      _showSnack("Listing updated.", isError: false);
      _load();
    }
  }

  Future<void> _deleteListing(Map<String, dynamic> listing) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Remove from Sale"),
        content: Text("Stop selling \"${listing['name']}\"?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (yes != true) return;

    final result = await ListingService.remove(listing['id'] as int);
    if (!mounted) return;
    if (result.ok) {
      _showSnack("Listing removed.", isError: false);
      _load();
    } else {
      _showSnack(result.error ?? "Failed to delete.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text("Manage Sales")),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createListing,
        icon: const Icon(Icons.add),
        label: const Text("Sell Item"),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _load, child: const Text("Try again")),
          ],
        ),
      );
    }
    if (_listings.isEmpty) {
      return const Center(
        child: Text("No items for sale yet. Tap \"Sell Item\"."),
      );
    }

    // Ada listing → tampilkan filter view mode + daftar terfilter.
    return Column(
      children: [
        _buildViewModeFilter(),
        Expanded(child: _buildList()),
      ],
    );
  }

  /// Filter view mode: All / Weapons / Food.
  Widget _buildViewModeFilter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: SizedBox(
        width: double.infinity,
        child: SegmentedButton<String>(
          showSelectedIcon: false,
          segments: const [
            ButtonSegment(value: 'all', label: Text("All")),
            ButtonSegment(value: 'weapon', label: Text("Weapons")),
            ButtonSegment(value: 'food', label: Text("Food")),
            ButtonSegment(value: 'artifact', label: Text("Artifacts")),
          ],
          selected: {_viewMode},
          onSelectionChanged: (s) => setState(() => _viewMode = s.first),
        ),
      ),
    );
  }

  Widget _buildList() {
    final listings = _visibleListings;
    if (listings.isEmpty) {
      // Total tidak kosong, tapi mode terpilih tidak punya item.
      final label = _viewMode == 'weapon' ? "weapons" : (_viewMode == 'food' ? "food" : "artifacts");
      return Center(child: Text("No $label listed for sale."));
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: listings.length,
        itemBuilder: (context, i) {
          final l = listings[i];
          final image = (l['image'] ?? '').toString();
          final stock = _asInt(l['stock']);
          final initial = _asInt(l['initial_stock']);
          final stockColor = _stockColor(stock, initial);
          return Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: image.isNotEmpty
                    ? Image.network(
                        image,
                        width: 48,
                        height: 48,
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => const Icon(
                          Icons.broken_image,
                          size: 40,
                          color: Colors.grey,
                        ),
                      )
                    : const Icon(Icons.image_not_supported,
                        size: 40, color: Colors.grey),
              ),
              isThreeLine: true,
              // Baris 1: nama item.
              title: Text(
                (l['name'] ?? 'Unknown').toString(),
                style: const TextStyle(fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  // Baris 2: stok (warna: hijau → kuning di 50% → merah di 20%).
                  Row(
                    children: [
                      const Text(
                        "Stock: ",
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      Text(
                        "$stock / $initial",
                        style: TextStyle(
                          color: stockColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  // Baris 3: harga.
                  Text(
                    "Price: \$${l['price'] ?? 0}",
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: AppColors.secondary),
                    onPressed: () => _editListing(l),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteListing(l),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Pemilih item katalog (weapons + foods) untuk dijadikan listing baru.
class CatalogPickerPage extends StatefulWidget {
  const CatalogPickerPage({super.key});

  @override
  State<CatalogPickerPage> createState() => _CatalogPickerPageState();
}

class _CatalogPickerPageState extends State<CatalogPickerPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  List<Map<String, dynamic>> _all = [];
  bool _loading = true;
  String? _error;
  String _query = "";
  String? _category; // null = semua kategori
  int _tabIndex = 0; // 0 = senjata, 1 = makanan

  String get _currentType => _tabIndex == 0 ? 'weapon' : (_tabIndex == 1 ? 'food' : 'artifact');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await ListingService.catalog();
      if (!mounted) return;
      setState(() {
        _all = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = "Failed to load catalog.";
        _loading = false;
      });
    }
  }

  /// Kategori unik untuk item di tab yang aktif (senjata / makanan).
  List<String> get _categories {
    final set = <String>{};
    for (final e in _all) {
      if (e['item_type'] != _currentType) continue;
      final c = (e['category'] ?? '').toString().trim();
      if (c.isNotEmpty) set.add(c);
    }
    final list = set.toList()..sort();
    return list;
  }

  /// Filter gabungan: tab (item_type) + kategori + pencarian nama.
  List<Map<String, dynamic>> get _filtered {
    final q = _query.toLowerCase();
    return _all.where((e) {
      if (e['item_type'] != _currentType) return false;
      if (_category != null &&
          (e['category'] ?? '').toString() != _category) {
        return false;
      }
      if (q.isNotEmpty &&
          !(e['name'] ?? '').toString().toLowerCase().contains(q)) {
        return false;
      }
      return true;
    }).toList();
  }

  Future<void> _pick(Map<String, dynamic> item) async {
    // Buka form create dengan item terpilih. Bila tersimpan, bubble up true.
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => ListingFormPage(catalogItem: item)),
    );
    if (saved == true && mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Pick Item"),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          // Ganti tab → reset filter kategori (kategori beda tiap tipe).
          onTap: (i) => setState(() {
            _tabIndex = i;
            _category = null;
          }),
          tabs: [
            Tab(text: "Weapons", icon: Icon(MdiIcons.sword)),
            const Tab(text: "Food", icon: Icon(Icons.restaurant)),
            const Tab(text: "Artifacts", icon: Icon(Icons.category)),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: "Search items...",
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          _buildCategoryFilter(),
          Expanded(child: _buildList()),
        ],
      ),
    );
  }

  /// Filter kategori berbentuk dropdown dengan logo filter.
  Widget _buildCategoryFilter() {
    if (_loading || _error != null) return const SizedBox.shrink();
    final cats = _categories;
    if (cats.isEmpty) return const SizedBox.shrink();
    final selectedLabel = _category ?? "All categories";

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return PopupMenuButton<String>(
            tooltip: "Filter category",
            initialValue: _category ?? "",
            position: PopupMenuPosition.under,
            constraints: BoxConstraints.tightFor(width: constraints.maxWidth),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(16),
              ),
            ),
            onSelected: (value) {
              setState(() => _category = value.isEmpty ? null : value);
            },
            itemBuilder: (context) => [
              const PopupMenuItem<String>(
                value: "",
                child: Text("All categories"),
              ),
              ...cats.map(
                (c) => PopupMenuItem<String>(
                  value: c,
                  child: Text(c),
                ),
              ),
            ],
            child: Container(
              height: 48,
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: 0.10),
                // Kapsul penuh (pill) sekaligus area tombol penuh.
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: AppColors.secondary.withValues(alpha: 0.5),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.filter_alt,
                    size: 20,
                    color: AppColors.secondary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      selectedLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppColors.text),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Icon(
                    Icons.keyboard_arrow_down,
                    color: AppColors.secondary,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildList() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _load, child: const Text("Try again")),
          ],
        ),
      );
    }

    final items = _filtered;
    if (items.isEmpty) {
      return const Center(child: Text("No matching items."));
    }

    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, i) {
        final item = items[i];
        final image = (item['image'] ?? '').toString();
        return ListTile(
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: image.isNotEmpty
                ? Image.network(
                    image,
                    width: 40,
                    height: 40,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) =>
                        const Icon(Icons.broken_image, color: Colors.grey),
                  )
                : const Icon(Icons.image_not_supported, color: Colors.grey),
          ),
          title: Text(
            (item['name'] ?? 'Unknown').toString(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            (item['category'] ?? '-').toString(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _pick(item),
        );
      },
    );
  }
}

/// Form listing. Mode create bila [catalogItem] diberikan; mode edit bila
/// [listing] diberikan. Field yang bisa diatur: price & stock.
class ListingFormPage extends StatefulWidget {
  final Map<String, dynamic>? catalogItem; // create
  final Map<String, dynamic>? listing; // edit

  const ListingFormPage({super.key, this.catalogItem, this.listing});

  @override
  State<ListingFormPage> createState() => _ListingFormPageState();
}

class _ListingFormPageState extends State<ListingFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _priceC;
  late final TextEditingController _stockC;
  bool _saving = false;

  bool get _isEdit => widget.listing != null;

  Map<String, dynamic> get _source => widget.listing ?? widget.catalogItem!;

  @override
  void initState() {
    super.initState();
    _priceC = TextEditingController(
      text: (widget.listing?['price'] ?? "").toString(),
    );
    _stockC = TextEditingController(
      text: (widget.listing?['stock'] ?? "").toString(),
    );
  }

  @override
  void dispose() {
    _priceC.dispose();
    _stockC.dispose();
    super.dispose();
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final price = int.parse(_priceC.text.trim());
    final stock = int.parse(_stockC.text.trim());

    final ({bool ok, String? error}) result;
    if (_isEdit) {
      result = await ListingService.update(
        widget.listing!['id'] as int,
        {"price": price, "stock": stock},
      );
    } else {
      result = await ListingService.create({
        "item_type": widget.catalogItem!['item_type'],
        "item_id": widget.catalogItem!['item_id'],
        "price": price,
        "stock": stock,
      });
    }

    if (!mounted) return;
    setState(() => _saving = false);

    if (result.ok) {
      Navigator.pop(context, true);
    } else {
      _showSnack(result.error ?? "Failed to save.");
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = (_source['name'] ?? 'Item').toString();
    final image = (_source['image'] ?? '').toString();
    final category = (_source['category'] ?? '-').toString();

    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? "Edit Sale" : "Sell Item")),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Info item (read-only — item tidak bisa diganti di sini).
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: image.isNotEmpty
                      ? Image.network(
                          image,
                          width: 48,
                          height: 48,
                          fit: BoxFit.contain,
                          errorBuilder: (_, _, _) => const Icon(
                            Icons.broken_image,
                            size: 40,
                            color: Colors.grey,
                          ),
                        )
                      : const Icon(Icons.image_not_supported,
                          size: 40, color: Colors.grey),
                ),
                title: Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(category),
              ),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _priceC,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Price",
                prefixText: "\$ ",
                border: OutlineInputBorder(),
              ),
              validator: (v) {
                final n = int.tryParse((v ?? "").trim());
                if (n == null) return "Invalid number";
                if (n <= 0) return "Price > 0";
                return null;
              },
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _stockC,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Stock",
                border: OutlineInputBorder(),
              ),
              validator: (v) {
                final n = int.tryParse((v ?? "").trim());
                if (n == null) return "Invalid number";
                if (n < 0) return "Stock ≥ 0";
                return null;
              },
            ),
            const SizedBox(height: 20),

            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(_isEdit ? "Save" : "Sell Now"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
