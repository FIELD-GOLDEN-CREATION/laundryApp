import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/services/api_client.dart';
import '../models/member_row.dart';

class AdminMembersState {
  const AdminMembersState({
    this.tab = 0,
    this.clients = const [],
    this.vendors = const [],
    this.drivers = const [],
    this.isLoading = false,
    this.error = '',
  });

  final int tab;
  final List<MemberRow> clients;
  final List<MemberRow> vendors;
  final List<MemberRow> drivers;
  final bool isLoading;
  final String error;

  List<MemberRow> get currentMembers => switch (tab) {
    0 => clients,
    1 => vendors,
    _ => drivers,
  };
}

class AdminMembersNotifier extends Notifier<AdminMembersState> {
  @override
  AdminMembersState build() => const AdminMembersState();

  void pickTab(int i) => state = AdminMembersState(
    tab: i,
    clients: state.clients,
    vendors: state.vendors,
    drivers: state.drivers,
  );

  Future<void> fetchMembers() async {
    state = AdminMembersState(
      tab: state.tab,
      isLoading: true,
      clients: state.clients,
      vendors: state.vendors,
      drivers: state.drivers,
    );

    try {
      final response = await ApiClient.get('/admin/users');
      if (response['success'] == true) {
        final users = (response['users'] as List)
            .map((u) => MemberRow.fromJson(u as Map<String, dynamic>))
            .toList();

        state = AdminMembersState(
          tab: state.tab,
          clients: users.where((u) => u.role == 'customer').toList(),
          vendors: users.where((u) => u.role == 'vendor').toList(),
          drivers: users.where((u) => u.role == 'driver' || u.role == 'staff').toList(),
        );
      } else {
        state = AdminMembersState(
          tab: state.tab,
          error: response['message'] as String? ?? 'Failed to load members.',
          clients: state.clients,
          vendors: state.vendors,
          drivers: state.drivers,
        );
      }
    } catch (e) {
      state = AdminMembersState(
        tab: state.tab,
        error: 'Unable to connect to server.',
        clients: state.clients,
        vendors: state.vendors,
        drivers: state.drivers,
      );
    }
  }

  Future<String?> addMember({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String role,
  }) async {
    try {
      final response = await ApiClient.post('/admin/users', body: {
        'name': name,
        'email': email,
        'phone': phone.isNotEmpty ? phone : null,
        'password': password,
        'role': role,
      });

      if (response['success'] == true) {
        await fetchMembers();
        return null;
      } else {
        return response['message'] as String? ?? 'Failed to create member.';
      }
    } catch (e) {
      return 'Unable to connect to server.';
    }
  }

  Future<String?> deleteMember(int id) async {
    try {
      final response = await ApiClient.delete('/admin/users/$id');
      if (response['success'] == true) {
        await fetchMembers();
        return null;
      } else {
        return response['message'] as String? ?? 'Failed to delete member.';
      }
    } catch (e) {
      return 'Unable to connect to server.';
    }
  }
}

final adminMembersProvider = NotifierProvider<AdminMembersNotifier, AdminMembersState>(AdminMembersNotifier.new);
