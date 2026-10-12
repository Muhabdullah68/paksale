import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/utils/input_rules.dart';
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
    final nicCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add New Member'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameCtrl, maxLength: 60, inputFormatters: InputRules.name(max: 60), decoration: const InputDecoration(counterText: '', labelText: 'Full Name')),
                TextField(
                  controller: amountCtrl, 
                  decoration: const InputDecoration(counterText: '', labelText: 'Initial Payment Amount (Rs)'),
                  keyboardType: TextInputType.number,
                  maxLength: 10,
                  inputFormatters: InputRules.digits(10),
                  onChanged: (val) => setState(() {}),
                ),
                TextField(
                  controller: emailCtrl, 
                  keyboardType: TextInputType.emailAddress,
                  maxLength: 100,
                  inputFormatters: InputRules.email(max: 100),
                  decoration: InputDecoration(
                    counterText: '',
                    labelText: 'Email',
                    hintText: double.tryParse(amountCtrl.text) != null && double.parse(amountCtrl.text) > 20000 
                        ? 'Required for > 20k' : 'Optional',
                  ),
                ),
                TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  maxLength: 15,
                  inputFormatters: InputRules.phone(max: 15, maxDigits: 11),
                  decoration: const InputDecoration(counterText: '', labelText: 'Phone')),
                TextField(
                  controller: nicCtrl, 
                  keyboardType: TextInputType.number,
                  maxLength: 13,
                  inputFormatters: InputRules.digits(13),
                  decoration: InputDecoration(
                    counterText: '',
                    labelText: 'NIC Number',
                    hintText: double.tryParse(amountCtrl.text) != null && double.parse(amountCtrl.text) > 20000 
                        ? 'Required for > 20k' : 'Optional',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (nameCtrl.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Name is required')),
                  );
                  return;
                }
                if (phoneCtrl.text.trim().isNotEmpty &&
                    InputRules.validatePhone(phoneCtrl.text) != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Phone number must be 10–11 digits')),
                  );
                  return;
                }
                if (emailCtrl.text.trim().isNotEmpty &&
                    !InputRules.isValidEmail(emailCtrl.text)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Enter a valid email')),
                  );
                  return;
                }
                final amount = double.tryParse(amountCtrl.text) ?? 0;
                if (amount > 20000) {
                  if (emailCtrl.text.isEmpty || nicCtrl.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Email and NIC are mandatory for payments > 20,000 Rs')),
                    );
                    return;
                  }
                  if (nicCtrl.text.length != 13) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('NIC must be 13 digits')),
                    );
                    return;
                  }
                }
                // Logic to save member
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Member added successfully.')),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.gold),
              child: const Text('Add Member'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MemberListItem extends StatelessWidget {
  final UserModel user;

  const _MemberListItem({required this.user});

  @override
  Widget build(BuildContext context) {
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
            if (user.nicNumber != null) Text('NIC: ${user.nicNumber}', style: const TextStyle(fontSize: 12)),
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
            _buildDetailRow('NIC Number', user.nicNumber ?? 'Not provided'),
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
