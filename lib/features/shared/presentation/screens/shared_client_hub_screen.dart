import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moharek_app/core/theme/app_theme.dart';
import 'package:moharek_app/features/admin/presentation/screens/manage_client.dart'; // We'll keep the internal tab implementations in manage_client.dart for now and wrap them

class SharedClientHubScreen extends ConsumerWidget {
  final String projectId;
  final bool isAdmin;
  
  const SharedClientHubScreen({
    super.key, 
    required this.projectId, 
    this.isAdmin = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // For now, we reuse the existing AdminManageClient but pass the context/state needed
    // In a full refactor, we would move all 11 tabs here and use the isAdmin flag 
    // to show/hide specific management buttons in the top bar or settings tab.
    
    return AdminManageClient(
      projectId: projectId,
      isAdmin: isAdmin,
    ); 
    // Note: We will need to update AdminManageClient to support the isAdmin flag 
    // to hide things like "Reassign AM" or "Delete Project".
  }
}
