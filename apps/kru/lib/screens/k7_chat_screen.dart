import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tk_core/tk_core.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart';

import '../providers/app_providers.dart';

final chatMessagesProvider =
    StreamProvider.autoDispose.family<List<MessageModel>, String>((ref, orderId) {
  return ref.watch(firestoreServiceProvider).watchChatMessages(orderId);
});

class K7ChatScreen extends ConsumerStatefulWidget {
  const K7ChatScreen({super.key});

  static const route = '/k7';

  @override
  ConsumerState<K7ChatScreen> createState() => _K7ChatScreenState();
}

class _K7ChatScreenState extends ConsumerState<K7ChatScreen> {
  final _controller = TextEditingController();

  Future<void> _kirimPesan(String orderId, String userId) async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();

    final msg = MessageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: userId,
      text: text,
      timestamp: DateTime.now(),
    );

    await ref.read(firestoreServiceProvider).kirimPesanChat(orderId, msg);
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final orderId = args['orderId'] as String;
    final namaPelanggan = args['namaPelanggan'] as String;
    final noTelpPelanggan = args['noTelpPelanggan'] as String;
    final user = ref.watch(authServiceProvider).currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(namaPelanggan),
            Text('Pelanggan',
                style: GoogleFonts.montserrat(
                    fontSize: 12, color: TkColors.textSecondary)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.call_rounded),
            onPressed: () async {
              final phone = noTelpPelanggan.startsWith('0') 
                  ? noTelpPelanggan.substring(1) 
                  : noTelpPelanggan;
              final url = Uri.parse('https://wa.me/62$phone');
              if (await canLaunchUrl(url)) {
                await launchUrl(url);
              } else {
                await launchUrl(Uri(scheme: 'tel', path: noTelpPelanggan));
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Consumer(
              builder: (context, ref, child) {
                final messagesAsync = ref.watch(chatMessagesProvider(orderId));
                
                return messagesAsync.when(
                  data: (messages) {
                    if (messages.isEmpty) {
                      return Center(
                        child: Text('Belum ada pesan',
                            style: GoogleFonts.montserrat(color: TkColors.textMuted)),
                      );
                    }
                    
                    return ListView.builder(
                      reverse: true,
                      padding: const EdgeInsets.all(16),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final msg = messages[index];
                        final isMe = msg.senderId == user?.uid;
                        
                        return Align(
                          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: isMe ? TkColors.primary : TkColors.surfaceVariant,
                              borderRadius: BorderRadius.circular(16).copyWith(
                                bottomRight: isMe ? const Radius.circular(4) : null,
                                bottomLeft: !isMe ? const Radius.circular(4) : null,
                              ),
                            ),
                            child: Text(
                              msg.text,
                              style: GoogleFonts.montserrat(
                                color: isMe ? TkColors.surface : TkColors.textPrimary,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, _) => const Center(child: Text('Gagal memuat pesan')),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: TkColors.surface,
              border: Border(top: BorderSide(color: TkColors.outline)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Ketik pesan...',
                      hintStyle: GoogleFonts.montserrat(color: TkColors.textPlaceholder),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: TkColors.surfaceVariant,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                    ),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _kirimPesan(orderId, user!.uid),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: TkColors.primary,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white, size: 20),
                    onPressed: () => _kirimPesan(orderId, user!.uid),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

