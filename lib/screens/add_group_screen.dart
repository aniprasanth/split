import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:splitzy/models/group_model.dart';
import 'package:splitzy/services/database_service.dart';
import 'package:splitzy/services/auth_service.dart';
import 'package:splitzy/services/contacts_service.dart';
import 'package:splitzy/utils/validators.dart';
import 'package:splitzy/utils/async_operation_mixin.dart';
import 'package:splitzy/screens/group_detail_screen.dart';
import 'dart:async';

class AddGroupScreen extends StatefulWidget {
  const AddGroupScreen({super.key});

  @override
  State<AddGroupScreen> createState() => _AddGroupScreenState();
}

class _AddGroupScreenState extends State<AddGroupScreen> with AsyncOperationMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _newMemberController = TextEditingController();
  final List<String> _members = [];
  final Map<String, String> _memberNames = {};
  String? _contactSearchQuery;

  @override
  void initState() {
    super.initState();
    _initializeCurrentUser();
  }

  void _initializeCurrentUser() {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUser;
    if (user != null) {
      _members.add(user.uid);
      _memberNames[user.uid] = user.name.isNotEmpty ? user.name : 'You';
    } else {
      _members.add('current_user');
      _memberNames['current_user'] = 'You';
    }
  }

  bool _isCurrentUser(String memberId) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUser;
    return (user != null && user.uid == memberId) || memberId == 'current_user';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _newMemberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final userLoaded = authService.currentUser != null && !authService.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Group'),
        actions: [
          TextButton(
            onPressed: (isLoading || !userLoaded)
                ? null
                : () {
                    FocusScope.of(context).unfocus();
                    _saveGroup();
                  },
            child: (isLoading || !userLoaded)
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('SAVE'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Group Name
            TextFormField(
              controller: _nameController,
              enabled: !isLoading,
              decoration: const InputDecoration(
                labelText: 'Group Name',
                hintText: 'Enter group name...',
                prefixIcon: Icon(Icons.group),
                border: OutlineInputBorder(),
              ),
              validator: (value) => Validators.validateName(value, minLength: 2, maxLength: 50, fieldName: 'Group Name'),
              textCapitalization: TextCapitalization.words,
              maxLength: 50,
            ),
            const SizedBox(height: 16),
            // Members
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Members',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    ..._members.map((memberId) => ListTile(
                          leading: const Icon(Icons.person),
                          title: Text(_memberNames[memberId] ?? memberId),
                          trailing: _isCurrentUser(memberId)
                              ? null
                              : IconButton(
                                  icon: const Icon(Icons.remove_circle, color: Colors.red),
                                  onPressed: isLoading
                                      ? null
                                      : () {
                                          setState(() {
                                            _members.remove(memberId);
                                            _memberNames.remove(memberId);
                                          });
                                        },
                                ),
                        )),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.person_add),
                      title: TextFormField(
                        controller: _newMemberController,
                        decoration: const InputDecoration(hintText: 'Enter member name'),
                        validator: (value) =>
                            value != null && value.trim().isNotEmpty
                                ? Validators.validateName(value, minLength: 2, maxLength: 50, fieldName: 'Member Name')
                                : null,
                        onFieldSubmitted: (value) {
                          if (value.trim().isNotEmpty) {
                            _addManualMember(value.trim());
                          }
                        },
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.contacts, color: Colors.blue),
                        onPressed: isLoading ? null : _showContactsDialog,
                        tooltip: 'Add from contacts',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: !isLoading && userLoaded ? _saveGroup : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: isLoading
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 8),
                        Text('Adding...'),
                      ],
                    )
                  : const Text(
                      'Create Group',
                      style: TextStyle(fontSize: 16),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveGroup() async {
    if (!_formKey.currentState!.validate()) {
      debugPrint('Form validation failed');
      return;
    }
    if (_members.isEmpty) {
      showErrorSnackBar('Please add at least one member');
      debugPrint('No members in group');
      return;
    }

    final navigator = Navigator.of(context);

    await performAsyncOperation(
      operation: () async {
        final name = _nameController.text.trim();
        if (name.isEmpty) {
          throw Exception('Please enter a group name');
        }

        final authService = Provider.of<AuthService>(context, listen: false);
        final user = authService.currentUser;
        if (user == null) {
          throw Exception('User not loaded. Please wait and try again.');
        }

        final group = GroupModel.create(
          name: name,
          members: _members,
          memberNames: _memberNames,
          createdBy: user.uid,
          createdAt: DateTime.now().toUtc(),
        );

        final dbService = Provider.of<DatabaseService>(context, listen: false);
        debugPrint('Attempting to create group: $name');
        final success = await dbService.createGroup(group);

        if (!success) {
          throw Exception(dbService.errorMessage ?? 'Failed to create group');
        }

        return group;
      },
      timeout: const Duration(seconds: 30),
      onSuccess: () {
        showSuccessSnackBar('Group "${_nameController.text.trim()}" created successfully!');
        navigator.pushReplacement(
          MaterialPageRoute(
            builder: (context) => GroupDetailScreen(group: group),
          ),
        );
      },
      onError: (error) {
        showErrorSnackBar(error.toString());
      },
    );
  }

  void _addManualMember(String name) {
    final memberId = 'member_${name.toLowerCase().replaceAll(' ', '_')}';
    if (!_members.contains(memberId)) {
      setState(() {
        _members.add(memberId);
        _memberNames[memberId] = name;
      });
      _newMemberController.clear();
      showSuccessSnackBar('Added $name to the group');
    } else {
      showErrorSnackBar('Member "$name" is already in the group');
    }
  }

  void _showContactsDialog() {
    final contactsService = Provider.of<ContactsService>(context, listen: false);

    if (!contactsService.hasPermission) {
      _requestContactsPermission();
      return;
    }

    _contactSearchQuery = null;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Select from Contacts'),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: Column(
              children: [
                TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search contacts',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (query) {
                    setDialogState(() {
                      _contactSearchQuery = query.trim().toLowerCase();
                    });
                  },
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Consumer<ContactsService>(
                    builder: (context, contactsService, child) {
                      if (contactsService.isLoading) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final allContacts = contactsService.contacts;
                      final contacts = (_contactSearchQuery == null || _contactSearchQuery!.isEmpty)
                          ? allContacts
                          : allContacts
                              .where((c) => c.displayName.toLowerCase().contains(_contactSearchQuery!))
                              .toList();

                      if (contacts.isEmpty) {
                        return const Center(child: Text('No contacts found'));
                      }

                      return ListView.builder(
                        itemCount: contacts.length,
                        itemBuilder: (context, index) {
                          final contact = contacts[index];
                          return ListTile(
                            leading: const CircleAvatar(
                              child: Icon(Icons.person),
                            ),
                            title: Text(contact.displayName),
                            subtitle: contactsService.getContactPhone(contact) != null
                                ? Text(contactsService.getContactPhone(contact)!)
                                : contactsService.getContactEmail(contact) != null
                                    ? Text(contactsService.getContactEmail(contact)!)
                                    : null,
                            onTap: () {
                              final name = contact.displayName;
                              final memberId = 'member_${name.toLowerCase().replaceAll(' ', '_')}';
                              if (!_members.contains(memberId)) {
                                setState(() {
                                  _members.add(memberId);
                                  _memberNames[memberId] = name;
                                });
                                Navigator.of(context).pop();
                                showSuccessSnackBar('Added $name to the group');
                              } else {
                                Navigator.of(context).pop();
                                showErrorSnackBar('Member "$name" is already in the group');
                              }
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }

  void _requestContactsPermission() async {
    final contactsService = Provider.of<ContactsService>(context, listen: false);
    final granted = await contactsService.requestPermission();

    if (!mounted) return;

    if (granted) {
      _showContactsDialog();
    } else {
      showErrorSnackBar('Contacts permission is required to add members from contacts');
    }
  }
}