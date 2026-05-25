import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/auth_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/report_provider.dart';
import '../../repositories/user_repository.dart';
import '../../theme/app_theme.dart';

class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReportProvider>().listenToReports(status: 'pending');
    });
  }

  @override
  Widget build(BuildContext context) {
    final reportProvider = context.watch<ReportProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Reports'),
        backgroundColor: AppColors.primary,
      ),
      body: reportProvider.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
          : reportProvider.reports.isEmpty
              ? const Center(child: Text('No active reports'))
              : ListView.builder(
                  itemCount: reportProvider.reports.length,
                  itemBuilder: (context, index) {
                    final report = reportProvider.reports[index];
                    return _ReportListItem(report: report);
                  },
                ),
    );
  }
}

class _ReportListItem extends StatelessWidget {
  final ReportModel report;

  const _ReportListItem({required this.report});

  @override
  Widget build(BuildContext context) {
    final productProvider = context.read<ProductProvider>();
    final userRepo = UserRepository();

    return FutureBuilder(
      future: report.targetType == ReportType.product
          ? productProvider.fetchProductById(report.targetId)
          : userRepo.getUserById(report.targetId),
      builder: (context, snapshot) {
        String targetName = 'Loading...';
        if (snapshot.hasData) {
          if (report.targetType == ReportType.product) {
            targetName = (snapshot.data as ProductModel).title;
          } else {
            targetName = (snapshot.data as UserModel).name;
          }
        } else if (snapshot.hasError) {
          targetName = 'Error loading name';
        }

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: ListTile(
            title: Text(
              'Report on: $targetName',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Type: ${report.targetType.name.toUpperCase()}'),
                Text('Reason: ${report.reason.name}'),
                if (report.description.isNotEmpty)
                  Text('Desc: ${report.description}',
                      maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _viewReportedContent(context),
          ),
        );
      },
    );
  }

  void _viewReportedContent(BuildContext context) async {
    final reportProvider = context.read<ReportProvider>();
    final productProvider = context.read<ProductProvider>();
    final userRepo = UserRepository(); // Direct repo usage for admin
    final auth = context.read<AuthProvider>();

    showDialog(
      context: context,
      builder: (ctx) => FutureBuilder(
        future: report.targetType == ReportType.product
            ? productProvider.fetchProductById(report.targetId)
            : userRepo.getUserById(report.targetId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return AlertDialog(
              title: const Text('Error'),
              content: const Text('Content no longer exists or error fetching.'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
              ],
            );
          }

          final data = snapshot.data;

          return AlertDialog(
            title: Text('Review Reported ${report.targetType.name}'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (report.targetType == ReportType.product) ...[
                    Text('Title: ${(data as ProductModel).title}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('Description: ${data.description}'),
                    const SizedBox(height: 8),
                    Text('Seller ID: ${data.sellerId}'),
                  ] else ...[
                    Text('Name: ${(data as UserModel).name}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('Email: ${data.email}'),
                    const SizedBox(height: 8),
                    Text('Status: ${data.isSuspended ? "Suspended" : "Active"}'),
                  ],
                  const Divider(),
                  Text('Report Reason: ${report.reason.name}'),
                  const SizedBox(height: 4),
                  Text('Report Desc: ${report.description}'),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              if (report.targetType == ReportType.product)
                ElevatedButton(
                  onPressed: () async {
                    await reportProvider.blockProduct(report.targetId);
                    await reportProvider.resolveReport(report.id, auth.firebaseUser!.uid);
                    if (!ctx.mounted) return;
                    Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text('Block Product'),
                )
              else
                ElevatedButton(
                  onPressed: () async {
                    await reportProvider.suspendUser(report.targetId);
                    await reportProvider.resolveReport(report.id, auth.firebaseUser!.uid);
                    if (!ctx.mounted) return;
                    Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text('Suspend User'),
                ),
              ElevatedButton(
                onPressed: () async {
                  await reportProvider.resolveReport(report.id, auth.firebaseUser!.uid);
                  if (!ctx.mounted) return;
                  Navigator.pop(ctx);
                },
                child: const Text('Mark Resolved'),
              ),
            ],
          );
        },
      ),
    );
  }
}
