import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app_provider.dart';
import 'app_colors.dart' hide AppColors;

class IzinScreen extends StatefulWidget {
  const IzinScreen({super.key});

  @override
  State<IzinScreen> createState() => _IzinScreenState();
}

class _IzinScreenState extends State<IzinScreen> {
  String _seciliFiltre = "Tümü"; 

  // Türkçe karakter içermeyen temiz veri yapısı
  final List<Map<String, String>> _izinTalepleri = [
    {
      'turu': 'Ücretsiz İzni',
      'tarih': '2026-07-16 - 2026-09-30',
      'aciklama': 'Ailevi nedenlerden dolayı ücretsiz izin talebi.',
      'durum': 'Onaylandı',
      'gun': '76',
    },
    {
      'turu': 'Yıllık İzin',
      'tarih': '2026-06-01 - 2026-06-15',
      'aciklama': 'Yaz tatili planı.',
      'durum': 'Onaylandı',
      'gun': '14',
    },
    {
      'turu': 'Sağlık İzni',
      'tarih': '2026-04-12 - 2026-04-14',
      'aciklama': 'Diş tedavisi ve operasyon sonrası istirahat.',
      'durum': 'Onaylandı',
      'gun': '2',
    },
    {
      'turu': 'Mazeret İzni',
      'tarih': '2026-08-05 - 2026-08-06',
      'aciklama': 'Resmi kurum işlemleri için.',
      'durum': 'Beklemede',
      'gun': '1',
    },
  ];

  void _yeniIzinEkle(String turu, String baslangic, String bitis, String aciklama) {
    setState(() {
      _izinTalepleri.insert(0, {
        'turu': turu,
        'tarih': '$baslangic - $bitis',
        'aciklama': aciklama,
        'durum': 'Beklemede',
        'gun': '3', 
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<AppSettings>(context);
    final isDark = settings.isDarkMode;

    final cardBg = isDark ? AppColors.cardNavy : Colors.white;
    final textColor = isDark ? Colors.white : AppColors.darkNavy;

    // Hata veren değişken ismi düzeltildi
    final filtreliListe = _izinTalepleri.where((talep) {
      if (_seciliFiltre == "Tümü") return true;
      return talep['durum'] == _seciliFiltre;
    }).toList();

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkNavy : AppColors.lightBackground,
      appBar: AppBar(
        title: Text(
          "İzin Yönetimi",
          style: TextStyle(color: textColor, fontSize: 22, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: CustomScrollView(
        slivers: [
          // 1. Üst İstatistik Kartları
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  _buildStatCard("Kalan İzin", "18 Gün", AppColors.neonTurquoise, isDark),
                  const SizedBox(width: 12),
                  _buildStatCard("Kullanılan", "92 Gün", Colors.greenAccent, isDark),
                  const SizedBox(width: 12),
                  _buildStatCard("Bekleyen", "1 Talep", Colors.orangeAccent, isDark),
                ],
              ),
            ),
          ),

          // 2. Filtre Satırı
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: ["Tümü", "Onaylandı", "Beklemede"].map((filtre) {
                  final bool isSelected = _seciliFiltre == filtre; // Değişken ismi hatası çözüldü
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(
                        filtre,
                        style: TextStyle(
                          color: isSelected ? AppColors.darkNavy : (isDark ? Colors.white70 : Colors.black87),
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: AppColors.neonTurquoise,
                      backgroundColor: cardBg,
                      checkmarkColor: AppColors.darkNavy,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      side: BorderSide(color: isSelected ? AppColors.neonTurquoise : Colors.white10),
                      onSelected: (val) {
                        setState(() => _seciliFiltre = filtre);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // 3. İzin Kartları Listesi
          filtreliListe.isEmpty
              ? SliverFillRemaining(
                  child: Center(
                    child: Text("Bu kategoride izin bulunamadı.", style: TextStyle(color: Colors.grey[400])),
                  ),
                )
              : SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final talep = filtreliListe[index];
                        final durum = talep['durum']!;
                        
                        Color durumColor = Colors.orangeAccent;
                        IconData durumIcon = Icons.hourglass_empty_rounded;
                        
                        if (durum == 'Onaylandı') {
                          durumColor = Colors.greenAccent;
                          durumIcon = Icons.check_circle_outline_rounded;
                        }

                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withOpacity(0.05)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 10,
                                offset: const Offset(0, 6),
                              )
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Theme(
                              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                              child: ExpansionTile(
                                leading: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: durumColor.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(durumIcon, color: durumColor, size: 24),
                                ),
                                title: Text(
                                  talep['turu']!,
                                  style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                subtitle: Text(
                                  talep['tarih']!,
                                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                                ),
                                trailing: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: AppColors.darkNavy.withOpacity(0.5),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    "${talep['gun']} Gün",
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                ),
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20, top: 4),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Divider(color: Colors.white.withOpacity(0.05)),
                                        const SizedBox(height: 8),
                                        const Text(
                                          "Talep Açıklaması:",
                                          style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          talep['aciklama']!,
                                          style: TextStyle(color: Colors.grey[400], fontSize: 13, height: 1.4),
                                        ),
                                      ],
                                    ),
                                  )
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                      childCount: filtreliListe.length,
                    ),
                  ),
                ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.neonTurquoise,
        onPressed: _izinTalepFormuGoster,
        icon: const Icon(Icons.add, color: AppColors.darkNavy),
        label: const Text(
          "Yeni Talep",
          style: TextStyle(color: AppColors.darkNavy, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardNavy : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(color: Colors.grey[400], fontSize: 12, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  void _izinTalepFormuGoster() {
    final turController = TextEditingController(text: 'Yıllık İzin');
    final baslangicController = TextEditingController(text: '2026-08-01');
    final bitisController = TextEditingController(text: '2026-08-10');
    final aciklamaController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardNavy,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          top: 24,
          left: 24,
          right: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Yeni İzin Talebi", 
              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            _buildTextField("İzin Türü", turController),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildTextField("Başlangıç Tarihi", baslangicController)),
                const SizedBox(width: 12),
                Expanded(child: _buildTextField("Bitiş Tarihi", bitisController)),
              ],
            ),
            const SizedBox(height: 12),
            _buildTextField("Açıklama", aciklamaController, maxLines: 3),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.neonTurquoise,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  if (aciklamaController.text.isNotEmpty) {
                    _yeniIzinEkle(turController.text, baslangicController.text, bitisController.text, aciklamaController.text);
                    Navigator.pop(context);
                  }
                },
                child: const Text("Talep Gönder", style: TextStyle(color: AppColors.darkNavy, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey[400]),
        filled: true,
        fillColor: AppColors.darkNavy,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.neonTurquoise),
        ),
      ),
    );
  }
}