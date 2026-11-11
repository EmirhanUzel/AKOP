import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../../../core/theme/app_colors.dart';

/// Söyleneni [text]'in sonuna bir boşlukla ekler; sonuç [maxLength]'i aşmaz.
String appendSpoken(String text, String spoken, {int maxLength = 2000}) {
  final s = spoken.trim();
  if (s.isEmpty) return text;
  final t = text.trimRight();
  final all = t.isEmpty ? s : '$t $s';
  return all.length > maxLength ? all.substring(0, maxLength) : all;
}

/// "Sesle yaz": cihazın konuşma tanıma servisiyle (Türkçe) söyleneni [controller]'a yazar.
/// Ses kaydı saklanmaz ya da sunucuya gönderilmez; yalnızca çıkan metin alana eklenir.
class VoiceInputButton extends StatefulWidget {
  const VoiceInputButton({super.key, required this.controller, required this.onChanged, this.maxLength = 2000});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final int maxLength;

  @override
  State<VoiceInputButton> createState() => _VoiceInputButtonState();
}

class _VoiceInputButtonState extends State<VoiceInputButton> {
  final _speech = SpeechToText();
  bool _listening = false;
  String _before = '';

  void _stopped() {
    if (mounted) setState(() => _listening = false);
  }

  Future<void> _toggle() async {
    if (_listening) {
      await _speech.stop();
      return _stopped();
    }
    final messenger = ScaffoldMessenger.of(context);
    final ready = await _speech.initialize(
      onStatus: (s) {
        if (s == SpeechToText.doneStatus || s == SpeechToText.notListeningStatus) _stopped();
      },
      onError: (e) {
        _stopped();
        // Konuşma duyulmadı ya da anlaşılmadıysa söylenir; düğme sessizce kapanmaz
        final unheard = e.errorMsg == 'error_no_match' || e.errorMsg == 'error_speech_timeout';
        messenger.showSnackBar(SnackBar(content: Text(unheard ? 'Ses anlaşılamadı. Tekrar deneyin.' : 'Sesle yazma şu an çalışmıyor.')));
      },
    );
    if (!ready) {
      messenger.showSnackBar(const SnackBar(content: Text('Sesle yazma kullanılamıyor. Mikrofon iznini kontrol edin.')));
      return;
    }
    _before = widget.controller.text;
    setState(() => _listening = true);
    await _speech.listen(
      onResult: (r) {
        final text = appendSpoken(_before, r.recognizedWords, maxLength: widget.maxLength);
        widget.controller.value = TextEditingValue(text: text, selection: TextSelection.collapsed(offset: text.length));
        widget.onChanged(text);
      },
      listenOptions: SpeechListenOptions(localeId: 'tr_TR', listenMode: ListenMode.dictation, partialResults: true),
    );
  }

  @override
  void dispose() {
    if (_listening) _speech.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => TextButton.icon(
        onPressed: _toggle,
        style: TextButton.styleFrom(foregroundColor: _listening ? AppColors.orange : AppColors.navy, visualDensity: VisualDensity.compact),
        icon: Icon(_listening ? Icons.stop_circle_outlined : Icons.mic_none),
        label: Text(_listening ? 'Dinleniyor… Durdur' : 'Sesle yaz'),
      );
}
