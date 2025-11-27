import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:unipantry/providers/auth_provider.dart';
import 'package:unipantry/providers/household_provider.dart';

class HouseholdScreen extends ConsumerWidget {
  const HouseholdScreen({super.key});

  void _confirmRemove(BuildContext context, WidgetRef ref, String userId, String email, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Member?'),
        content: Text('Are you sure you want to remove $name from this household?\n\nThey will be moved to their own empty pantry.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx); 
              await ref.read(householdActionsProvider).removeMember(userId, email);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('$name has been removed.')),
                );
              }
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    
    final householdId = ref.watch(householdIdProvider);
    final currentUser = ref.watch(firebaseAuthProvider).currentUser;
    final membersAsync = ref.watch(householdMembersProvider);
    final householdDataAsync = ref.watch(householdDataProvider);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Manage Household', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 1. INVITE CODE SECTION (FIXED OVERFLOW) ---
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withOpacity(0.4),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.colorScheme.primary.withOpacity(0.2)),
              ),
              child: Column(
                children: [
                  Icon(PhosphorIconsDuotone.shareNetwork, size: 32, color: theme.colorScheme.primary),
                  const SizedBox(height: 12),
                  const Text("Invite Family Members", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  const Text(
                    "Share this code to let others join your pantry.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () {
                      if (householdId != null) {
                        Clipboard.setData(ClipboardData(text: householdId));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Invite code copied!')),
                        );
                      }
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min, // Shrink to fit
                        children: [
                          // --- FIX: Wrapped Text in Flexible ---
                          Flexible(
                            child: Text(
                              householdId ?? "Loading...",
                              style: const TextStyle(
                                fontFamily: 'Courier',
                                fontWeight: FontWeight.bold,
                                fontSize: 14, // Slightly smaller font to fit better
                                letterSpacing: 1.0,
                              ),
                              overflow: TextOverflow.ellipsis, // Handle overflow gracefully
                              maxLines: 1,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(PhosphorIconsDuotone.copy, size: 18, color: theme.colorScheme.primary),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
            const Text("Members", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            // --- 2. MEMBERS LIST (FIXED OVERFLOW) ---
            householdDataAsync.when(
              data: (householdData) {
                final ownerId = householdData?['ownerId'];
                final isCurrentUserOwner = currentUser?.uid == ownerId;

                return membersAsync.when(
                  data: (members) {
                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: members.length,
                      itemBuilder: (context, index) {
                        final member = members[index];
                        final uid = member['uid'];
                        final name = member['displayName'] != null && member['displayName'].isNotEmpty 
                            ? member['displayName'] 
                            : 'User';
                        final email = member['email'] ?? '';
                        final photoUrl = member['photoUrl'];
                        final isMemberOwner = uid == ownerId;
                        final isMe = uid == currentUser?.uid;

                        return Card(
                          elevation: 0,
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            leading: CircleAvatar(
                              backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                              backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                              child: photoUrl == null 
                                ? Text(name[0].toUpperCase(), style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold))
                                : null,
                            ),
                            title: Row(
                              children: [
                                // --- FIX: Wrapped Name in Flexible ---
                                Flexible(
                                  child: Text(
                                    name + (isMe ? " (You)" : ""),
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (isMemberOwner) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.amber.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: Colors.amber),
                                    ),
                                    child: const Text("OWNER", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.orange)),
                                  )
                                ]
                              ],
                            ),
                            subtitle: Text(email, style: TextStyle(fontSize: 12, color: Colors.grey[600]), overflow: TextOverflow.ellipsis),
                            
                            trailing: (isCurrentUserOwner && !isMe)
                                ? IconButton(
                                    icon: Icon(PhosphorIconsDuotone.trash, color: theme.colorScheme.error),
                                    onPressed: () => _confirmRemove(context, ref, uid, email, name),
                                  )
                                : null,
                          ),
                        );
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, s) => Text("Error loading members: $e"),
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}