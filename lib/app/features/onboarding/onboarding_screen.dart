import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app_name.dart';
import '../feed/models/supported_filters.dart';
import '../feed/providers/data_gateway_provider.dart';
import '../shopper/models/destination_country.dart';
import '../shopper/models/shopper_config.dart';
import '../shopper/providers/shopper_config_provider.dart';

/// The copy on the onboarding screens. Tone: see `docs/TONE_OF_VOICE.md`.
abstract final class OnboardingCopy {
  static const welcome =
      "Welcome to $appName. It's all ads. We're not hiding it.";
  static const start = "Let's go";

  static const countryQuestion = 'Where should things be delivered?';
  static const countryNote = "You'll only see what ships there.";
  static const currencyQuestion = 'Which currency do you use?';
  static const next = 'Continue';

  static const interestsQuestion = 'What are you into?';
  static const interestsNote =
      'Pick a few, or skip. The ads will find you either way.';
  static const skip = 'Skip';
  static const finish = 'Show me the ads';
}

enum _Step { welcome, delivery, interests }

/// First launch only: a welcome, then Destination Country and currency,
/// then interests (which can be skipped). Finishing saves the Shopper's
/// config, and the app opens the Feed.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  _Step _step = _Step.welcome;
  DestinationCountry? _country;
  String? _currencyCode;
  final Set<String> _interests = {};

  void _chooseCountry(DestinationCountry country) {
    setState(() {
      _country = country;
      // The country's usual currency; the Shopper can still pick another.
      _currencyCode = country.defaultCurrency;
    });
  }

  void _finish({required bool withInterests}) {
    ref
        .read(shopperConfigProvider.notifier)
        .save(
          ShopperConfig(
            destinationCountry: _country!,
            currencyCode: _currencyCode!,
            interests: withInterests ? {..._interests} : const {},
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: switch (_step) {
            _Step.welcome => _welcome(context),
            _Step.delivery => _delivery(context),
            _Step.interests => _interestsStep(context),
          },
        ),
      ),
    );
  }

  Widget _welcome(BuildContext context) {
    final theme = Theme.of(context);

    return _StepLayout(
      content: [
        const SizedBox(height: 48),
        Text(appName, style: theme.textTheme.displaySmall),
        const SizedBox(height: 16),
        Text(OnboardingCopy.welcome, style: theme.textTheme.headlineSmall),
      ],
      actions: [
        FilledButton(
          onPressed: () => setState(() => _step = _Step.delivery),
          child: const Text(OnboardingCopy.start),
        ),
      ],
    );
  }

  Widget _delivery(BuildContext context) {
    final theme = Theme.of(context);

    return _StepLayout(
      content: [
        Text(
          OnboardingCopy.countryQuestion,
          style: theme.textTheme.headlineSmall,
        ),
        const SizedBox(height: 4),
        Text(OnboardingCopy.countryNote, style: theme.textTheme.bodyMedium),
        const SizedBox(height: 12),
        for (final country in DestinationCountry.values)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              country == _country
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
            ),
            title: Text(country.label),
            selected: country == _country,
            onTap: () => _chooseCountry(country),
          ),
        if (_country != null) ...[
          const SizedBox(height: 12),
          Text(
            OnboardingCopy.currencyQuestion,
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final code in shopperCurrencies)
                ChoiceChip(
                  label: Text(code),
                  selected: code == _currencyCode,
                  onSelected: (_) => setState(() => _currencyCode = code),
                ),
            ],
          ),
        ],
      ],
      actions: [
        FilledButton(
          onPressed: _country == null
              ? null
              : () => setState(() => _step = _Step.interests),
          child: const Text(OnboardingCopy.next),
        ),
      ],
    );
  }

  Widget _interestsStep(BuildContext context) {
    final theme = Theme.of(context);
    final categories =
        ref.watch(supportedFiltersProvider).asData?.value.categories ??
        const <ProductCategory>[];

    return _StepLayout(
      content: [
        Text(
          OnboardingCopy.interestsQuestion,
          style: theme.textTheme.headlineSmall,
        ),
        const SizedBox(height: 4),
        Text(OnboardingCopy.interestsNote, style: theme.textTheme.bodyMedium),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            for (final category in categories)
              FilterChip(
                label: Text(category.label),
                selected: _interests.contains(category.id),
                onSelected: (selected) => setState(() {
                  if (selected) {
                    _interests.add(category.id);
                  } else {
                    _interests.remove(category.id);
                  }
                }),
              ),
          ],
        ),
      ],
      actions: [
        TextButton(
          onPressed: () => _finish(withInterests: false),
          child: const Text(OnboardingCopy.skip),
        ),
        const SizedBox(width: 12),
        FilledButton(
          onPressed: () => _finish(withInterests: true),
          child: const Text(OnboardingCopy.finish),
        ),
      ],
    );
  }
}

/// One onboarding step: its content scrolls when the screen is short, and
/// its buttons stay put at the bottom right.
class _StepLayout extends StatelessWidget {
  const _StepLayout({required this.content, required this.actions});

  final List<Widget> content;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: content,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(mainAxisAlignment: MainAxisAlignment.end, children: actions),
      ],
    );
  }
}
