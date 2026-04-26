import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/presentation/responsive_scroll_body.dart';
import '../../../core/shared/constants/merchant_colors.dart';
import '../../../types.dart';
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
    this.onLogin,
    this.onSignup,
    this.onGuestDiscover,
    this.onScanQr,
  });

  final ValueChanged<UserRole> onSelectRole;
  final UserRole? initialRole;
  final ValueChanged<UserRole>? onRoleChanged;
  final ValueChanged<UserRole>? onLogin;
  final ValueChanged<UserRole>? onSignup;
  /// Navigate to discovery screen without authenticating.
  final VoidCallback? onGuestDiscover;
  /// Open the QR scanner directly (no account required).
  final VoidCallback? onScanQr;

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  late UserRole _selectedRole;
  // isScanning is always false now — QR scanner opens immediately via onScanQr.
  final bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.initialRole ?? UserRole.client;
  }

  void _handleScan() {
    // If the shell provides a direct QR scanner callback, use it.
    if (widget.onScanQr != null) {
      widget.onScanQr!();
      return;
    }
    // Fallback: navigate to client login (original behaviour).
    widget.onSelectRole(UserRole.client);
  }

  void _handleDiscover() {
    widget.onSelectRole(UserRole.merchant);
  }

  void _handleMerchantLogin() {
    // Navigate to login specifically for merchant role
    // This is called from the "Se connecter" button in merchant view
    // Use onLogin callback if provided, otherwise fallback to onSelectRole
    if (widget.onLogin != null) {
      widget.onLogin!(UserRole.merchant);
    } else {
      widget.onSelectRole(UserRole.merchant);
    }
  }

  void _handleClientLogin() {
    if (widget.onLogin != null) {
      widget.onLogin!(UserRole.client);
      return;
    }
    widget.onSelectRole(UserRole.client);
  }

  void _handleClientSignup() {
    if (widget.onSignup != null) {
      widget.onSignup!(UserRole.client);
      return;
    }
    widget.onSelectRole(UserRole.client);
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
        statusBarColor: MerchantColors.bgMain,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: MerchantColors.bgMain,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: MerchantColors.bgMain,
        body: SafeArea(
          child: ResponsiveScrollBody(
            horizontalPadding: 24,
            verticalPadding: 8,
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
                const SizedBox(height: 16),
                _selectedRole == UserRole.merchant
                    ? MerchantView(
                        onDiscover: _handleDiscover,
                        onLogin: _handleMerchantLogin,
                      )
                    : ClientView(
                        isScanning: _isScanning,
                        onScan: _handleScan,
                        onCreateAccount: _handleClientSignup,
                        onGuestDiscover: widget.onGuestDiscover,
                      ),
                const SizedBox(height: 20),
                // Both roles share the same "already have account?" link widget
                LoginLink(
                  onTap: _selectedRole == UserRole.client
                      ? _handleClientLogin
                      : () {
                          if (widget.onLogin != null) {
                            widget.onLogin!(_selectedRole);
                          } else {
                            widget.onSelectRole(_selectedRole);
                          }
                        },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
