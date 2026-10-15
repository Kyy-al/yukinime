import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/constants/app_constants.dart';
import '../../providers/anime_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundSecondary,
        elevation: 0,
        title: Text(
            'Pengaturan',
            style: AppTypography.headlineSmall.copyWith(
              fontWeight: FontWeight.bold,
            ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        children: [
          // Section: Pemutaran Video
          _buildSectionTitle('PEMUTARAN VIDEO'),
          Card(
            color: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: AppColors.border, width: 0.8),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  activeTrackColor: AppColors.primary,
                  title: Text(
                    'Putar Otomatis Episode Berikutnya',
                    style: AppTypography.titleSmall,
                  ),
                  subtitle: Text(
                    'Lanjutkan ke episode selanjutnya saat video selesai',
                    style: AppTypography.bodySmall,
                  ),
                  value: settings.autoplayNext,
                  onChanged: (val) {
                    ref.read(settingsProvider.notifier).setAutoplayNext(val);
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  title: Text(
                    'Kualitas Default Video',
                    style: AppTypography.titleSmall,
                  ),
                  subtitle: Text(
                    'Pilihan resolusi utama saat memutar',
                    style: AppTypography.bodySmall,
                  ),
                  trailing: DropdownButton<String>(
                    value: settings.defaultQuality,
                    dropdownColor: AppColors.surfaceElevated,
                    underline: const SizedBox(),
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.accent),
                    items: const [
                      DropdownMenuItem(
                        value: '720p',
                        child: Text('720p HD', style: TextStyle(color: Colors.white)),
                      ),
                      DropdownMenuItem(
                        value: '480p',
                        child: Text('480p SD', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        ref.read(settingsProvider.notifier).setDefaultQuality(val);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Section: Penyimpanan & Data
          _buildSectionTitle('PENYIMPANAN & DATA'),
          Card(
            color: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: AppColors.border, width: 0.8),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.history_rounded, color: AppColors.textSecondary),
                  title: Text('Hapus Riwayat Tontonan', style: AppTypography.titleSmall),
                  trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary),
                  onTap: () async {
                    final confirm = await _showConfirmDialog(
                      context,
                      title: 'Hapus Riwayat',
                      content: 'Apakah Anda yakin ingin menghapus seluruh riwayat tontonan?',
                    );
                    if (confirm == true) {
                      ref.read(watchHistoryProvider.notifier).clearAll();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Riwayat berhasil dihapus')),
                        );
                      }
                    }
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.manage_search_rounded, color: AppColors.textSecondary),
                  title: Text('Hapus Riwayat Pencarian', style: AppTypography.titleSmall),
                  trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary),
                  onTap: () async {
                    final confirm = await _showConfirmDialog(
                      context,
                      title: 'Hapus Pencarian',
                      content: 'Apakah Anda yakin ingin menghapus seluruh kata kunci pencarian?',
                    );
                    if (confirm == true) {
                      ref.read(searchHistoryProvider.notifier).clearAll();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Riwayat pencarian dihapus')),
                        );
                      }
                    }
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Section: Tentang Aplikasi
          _buildSectionTitle('TENTANG YUKINIME'),
          Card(
            color: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: AppColors.border, width: 0.8),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 20),
                  ),
                  title: Text(AppConstants.appName, style: AppTypography.titleMedium),
                  subtitle: Text(
                    'Versi ${AppConstants.appVersion} • Midnight Anime Experience',
                    style: AppTypography.bodySmall,
                  ),
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'YUKINIME adalah aplikasi pemutar anime modern dengan desain gelap elegan dan stream cepat. Data disediakan melalui Sankavollerei Otakudesu API.',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textTertiary,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: AppTypography.labelSmall.copyWith(
          letterSpacing: 1.2,
          fontWeight: FontWeight.bold,
          color: AppColors.accent,
        ),
      ),
    );
  }

  Future<bool?> _showConfirmDialog(
    BuildContext context, {
    required String title,
    required String content,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.border),
        ),
        title: Text(title, style: AppTypography.titleMedium),
        content: Text(content, style: AppTypography.bodyMedium),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
