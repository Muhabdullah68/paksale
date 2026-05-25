import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../providers/admin_provider.dart';
import '../../theme/app_theme.dart';

class MembersManagementScreen extends StatefulWidget {
  const MembersManagementScreen({super.key});

  @override
  State<MembersManagementScreen> createState() => _MembersManagementScreenState();
}

class _MembersManagementScreenState extends State<MembersManagementScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().fetchAllUsers();
    });
  }

  @override
  Widget build(BuildContext context) {
    final adminProvider = context.watch<AdminProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Registered Members'),
        backgroundColor: AppColors.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add, color: Colors.white),
            onPressed: () => _showAddMemberDialog(context),
          ),
        ],
      ),
      body: adminProvider.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
          : adminProvider.allUsers.isEmpty
              ? const Center(child: Text('No members found'))
              : ListView.builder(
                  itemCount: adminProvider.allUsers.length,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemBuilder: (context, index) {
                    final user = adminProvider.allUsers[index];
                    return _MemberListItem(user: user);
                  },
                ),
    );
  }

  void _showAddMemberDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add New Member'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Full Name')),
            TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email')),
            TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Phone')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              // Note: This would typically call a Firebase Auth creation method via Admin SDK or similar.
              // For now, we'll just show a snackbar as a placeholder for the logic.
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Member creation requires backend Admin SDK access.')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.gold),
            child: const Text('Add Member'),
          ),
        ],
      ),
    );
  }
}

class _MemberListItem extends StatelessWidget {
  final UserModel user;

  const _MemberListItem({required this.user});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.gold.withValues(alpha: 0.2),
          child: Text(user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
              style: const TextStyle(color: AppColors.gold)),
        ),
        title: Text(user.name.isEmpty ? 'Unknown User' : user.name,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user.email),
            Text('Status: ${user.isSuspended ? "Suspended" : "Active"}',
                style: TextStyle(color: user.isSuspended ? Colors.red : Colors.green, fontSize: 12)),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => AdminUserDetailScreen(user: user)),
        ),
      ),
    );
  }
}

class AdminUserDetailScreen extends StatelessWidget {
  final UserModel user;
  const AdminUserDetailScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final adminProvider = context.watch<AdminProvider>();
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(user.name),
        backgroundColor: AppColors.primary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('User ID', user.id),
            _buildDetailRow('Full Name', user.name),
            _buildDetailRow('Email', user.email),
            _buildDetailRow('Phone', user.phone),
            _buildDetailRow('Verified', user.isVerified ? 'Yes' : 'No'),
            _buildDetailRow('Suspended', user.isSuspended ? 'Yes' : 'No'),
            _buildDetailRow('Admin', user.isAdmin ? 'Yes' : 'No'),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _toggleSuspension(context, adminProvider),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: user.isSuspended ? Colors.green : Colors.orange,
                    ),
                    child: Text(user.isSuspended ? 'Unsuspend' : 'Suspend User'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _deleteUser(context, adminProvider),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    child: const Text('Remove Member'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _toggleSuspension(BuildContext context, AdminProvider provider) async {
    try {
      await provider.toggleUserSuspension(user.id, !user.isSuspended);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(user.isSuspended ? 'User unsuspended' : 'User suspended')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _deleteUser(BuildContext context, AdminProvider provider) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete User?'),
        content: const Text('This will permanently remove the user and all their data. This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await provider.deleteUser(user.id);
        if (context.mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User deleted successfully')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }
}
