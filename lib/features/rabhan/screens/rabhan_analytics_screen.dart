import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moharek_app/features/rabhan/widgets/rabhan_results_view.dart';

class RabhanAnalyticsScreen extends ConsumerWidget {
  const RabhanAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const RabhanResultsView();
  }
}
