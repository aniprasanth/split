import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:logger/logger.dart';

class ContactsService extends ChangeNotifier {
  final Logger _logger = Logger();
  List<Contact> _contacts = [];
  bool _isLoading = false;
  bool _hasPermission = false;
  String? _errorMessage;

  // Getters
  List<Contact> get contacts => _contacts;
  bool get isLoading => _isLoading;
  bool get hasPermission => _hasPermission;
  String? get errorMessage => _errorMessage;

  ContactsService() {
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    try {
      _hasPermission = await FlutterContacts.requestPermission();
      if (_hasPermission) {
        await loadContacts();
      }
      notifyListeners();
    } catch (e) {
      _logger.e('Error checking contacts permission: $e');
      _errorMessage = 'Failed to check contacts permission';
      notifyListeners();
    }
  }

  Future<bool> requestPermission() async {
    try {
      _hasPermission = await FlutterContacts.requestPermission();
      if (_hasPermission) {
        await loadContacts();
      }
      notifyListeners();
      return _hasPermission;
    } catch (e) {
      _logger.e('Error requesting contacts permission: $e');
      _errorMessage = 'Failed to request contacts permission';
      notifyListeners();
      return false;
    }
  }

  Future<void> loadContacts() async {
    if (!_hasPermission) {
      _errorMessage = 'No permission to access contacts';
      return;
    }

    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      _contacts = await FlutterContacts.getContacts(
        withProperties: true,
        withPhoto: false,
      );

      // Filter out contacts without names and sort by display name
      _contacts = _contacts.where((contact) => contact.displayName.isNotEmpty).toList();
      _contacts.sort((a, b) => 
        a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase())
      );

      _logger.i('Loaded ${_contacts.length} contacts');
    } catch (e) {
      _logger.e('Error loading contacts: $e');
      _errorMessage = 'Failed to load contacts';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<Contact> searchContacts(String query) {
    if (query.isEmpty) return _contacts;
    
    final lowercaseQuery = query.toLowerCase();
    return _contacts.where((contact) {
      final name = contact.displayName.toLowerCase();
      final phones = contact.phones.map((p) => p.number.toLowerCase());
      final emails = contact.emails.map((e) => e.address.toLowerCase());
      
      return name.contains(lowercaseQuery) ||
             phones.any((phone) => phone.contains(lowercaseQuery)) ||
             emails.any((email) => email.contains(lowercaseQuery));
    }).toList();
  }

  String? getContactPhone(Contact contact) {
    if (contact.phones.isNotEmpty) {
      return contact.phones.first.number;
    }
    return null;
  }

  String? getContactEmail(Contact contact) {
    if (contact.emails.isNotEmpty) {
      return contact.emails.first.address;
    }
    return null;
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
