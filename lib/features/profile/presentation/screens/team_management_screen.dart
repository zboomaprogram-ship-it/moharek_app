import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moharek_app/core/theme/app_theme.dart';
import 'package:moharek_app/shared/services/data_providers.dart';

final companyMembersProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  
  // Get my company ID
  final myCompany = await client
      .from('company_members')
      .select('company_id, role')
      .eq('user_id', client.auth.currentUser!.id)
      .maybeSingle();
      
  if (myCompany == null) return [];
  
  // Fetch all members of this company
  final members = await client
      .from('company_members')
      .select('*, profiles:user_id(full_name)')
      .eq('company_id', myCompany['company_id']);
      
  return (members as List).cast<Map<String, dynamic>>();
});

class TeamManagementScreen extends ConsumerStatefulWidget {
  const TeamManagementScreen({super.key});

  @override
  ConsumerState<TeamManagementScreen> createState() => _TeamManagementScreenState();
}

class _TeamManagementScreenState extends ConsumerState<TeamManagementScreen> {
  final _emailCtrl = TextEditingController();
  String _selectedRole = 'viewer';
  bool _isLoading = false;

  Future<void> _inviteMember() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final client = ref.read(supabaseClientProvider);
      
      // Get my company ID
      final myCompany = await client
          .from('company_members')
          .select('company_id, role')
          .eq('user_id', client.auth.currentUser!.id)
          .single();
          
      if (myCompany['role'] != 'owner') {
        throw Exception('Only owners can invite members');
      }

      // Check if user exists in profiles
      final profileResponse = await client
          .from('profiles')
          .select('id')
          .eq('email', email)
          .maybeSingle();

      if (profileResponse == null) {
        throw Exception('User with this email not found. They must sign up first.');
      }

      // Add to company_members
      await client.from('company_members').insert({
        'company_id': myCompany['company_id'],
        'user_id': profileResponse['id'],
        'role': _selectedRole,
      });

      _emailCtrl.clear();
      ref.invalidate(companyMembersProvider);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Member added successfully!'), backgroundColor: AppTheme.primaryGreen),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _removeMember(String memberId, String userId) async {
    try {
      final client = ref.read(supabaseClientProvider);
      if (userId == client.auth.currentUser!.id) {
        throw Exception('You cannot remove yourself');
      }
      
      await client.from('company_members').delete().eq('id', memberId);
      ref.invalidate(companyMembersProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final membersAsync = ref.watch(companyMembersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Team Management')),
      body: membersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen)),
        error: (err, _) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.red))),
        data: (members) {
          final isOwner = members.any((m) => m['user_id'] == ref.read(supabaseClientProvider).auth.currentUser?.id && m['role'] == 'owner');

          return Column(
            children: [
              if (isOwner)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.cardColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Add Team Member', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _emailCtrl,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'User Email',
                            hintStyle: const TextStyle(color: Colors.grey),
                            filled: true,
                            fillColor: Colors.white.withValues(alpha: 0.05),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                          ),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: _selectedRole,
                          dropdownColor: AppTheme.cardColor,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white.withValues(alpha: 0.05),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'manager', child: Text('Manager')),
                            DropdownMenuItem(value: 'marketing', child: Text('Marketing')),
                            DropdownMenuItem(value: 'finance', child: Text('Finance')),
                            DropdownMenuItem(value: 'viewer', child: Text('Viewer')),
                          ],
                          onChanged: (v) => setState(() => _selectedRole = v!),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _inviteMember,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryGreen,
                              foregroundColor: Colors.black,
                            ),
                            child: _isLoading 
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                              : const Text('Add Member'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: members.length,
                  itemBuilder: (context, index) {
                    final member = members[index];
                    final profile = member['profiles'] ?? {};
                    return Card(
                      color: AppTheme.cardColor,
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.2),
                          child: const Icon(Icons.person, color: AppTheme.primaryGreen),
                        ),
                        title: Text(profile['full_name'] ?? 'Unknown', style: const TextStyle(color: Colors.white)),
                        subtitle: Text('${profile['email']} • ${member['role']}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        trailing: (isOwner && member['user_id'] != ref.read(supabaseClientProvider).auth.currentUser?.id)
                            ? IconButton(
                                icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                                onPressed: () => _removeMember(member['id'], member['user_id']),
                              )
                            : null,
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
