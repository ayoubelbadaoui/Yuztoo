import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/entities/organization.dart';
import '../domain/entities/organization_member.dart';

/// Placeholder data for presenting the multi-store experience. Lives in
/// memory only: nothing here is read from or written to Firestore.
class DemoStore {
  const DemoStore({
    required this.id,
    required this.label,
    required this.city,
    required this.address,
    this.isOnline = true,
    this.clients = 0,
    this.passagesThisMonth = 0,
    this.rewardsThisMonth = 0,
  });

  final String id;
  final String label;
  final String city;
  final String address;
  final bool isOnline;
  final int clients;
  final int passagesThisMonth;
  final int rewardsThisMonth;

  DemoStore copyWith({bool? isOnline}) => DemoStore(
        id: id,
        label: label,
        city: city,
        address: address,
        isOnline: isOnline ?? this.isOnline,
        clients: clients,
        passagesThisMonth: passagesThisMonth,
        rewardsThisMonth: rewardsThisMonth,
      );
}

class DemoMember {
  const DemoMember({
    required this.id,
    required this.name,
    required this.contact,
    required this.role,
    this.storeIds = const <String>[],
    this.isPending = false,
  });

  final String id;
  final String name;
  final String contact;
  final OrganizationRole role;
  final List<String> storeIds;
  final bool isPending;

  DemoMember copyWith({OrganizationRole? role, List<String>? storeIds}) =>
      DemoMember(
        id: id,
        name: name,
        contact: contact,
        role: role ?? this.role,
        storeIds: storeIds ?? this.storeIds,
        isPending: isPending,
      );
}

class MultiStoreDemoState {
  const MultiStoreDemoState({
    required this.brandName,
    required this.loyaltyMode,
    required this.stores,
    required this.activeStoreId,
    required this.members,
  });

  final String brandName;
  final LoyaltyMode loyaltyMode;
  final List<DemoStore> stores;
  final String activeStoreId;
  final List<DemoMember> members;

  DemoStore get activeStore => stores.firstWhere((s) => s.id == activeStoreId,
      orElse: () => stores.first);

  int get totalClients => stores.fold(0, (sum, s) => sum + s.clients);
  int get totalPassages =>
      stores.fold(0, (sum, s) => sum + s.passagesThisMonth);
  int get totalRewards => stores.fold(0, (sum, s) => sum + s.rewardsThisMonth);

  String storeName(DemoStore s) => '$brandName · ${s.label}';

  MultiStoreDemoState copyWith({
    String? brandName,
    LoyaltyMode? loyaltyMode,
    List<DemoStore>? stores,
    String? activeStoreId,
    List<DemoMember>? members,
  }) =>
      MultiStoreDemoState(
        brandName: brandName ?? this.brandName,
        loyaltyMode: loyaltyMode ?? this.loyaltyMode,
        stores: stores ?? this.stores,
        activeStoreId: activeStoreId ?? this.activeStoreId,
        members: members ?? this.members,
      );
}

class MultiStoreDemoNotifier extends Notifier<MultiStoreDemoState> {
  int _seq = 0;

  @override
  MultiStoreDemoState build() => const MultiStoreDemoState(
        brandName: 'Boulangerie Dupont',
        loyaltyMode: LoyaltyMode.shared,
        activeStoreId: 'centre',
        stores: <DemoStore>[
          DemoStore(
            id: 'centre',
            label: 'Centre-ville',
            city: 'Belfort',
            address: '12 rue de la République',
            clients: 842,
            passagesThisMonth: 1260,
            rewardsThisMonth: 96,
          ),
          DemoStore(
            id: 'gare',
            label: 'Gare',
            city: 'Belfort',
            address: '2 avenue Wilson',
            clients: 515,
            passagesThisMonth: 731,
            rewardsThisMonth: 48,
          ),
          DemoStore(
            id: 'montbeliard',
            label: 'Montbéliard',
            city: 'Montbéliard',
            address: '8 place Saint-Martin',
            clients: 388,
            passagesThisMonth: 604,
            rewardsThisMonth: 37,
          ),
          DemoStore(
            id: 'mulhouse',
            label: 'Mulhouse Porte Jeune',
            city: 'Mulhouse',
            address: '1 place de la Porte Jeune',
            isOnline: false,
          ),
        ],
        members: <DemoMember>[
          DemoMember(
            id: 'owner',
            name: 'Paul Dupont',
            contact: 'paul@boulangerie-dupont.fr',
            role: OrganizationRole.owner,
          ),
          DemoMember(
            id: 'm1',
            name: 'Sophie Martin',
            contact: '06 12 34 56 78',
            role: OrganizationRole.manager,
            storeIds: <String>['centre', 'gare'],
          ),
          DemoMember(
            id: 'm2',
            name: 'Karim Benali',
            contact: '06 98 76 54 32',
            role: OrganizationRole.manager,
            storeIds: <String>['montbeliard'],
          ),
          DemoMember(
            id: 'e1',
            name: 'Léa Roux',
            contact: '07 11 22 33 44',
            role: OrganizationRole.employee,
            storeIds: <String>['centre'],
          ),
          DemoMember(
            id: 'e2',
            name: 'Hugo Petit',
            contact: '07 55 66 77 88',
            role: OrganizationRole.employee,
            storeIds: <String>['gare'],
            isPending: true,
          ),
        ],
      );

  void switchTo(String storeId) =>
      state = state.copyWith(activeStoreId: storeId);

  void setLoyaltyMode(LoyaltyMode mode) =>
      state = state.copyWith(loyaltyMode: mode);

  void toggleOnline(String storeId) => state = state.copyWith(
        stores: [
          for (final s in state.stores)
            s.id == storeId ? s.copyWith(isOnline: !s.isOnline) : s,
        ],
      );

  /// Adds an offline store and makes it the active one.
  String addStore({
    required String label,
    required String city,
    required String address,
  }) {
    final id = 'new-${++_seq}';
    state = state.copyWith(
      stores: [
        ...state.stores,
        DemoStore(
          id: id,
          label: label.trim().isEmpty ? city : label.trim(),
          city: city,
          address: address.trim(),
          isOnline: false,
        ),
      ],
      activeStoreId: id,
    );
    return id;
  }

  void invite({
    required String name,
    required String contact,
    required OrganizationRole role,
    required List<String> storeIds,
  }) {
    state = state.copyWith(
      members: [
        ...state.members,
        DemoMember(
          id: 'invite-${++_seq}',
          name: name.trim().isEmpty ? contact.trim() : name.trim(),
          contact: contact.trim(),
          role: role,
          storeIds: storeIds,
          isPending: true,
        ),
      ],
    );
  }

  void updateMember(String id,
      {OrganizationRole? role, List<String>? storeIds}) {
    state = state.copyWith(
      members: [
        for (final m in state.members)
          m.id == id ? m.copyWith(role: role, storeIds: storeIds) : m,
      ],
    );
  }

  void removeMember(String id) => state = state.copyWith(
        members: [
          for (final m in state.members)
            if (m.id != id) m
        ],
      );
}

final multiStoreDemoProvider =
    NotifierProvider<MultiStoreDemoNotifier, MultiStoreDemoState>(
  MultiStoreDemoNotifier.new,
);
