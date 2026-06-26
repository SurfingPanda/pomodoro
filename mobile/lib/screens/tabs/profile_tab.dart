import 'package:flutter/material.dart';

import '../../services/app_settings.dart';
import '../../services/auth_service.dart';
import '../../theme.dart';
import '../../utils.dart';
import '../../widgets/panda_logo.dart';
import '../settings_screen.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  Future<void> _openSettings() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );
    if (mounted) setState(() {}); // reflect any goal change on return
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthService();
    final user = auth.currentUser;
    final name = user?.userMetadata?['name'] as String? ?? 'Panda';
    final email = user?.email ?? '';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.ink,
        titleSpacing: 20,
        title: const Text('Profile', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      extendBodyBehindAppBar: true,
      body: AppBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
            children: [
              const SizedBox(height: 12),
              Center(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: AppColors.ink.withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, 10)),
                        ],
                      ),
                      child: const PandaLogo(size: 80),
                    ),
                    const SizedBox(height: 14),
                    Text(name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.ink)),
                    const SizedBox(height: 2),
                    Text(email, style: const TextStyle(color: AppColors.muted)),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              _section([
                _row(Icons.tune_rounded, 'Settings', 'Auto-start, alerts, daily goal',
                    onTap: _openSettings),
              ]),
              const SizedBox(height: 16),
              _section([
                _row(Icons.verified_user_outlined, 'Authentication', 'Supabase Auth'),
                _row(Icons.flag_outlined, 'Daily goal', fmtMinutes(AppSettings.instance.dailyGoalMinutes)),
                _row(Icons.cloud_outlined, 'Data', 'Laravel API · Supabase Postgres'),
              ]),
              const SizedBox(height: 16),
              _section([
                _row(Icons.info_outline, 'Version', '1.0.0'),
              ]),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => auth.logout(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.accent,
                    side: const BorderSide(color: AppColors.accent),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  icon: const Icon(Icons.logout),
                  label: const Text('Log out', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _section(List<Widget> rows) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: AppColors.ink.withValues(alpha: 0.06), blurRadius: 16, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(children: rows),
    );
  }

  Widget _row(IconData icon, String label, String value, {VoidCallback? onTap}) {
    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: AppColors.field, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 18, color: AppColors.ink),
          ),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.ink)),
          const Spacer(),
          Flexible(
            child: Text(value,
                textAlign: TextAlign.right,
                style: const TextStyle(color: AppColors.muted, fontSize: 13)),
          ),
          if (onTap != null) ...[
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.muted),
          ],
        ],
      ),
    );
    if (onTap == null) return content;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: content,
    );
  }
}
