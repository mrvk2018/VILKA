import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../domain/hangul/hangul_alphabet.dart';
import '../../l10n/generated/app_localizations.dart';
import '../settings/presentation/speech_speed_notifier.dart';

class HangulDrawingScreen extends ConsumerStatefulWidget {
  const HangulDrawingScreen({super.key, required this.letter});

  final String letter;

  @override
  ConsumerState<HangulDrawingScreen> createState() =>
      _HangulDrawingScreenState();
}

class _HangulDrawingScreenState extends ConsumerState<HangulDrawingScreen> {
  final List<List<Offset>> _strokes = [];
  final List<Offset> _currentStroke = [];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final meta = HangulAlphabet.findByChar(widget.letter);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.hangulDrawingTitle(widget.letter)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                l10n.hangulDrawingInstruction,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              if (meta != null) ...[
                const SizedBox(height: 8),
                Text(
                  widget.letter,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 28),
                ),
              ],
              const SizedBox(height: 16),
              Expanded(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest.withValues(
                      alpha: 0.35,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Center(
                          child: Text(
                            widget.letter,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 200,
                              color: scheme.onSurface.withValues(alpha: 0.12),
                            ),
                          ),
                        ),
                        GestureDetector(
                          onPanStart: (details) {
                            setState(() {
                              _currentStroke
                                ..clear()
                                ..add(details.localPosition);
                            });
                          },
                          onPanUpdate: (details) {
                            setState(() {
                              _currentStroke.add(details.localPosition);
                            });
                          },
                          onPanEnd: (_) {
                            setState(() {
                              if (_currentStroke.isNotEmpty) {
                                _strokes.add(List<Offset>.from(_currentStroke));
                                _currentStroke.clear();
                              }
                            });
                          },
                          onPanCancel: () {
                            setState(_currentStroke.clear);
                          },
                          child: CustomPaint(
                            painter: _HangulStrokePainter(
                              strokes: _strokes,
                              currentStroke: _currentStroke,
                              inkColor: scheme.primary,
                              guideColor: scheme.outline.withValues(
                                alpha: 0.45,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    setState(() {
                      _strokes.clear();
                      _currentStroke.clear();
                    });
                  },
                  child: Text(l10n.hangulClearCanvas),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton.tonal(
                  onPressed: () {
                    ref.read(ttsEngineProvider).speakKorean(
                          widget.letter,
                          speedCoefficient: ref.read(speechSpeedProvider),
                        );
                  },
                  child: Text(l10n.hangulPlayLetter),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HangulStrokePainter extends CustomPainter {
  _HangulStrokePainter({
    required this.strokes,
    required this.currentStroke,
    required this.inkColor,
    required this.guideColor,
  });

  final List<List<Offset>> strokes;
  final List<Offset> currentStroke;
  final Color inkColor;
  final Color guideColor;

  @override
  void paint(Canvas canvas, Size size) {
    final guidePaint = Paint()
      ..color = guideColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final dash = <double>[12, 12];
    _drawDashedLine(
      canvas,
      Offset(size.width / 2, 0),
      Offset(size.width / 2, size.height),
      guidePaint,
      dash,
    );
    _drawDashedLine(
      canvas,
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      guidePaint,
      dash,
    );
    canvas.drawRect(Offset.zero & size, guidePaint);

    final strokePaint = Paint()
      ..color = inkColor
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    for (final stroke in strokes) {
      _drawStroke(canvas, stroke, strokePaint);
    }
    _drawStroke(canvas, currentStroke, strokePaint);
  }

  void _drawStroke(Canvas canvas, List<Offset> points, Paint paint) {
    if (points.length < 2) {
      return;
    }
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(path, paint);
  }

  void _drawDashedLine(
    Canvas canvas,
    Offset start,
    Offset end,
    Paint paint,
    List<double> dash,
  ) {
    final path = Path()
      ..moveTo(start.dx, start.dy)
      ..lineTo(end.dx, end.dy);
    canvas.drawPath(
      dashPath(path, dashArray: dash),
      paint,
    );
  }

  Path dashPath(Path source, {required List<double> dashArray}) {
    final dest = Path();
    for (final metric in source.computeMetrics()) {
      var distance = 0.0;
      var draw = true;
      var index = 0;
      while (distance < metric.length) {
        final length = dashArray[index % dashArray.length];
        final next = distance + length;
        if (draw) {
          dest.addPath(
            metric.extractPath(distance, next.clamp(0, metric.length)),
            Offset.zero,
          );
        }
        distance = next;
        draw = !draw;
        index++;
      }
    }
    return dest;
  }

  @override
  bool shouldRepaint(covariant _HangulStrokePainter oldDelegate) {
    return true;
  }
}
