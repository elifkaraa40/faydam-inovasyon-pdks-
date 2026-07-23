import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app_provider.dart';
import 'login_screen.dart' hide AppColors;
import 'services/api_service.dart';
import 'utils/download_file.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ApiService _apiService = ApiService();
  Map<String, dynamic>? _profile;
  List<Map<String, dynamic>> _deviceSessions = const [];
  bool _isLoading = true;
  bool _isLoggingOut = false;
  bool _isSaving = false;
  bool _isExporting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final value = await _apiService.getUserProfile();
      final devices = await _apiService.getDeviceSessions();
      if (!mounted) return;
      setState(() {
        _profile = value;
        _deviceSessions = devices
            .where((device) => device['revokedAt'] == null)
            .toList(growable: false);
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String? _value(List<String> keys) {
    for (final key in keys) {
      final value = _profile?[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    }
    return null;
  }

  Future<void> _logout() async {
    if (_isLoggingOut) return;
    setState(() => _isLoggingOut = true);
    try {
      await _apiService.logout();
    } catch (_) {
      await _apiService.clearSession();
    }
    if (!mounted) return;
    context.read<AppSettings>().logout();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  Future<void> _editAccount() async {
    final phone = TextEditingController(text: _value(['phoneNumber']) ?? '');
    var emailEnabled = _profile?['isEmailNotificationEnabled'] == true;
    var smsEnabled = _profile?['isSmsNotificationEnabled'] == true;
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Hesap ayarları'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: phone,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Telefon numarası',
                    hintText: '+90 5xx xxx xx xx',
                  ),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('E-posta bildirimleri'),
                  value: emailEnabled,
                  onChanged: (value) =>
                      setDialogState(() => emailEnabled = value),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('SMS bildirimleri'),
                  value: smsEnabled,
                  onChanged: (value) =>
                      setDialogState(() => smsEnabled = value),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('İptal'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Kaydet'),
            ),
          ],
        ),
      ),
    );
    if (saved != true || !mounted) {
      phone.dispose();
      return;
    }
    setState(() => _isSaving = true);
    try {
      final profile = await _apiService.updateUserProfile(
        phoneNumber: phone.text.trim().isEmpty ? null : phone.text.trim(),
        isEmailNotificationEnabled: emailEnabled,
        isSmsNotificationEnabled: smsEnabled,
      );
      if (mounted) {
        setState(() => _profile = profile);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Hesap ayarları güncellendi.')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$error'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      phone.dispose();
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _exportPersonalData() async {
    if (_isExporting) return;
    setState(() => _isExporting = true);
    try {
      final bytes = await _apiService.exportPersonalData();
      final path = await downloadFile(
        bytes,
        'personal-data-${DateTime.now().toIso8601String().substring(0, 10)}.json',
        'application/json',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kişisel veri dosyası hazırlandı: $path')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$error'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _logoutAllDevices() async {
    if (_isLoggingOut) return;
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Tüm cihazlardan çıkış yap'),
        content: const Text(
          'Telefonunuz dahil bu hesaba bağlı tüm cihaz oturumları kapatılacak. Devam etmek istiyor musunuz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Tümünden çıkış yap'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _isLoggingOut = true);
    try {
      await _apiService.logoutAllDevices();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$error'), backgroundColor: Colors.redAccent),
        );
        setState(() => _isLoggingOut = false);
      }
      return;
    }
    if (!mounted) return;
    context.read<AppSettings>().logout();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  String _formatSessionTime(Object? value) {
    final parsed = DateTime.tryParse(value?.toString() ?? '');
    if (parsed == null) return '-';
    final local = parsed.toLocal();
    String two(int number) => number.toString().padLeft(2, '0');
    return '${two(local.day)}.${two(local.month)}.${local.year} '
        '${two(local.hour)}:${two(local.minute)}';
  }

  Future<void> _chooseLanguage() async {
    final selected = await showDialog<String>(
        context: context,
        builder: (context) => SimpleDialog(
              title: const Text('Dil ayarı'),
              children: ['Türkçe (TR)', 'English (EN)']
                  .map((value) => SimpleDialogOption(
                      onPressed: () => Navigator.pop(context, value),
                      child: Text(value)))
                  .toList(),
            ));
    if (selected != null && mounted) {
      context.read<AppSettings>().setLanguage(selected);
    }
  }

  void _showSupport() => showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
            title: const Text('Yardım ve destek'),
            content: const Text(
                'Bir sorun yaşarsanız yöneticinizle iletişime geçin veya destek ekibine ulaşın.'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Kapat'))
            ],
          ));

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettings>();
    final en = settings.isEnglish;
    final isDark = settings.isDarkMode;
    final cardBg = isDark ? AppColors.cardNavy : Colors.white;
    final textColor = isDark ? Colors.white : AppColors.darkNavy;
    final subTextColor = isDark ? Colors.white60 : Colors.black54;
    final name =
        _value(['fullName', 'name']) ?? settings.userName ?? 'Kullanıcı';
    final email = _value(['email']) ?? settings.userEmail;
    final department = _value(['departmentName', 'department']);
    final workplace = _value(['workplaceName', 'workplace']);
    final role = _value(['role']);
    final employeeNumber = _value(['employeeNumber']);
    final position = _value(['positionName', 'position', 'title']);
    final hireDate = _value(['hireDate', 'employmentStartDate']);
    final phone = _value(['phoneNumber']);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkNavy : AppColors.lightBackground,
      appBar: AppBar(
        title: Text(en ? 'My Profile' : 'Profilim',
            style: TextStyle(color: textColor)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(onPressed: _loadProfile, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadProfile,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(_error!,
                          style: const TextStyle(color: Colors.redAccent)),
                    ),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const CircleAvatar(
                              radius: 34,
                              backgroundColor: AppColors.darkNavy,
                              child: Icon(CupertinoIcons.person_fill,
                                  color: AppColors.neonTurquoise, size: 34),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(name,
                                      style: TextStyle(
                                          color: textColor,
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold)),
                                  if (email != null)
                                    Text(email,
                                        style: TextStyle(color: subTextColor)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (department != null) ...[
                          const SizedBox(height: 18),
                          _detail(
                              'Departman', department, textColor, subTextColor),
                        ],
                        if (position != null) ...[
                          const SizedBox(height: 10),
                          _detail(
                              'Pozisyon', position, textColor, subTextColor),
                        ],
                        if (hireDate != null) ...[
                          const SizedBox(height: 10),
                          _detail('İşe giriş tarihi', hireDate, textColor,
                              subTextColor),
                        ],
                        if (phone != null) ...[
                          const SizedBox(height: 10),
                          _detail('Telefon', phone, textColor, subTextColor),
                        ],
                        if (workplace != null) ...[
                          const SizedBox(height: 10),
                          _detail('İşyeri', workplace, textColor, subTextColor),
                        ],
                        if (role != null) ...[
                          const SizedBox(height: 10),
                          _detail('Rol', role, textColor, subTextColor),
                        ],
                        if (employeeNumber != null) ...[
                          const SizedBox(height: 10),
                          _detail('Sicil no', employeeNumber, textColor,
                              subTextColor),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.devices,
                              color: AppColors.neonTurquoise,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              en ? 'Active devices' : 'Aktif cihazlar',
                              style: TextStyle(
                                color: textColor,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (_deviceSessions.isEmpty)
                          Text(
                            en
                                ? 'No active device session was found.'
                                : 'Aktif cihaz oturumu bulunamadı.',
                            style: TextStyle(color: subTextColor),
                          )
                        else
                          ..._deviceSessions.map(
                            (device) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    device['isCurrentDevice'] == true
                                        ? Icons.smartphone
                                        : Icons.devices_other,
                                    color: AppColors.neonTurquoise,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          device['deviceName']?.toString() ??
                                              (en
                                                  ? 'Mobile device'
                                                  : 'Mobil cihaz'),
                                          style: TextStyle(
                                            color: textColor,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        Text(
                                          en
                                              ? 'Last active: ${_formatSessionTime(device['lastActiveAt'])}'
                                              : 'Son aktiflik: ${_formatSessionTime(device['lastActiveAt'])}',
                                          style: TextStyle(
                                            color: subTextColor,
                                            fontSize: 12,
                                          ),
                                        ),
                                        if (device['isCurrentDevice'] == true)
                                          Text(
                                            en ? 'This device' : 'Bu cihaz',
                                            style: const TextStyle(
                                              color: AppColors.neonTurquoise,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: _isLoggingOut ? null : _logoutAllDevices,
                    icon: const Icon(Icons.logout),
                    label: Text(
                      en
                          ? 'Log out from all devices'
                          : 'Tüm cihazlardan çıkış yap',
                    ),
                  ),
                  const SizedBox(height: 20),
                  SwitchListTile(
                    tileColor: cardBg,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    value: settings.isDarkMode,
                    onChanged: (_) => settings.toggleTheme(),
                    secondary: const Icon(CupertinoIcons.moon_fill,
                        color: AppColors.neonTurquoise),
                    title:
                        Text('Koyu Tema', style: TextStyle(color: textColor)),
                  ),
                  const SizedBox(height: 10),
                  ListTile(
                    tileColor: cardBg,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    leading: const Icon(Icons.language,
                        color: AppColors.neonTurquoise),
                    title: Text(en ? 'Language' : 'Dil ayarı',
                        style: TextStyle(color: textColor)),
                    subtitle: Text(settings.language,
                        style: TextStyle(color: subTextColor)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _chooseLanguage,
                  ),
                  const SizedBox(height: 10),
                  ListTile(
                    tileColor: cardBg,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    leading: const Icon(Icons.help_outline,
                        color: AppColors.neonTurquoise),
                    title: Text(en ? 'Help & Support' : 'Yardım ve destek',
                        style: TextStyle(color: textColor)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _showSupport,
                  ),
                  const SizedBox(height: 24),
                  OutlinedButton.icon(
                    onPressed: _isSaving ? null : _editAccount,
                    icon: const Icon(Icons.manage_accounts),
                    label: Text(_isSaving
                        ? (en ? 'Saving...' : 'Kaydediliyor...')
                        : (en ? 'Account settings' : 'Hesap ayarları')),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: _isExporting ? null : _exportPersonalData,
                    icon: _isExporting
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.download_outlined),
                    label: Text(
                        en ? 'Download my data' : 'Kişisel verilerimi indir'),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 52,
                    child: OutlinedButton(
                      onPressed: _isLoggingOut ? null : _logout,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.redAccent),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: _isLoggingOut
                          ? const CircularProgressIndicator()
                          : Text(en ? 'Log out' : 'Çıkış Yap',
                              style: const TextStyle(color: Colors.redAccent)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _detail(String label, String value, Color text, Color subText) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: subText)),
          Flexible(
              child: Text(value,
                  textAlign: TextAlign.end,
                  style: TextStyle(color: text, fontWeight: FontWeight.bold))),
        ],
      );
}
