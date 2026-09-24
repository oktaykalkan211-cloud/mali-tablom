import 'package:flutter/material.dart';

void main() {
  runApp(const MaliTabloApp());
}

class MaliTabloApp extends StatelessWidget {
  const MaliTabloApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mali Tablom',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.teal,
        useMaterial3: true,
      ),
      home: const AnaEkrani(),
    );
  }
}

class Islem {
  String id;
  double tutar;
  String tur; // 'Gelir' veya 'Gider'
  String kategori;
  String aciklama;
  DateTime? tarih; // null ise "Tarihi Belirsiz"

  Islem({
    required this.id,
    required this.tutar,
    required this.tur,
    required this.kategori,
    required this.aciklama,
    this.tarih,
  });
}

class AnaEkrani extends StatefulWidget {
  const AnaEkrani({super.key});

  @override
  State<AnaEkrani> createState() => _AnaEkraniState();
}

class _AnaEkraniState extends State<AnaEkrani> {
  final List<Islem> _islemler = [];

  final _tutarController = TextEditingController();
  final _aciklamaController = TextEditingController();
  String _secilenTur = 'Gider';
  String _secilenKategori = 'Genel';
  DateTime? _secilenTarih = DateTime.now();
  bool _tarihiBelirsiz = false;

  final List<String> _kategoriler = ['Genel', 'Mutfak', 'Maaş', 'Fatura', 'Eğlence', 'Kira', 'Diğer'];

  // Yardımcı Tarih Formatlayıcı (Gün/Ay/Yıl)
  String _tarihFormatla(DateTime dt) {
    String gun = dt.day.toString().padLeft(2, '0');
    String ay = dt.month.toString().padLeft(2, '0');
    return "$gun/$ay/${dt.year}";
  }

  double get _toplamGelir {
    return _islemler
        .where((i) => i.tur == 'Gelir')
        .fold(0.0, (sum, item) => sum + item.tutar);
  }

  double get _toplamGider {
    return _islemler
        .where((i) => i.tur == 'Gider')
        .fold(0.0, (sum, item) => sum + item.tutar);
  }

  double get _bakiye => _toplamGelir - _toplamGider;

  List<Islem> get _siraliIslemler {
    List<Islem> liste = List.from(_islemler);
    liste.sort((a, b) {
      if (a.tarih == null && b.tarih != null) return -1;
      if (a.tarih != null && b.tarih == null) return 1;
      if (a.tarih == null && b.tarih == null) return 0;
      return b.tarih!.compareTo(a.tarih!);
    });
    return liste;
  }

  void _islemEkle() {
    final tutar = double.tryParse(_tutarController.text);
    if (tutar == null || tutar <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen geçerli bir tutar girin!')),
      );
      return;
    }

    setState(() {
      _islemler.add(Islem(
        id: DateTime.now().toString(),
        tutar: tutar,
        tur: _secilenTur,
        kategori: _secilenKategori,
        aciklama: _aciklamaController.text.isEmpty ? _secilenKategori : _aciklamaController.text,
        tarih: _tarihiBelirsiz ? null : _secilenTarih,
      ));
    });

    _tutarController.clear();
    _aciklamaController.clear();
    FocusScope.of(context).unfocus();
  }

  void _islemSil(String id) {
    setState(() {
      _islemler.removeWhere((i) => i.id == id);
    });
  }

  void _tutarDuzenleDialog(Islem islem) {
    final editController = TextEditingController(text: islem.tutar.toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tutarı Değiştir'),
        content: TextField(
          controller: editController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Yeni Tutar (TL)'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              final yeniTutar = double.tryParse(editController.text);
              if (yeniTutar != null && yeniTutar > 0) {
                setState(() {
                  islem.tutar = yeniTutar;
                });
                Navigator.of(ctx).pop();
              }
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mali Tablom'),
        centerTitle: true,
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // 1. SATIR: MALİ DURUM ÖZETİ
          Card(
            margin: const EdgeInsets.all(12),
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _ozetKutusu('Gelir', '+${_toplamGelir.toStringAsFixed(2)} TL', Colors.green),
                  _ozetKutusu('Gider', '-${_toplamGider.toStringAsFixed(2)} TL', Colors.red),
                  _ozetKutusu('Bakiye', '${_bakiye.toStringAsFixed(2)} TL', _bakiye >= 0 ? Colors.teal : Colors.deepOrange),
                ],
              ),
            ),
          ),

          // 2. SATIR: VERİ GİRİŞ ALANI
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _tutarController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Tutar (TL)', border: OutlineInputBorder()),
                        ),
                      ),
                      const SizedBox(width: 8),
                      DropdownButton<String>(
                        value: _secilenTur,
                        items: ['Gelir', 'Gider'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                        onChanged: (val) => setState(() => _secilenTur = val!),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _secilenKategori,
                          decoration: const InputDecoration(labelText: 'Kategori', border: OutlineInputBorder()),
                          items: _kategoriler.map((k) => DropdownMenuItem(value: k, child: Text(k))).toList(),
                          onChanged: (val) => setState(() => _secilenKategori = val!),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _aciklamaController,
                          decoration: const InputDecoration(labelText: 'Açıklama', border: OutlineInputBorder()),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Checkbox(
                        value: _tarihiBelirsiz,
                        onChanged: (val) => setState(() => _tarihiBelirsiz = val!),
                      ),
                      const Text('Tarihi Belirsiz'),
                      const Spacer(),
                      if (!_tarihiBelirsiz)
                        TextButton.icon(
                          icon: const Icon(Icons.calendar_today),
                          label: Text(_tarihFormatla(_secilenTarih!)),
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _secilenTarih!,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2030),
                            );
                            if (picked != null) setState(() => _secilenTarih = picked);
                          },
                        ),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: _islemEkle,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      minimumSize: const Size.fromHeight(40),
                    ),
                    child: const Text('Ekle', style: TextStyle(color: Colors.white)),
                  )
                ],
              ),
            ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text('İşlem Geçmişi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),

          // 3. SATIR: KRONOLOJİK VE ÖZEL SIRALAMALI LİSTE
          Expanded(
            child: _siraliIslemler.isEmpty
                ? const Center(child: Text('Henüz veri girilmedi.'))
                : ListView.builder(
                    itemCount: _siraliIslemler.length,
                    itemBuilder: (ctx, index) {
                      final item = _siraliIslemler[index];
                      final isBelirsiz = item.tarih == null;

                      return Card(
                        color: isBelirsiz ? Colors.amber.shade50 : Colors.white,
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: item.tur == 'Gelir' ? Colors.green.shade100 : Colors.red.shade100,
                            child: Icon(
                              item.tur == 'Gelir' ? Icons.arrow_downward : Icons.arrow_upward,
                              color: item.tur == 'Gelir' ? Colors.green : Colors.red,
                            ),
                          ),
                          title: Text('${item.aciklama} (${item.kategori})'),
                          subtitle: Text(
                            isBelirsiz
                                ? '📌 Tarihi Belirsiz (Sabit)'
                                : _tarihFormatla(item.tarih!),
                            style: TextStyle(
                              color: isBelirsiz ? Colors.orange.shade900 : Colors.grey,
                              fontWeight: isBelirsiz ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${item.tur == 'Gelir' ? '+' : '-'}${item.tutar.toStringAsFixed(2)} TL',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: item.tur == 'Gelir' ? Colors.green : Colors.red,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () => _tutarDuzenleDialog(item),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _islemSil(item.id),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _ozetKutusu(String baslik, String tutar, Color renk) {
    return Column(
      children: [
        Text(baslik, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 4),
        Text(tutar, style: TextStyle(color: renk, fontWeight: FontWeight.bold, fontSize: 14)),
      ],
    );
  }
}
