import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:image_picker/image_picker.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(const MaterialApp(
    home: SakapayHome(),
    debugShowCheckedModeBanner: false,
  ));
}

class SakapayHome extends StatefulWidget {
  const SakapayHome({super.key});

  @override
  State<SakapayHome> createState() => _SakapayHomeState();
}

class _SakapayHomeState extends State<SakapayHome> {
  final ScreenshotController _screenshotController = ScreenshotController();
  StreamSubscription? _intentSub;

  // Status & Data Transaksi
  bool isPln = false;
  String waktuTrx = "";
  String refId = "240365967239";
  String tokenPln1 = "4087 7208 5877";
  String tokenPln2 = "4070 8808";
  String noMeter = "-";
  String namaPelanggan = "SRI DEWI";
  String kwh = "30.10KWH";

  // Data Bank
  String bankTujuan = "BRI";
  String noRekening = "003301045155532";
  String penerima = "YAYASAN HMQ LIRBOYO";
  String pengirim = "TEGXXX DISXX SAKXXXXXX";
  String bankPengirim = "BRI";
  String rekPengirim = "5655 XXXX XXXX 539";
  String nominal = "400.000";
  String admin = "3.000";
  String total = "403.000";

  @override
  void initState() {
    super.initState();
    waktuTrx = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

    // Menerima Share Gambar saat aplikasi berjalan
    _intentSub = ReceiveSharingIntent.getImageStream().listen((List<SharedMediaFile> value) {
      if (value.isNotEmpty) {
        _prosesGambar(File(value.first.path));
      }
    });

    // Menerima Share Gambar saat aplikasi ditutup/baru dibuka
    ReceiveSharingIntent.getInitialMedia().then((List<SharedMediaFile> value) {
      if (value.isNotEmpty) {
        _prosesGambar(File(value.first.path));
      }
    });
  }

  @override
  void dispose() {
    _intentSub?.cancel();
    super.dispose();
  }

  // OCR memindai gambar screenshot
  Future<void> _prosesGambar(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
    await textRecognizer.close();

    _parseHasilOcr(recognizedText.text);
  }

  void _parseHasilOcr(String text) {
    setState(() {
      waktuTrx = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

      // Deteksi PLN Token
      if (text.toLowerCase().contains("pln") || text.toLowerCase().contains("token") || text.toLowerCase().contains("stroom")) {
        isPln = true;
        RegExp tokenRegex = RegExp(r'\b\d{4}[-\s]?\d{4}[-\s]?\d{4}[-\s]?\d{4}[-\s]?\d{4}\b');
        var match = tokenRegex.firstMatch(text);
        if (match != null) {
          String raw = match.group(0)!.replaceAll(RegExp(r'[-\s]'), '');
          tokenPln1 = "${raw.substring(0, 4)} ${raw.substring(4, 8)} ${raw.substring(8, 12)}";
          tokenPln2 = "${raw.substring(12, 16)} ${raw.substring(16, 20)}";
        }
      } else {
        isPln = false;
      }

      // Deteksi Nominal
      RegExp nomRegex = RegExp(r'(?:Rp|IDR)\s?([0-9.,]+)', caseSensitive: false);
      var nomMatch = nomRegex.firstMatch(text);
      if (nomMatch != null) {
        nominal = nomMatch.group(1)!;
        total = nominal;
      }

      // Deteksi Referensi
      RegExp refRegex = RegExp(r'(?:ref|nomor ref|transaksi|id)[:\s]+([0-9A-Za-z]+)', caseSensitive: false);
      var refMatch = refRegex.firstMatch(text);
      if (refMatch != null) {
        refId = refMatch.group(1)!;
      }
    });
  }

  // Ambil manual dari galeri
  Future<void> _pilihGambarManual() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      _prosesGambar(File(pickedFile.path));
    }
  }

  // Bagikan Struk ke WA / Media Lain
  Future<void> _bagikanStruk() async {
    final Uint8List? imageBytes = await _screenshotController.capture();
    if (imageBytes != null) {
      final tempDir = await getTemporaryDirectory();
      final file = await File('${tempDir.path}/struk_sakapay.png').create();
      await file.writeAsBytes(imageBytes);
      await Share.shareXFiles([XFile(file.path)], text: 'Bukti Transaksi SAKAPAY');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
        title: const Text("SAKAPAY Struk Generator", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.photo_library),
            onPressed: _pilihGambarManual,
            tooltip: "Pilih Bukti dari Galeri",
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _bagikanStruk,
            tooltip: "Bagikan Struk",
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () => setState(() => isPln = false),
                  icon: const Icon(Icons.account_balance),
                  label: const Text("Struk Transfer"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: !isPln ? Colors.blue : Colors.grey[800],
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: () => setState(() => isPln = true),
                  icon: const Icon(Icons.bolt),
                  label: const Text("Token PLN"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isPln ? Colors.orange : Colors.grey[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),

            // Tampilan Struk Fisik SAKAPAY
            Center(
              child: Screenshot(
                controller: _screenshotController,
                child: Container(
                  width: 330,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
                  color: Colors.white,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Logo SAKAPAY Petir Panah
                      const Icon(Icons.electric_bolt, size: 55, color: Colors.black),
                      const Text(
                        "SAKAPAY",
                        style: TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black),
                      ),
                      const SizedBox(height: 8),
                      const Text("--------------------------------------------------", maxLines: 1, style: TextStyle(color: Colors.black)),
                      
                      Text(
                        isPln ? "TOKEN LISTRIK PRABAYAR" : "==================================",
                        style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black),
                      ),
                      
                      if (isPln) ...[
                        Text(waktuTrx, style: const TextStyle(fontFamily: 'monospace', fontSize: 13, color: Colors.black)),
                        const Text("--------------------------------------------------", maxLines: 1, style: TextStyle(color: Colors.black)),
                        const SizedBox(height: 10),
                        Text(tokenPln1, style: const TextStyle(fontFamily: 'monospace', fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black)),
                        Text(tokenPln2, style: const TextStyle(fontFamily: 'monospace', fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black)),
                        const SizedBox(height: 10),
                        const Text("MASUKKAN 20 ANGKA DI METERAN", style: TextStyle(fontFamily: 'monospace', fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black)),
                        const Text("--------------------------------------------------", maxLines: 1, style: TextStyle(color: Colors.black)),
                        _rowItem("NO METER", ": $noMeter"),
                        _rowItem("NAMA", ": $namaPelanggan"),
                        _rowItem("KWH", ": $kwh"),
                        const Text("--------------------------------------------------", maxLines: 1, style: TextStyle(color: Colors.black)),
                        _rowItem("TOTAL", "RP $nominal", isBold: true),
                        _rowItem("REF", ": $refId"),
                      ] else ...[
                        _rowItem("TANGGAL", waktuTrx.split(" ")[0]),
                        _rowItem("WAKTU", waktuTrx.contains(" ") ? waktuTrx.split(" ")[1] : waktuTrx),
                        const Text("--------------------------------------------------", maxLines: 1, style: TextStyle(color: Colors.black)),
                        const Text("KODE REFERENSI", style: TextStyle(fontFamily: 'monospace', fontSize: 12, color: Colors.black)),
                        Text(refId, style: const TextStyle(fontFamily: 'monospace', fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black)),
                        const Text("--------------------------------------------------", maxLines: 1, style: TextStyle(color: Colors.black)),
                        const Text("DATA PENGIRIM", style: TextStyle(fontFamily: 'monospace', fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black)),
                        _rowItem("NAMA", pengirim),
                        _rowItem("BANK", bankPengirim),
                        _rowItem("NO REKENING", rekPengirim),
                        const Text("--------------------------------------------------", maxLines: 1, style: TextStyle(color: Colors.black)),
                        const Text("DATA PENERIMA", style: TextStyle(fontFamily: 'monospace', fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black)),
                        _rowItem("BANK TUJUAN", bankTujuan),
                        _rowItem("NO REKENING", noRekening),
                        _rowItem("PENERIMA", penerima),
                        const Text("--------------------------------------------------", maxLines: 1, style: TextStyle(color: Colors.black)),
                        _rowItem("NOMINAL", "RP $nominal"),
                        _rowItem("ADMIN", "RP $admin"),
                        const Text("==================================", maxLines: 1, style: TextStyle(color: Colors.black)),
                        _rowItem("TOTAL", "RP $total", isBold: true),
                        const Text("==================================", maxLines: 1, style: TextStyle(color: Colors.black)),
                      ],

                      const SizedBox(height: 12),
                      const Text("** TRANSAKSI BERHASIL **", style: TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black)),
                      const Text("TERIMA KASIH ATAS KEPERCAYAAN", style: TextStyle(fontFamily: 'monospace', fontSize: 11, color: Colors.black)),
                      const Text("ANDA CS / BANTUAN:", style: TextStyle(fontFamily: 'monospace', fontSize: 11, color: Colors.black)),
                      const Text("0857-8024-3664 SIMPAN STRUK INI", style: TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold, fontSize: 11, color: Colors.black)),
                      const Text("SEBAGAI BUKTI SAH", style: TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold, fontSize: 11, color: Colors.black)),
                      const SizedBox(height: 5),
                      const Text("TID: AD4ECF", style: TextStyle(fontFamily: 'monospace', fontSize: 12, color: Colors.black)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 25),
          ],
        ),
      ),
    );
  }

  Widget _rowItem(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontFamily: 'monospace', fontSize: 12, fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: Colors.black)),
          Text(value, style: TextStyle(fontFamily: 'monospace', fontSize: 12, fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: Colors.black)),
        ],
      ),
    );
  }
}
