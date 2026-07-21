import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../models/user.dart';
import '../../models/vehicle.dart';
import '../../services/api_client.dart';
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
  ProfileStats? _stats;

  @override
  void initState() {
    super.initState();
    _loadUser();
    SessionService.instance.authChanged.addListener(_onAuthChanged);
    SessionService.instance.driverModeChanged.addListener(_onDriverModeChanged);
  }

  void _onAuthChanged() { if (mounted) _loadUser(); }

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
    ProfileStats? stats;
    if (loggedIn) {
      try { vehicle = await VehicleService.instance.getMyVehicle(); } catch (e) {
        // ignore: avoid_print
        print('Error in lib/screens/profile/profile_screen.dart: $e');
      }
      try {
        final res = await ApiClient.instance.get('/me/stats');
        if (res is Map<String, dynamic>) stats = ProfileStats.fromJson(res);
      } catch (e) {
        // ignore: avoid_print
        print('Error in lib/screens/profile/profile_screen.dart: $e');
      }
    }
    if (!mounted) return;
    setState(() {
      _loggedIn = loggedIn; _user = user; _vehicle = vehicle;
      _driverMode = driverMode; _stats = stats; _loading = false;
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
    final l = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l.profileLogoutTitle),
        content: Text(l.profileLogoutBody),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false),
              child: Text(l.cancel)),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l.profileLogout, style: const TextStyle(color: AppColors.danger)),
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

  String _monthYear(DateTime d) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(strokeWidth: 2.4)),
      );
    }
    if (!_loggedIn) return _buildGuest(l);

    final user = _user;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: buildAppHeader(l.profileTitle, showProfileIcon: false, showLanguageSwitcher: false),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildHeroCard(user),
          const SizedBox(height: 14),
          _buildStatsCard(),
          const SizedBox(height: 22),

          _sectionLabel(l.profileAccount),
          _menuTile(
            icon: Icons.person_outline,
            iconColor: AppColors.primary,
            label: 'Personal Information',
            subtitle: 'View and edit your details',
            onTap: user == null ? () {} : _editProfile,
          ),
          if (_vehicle == null)
            _menuTile(
              icon: Icons.directions_car_outlined,
              iconColor: AppColors.gold,
              label: l.profileBecomeDriver,
              subtitle: 'Earn money by offering rides',
              onTap: () => openDriverFlow(context),
            )
          else ...[
            _menuTile(
              icon: Icons.directions_car_outlined,
              iconColor: AppColors.gold,
              label: l.profileMyVehicle,
              subtitle: 'Manage your vehicle details',
              onTap: () => openDriverFlow(context),
            ),
            _buildModeSwitchTile(l),
            if (user?.canDrive ?? false)
              _menuTile(
                icon: Icons.payments_outlined,
                iconColor: AppColors.gold,
                label: l.profilePayoutHistory,
                subtitle: 'View your earnings',
                onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const PayoutHistoryScreen())),
              ),
          ],

          const SizedBox(height: 18),
          _sectionLabel(l.profileSupport),
          _menuTile(
            icon: Icons.help_outline,
            iconColor: AppColors.primary,
            label: l.profileHelpSupport,
            subtitle: "We're here to help you",
            onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const HelpSupportScreen())),
          ),

          const SizedBox(height: 18),
          _sectionLabel('Legal'),
          _menuTile(
            icon: Icons.description_outlined,
            iconColor: AppColors.textSecondary,
            label: l.profileTermsPrivacy,
            subtitle: 'Read our terms and privacy policy',
            onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const TermsPrivacyScreen())),
          ),

          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton.icon(
              onPressed: _logout,
              icon: const Icon(Icons.logout, color: AppColors.danger),
              label: Text(l.profileLogout, style: const TextStyle(fontWeight: FontWeight.w700)),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.danger,
                side: const BorderSide(color: AppColors.danger),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Center(child: Text(l.profileVersion,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12))),
        ],
      ),
    );
  }

  Widget _buildHeroCard(AppUser? user) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: Container(
        decoration: const BoxDecoration(color: AppColors.infoBg),
        child: Stack(children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.9,
              child: Image.asset(
                'assets/images/hero_road.png',
                fit: BoxFit.cover,
                alignment: Alignment.centerRight,
                errorBuilder: (_, __, ___) => const SizedBox(),
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    AppColors.infoBg,
                    AppColors.infoBg.withOpacity(0.75),
                    AppColors.infoBg.withOpacity(0.1),
                  ],
                  stops: const [0, 0.5, 0.95],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: AppColors.primary,
                    child: Text(
                      user != null && user.displayName.isNotEmpty
                          ? user.displayName[0].toUpperCase() : '?',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 26),
                    ),
                  ),
                  Positioned(
                    right: -2, bottom: -2,
                    child: InkWell(
                      onTap: user == null ? null : _editProfile,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        width: 26, height: 26,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Icon(Icons.camera_alt_outlined, size: 13, color: AppColors.textSecondary),
                      ),
                    ),
                  ),
                ]),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Flexible(
                          child: Text(user?.displayName ?? '...',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 19)),
                        ),
                        if (user?.isVerified ?? false) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.14),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              const Icon(Icons.verified, size: 12, color: AppColors.primary),
                              const SizedBox(width: 4),
                              const Text('Verified',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary)),
                            ]),
                          ),
                        ],
                      ]),
                      const SizedBox(height: 8),
                      Row(children: [
                        const Icon(Icons.phone_outlined, size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 6),
                        Text(user?.phone ?? '',
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                      ]),
                      if (user?.memberSince != null) ...[
                        const SizedBox(height: 4),
                        Row(children: [
                          const Icon(Icons.calendar_today_outlined, size: 13, color: AppColors.textSecondary),
                          const SizedBox(width: 6),
                          Text('Member since ${_monthYear(user!.memberSince!)}',
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
                        ]),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildStatsCard() {
    final stats = _stats;
    final memberSince = _user?.memberSince;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(children: [
        Expanded(
          child: _statItem(
            icon: Icons.directions_car_outlined,
            iconColor: AppColors.primary,
            value: '${stats?.tripsCompleted ?? 0}',
            label: 'Trips completed',
          ),
        ),
        Container(height: 40, width: 1, color: AppColors.border),
        Expanded(
          child: _statItem(
            icon: Icons.star_rounded,
            iconColor: AppColors.gold,
            value: stats?.averageRating != null ? stats!.averageRating!.toStringAsFixed(1) : '—',
            label: 'Average rating',
          ),
        ),
        Container(height: 40, width: 1, color: AppColors.border),
        Expanded(
          child: _statItem(
            icon: Icons.calendar_today_outlined,
            iconColor: AppColors.primary,
            value: memberSince != null ? _monthYear(memberSince) : '—',
            label: 'Member since',
            valueFontSize: 14,
          ),
        ),
      ]),
    );
  }

  Widget _statItem({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
    double valueFontSize = 18,
  }) {
    return Column(children: [
      Container(
        width: 34, height: 34,
        decoration: BoxDecoration(color: iconColor.withOpacity(0.12), shape: BoxShape.circle),
        child: Icon(icon, size: 17, color: iconColor),
      ),
      const SizedBox(height: 8),
      Text(value, style: TextStyle(fontWeight: FontWeight.w800, fontSize: valueFontSize)),
      const SizedBox(height: 2),
      Text(label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 10.5, color: AppColors.textSecondary)),
    ]);
  }

  Widget _buildGuest(AppLocalizations l) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: buildAppHeader(l.profileTitle, showProfileIcon: false),
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
            child: Column(children: [
              Container(
                width: 64, height: 64,
                decoration: const BoxDecoration(color: AppColors.infoBg, shape: BoxShape.circle),
                child: const Icon(Icons.person_outline, color: AppColors.primary, size: 32),
              ),
              const SizedBox(height: 14),
              Text(l.profileGuestTitle,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              const SizedBox(height: 6),
              Text(l.profileGuestBody,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              const SizedBox(height: 18),
              PrimaryButton(label: l.profileLoginSignup, onPressed: _login),
            ]),
          ),
          const SizedBox(height: 22),
          _sectionLabel(l.profileSupport),
          _menuTile(
            icon: Icons.help_outline,
            iconColor: AppColors.primary,
            label: l.profileHelpSupport,
            subtitle: "We're here to help you",
            onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const HelpSupportScreen())),
          ),
          _menuTile(
            icon: Icons.description_outlined,
            iconColor: AppColors.textSecondary,
            label: l.profileTermsPrivacy,
            subtitle: 'Read our terms and privacy policy',
            onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const TermsPrivacyScreen())),
          ),
          const SizedBox(height: 18),
          Center(child: Text(l.profileVersion,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12))),
        ],
      ),
    );
  }

  Widget _buildModeSwitchTile(AppLocalizations l) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: _toggleDriverMode,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(color: AppColors.infoBg, borderRadius: BorderRadius.circular(14)),
          child: Row(children: [
            Icon(_driverMode ? Icons.person_outline : Icons.directions_car, size: 20, color: AppColors.primary),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                _driverMode ? l.profileSwitchToPassenger : l.profileSwitchToDriver,
                style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary),
              ),
            ),
            const Icon(Icons.swap_horiz, color: AppColors.primary),
          ]),
        ),
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 4),
      child: Text(label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
    );
  }

  Widget _menuTile({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(color: iconColor.withOpacity(0.12), shape: BoxShape.circle),
              child: Icon(icon, size: 19, color: iconColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ]),
        ),
      ),
    );
  }
}