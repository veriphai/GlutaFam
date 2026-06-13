// Handle Lamp (beat P.1) — the Flutter shell.
//
// Pure Flutter: a single CustomPainter canvas (crank, wire, pulse, the four
// outputs, the discovery flash) driven by a Ticker. The shell owns the frame
// clock and pumps `controller.tick(dt)`; the controller owns all physics +
// geometry + the SEQUENTIAL step machine (lamp → fan → heater → speaker, one at
// a time — no chooser). The painter is a pure renderer (repaint: controller).
//
// A short large top instruction guides the kid; there is no companion / dialogue
// / voice-over. A looping BGM bed plays underneath. When every device has been
// driven, the close state shows Continue → the Conservation-of-Energy card.

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../collectibles/collectible_earn_overlay.dart';
import '../lessonRunner.dart';
import '../activity_header.dart';
import '../../collectibles/collectible_models.dart';
import '../../home/career/careerCommon.dart';
import '../../home/career/careerTheme.dart';
import 'state/crank_controller.dart';
import 'widgets/crank_surface.dart';
import '../episode_board/activity_background.dart';
import 'widgets/instruction_banner.dart';

class HandCrankLampScreen extends StatefulWidget {
  const HandCrankLampScreen({super.key});

  @override
  State<HandCrankLampScreen> createState() => _HandCrankLampScreenState();
}

class _HandCrankLampScreenState extends State<HandCrankLampScreen>
    with SingleTickerProviderStateMixin {
  late final CrankController _controller;
  late final Ticker _ticker;
  Duration _last = Duration.zero;
  bool _showCard = false; // Continue tapped → the collectible earn moment

  final AudioPlayer _bgm = AudioPlayer(); // looping music bed
  bool _soundOn = true;
  static const double _bgmVol = 0.18;

  @override
  void initState() {
    super.initState();
    _controller = CrankController()..onCrankTick = _hapticTick;
    _bgm.setReleaseMode(ReleaseMode.loop);
    _ticker = createTicker(_onTick);
    _ticker.start();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startAudio());
  }

  /// PER-PLAYER audio-context (AndroidAudioFocus.none) so the BGM mixes with any
  /// other app audio rather than grabbing focus. Then start the loop.
  Future<void> _startAudio() async {
    final mix = AudioContext(
      android: AudioContextAndroid(audioFocus: AndroidAudioFocus.none),
      iOS: AudioContextIOS(
        category: AVAudioSessionCategory.playback,
        options: const {AVAudioSessionOptions.mixWithOthers},
      ),
    );
    await _bgm.setAudioContext(mix).catchError((_) {});
    if (!mounted) return;
    if (_soundOn) {
      _bgm.play(AssetSource('sounds/hand_crank_lamp/bgm.mp3'), volume: _bgmVol).catchError((_) {});
    }
    _controller.start();
  }

  void _onTick(Duration elapsed) {
    final dt = (elapsed - _last).inMicroseconds / 1e6;
    _last = elapsed;
    if (dt > 0 && dt < 0.1) _controller.tick(dt);
  }

  void _hapticTick() => HapticFeedback.selectionClick();

  void _toggleSound() {
    setState(() => _soundOn = !_soundOn);
    if (_soundOn) {
      _bgm.resume().catchError((_) {});
    } else {
      _bgm.pause().catchError((_) {});
    }
  }

  void _finish() => completeActivity(context);

  @override
  void dispose() {
    _ticker.dispose();
    _controller.dispose();
    _bgm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
      child: Scaffold(
        backgroundColor: const Color(0xFF070A1C),
        body: Stack(
          children: [
            const Positioned.fill(child: ActivityDossierBackground()),
            Positioned.fill(
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
                  child: Column(
                    children: [
                      ActivityNameHeader(
                        onBack: () => Navigator.of(context).maybePop(),
                        fallbackName: 'Making Electricity by Hand',
                        trailing: PressableScale(
                          onTap: _toggleSound,
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(13),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                            ),
                            alignment: Alignment.center,
                            child: Icon(
                              _soundOn ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                              color: Colors.white.withValues(alpha: 0.8),
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // The large top instruction — fixed height so the stage
                      // below never resizes as the text swaps.
                      SizedBox(
                        height: 96,
                        child: Center(child: InstructionBanner(controller: _controller)),
                      ),
                      const SizedBox(height: 4),
                      Expanded(child: CrankSurface(controller: _controller)),
                      const SizedBox(height: 8),
                      // Bottom slot — Continue only in the done state (fixed
                      // height so the stage stays stable when it appears).
                      SizedBox(
                        height: 84,
                        child: ValueListenableBuilder<bool>(
                          valueListenable: _controller.done,
                          builder: (context, done, _) => AnimatedSwitcher(
                            duration: const Duration(milliseconds: 380),
                            child: done
                                ? Align(
                                    key: const ValueKey('continue'),
                                    alignment: Alignment.bottomCenter,
                                    child: _ContinueButton(onTap: () => setState(() => _showCard = true)),
                                  )
                                : const SizedBox.shrink(key: ValueKey('empty')),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // The collectible earn moment (after Continue). MUST stay
            // Positioned.fill — a non-positioned Stack child collapses the Stack.
            Positioned.fill(
              child: _showCard
                  ? CollectibleEarnOverlay(
                      card: kConservationCard,
                      onDone: _finish,
                      onReplay: () => replayCurrentActivity(context),
                      mascot: const SizedBox.shrink(), // no companion
                    )
                  : const IgnorePointer(child: SizedBox.shrink()),
            ),
          ],
        ),
      ),
    );
  }
}

/// The done-state CTA — calm gold, full-width bottom button.
class _ContinueButton extends StatelessWidget {
  const _ContinueButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: Container(
        height: 52,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 30),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF5C451), Color(0xFFD9A43B)],
          ),
          borderRadius: BorderRadius.circular(CareerRadii.pill),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Continue',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14.5,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1A1340),
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.arrow_forward_rounded, size: 19, color: Color(0xFF1A1340)),
          ],
        ),
      ),
    );
  }
}
