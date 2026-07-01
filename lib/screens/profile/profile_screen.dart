import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../../models/vehicle.dart';
import '../../services/auth_gate.dart';
import '../../services/auth_service.dart';
import '../../services/session_service.dart';
import '../../services/vehicle_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_header.dart';
import '../../widgets/primary_button.dart';
import '../driver/driver_flow_router.dart';
import '../driver/payout_history_screen.dart';
import '../main_tab_screen.dart';
import 'edit_profile_screen.dart';
import 'help_support_screen.dart';
import 'terms_privacy_screen.dart';

/// Profile tab — account info, driver access, support, and logout.
///
/// Guests (no account yet) see a login prompt here instead of account
/// details — Help & Support and Terms & Privacy still work either way
/// since those don't need an account.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  AppUser? _user;
  bool _loggedIn = false;
  bool _loading = true;
  Vehicle? _vehicle;
  bool _driverMode = false;

  @override
  void initState() {
    super.initState();
    _loadUser();
    SessionService.instance.authChanged.addListener(_onAuthChanged);
    SessionService.instance.driverModeChanged.addListener(_onDriverModeChanged);
  }

  void _onAuthChanged() {
    if (mounted) _loadUser();
  }

  void _onDriverModeChanged() async {
    final driverMode = await SessionService.instance.isDriverMode();
    if (mounted) setState(() => _driverMode = driverMode);
  }

  @override
  void dispose() {
    SessionService.instance.authChanged.removeListener(_onAuthChanged);
    SessionService.instance.driverModeChanged.removeListener(_onDriverModeChanged);
    super.dispose();
  }

  Future<void> _loadUser() async {
    final loggedIn = await SessionService.instance.isLoggedIn();
    final user = loggedIn ? await SessionService.instance.getUser() : null;
    final driverMode = await SessionService.instance.isDriverMode();
    Vehicle? vehicle;
    if (loggedIn) {
      try {
        vehicle = await VehicleService.instance.getMyVehicle();
      } catch (e) {
        // ignore: avoid_print
        print('Error in lib/screens/profile/profile_screen.dart: $e');
      }
    }
    if (!mounted) return;
    setState(() {
      _loggedIn = loggedIn;
      _user = user;
      _vehicle = vehicle;
      _driverMode = driverMode;
      _loading = false;
    });
  }

  Future<void> _toggleDriverMode() async {
    await SessionService.instance.setDriverMode(!_driverMode);
  }

  Future<void> _login() async {
    final success = await requireLogin(context);
    if (success) _loadUser();
  }

  Future<void> _editProfile() async {
    final user = _user;
    if (user == null) return;
    final updated = await Navigator.of(context).push<AppUser>(
      MaterialPageRoute(builder: (_) => EditProfileScreen(user: user)),
    );
    if (updated != null && mounted) setState(() => _user = updated);
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('You\'ll need to verify your phone number again to log back in.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Log out', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await AuthService.instance.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MainTabScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(strokeWidth: 2.4)),
      );
    }
    if (!_loggedIn) {
      return _buildGuest();
    }
    final user = _user;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: buildAppHeader('Profile', showProfileIcon: false),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.infoBg,
                  child: Text(
                    user != null && user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : '?',
                    style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 22),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.displayName ?? '...',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
                      ),
                      const SizedBox(height: 2),
                      Text(user?.phone ?? '', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: user == null ? null : _editProfile,
                  icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          _sectionLabel('Account'),
          if (_vehicle == null)
            _menuTile(
              icon: Icons.directions_car_outlined,
              label: 'Become a Driver',
              onTap: () => openDriverFlow(context),
            )
          else ...[
            _menuTile(
              icon: Icons.directions_car_outlined,
              label: 'My Vehicle',
              onTap: () => openDriverFlow(context),
            ),
            _buildModeSwitchTile(),
            if (user?.canDrive ?? false)
              _menuTile(
                icon: Icons.payments_outlined,
                label: 'Payout History',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const PayoutHistoryScreen()),
                ),
              ),
          ],
          const SizedBox(height: 18),
          _sectionLabel('Support'),
          _menuTile(
            icon: Icons.help_outline,
            label: 'Help & Support',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const HelpSupportScreen()),
            ),
          ),
          _menuTile(
            icon: Icons.description_outlined,
            label: 'Terms & Privacy Policy',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const TermsPrivacyScreen()),
            ),
          ),
          const SizedBox(height: 28),
          OutlinedButton.icon(
            onPressed: _logout,
            icon: const Icon(Icons.logout, color: AppColors.danger),
            label: const Text('Log out'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.danger,
              side: const BorderSide(color: AppColors.danger),
            ),
          ),
          const SizedBox(height: 18),
          const Center(
            child: Text('HolaRide v1.0.0', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildGuest() {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: buildAppHeader('Profile', showProfileIcon: false),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(color: AppColors.infoBg, shape: BoxShape.circle),
                  child: const Icon(Icons.person_outline, color: AppColors.primary, size: 32),
                ),
                const SizedBox(height: 14),
                const Text("You're browsing as a guest",
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                const SizedBox(height: 6),
                const Text(
                  'Log in or sign up to book trips, publish rides, and manage your account.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 18),
                PrimaryButton(label: 'Log in / Sign up', onPressed: _login),
              ],
            ),
          ),
          const SizedBox(height: 22),
          _sectionLabel('Support'),
          _menuTile(
            icon: Icons.help_outline,
            label: 'Help & Support',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const HelpSupportScreen()),
            ),
          ),
          _menuTile(
            icon: Icons.description_outlined,
            label: 'Terms & Privacy Policy',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const TermsPrivacyScreen()),
            ),
          ),
          const SizedBox(height: 18),
          const Center(
            child: Text('HolaRide v1.0.0', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildModeSwitchTile() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: _toggleDriverMode,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.infoBg,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Icon(_driverMode ? Icons.person_outline : Icons.directions_car, size: 20, color: AppColors.primary),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  _driverMode ? 'Switch to Passenger' : 'Switch to Driver',
                  style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary),
                ),
              ),
              const Icon(Icons.swap_horiz, color: AppColors.primary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 4),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
      ),
    );
  }

  Widget _menuTile({required IconData icon, required String label, required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: AppColors.primary),
              const SizedBox(width: 14),
              Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600))),
              const Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
