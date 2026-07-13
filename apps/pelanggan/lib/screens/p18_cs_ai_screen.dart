import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tk_core/tk_core.dart';

/// Satu gelembung percakapan CS AI.
class _Pesan {
  const _Pesan(this.teks, {required this.dariAi});
  final String teks;
  final bool dariAi;
}

/// P18 — Tanya CS AI. Chat asisten yang menjawab dari pengetahuan publik
/// Tuntaskilat (katalog, harga, jam, cara pesan/bayar) lewat Cloud Function
/// `csAi`. Untuk hal sensitif AI mengarahkan ke CS manusia.
class P18CsAiScreen extends ConsumerStatefulWidget {
  const P18CsAiScreen({super.key});

  static const route = '/p18';

  @override
  ConsumerState<P18CsAiScreen> createState() => _P18CsAiScreenState();
}

class _P18CsAiScreenState extends ConsumerState<P18CsAiScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final _pesan = <_Pesan>[
    const _Pesan(
        'Halo! Saya asisten Tuntaskilat. Tanya apa saja soal layanan, '
        'harga, jam operasional, atau cara memesan. 😊',
        dariAi: true),
  ];
  var _mengirim = false;

  final _ai = AiService();

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _keBawah() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut);
      }
    });
  }

  Future<void> _kirim() async {
    final t = _input.text.trim();
    if (t.isEmpty || _mengirim) return;
    setState(() {
      _pesan.add(_Pesan(t, dariAi: false));
      _mengirim = true;
      _input.clear();
    });
    _keBawah();
    try {
      final jawaban = await _ai.tanyaCs(t);
      if (!mounted) return;
      setState(() => _pesan.add(_Pesan(
          jawaban.isEmpty ? 'Maaf, saya belum punya jawabannya.' : jawaban,
          dariAi: true)));
    } on AiBelumAktif {
      if (!mounted) return;
      setState(() => _pesan.add(const _Pesan(
          'Asisten AI belum diaktifkan. Silakan hubungi CS lewat menu '
          'Bantuan untuk sekarang.',
          dariAi: true)));
    } catch (_) {
      if (!mounted) return;
      setState(() => _pesan.add(const _Pesan(
          'Koneksi ke asisten gagal. Coba lagi sebentar ya.',
          dariAi: true)));
    } finally {
      if (mounted) setState(() => _mengirim = false);
      _keBawah();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F5),
      appBar: AppBar(
        backgroundColor: TkColors.surface,
        foregroundColor: TkColors.inkSoft,
        elevation: 0,
        title: Row(children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: TkColors.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.auto_awesome_rounded,
                size: 18, color: TkColors.primary),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Asisten Tuntaskilat',
                  style: GoogleFonts.montserrat(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: TkColors.inkSoft)),
              Text('Balasan otomatis',
                  style: GoogleFonts.montserrat(
                      fontSize: 11, color: TkColors.textMuted)),
            ],
          ),
        ]),
      ),
      body: Column(children: [
        Expanded(
          child: ListView.builder(
            controller: _scroll,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            itemCount: _pesan.length + (_mengirim ? 1 : 0),
            itemBuilder: (context, i) {
              if (i >= _pesan.length) return const _Mengetik();
              return _Gelembung(pesan: _pesan[i]);
            },
          ),
        ),
        SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            decoration: const BoxDecoration(
              color: TkColors.surface,
              border: Border(top: BorderSide(color: Color(0x0F0F281C))),
            ),
            child: Row(children: [
              Expanded(
                child: TextField(
                  controller: _input,
                  minLines: 1,
                  maxLines: 4,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _kirim(),
                  decoration: InputDecoration(
                    hintText: 'Tulis pertanyaan…',
                    filled: true,
                    fillColor: TkColors.surfaceMuted,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(22),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Material(
                color: TkColors.primary,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: _mengirim ? null : _kirim,
                  child: const SizedBox(
                    width: 46,
                    height: 46,
                    child: Icon(Icons.send_rounded,
                        color: Colors.white, size: 20),
                  ),
                ),
              ),
            ]),
          ),
        ),
      ]),
    );
  }
}

class _Gelembung extends StatelessWidget {
  const _Gelembung({required this.pesan});
  final _Pesan pesan;

  @override
  Widget build(BuildContext context) {
    final ai = pesan.dariAi;
    return Align(
      alignment: ai ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
            maxWidth: MediaQuery.sizeOf(context).width * 0.78),
        decoration: BoxDecoration(
          color: ai ? TkColors.surface : TkColors.primary,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(ai ? 4 : 16),
            bottomRight: Radius.circular(ai ? 16 : 4),
          ),
          border: ai ? Border.all(color: const Color(0x0F0F281C)) : null,
        ),
        child: Text(pesan.teks,
            style: GoogleFonts.montserrat(
                fontSize: 13.5,
                height: 1.5,
                color: ai ? TkColors.inkSoft : Colors.white)),
      ),
    );
  }
}

class _Mengetik extends StatelessWidget {
  const _Mengetik();
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: TkColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0x0F0F281C)),
        ),
        child: const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
              strokeWidth: 2, color: TkColors.primary),
        ),
      ),
    );
  }
}
