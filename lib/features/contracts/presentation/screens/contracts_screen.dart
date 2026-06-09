import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moharek_app/core/theme/app_theme.dart';
import 'package:moharek_app/shared/services/data_providers.dart';
import 'package:moharek_app/shared/models/contract.dart';
import 'package:moharek_app/shared/widgets/shimmer_placeholders.dart';
import 'package:moharek_app/shared/services/haptic_service.dart';
import 'package:moharek_app/features/contracts/presentation/screens/contract_sign_screen.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:moharek_app/core/utils/error_handler.dart';

class ContractsScreen extends ConsumerWidget {
  const ContractsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contractsAsync = ref.watch(contractsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('العقود والاتفاقيات')),
      body: contractsAsync.when(
        loading: () => const ShimmerList(itemCount: 3, itemHeight: 100),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text(
              ErrorHandler.getFriendlyMessage(err, context),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        data: (contracts) {
          if (contracts.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.description_outlined, color: Colors.grey, size: 64),
                    SizedBox(height: 16),
                    Text('لا توجد عقود حالياً', style: TextStyle(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Text('سيقوم مدير حسابك برفع العقود والاتفاقيات هنا لتتمكن من مراجعتها وتوقيعها.', style: TextStyle(color: Colors.white38, fontSize: 13), textAlign: TextAlign.center),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            color: AppTheme.primaryGreen,
            onRefresh: () async {
              ref.invalidate(contractsProvider);
              HapticService.light();
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: contracts.length,
              itemBuilder: (context, index) {
                return _buildContractCard(context, ref, contracts[index]);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildContractCard(BuildContext context, WidgetRef ref, Contract contract) {
    final isPending = contract.status == 'pending';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPending ? AppTheme.primaryGreen.withValues(alpha: 0.4) : Colors.white10,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.description_outlined, color: AppTheme.primaryGreen, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        contract.title,
                        style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'تاريخ الرفع: ${contract.createdAt.day}/${contract.createdAt.month}/${contract.createdAt.year}',
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                _buildStatusBadge(contract.status),
              ],
            ),
          ),
          if (contract.fileUrl != null) ...[
            const Divider(color: Colors.white10, height: 1),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        HapticService.light();
                        _openContract(context, contract);
                      },
                      icon: const Icon(Icons.visibility_outlined, size: 16),
                      label: const Text('عرض العقد'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white70,
                        side: const BorderSide(color: Colors.white24),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                  if (isPending) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          HapticService.light();
                          _signContract(context, ref, contract);
                        },
                        icon: const Icon(Icons.draw_outlined, size: 16),
                        label: const Text('توقيع العقد'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryGreen,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String label;
    switch (status) {
      case 'signed':
        color = AppTheme.primaryGreen;
        label = 'موقّع';
        break;
      case 'expired':
        color = Colors.redAccent;
        label = 'منتهي';
        break;
      default:
        color = AppTheme.primaryBlue;
        label = 'قيد الانتظار';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }

  void _openContract(BuildContext context, Contract contract) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _ContractViewerScreen(contract: contract),
      ),
    );
  }

  Future<void> _signContract(BuildContext context, WidgetRef ref, Contract contract) async {
    final signed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => ContractSignScreen(contract: contract),
      ),
    );

    if (signed == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم توقيع العقد بنجاح! ✅'),
          backgroundColor: AppTheme.primaryGreen,
        ),
      );
      ref.invalidate(contractsProvider);
    }
  }
}

class _ContractViewerScreen extends StatelessWidget {
  final Contract contract;

  const _ContractViewerScreen({required this.contract});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(contract.title)),
      body: contract.fileUrl != null
          ? SfPdfViewer.network(contract.fileUrl!)
          : const Center(child: Text('ملف العقد غير متوفر', style: TextStyle(color: Colors.grey))),
    );
  }
}
