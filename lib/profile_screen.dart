import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _selectedLanguage = 'Türkçe (TR)';
  bool _isDarkMode = true;

  // --- SAHTE VERİLER (BİLDİRİMLER VE TAKVİM İÇİN) ---
  final List<Map<String, dynamic>> _notifications = [
    {'title': 'İzin Onayı', 'desc': '27-28 Temmuz tarihlerindeki yıllık izin talebiniz onaylandı.', 'time': '10 dk önce', 'isRead': false},
    {'title': 'Yeni Bordro', 'desc': 'Haziran 2026 dönemine ait maaş bordronuz yayınlandı.', 'time': '2 saat önce', 'isRead': false},
    {'title': 'Sistem Güncellemesi', 'desc': 'Uygulamamız İK süreçlerinizi kolaylaştırmak için güncellendi.', 'time': 'Dün', 'isRead': true},
  ];

  // Temmuz 2026 İzin ve Önemli Günleri (Örn: 15 Temmuz Resmi Tatil, 27-28 Temmuz Yıllık İzin)
  final List<int> _approvedLeaveDays = [27, 28];
  final List<int> _importantDays = [15];

  // --- EKSİKSİZ DİL SÖZLÜĞÜ ---
  final Map<String, Map<String, String>> _localizedTexts = {
    'Türkçe (TR)': {
      'title': 'Profilim',
      'dept': 'Departman',
      'dept_val': 'Yazılım Geliştirme',
      'pos': 'Pozisyon',
      'pos_val': 'Kıdemli Mobil Geliştirici',
      'date': 'İşe Giriş Tarihi',
      'app_settings': 'Uygulama Ayarları',
      'dark_mode': 'Koyu Tema',
      'lang': 'Uygulama Dili',
      'sec_support': 'Hesap Güvenliği & Destek',
      'change_pass': 'Şifre Değiştir',
      'help': 'Yardım & Destek',
      'logout': 'Çıkış Yap',
      'leave_stats': 'İzin Özet Bilgileri',
      'leave_remain': 'Kalan İzin',
      'leave_used': 'Kullanılan İzin',
      'recent_activity': 'Son QR Giriş/Çıkış Hareketleri',
      'docs': 'Kurumsal Dokümanlar & Bordro',
      'payroll': 'Maaş Bordroları (PDF)',
      'kvkk': 'KVKK Aydınlatma Metni',
      'in': 'Giriş',
      'out': 'Çıkış',
      'close': 'Kapat',
      'kvkk_title': 'KVKK ve Veri Güvenliği',
      'kvkk_text': 'Faydam Bilişim bünyesinde kişisel verileriniz 6698 sayılı KVKK kapsamında hassasiyetle korunmaktadır.',
      'change_pass_title': 'Şifre Yenileme',
      'current_pass': 'Mevcut Şifre',
      'new_pass': 'Yeni Şifre',
      'save': 'Güncelle',
      'help_title': 'Destek Merkezi',
      'help_text': 'Herhangi bir sorun yaşarsanız İnsan Kaynakları departmanına ik@faydam.com adresinden ulaşabilirsiniz.',
      'create_ticket': 'Destek Talebi Oluştur',
      'logout_confirm_title': 'Çıkış Yapılsın mı?',
      'logout_confirm_desc': 'Hesabınızdan çıkış yapmak istediğinize emin misiniz?',
      'cancel': 'İptal',
      'yes_logout': 'Evet, Çıkış Yap',
      'ticket_title': 'Yeni Destek Talebi',
      'ticket_hint': 'Lütfen sorununuzu detaylıca açıklayın...',
      'send': 'Gönder',
      'ticket_success': 'Destek talebiniz başarıyla alınmıştır.',
      'notifications_title': 'Bildirimler',
      'calendar_title': 'İK & İzin Takvimi',
      'approved_leave': 'İzin',
      'important_day': 'Tatil',
    },
    'English (EN)': {
      'title': 'My Profile',
      'dept': 'Department',
      'dept_val': 'Software Development',
      'pos': 'Position',
      'pos_val': 'Senior Mobile Developer',
      'date': 'Hire Date',
      'app_settings': 'Application Settings',
      'dark_mode': 'Dark Mode',
      'lang': 'Language',
      'sec_support': 'Security & Support',
      'change_pass': 'Change Password',
      'help': 'Help & Support',
      'logout': 'Log Out',
      'leave_stats': 'Leave Balance Summary',
      'leave_remain': 'Remaining Leave',
      'leave_used': 'Used Leave',
      'recent_activity': 'Recent QR Check-In/Out Activity',
      'docs': 'Corporate Documents & Payroll',
      'payroll': 'Payslips (PDF)',
      'kvkk': 'Privacy Policy (KVKK)',
      'in': 'Check-In',
      'out': 'Check-Out',
      'close': 'Close',
      'kvkk_title': 'KVKK & Data Security',
      'kvkk_text': 'Within Faydam IT, your personal data is protected with high sensitivity under Law No. 6698.',
      'change_pass_title': 'Reset Password',
      'current_pass': 'Current Password',
      'new_pass': 'New Password',
      'save': 'Update',
      'help_title': 'Support Center',
      'help_text': 'If you face any technical issues, you can contact the HR department at hr@faydam.com.',
      'create_ticket': 'Create Support Ticket',
      'logout_confirm_title': 'Log Out?',
      'logout_confirm_desc': 'Are you sure you want to log out of your account?',
      'cancel': 'Cancel',
      'yes_logout': 'Yes, Log Out',
      'ticket_title': 'New Support Ticket',
      'ticket_hint': 'Please describe your problem in detail...',
      'send': 'Send',
      'ticket_success': 'Your support ticket has been submitted successfully.',
      'notifications_title': 'Notifications',
      'calendar_title': 'HR & Leave Calendar',
      'approved_leave': 'Leave',
      'important_day': 'Holiday',
    }
  };

  String _t(String key) {
    return _localizedTexts[_selectedLanguage]?[key] ?? key;
  }

  static const Color neonTurquoise = Color(0xFF00E5FF);
  static const Color darkNavy = Color(0xFF0A0E1A);
  static const Color cardNavy = Color(0xFF151D30);
  static const Color lightBackground = Color(0xFFF4F6F9);

  // --- BİLDİRİMLER PANELLİ (BOTTOM SHEET) ---
  void _showNotificationsBottomSheet(BuildContext context, Color cardBg, Color textColor, Color subTextColor) {
    showModalBottomSheet(
      context: context,
      backgroundColor: cardBg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_t('notifications_title'), style: TextStyle(color: textColor, fontSize: 20, fontWeight: FontWeight.bold)),
                    IconButton(icon: Icon(Icons.close, color: textColor), onPressed: () => Navigator.pop(context)),
                  ],
                ),
                const SizedBox(height: 10),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: _notifications.length,
                    separatorBuilder: (context, index) => Divider(color: textColor.withOpacity(0.05)),
                    itemBuilder: (context, index) {
                      final notif = _notifications[index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: notif['isRead'] ? Colors.grey.withOpacity(0.1) : neonTurquoise.withOpacity(0.1),
                          child: Icon(
                            notif['isRead'] ? CupertinoIcons.bell : CupertinoIcons.bell_fill,
                            color: notif['isRead'] ? Colors.grey : neonTurquoise,
                          ),
                        ),
                        title: Text(notif['title'], style: TextStyle(color: textColor, fontWeight: notif['isRead'] ? FontWeight.normal : FontWeight.bold)),
                        subtitle: Text(notif['desc'], style: TextStyle(color: subTextColor, fontSize: 13)),
                        trailing: Text(notif['time'], style: TextStyle(color: subTextColor.withOpacity(0.6), fontSize: 11)),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- ÇIKIŞ YAPMA DİYALOGU ---
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: Text(_t('logout_confirm_title')),
          content: Padding(padding: const EdgeInsets.only(top: 8.0), child: Text(_t('logout_confirm_desc'))),
          actions: [
            CupertinoDialogAction(child: Text(_t('cancel'), style: const TextStyle(color: Colors.grey)), onPressed: () => Navigator.pop(context)),
            CupertinoDialogAction(
              isDestructiveAction: true,
              child: Text(_t('yes_logout')),
              onPressed: () {
                Navigator.pop(context);
                try {
                  Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
                } catch (e) {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                }
              },
            ),
          ],
        );
      },
    );
  }

  // --- DESTEK TALEBİ OLUŞTURMA DİYALOGU ---
  void _showCreateTicketDialog(BuildContext context, Color cardBg, Color textColor, Color subTextColor) {
    final TextEditingController ticketController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: cardBg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(_t('ticket_title'), style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold)),
          content: TextField(
            controller: ticketController,
            maxLines: 4,
            style: TextStyle(color: textColor),
            decoration: InputDecoration(
              hintText: _t('ticket_hint'),
              hintStyle: TextStyle(color: subTextColor.withOpacity(0.5), fontSize: 14),
              filled: true,
              fillColor: textColor.withOpacity(0.05),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text(_t('cancel'), style: const TextStyle(color: Colors.grey))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: neonTurquoise, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
              onPressed: () {
                if (ticketController.text.trim().isNotEmpty) {
                  Navigator.pop(context);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_t('ticket_success')), backgroundColor: Colors.green, behavior: SnackBarBehavior.floating));
                }
              },
              child: Text(_t('send'), style: const TextStyle(color: darkNavy, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _showDetailBottomSheet(BuildContext context, String title, Widget content, Color cardBg, Color textColor) {
    showModalBottomSheet(
      context: context,
      backgroundColor: cardBg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(title, style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold)),
                    IconButton(icon: Icon(Icons.close, color: textColor.withOpacity(0.6)), onPressed: () => Navigator.pop(context)),
                  ],
                ),
                const SizedBox(height: 16),
                content,
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  // Haftanın gün adını döndüren basit yardımcı fonksiyon
  String _getDayName(int dayIndex) {
    List<String> days = ['Pz', 'Pt', 'Sa', 'Ça', 'Pe', 'Cu', 'Ct'];
    return days[dayIndex % 7];
  }

  @override
  Widget build(BuildContext context) {
    final cardBg = _isDarkMode ? cardNavy : Colors.white;
    final textColor = _isDarkMode ? Colors.white : darkNavy;
    final subTextColor = _isDarkMode ? Colors.grey[400]! : Colors.grey[600]!;

    int unreadNotificationsCount = _notifications.where((n) => !n['isRead']).length;

    return Scaffold(
      backgroundColor: _isDarkMode ? darkNavy : lightBackground,
      appBar: AppBar(
        title: Text(_t('title'), style: TextStyle(color: textColor, fontSize: 20, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
        actions: [
          IconButton(
            icon: Badge(
              label: Text(unreadNotificationsCount.toString()),
              isLabelVisible: unreadNotificationsCount > 0,
              backgroundColor: Colors.redAccent,
              child: Icon(CupertinoIcons.bell_fill, color: textColor),
            ),
            onPressed: () => _showNotificationsBottomSheet(context, cardBg, textColor, subTextColor),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 1. Kullanıcı Bilgileri
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      CircleAvatar(radius: 36, backgroundColor: neonTurquoise.withOpacity(0.1), child: const Icon(CupertinoIcons.person_solid, color: neonTurquoise, size: 40)),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Demo Personel", style: TextStyle(color: textColor, fontSize: 20, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text("personel@faydam.com", style: TextStyle(color: subTextColor, fontSize: 14)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Divider(color: (_isDarkMode ? Colors.white : Colors.black).withOpacity(0.05)),
                  const SizedBox(height: 12),
                  _buildProfileDetailRow(_t('dept'), _t('dept_val'), textColor, subTextColor),
                  const SizedBox(height: 10),
                  _buildProfileDetailRow(_t('pos'), _t('pos_val'), textColor, subTextColor),
                  const SizedBox(height: 10),
                  _buildProfileDetailRow(_t('date'), "15.01.2024", textColor, subTextColor),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 2. KÜÇÜLTÜLMÜŞ YATAY ŞERİT TAKVİM (YENİ 📆)
            _buildSectionHeader(_t('calendar_title'), subTextColor),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
              decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(18)),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Temmuz 2026", style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.bold)),
                        Row(
                          children: [
                            _buildCalendarLegend(_t('approved_leave'), neonTurquoise, subTextColor),
                            const SizedBox(width: 8),
                            _buildCalendarLegend(_t('important_day'), Colors.redAccent, subTextColor),
                          ],
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 64,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: 31, // Ayın gün sayısı
                      itemBuilder: (context, index) {
                        final dayNum = index + 1;
                        // Örnek gün isimleri eşleşmesi (Temmuz 2026 Çarşamba ile başlıyor)
                        String dayName = _getDayName(index + 3); 

                        bool isLeave = _approvedLeaveDays.contains(dayNum);
                        bool isImportant = _importantDays.contains(dayNum);
                        bool isToday = (dayNum == 22); // Bugünün tarihi (Demo için 22 Temmuz)

                        return Container(
                          width: 48,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: isToday 
                                ? neonTurquoise 
                                : (isLeave ? neonTurquoise.withOpacity(0.12) : (isImportant ? Colors.redAccent.withOpacity(0.12) : Colors.transparent)),
                            borderRadius: BorderRadius.circular(12),
                            border: isToday 
                                ? null 
                                : (isLeave ? Border.all(color: neonTurquoise.withOpacity(0.5)) : (isImportant ? Border.all(color: Colors.redAccent.withOpacity(0.5)) : null)),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(dayName, style: TextStyle(color: isToday ? darkNavy : subTextColor.withOpacity(0.7), fontSize: 11, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text(dayNum.toString(), style: TextStyle(color: isToday ? darkNavy : textColor, fontWeight: FontWeight.bold, fontSize: 14)),
                              if (!isToday && (isLeave || isImportant)) ...[
                                const SizedBox(height: 2),
                                CircleAvatar(radius: 2, backgroundColor: isLeave ? neonTurquoise : Colors.redAccent),
                              ]
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 3. İzin İstatistikleri
            _buildSectionHeader(_t('leave_stats'), subTextColor),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(16)),
              child: Row(
                children: [
                  _buildMiniStatBox(_t('leave_remain'), "18 Gün", neonTurquoise, _isDarkMode),
                  Container(width: 1, height: 40, color: _isDarkMode ? Colors.white10 : Colors.black12),
                  _buildMiniStatBox(_t('leave_used'), "12 Gün", Colors.orangeAccent, _isDarkMode),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 4. Ayarlar
            _buildSectionHeader(_t('app_settings'), subTextColor),
            Container(
              decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: [
                  SwitchListTile(
                    secondary: const Icon(CupertinoIcons.moon_fill, color: neonTurquoise),
                    title: Text(_t('dark_mode'), style: TextStyle(color: textColor, fontWeight: FontWeight.w500)),
                    value: _isDarkMode,
                    activeColor: neonTurquoise,
                    onChanged: (bool value) { setState(() { _isDarkMode = value; }); },
                  ),
                  Divider(height: 1, color: Colors.white.withOpacity(0.05)),
                  ListTile(
                    leading: const Icon(CupertinoIcons.globe, color: neonTurquoise),
                    title: Text(_t('lang'), style: TextStyle(color: textColor, fontWeight: FontWeight.w500)),
                    trailing: DropdownButton<String>(
                      value: _selectedLanguage,
                      dropdownColor: cardBg,
                      underline: const SizedBox(),
                      style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
                      icon: Icon(Icons.arrow_drop_down, color: subTextColor),
                      items: <String>['Türkçe (TR)', 'English (EN)'].map((String value) { return DropdownMenuItem<String>(value: value, child: Text(value)); }).toList(),
                      onChanged: (String? newValue) { if (newValue != null) { setState(() { _selectedLanguage = newValue; }); } },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 5. Son QR Hareketleri
            _buildSectionHeader(_t('recent_activity'), subTextColor),
            Container(
              decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: [
                  _buildActivityRow("Bugün / Today", "09:02", _t('in'), Colors.greenAccent, textColor),
                  Divider(height: 1, color: Colors.white.withOpacity(0.05)),
                  _buildActivityRow("Dün / Yesterday", "18:05", _t('out'), neonTurquoise, textColor),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 6. Kurumsal Dokümanlar & Bordro
            _buildSectionHeader(_t('docs'), subTextColor),
            Container(
              decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(CupertinoIcons.doc_text_fill, color: Colors.amberAccent),
                    title: Text(_t('payroll'), style: TextStyle(color: textColor, fontWeight: FontWeight.w500)),
                    trailing: Icon(Icons.chevron_right, color: subTextColor),
                    onTap: () {
                      _showDetailBottomSheet(context, _t('payroll'), Column(
                        children: [
                          _buildDocDownloadRow("Haziran 2026 / June 2026", textColor),
                          const Divider(color: Colors.white10),
                          _buildDocDownloadRow("Mayıs 2026 / May 2026", textColor),
                        ],
                      ), cardBg, textColor);
                    },
                  ),
                  Divider(height: 1, color: Colors.white.withOpacity(0.05)),
                  ListTile(
                    leading: const Icon(CupertinoIcons.shield_fill, color: Colors.blueAccent),
                    title: Text(_t('kvkk'), style: TextStyle(color: textColor, fontWeight: FontWeight.w500)),
                    trailing: Icon(Icons.chevron_right, color: subTextColor),
                    onTap: () {
                      _showDetailBottomSheet(context, _t('kvkk_title'), Text(_t('kvkk_text'), style: TextStyle(color: textColor.withOpacity(0.8), fontSize: 14, height: 1.5)), cardBg, textColor);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 7. Hesap Güvenliği & Destek
            _buildSectionHeader(_t('sec_support'), subTextColor),
            Container(
              decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(CupertinoIcons.lock_fill, color: Colors.purpleAccent),
                    title: Text(_t('change_pass'), style: TextStyle(color: textColor, fontWeight: FontWeight.w500)),
                    trailing: Icon(Icons.chevron_right, color: subTextColor),
                    onTap: () {
                      _showDetailBottomSheet(context, _t('change_pass_title'), Column(
                        children: [
                          _buildInputField(_t('current_pass'), true, textColor, subTextColor),
                          const SizedBox(height: 12),
                          _buildInputField(_t('new_pass'), true, textColor, subTextColor),
                          const SizedBox(height: 20),
                          SizedBox(width: double.infinity, height: 46, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: neonTurquoise), onPressed: () => Navigator.pop(context), child: Text(_t('save'), style: const TextStyle(color: darkNavy, fontWeight: FontWeight.bold))))
                        ],
                      ), cardBg, textColor);
                    },
                  ),
                  Divider(height: 1, color: Colors.white.withOpacity(0.05)),
                  ListTile(
                    leading: const Icon(CupertinoIcons.question_circle_fill, color: Colors.tealAccent),
                    title: Text(_t('help'), style: TextStyle(color: textColor, fontWeight: FontWeight.w500)),
                    trailing: Icon(Icons.chevron_right, color: subTextColor),
                    onTap: () {
                      _showDetailBottomSheet(context, _t('help_title'), Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_t('help_text'), style: TextStyle(color: textColor.withOpacity(0.8), fontSize: 14, height: 1.5)),
                          const SizedBox(height: 20),
                          SizedBox(width: double.infinity, height: 46, child: OutlinedButton(style: OutlinedButton.styleFrom(side: const BorderSide(color: neonTurquoise)), onPressed: () => _showCreateTicketDialog(context, cardBg, textColor, subTextColor), child: Text(_t('create_ticket'), style: const TextStyle(color: neonTurquoise, fontWeight: FontWeight.bold))))
                        ],
                      ), cardBg, textColor);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // 8. Çıkış Yap Butonu
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent.withOpacity(0.1), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Colors.redAccent, width: 1))),
                onPressed: () => _showLogoutDialog(context),
                child: Text(_t('logout'), style: const TextStyle(color: Colors.redAccent, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- YARDIMCI BİLEŞENLER ---
  Widget _buildCalendarLegend(String label, Color color, Color subTextColor) {
    return Row(
      children: [
        CircleAvatar(radius: 3, backgroundColor: color),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(color: subTextColor, fontSize: 11)),
      ],
    );
  }

  Widget _buildSectionHeader(String title, Color subTextColor) {
    return Align(alignment: Alignment.centerLeft, child: Padding(padding: const EdgeInsets.only(left: 8, bottom: 8, top: 8), child: Text(title, style: TextStyle(color: subTextColor, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1))));
  }

  Widget _buildProfileDetailRow(String label, String value, Color textColor, Color subTextColor) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: TextStyle(color: subTextColor, fontSize: 14)), Text(value, style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.bold))]);
  }

  Widget _buildMiniStatBox(String label, String value, Color color, bool isDark) {
    return Expanded(child: Column(children: [Text(label, style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600], fontSize: 13)), const SizedBox(height: 4), Text(value, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold))]));
  }

  Widget _buildActivityRow(String day, String time, String type, Color color, Color textColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(children: [Icon(CupertinoIcons.time, color: Colors.grey[400], size: 18), const SizedBox(width: 8), Text(day, style: TextStyle(color: textColor, fontSize: 14))]),
          Row(children: [Text(time, style: TextStyle(color: Colors.grey[400], fontSize: 14)), const SizedBox(width: 12), Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Text(type, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)))]),
        ],
      ),
    );
  }

  Widget _buildDocDownloadRow(String title, Color textColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(title, style: TextStyle(color: textColor, fontSize: 14)), IconButton(icon: const Icon(CupertinoIcons.cloud_download, color: neonTurquoise), onPressed: () {})],
      ),
    );
  }

  Widget _buildInputField(String hint, bool isPassword, Color textColor, Color subTextColor) {
    return TextField(
      obscureText: isPassword,
      style: TextStyle(color: textColor),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: subTextColor.withOpacity(0.7)),
        filled: true,
        fillColor: textColor.withOpacity(0.05),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}