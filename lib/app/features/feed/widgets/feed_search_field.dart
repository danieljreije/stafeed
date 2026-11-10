import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/feed_filter.dart';
import '../providers/feed_filter_provider.dart';

class FeedSearchField extends ConsumerStatefulWidget {
  const FeedSearchField({super.key});

  @override
  ConsumerState<FeedSearchField> createState() =>
      _FeedSearchFieldState();
}

class _FeedSearchFieldState extends ConsumerState<FeedSearchField> {
  late final TextEditingController _controller;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();

    _controller = TextEditingController(
      text: ref.read(feedFilterProvider).query,
    );
  }

  void _onSearchChanged(String value) {
    // Cancel the previous scheduled search.
    _debounce?.cancel();

    // Schedule a new search.
    _debounce = Timer(
      const Duration(milliseconds: 500),
      () {
        if (!mounted) return;

        ref.read(feedFilterProvider.notifier).setSearch(value);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Keep the text field synchronized when a category
    // selection or another action changes the filter.
    ref.listen<FeedFilter>(feedFilterProvider, (previous, next) {
      if (_controller.text != next.query) {
        _debounce?.cancel();

        _controller.value = TextEditingValue(
          text: next.query,
          selection: TextSelection.collapsed(
            offset: next.query.length,
          ),
        );
      }
    });

    return TextField(
      controller: _controller,
      textInputAction: TextInputAction.search,
      onChanged: _onSearchChanged,

      onSubmitted: (value) {
        _debounce?.cancel();

        ref.read(feedFilterProvider.notifier).setSearch(value);
      },

      decoration: InputDecoration(
        hintText: 'Search products...',
        prefixIcon: const Icon(Icons.search),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();

    super.dispose();
  }
}
