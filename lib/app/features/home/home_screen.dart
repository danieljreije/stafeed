import '../feed/data/sample_products.dart';
import 'package:flutter/material.dart';
import '../feed/widgets/product_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
     
      appBar: AppBar(
        title: const Text('Stafeed'),
      ),
      body:
      Padding(
        padding: const EdgeInsets.all(24.0),
        child:Column( 
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 40.0),

            Text('Discover',
            style: Theme.of(context).textTheme.headlineLarge,
            ),
            
            const SizedBox(height: 12.0),

            Text('Swipe through products selected just for you.',
            style: Theme.of(context).textTheme.bodyLarge,
            ),

            const SizedBox(height: 24.0),

            ProductCard(
              product: sampleProducts[0],
            ),
            
          FilledButton(
            onPressed: () {
              // Handle button press
            },
            child: const Text('Start Exploring'),
          ),
          ],
        ),
      ),
    );
  }
}