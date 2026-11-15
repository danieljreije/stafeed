import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../feed/models/feed_filter.dart';
import '../feed/models/money.dart';
import '../feed/models/supported_filters.dart';
import '../feed/providers/data_gateway_provider.dart';
import '../shopper/providers/shopper_config_provider.dart';
import 'models/shopping_session.dart';
import 'providers/shopping_sessions_provider.dart';

/// How long typing must pause before the match count is looked up again.
const sessionPreviewDebounce = Duration(milliseconds: 400);

/// Opens the form for a new Shopping Session, or for changing [session]'s
/// filters. Returns true when it was saved.
Future<bool> openSessionEditor(
  BuildContext context, {
  ShoppingSession? session,
}) async {
  final saved = await Navigator.of(context).push<bool>(
    MaterialPageRoute(builder: (_) => SessionEditorScreen(session: session)),
  );
  return saved ?? false;
}

/// The New session form: a goal, and only the filters the source supports
/// (budget, Brand, category). While the Shopper types it says how many
/// Feed Items match, looked up once typing pauses.
class SessionEditorScreen extends ConsumerStatefulWidget {
  const SessionEditorScreen({super.key, this.session});

  /// The session to change, or null for a new one.
  final ShoppingSession? session;

  @override
  ConsumerState<SessionEditorScreen> createState() =>
      _SessionEditorScreenState();
}

class _SessionEditorScreenState extends ConsumerState<SessionEditorScreen> {
  late final _goal = TextEditingController(text: widget.session?.goal ?? '');
  late final _name = TextEditingController(text: widget.session?.name ?? '');
  late final _budget = TextEditingController(
    text: switch (widget.session?.maxPrice) {
      final price? => (price.minorUnits ~/ 100).toString(),
      null => '',
    },
  );
  late String? _brand = widget.session?.brand;
  late String? _category = widget.session?.category;

  Timer? _debounce;
  int _lookup = 0;
  String? _preview;

  bool get _isNew => widget.session == null;

  @override
  void initState() {
    super.initState();
    _goal.addListener(_scheduleLookup);
    _budget.addListener(_scheduleLookup);
    _scheduleLookup();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _goal.dispose();
    _name.dispose();
    _budget.dispose();
    super.dispose();
  }

  String get _currency =>
      widget.session?.maxPrice?.currencyCode ??
      ref.read(shopperConfigProvider).value?.currencyCode ??
      'USD';

  Money? get _maxPrice {
    final whole = int.tryParse(_budget.text.trim());
    if (whole == null || whole <= 0) return null;
    return Money(whole * 100, _currency);
  }

  FeedFilter get _filter => FeedFilter(
    sessionId: widget.session?.id ?? 'new-session-preview',
    query: _goal.text.trim(),
    category: _category,
    brand: _brand,
    maxPrice: _maxPrice,
  );

  void _scheduleLookup() {
    _debounce?.cancel();
    _debounce = Timer(sessionPreviewDebounce, _lookUp);
  }

  Future<void> _lookUp() async {
    final lookup = ++_lookup;
    final gateway = ref.read(dataGatewayProvider);
    String preview;
    try {
      final page = await gateway.getFeedPage(filter: _filter);
      final count = page.items.length;
      preview = count == 0
          ? 'Nothing matches yet'
          : '$count${page.nextCursor != null ? '+' : ''} '
                '${count == 1 && page.nextCursor == null ? 'match' : 'matches'}';
    } on Object {
      preview = '';
    }
    // An older lookup that answers late never overwrites a newer one.
    if (!mounted || lookup != _lookup) return;
    setState(() => _preview = preview);
  }

  Future<void> _save() async {
    final sessions = ref.read(shoppingSessionsProvider.notifier);
    final session = widget.session;
    if (session == null) {
      await sessions.create(
        goal: _goal.text,
        name: _name.text,
        category: _category,
        brand: _brand,
        maxPrice: _maxPrice,
      );
    } else {
      if (_name.text.trim().isNotEmpty && _name.text.trim() != session.name) {
        await sessions.rename(session.id, _name.text);
      }
      await sessions.changeFilters(
        session.id,
        goal: _goal.text,
        category: _category,
        brand: _brand,
        maxPrice: _maxPrice,
      );
    }
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final filters = ref.watch(supportedFiltersProvider).asData?.value;
    final categories = filters?.categories ?? const <ProductCategory>[];
    final brands = filters?.brands ?? const <String>[];

    return Scaffold(
      appBar: AppBar(title: Text(_isNew ? 'New session' : 'Edit session')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _goal,
            autofocus: _isNew,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'What are you shopping for?',
              hintText: 'e.g. white sneakers',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _name,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Name (optional)',
              border: OutlineInputBorder(),
            ),
          ),
          if (filters?.supportsMaxPrice ?? false) ...[
            const SizedBox(height: 16),
            TextField(
              controller: _budget,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: 'Budget (optional)',
                prefixText: '$_currency ',
                border: const OutlineInputBorder(),
              ),
            ),
          ],
          if (brands.isNotEmpty) ...[
            const SizedBox(height: 16),
            DropdownButtonFormField<String?>(
              initialValue: _brand,
              decoration: const InputDecoration(
                labelText: 'Brand',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('Any Brand')),
                for (final brand in brands)
                  DropdownMenuItem(value: brand, child: Text(brand)),
              ],
              onChanged: (value) {
                setState(() => _brand = value);
                _scheduleLookup();
              },
            ),
          ],
          if (categories.isNotEmpty) ...[
            const SizedBox(height: 16),
            DropdownButtonFormField<String?>(
              initialValue: _category,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('Any category'),
                ),
                for (final category in categories)
                  DropdownMenuItem(
                    value: category.id,
                    child: Text(category.label),
                  ),
              ],
              onChanged: (value) {
                setState(() => _category = value);
                _scheduleLookup();
              },
            ),
          ],
          const SizedBox(height: 16),
          Text(
            _preview ?? '',
            key: const Key('session-preview'),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _save,
            child: Text(_isNew ? 'Start session' : 'Save'),
          ),
        ],
      ),
    );
  }
}
