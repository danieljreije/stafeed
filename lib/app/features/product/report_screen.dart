import 'package:flutter/material.dart';

import '../feed/models/product_actions.dart';

/// What the Shopper picked on the Report screen.
@immutable
class ReportChoice {
  const ReportChoice({required this.reason, this.note = ''});

  final ReportReason reason;
  final String note;
}

/// Asks why the Shopper is reporting a Product, with room for a note.
/// Closes with a [ReportChoice] when sent, or nothing when closed.
class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key, required this.productTitle});

  final String productTitle;

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final _note = TextEditingController();
  ReportReason? _reason;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reason = _reason;

    return Scaffold(
      appBar: AppBar(title: const Text('Report')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              "What's wrong with ${widget.productTitle}?",
              style: theme.textTheme.titleMedium,
            ),
          ),
          RadioGroup<ReportReason>(
            groupValue: reason,
            onChanged: (picked) => setState(() => _reason = picked),
            child: Column(
              children: [
                for (final option in ReportReason.values)
                  RadioListTile<ReportReason>(
                    value: option,
                    title: Text(option.label),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _note,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Anything to add? (optional)',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: FilledButton(
              onPressed: reason == null
                  ? null
                  : () => Navigator.of(context).pop(
                      ReportChoice(reason: reason, note: _note.text.trim()),
                    ),
              child: const Text('Send report'),
            ),
          ),
        ],
      ),
    );
  }
}
