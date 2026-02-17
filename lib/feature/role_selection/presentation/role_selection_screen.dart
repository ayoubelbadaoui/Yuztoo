import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../types.dart';
import 'widgets/role_selection_colors.dart';
import 'widgets/role_selection_header.dart';
import 'widgets/merchant_view.dart';
import 'widgets/client_view.dart';
import 'widgets/login_link.dart';

/// Role selection screen - first screen for unauthenticated users
class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({
    super.key,
    required this.onSelectRole,
    this.initialRole,
    this.onRoleChanged,
  });

  static String get path => '/role-selection';

  final ValueChanged<UserRole> onSelectRole;
  final UserRole? initialRole;
  final ValueChanged<UserRole>? onRoleChanged;

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  late UserRole _selectedRole;
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.initialRole ?? UserRole.client;
  }

  void _handleScan() {
    setState(() => _isScanning = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _isScanning = false);
        widget.onSelectRole(UserRole.client);
      }
    });
  }

  void _handleDiscover() {
    // Navigate to merchant onboarding instead of login
    // This will be handled by main.dart navigation
    widget.onSelectRole(UserRole.merchant);
  }

  void _handleLogin() {
    // In the original onboarding-wizard UI-only flow, "login" simply validates
    // the selected role and lets the host decide what screen to show.
    widget.onSelectRole(_selectedRole);
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: RoleSelectionColors.bgDark1,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: RoleSelectionColors.bgDark1,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: RoleSelectionColors.bgDark1,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                RoleSelectionHeader(
                  selectedRole: _selectedRole,
                  onRoleChanged: (UserRole role) {
                    setState(() => _selectedRole = role);
                    // Sync with parent to preserve selection (without navigating)
                    widget.onRoleChanged?.call(role);
                  },
                ),
                const SizedBox(height: 24),
                _selectedRole == UserRole.merchant
                    ? MerchantView(
                        onDiscover: _handleDiscover,
                      )
                    : ClientView(
                        isScanning: _isScanning,
                        onScan: _handleScan,
                      ),
                const SizedBox(height: 40),
                LoginLink(onTap: _handleLogin),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
