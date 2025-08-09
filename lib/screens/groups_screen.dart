import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:splitzy/screens/group_detail_screen.dart';
import 'package:splitzy/services/database_service.dart';
import 'package:splitzy/services/auth_service.dart';
import 'package:splitzy/models/group_model.dart';

class GroupsScreen extends StatefulWidget {
  const GroupsScreen({super.key});

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  List<GroupModel> groups = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  void _loadGroups() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final currentUser = authService.currentUser;

      if (currentUser == null) {
        setState(() {
          isLoading = false;
        });
        return;
      }

      final dbService = Provider.of<DatabaseService>(context, listen: false);

      // Listen to groups stream
      dbService.getUserGroups(currentUser.uid).listen(
            (groupsList) {
          if (mounted) {
            setState(() {
              groups = groupsList;
              isLoading = false;
            });
          }
        },
        onError: (error) {
          if (mounted) {
            setState(() {
              isLoading = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to load groups: $error'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading groups: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showCreateGroupDialog() {
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Group'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Group Name',
            hintText: 'Enter group name...',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.trim().isNotEmpty) {
                _createGroup(nameController.text.trim());
                Navigator.pop(context);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _createGroup(String name) async {
    // Store context references before any async operations
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final authService = Provider.of<AuthService>(context, listen: false);
    final dbService = Provider.of<DatabaseService>(context, listen: false);

    try {
      // Get current user from auth service
      final currentUser = authService.currentUser;

      if (currentUser == null) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('Please sign in to create a group'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Create group with proper user data
      final newGroup = GroupModel.create(
        name: name,
        members: [currentUser.uid],
        memberNames: {currentUser.uid: currentUser.displayName},
        createdBy: currentUser.uid,
      );

      // Save to Firebase
      final success = await dbService.createGroup(newGroup);

      if (!mounted) return;

      if (success) {
        setState(() {
          groups.add(newGroup);
        });

        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('Group "$name" created successfully!')),
        );
      } else {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(dbService.errorMessage ?? 'Failed to create group'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Error creating group: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Groups'),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : groups.isEmpty
          ? _buildEmptyState()
          : _buildGroupsList(),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateGroupDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.group_off,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No groups yet',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first group to start splitting expenses',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _showCreateGroupDialog,
            icon: const Icon(Icons.add),
            label: const Text('Create Group'),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: groups.length,
      itemBuilder: (context, index) {
        final group = groups[index];
        return _buildGroupCard(group);
      },
    );
  }

  Widget _buildGroupCard(GroupModel group) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primary,
          child: Icon(
            Icons.group,
            color: Theme.of(context).colorScheme.onPrimary,
          ),
        ),
        title: Text(
          group.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('${group.memberNames.length} members'),
            const SizedBox(height: 4),
            Text(
              'You are settled up', // This will be dynamic later
              style: TextStyle(
                color: Colors.green.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => GroupDetailScreen(group: group),
            ),
          );
        },
      ),
    );
  }
}