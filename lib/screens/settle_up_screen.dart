import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:splitzy/services/database_service.dart';
import 'package:splitzy/services/optimized_data_service.dart';
import 'package:splitzy/services/auth_service.dart';
import 'package:splitzy/models/expense_model.dart';
import 'package:splitzy/models/group_model.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:splitzy/models/settlement_model.dart';
import 'package:rxdart/rxdart.dart';

class SettleUpScreen extends StatefulWidget {
  const SettleUpScreen({super.key});

  @override
  State<SettleUpScreen> createState() => _SettleUpScreenState();
}

class _SettleUpScreenState extends State<SettleUpScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Stream<Map<String, dynamic>> _getOptimizedSettlementData(
    String currentUserId,
    OptimizedDataService optimizedDataService,
  ) {
    return Rx.combineLatest3(
      optimizedDataService.expensesStream,
      optimizedDataService.getUserGroups(currentUserId),
      optimizedDataService.getUserSettlements(currentUserId),
      (List<ExpenseModel> expenses, List<GroupModel> groups, List<SettlementModel> settlements) async {
        // Convert groups to map for efficient lookup
        final groupsMap = <String, GroupModel>{};
        for (final group in groups) {
          groupsMap[group.id] = group;
        }

        // Use optimized calculation with caching
        return await optimizedDataService.calculateSettlementsOptimized(
          currentUserId,
          expenses,
          settlements,
          groupsMap,
        );
      },
    ).switchMap((future) => Stream.fromFuture(future));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settle Up'),
        centerTitle: true,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'To Get'),
            Tab(text: 'To Give'),
          ],
        ),
      ),
      body: Consumer2<AuthService, DatabaseService>(
        builder: (context, authService, dbService, child) {
          final currentUser = authService.currentUser;
          if (currentUser == null) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_outline, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('User not authenticated'),
                ],
              ),
            );
          }

          return Consumer<OptimizedDataService>(
            builder: (context, optimizedDataService, child) {
              return StreamBuilder<Map<String, dynamic>>(
                stream: _getOptimizedSettlementData(currentUser.uid, optimizedDataService),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
                          const SizedBox(height: 16),
                          const Text('Error loading settlement data'),
                        ],
                      ),
                    );
                  }

                  final data = snapshot.data!;
                  final youOweMap = data['youOwe'] as Map<String, double>;
                  final owesYouMap = data['owesYou'] as Map<String, double>;
                  final memberNames = data['memberNames'] as Map<String, String>;

                  return TabBarView(
                    controller: _tabController,
                    children: [
                      _buildSettlementTab(owesYouMap, memberNames, true),  // "To Get" - people who owe you
                      _buildSettlementTab(youOweMap, memberNames, false),  // "To Give" - people you owe
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildSettlementTab(
      Map<String, double> settlements, Map<String, String> memberNames, bool isOwesYou) {
    final totalAmount = settlements.values.fold(0.0, (sum, amount) => sum + amount);
    final color = isOwesYou ? Colors.green : Colors.red;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Total amount card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: color.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.shade200),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.account_balance_wallet,
                  color: color.shade600,
                  size: 32,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isOwesYou ? 'Total to give' : 'Total to get',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: color.shade700,
                        ),
                      ),
                      Text(
                        '₹${totalAmount.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: color.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Settlement items
          if (settlements.isEmpty) ...[
            const SizedBox(height: 100),
            Icon(
              Icons.celebration,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'All settled up!',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isOwesYou ? 'Nobody owes you money' : 'You don\'t owe anyone money',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade500,
              ),
            ),
          ] else ...[
            ...settlements.entries.map((entry) => _buildSettlementCard(
              entry.key,
              memberNames[entry.key] ?? entry.key,
              entry.value,
              isOwesYou,
            )),
          ],
        ],
      ),
    );
  }

  Widget _buildSettlementCard(String userId, String name, double amount, bool isOwesYou) {
    final color = isOwesYou ? Colors.green : Colors.red;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.shade100,
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : 'U',
                style: TextStyle(
                  color: color.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    isOwesYou ? 'to get' : 'to give',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₹${amount.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color.shade700,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!isOwesYou)
                      TextButton.icon(
                        onPressed: () => _pay(userId, name, amount),
                        icon: const Icon(Icons.payment, size: 18),
                        label: const Text('Pay'),
                      ),
                    if (isOwesYou)
                      TextButton.icon(
                        onPressed: () => _sendReminder(name, amount, isOwesYou),
                        icon: const Icon(Icons.message, size: 18),
                        label: const Text('Remind'),
                      ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: () => _markAsSettled(userId, name, amount, isOwesYou),
                      icon: const Icon(Icons.check_circle, size: 18),
                      label: const Text('Mark as Settled'),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _sendReminder(String name, double amount, bool isOwesYou) {
    final message = isOwesYou
        ? 'Hi $name! Just a friendly reminder that you owe me ₹${amount.toStringAsFixed(2)} to settle up. Thanks!'
        : 'Hi $name! I owe you ₹${amount.toStringAsFixed(2)} to settle up. Let me know when you\'d like me to pay!';

    Clipboard.setData(ClipboardData(text: message));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Reminder message copied to clipboard'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _markAsSettled(String userId, String name, double amount, bool isOwesYou) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark as Settled'),
        content: Text('Mark the ₹${amount.toStringAsFixed(2)} with $name as settled?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final auth = Provider.of<AuthService>(context, listen: false);
              final db = Provider.of<DatabaseService>(context, listen: false);
              final currentUser = auth.currentUser;
              if (currentUser == null) return;

              // Load groups once to find a group containing both users
              GroupModel? selectedGroup;
              try {
                final groupsSnapshot = await db.getUserGroups(currentUser.uid).first;
                
                // First try to find a group containing both users
                final sharedGroup = groupsSnapshot.where(
                  (g) => g.members.contains(currentUser.uid) && g.members.contains(userId)
                ).firstOrNull;
                
                if (sharedGroup != null) {
                  selectedGroup = sharedGroup;
                } else if (groupsSnapshot.isNotEmpty) {
                  // If no shared group, let user pick from their groups
                  selectedGroup = await _pickGroup(groupsSnapshot);
                } else {
                  // If no groups exist, create a default personal group and save it
                  selectedGroup = GroupModel(
                    id: 'personal_${currentUser.uid}',
                    name: 'Personal',
                    members: [currentUser.uid, userId],
                    memberNames: {
                      currentUser.uid: currentUser.displayName.isNotEmpty ? currentUser.displayName : 'You',
                      userId: name,
                    },
                    createdBy: currentUser.uid,
                  );
                  
                  // Save the personal group to database
                  await db.createGroup(selectedGroup);
                }
              } catch (e) {
                // If there's an error loading groups, create a default personal group and save it
                selectedGroup = GroupModel(
                  id: 'personal_${currentUser.uid}',
                  name: 'Personal',
                  members: [currentUser.uid, userId],
                  memberNames: {
                    currentUser.uid: currentUser.displayName.isNotEmpty ? currentUser.displayName : 'You',
                    userId: name,
                  },
                  createdBy: currentUser.uid,
                );
                
                // Save the personal group to database
                await db.createGroup(selectedGroup);
              }

              if (!mounted) return;
              if (selectedGroup == null) return;

              // Determine payment direction based on whether this is "owes you" or "you owe"
              final currentUserPays = !isOwesYou; // If it's not "owes you", then current user pays

              // Get current user display name (analyzer knows displayName is not null)
              final currentUserName = currentUser.displayName.isNotEmpty
                  ? currentUser.displayName
                  : 'You';

              final settlement = SettlementModel.create(
                fromUser: currentUserPays ? currentUser.uid : userId,
                fromUserName: currentUserPays ? currentUserName : name,
                toUser: currentUserPays ? userId : currentUser.uid,
                toUserName: currentUserPays ? name : currentUserName,
                amount: amount,
                groupId: selectedGroup.id,
                groupName: selectedGroup.name,
                paymentMethod: 'Manual',
              ).copyWith(status: SettlementStatus.completed);

              final success = await db.addSettlement(settlement);
              if (!mounted) return;

              // Use context after mounted check
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              scaffoldMessenger.showSnackBar(
                SnackBar(
                  content: Text(success
                      ? '₹${amount.toStringAsFixed(2)} marked as settled with $name'
                      : 'Failed to record settlement'),
                  backgroundColor: success ? Colors.green : Colors.red,
                  behavior: SnackBarBehavior.floating,
                ),
              );

              // The UI will automatically refresh due to the stream-based architecture
              // The settlement will be filtered out in the next calculation
            },
            child: const Text('Mark Settled'),
          ),
        ],
      ),
    );
  }

  Future<GroupModel?> _pickGroup(List<GroupModel> groups) async {
    if (groups.isEmpty) return null;
    GroupModel? chosen;
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Select Group'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: groups.length,
            itemBuilder: (context, index) {
              final g = groups[index];
              return ListTile(
                title: Text(g.name),
                onTap: () {
                  chosen = g;
                  Navigator.of(ctx).pop();
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          )
        ],
      ),
    );
    return chosen;
  }

  Future<void> _pay(String userId, String name, double amount) async {
    final upiAmount = amount.toStringAsFixed(2);
    final uri = Uri.parse('upi://pay?pa=example@upi&pn=$name&am=$upiAmount&cu=INR');
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (mounted) {
        final scaffoldMessenger = ScaffoldMessenger.of(context);
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('No payment app found'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}