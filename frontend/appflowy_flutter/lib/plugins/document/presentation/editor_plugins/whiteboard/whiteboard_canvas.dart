import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'whiteboard_element.dart';

/// An interactive, pannable / zoomable freehand whiteboard surface.
///
/// It owns the live editing state (current tool, in-progress draft, selection,
/// pan & zoom) and reports committed mutations through [onChanged] so the host
/// block can persist them.
class WhiteboardCanvas extends StatefulWidget {
  const WhiteboardCanvas({
    super.key,
    required this.elements,
    required this.onChanged,
    this.readOnly = false,
  });

  final List<WhiteboardElement> elements;
  final ValueChanged<List<WhiteboardElement>> onChanged;
  final bool readOnly;

  @override
  State<WhiteboardCanvas> createState() => _WhiteboardCanvasState();
}

class _WhiteboardCanvasState extends State<WhiteboardCanvas> {
  static const _palette = <int>[
    0xFF1F1F1F,
    0xFFE03131,
    0xFF2F9E44,
    0xFF1971C2,
    0xFFF08C00,
    0xFF9C36B5,
  ];

  late List<WhiteboardElement> _elements;

  WhiteboardTool _tool = WhiteboardTool.selection;
  int _strokeColor = 0xFF1F1F1F;
  double _strokeWidth = 2.0;

  // Viewport transform.
  Offset _pan = Offset.zero;
  double _scale = 1.0;

  // Interaction state.
  WhiteboardElement? _draft;
  String? _selectedId;
  _DragMode _dragMode = _DragMode.none;
  Offset _lastScreen = Offset.zero;
  Offset _lastCanvas = Offset.zero;

  // Manual double-tap detection (we route all gestures through [Listener] to
  // avoid arena conflicts with drawing).
  Offset? _lastTapScreen;
  DateTime? _lastTapTime;

  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _elements = widget.elements.map((e) => e.copy()).toList();
  }

  @override
  void didUpdateWidget(covariant WhiteboardCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reflect external (e.g. remote collab) updates only while the user is not
    // mid-interaction, to avoid clobbering local edits.
    if (_dragMode == _DragMode.none && _draft == null) {
      final incoming = encodeWhiteboardElements(widget.elements);
      if (incoming != encodeWhiteboardElements(_elements)) {
        _elements = widget.elements.map((e) => e.copy()).toList();
      }
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  WhiteboardElement? get _selected {
    if (_selectedId == null) return null;
    for (final e in _elements) {
      if (e.id == _selectedId) return e;
    }
    return null;
  }

  Offset _screenToCanvas(Offset screen) => (screen - _pan) / _scale;

  void _commit() {
    widget.onChanged(_elements.map((e) => e.copy()).toList());
  }

  String _newId() =>
      '${DateTime.now().microsecondsSinceEpoch}_${math.Random().nextInt(1 << 32)}';

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!widget.readOnly) _buildToolbar(context),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).dividerColor),
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(8),
            ),
            color: Theme.of(context).colorScheme.surface,
          ),
          clipBehavior: Clip.antiAlias,
          height: 520,
          child: _buildSurface(context),
        ),
      ],
    );
  }

  Widget _buildSurface(BuildContext context) {
    final surface = Listener(
      onPointerDown: widget.readOnly ? null : _onPointerDown,
      onPointerMove: widget.readOnly ? null : _onPointerMove,
      onPointerUp: widget.readOnly ? null : _onPointerUp,
      onPointerSignal: _onPointerSignal,
      child: MouseRegion(
        cursor: _cursorForTool(),
        child: CustomPaint(
          painter: _WhiteboardPainter(
            elements: _elements,
            draft: _draft,
            selectedId: _selectedId,
            pan: _pan,
            scale: _scale,
            gridColor: Theme.of(context).dividerColor.withValues(alpha: 0.4),
            selectionColor: Theme.of(context).colorScheme.primary,
          ),
          size: Size.infinite,
        ),
      ),
    );

    return Focus(
      focusNode: _focusNode,
      onKeyEvent: _onKeyEvent,
      child: surface,
    );
  }

  MouseCursor _cursorForTool() {
    if (widget.readOnly) return MouseCursor.defer;
    switch (_tool) {
      case WhiteboardTool.selection:
        return SystemMouseCursors.basic;
      case WhiteboardTool.text:
        return SystemMouseCursors.text;
      default:
        return SystemMouseCursors.precise;
    }
  }

  // ---------------------------------------------------------------------------
  // Toolbar
  // ---------------------------------------------------------------------------

  Widget _buildToolbar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      child: Wrap(
        spacing: 2,
        runSpacing: 2,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _toolButton(WhiteboardTool.selection, Icons.near_me_outlined, 'Select'),
          _toolButton(WhiteboardTool.pen, Icons.edit_outlined, 'Pen'),
          _toolButton(
            WhiteboardTool.rectangle,
            Icons.crop_square,
            'Rectangle',
          ),
          _toolButton(WhiteboardTool.ellipse, Icons.circle_outlined, 'Ellipse'),
          _toolButton(WhiteboardTool.line, Icons.horizontal_rule, 'Line'),
          _toolButton(WhiteboardTool.arrow, Icons.north_east, 'Arrow'),
          _toolButton(WhiteboardTool.text, Icons.title, 'Text'),
          const _ToolbarDivider(),
          ..._palette.map(_colorSwatch),
          const _ToolbarDivider(),
          _strokeWidthButton(),
          const _ToolbarDivider(),
          _iconButton(Icons.zoom_out, 'Zoom out', () => _zoomBy(1 / 1.2)),
          _iconButton(Icons.center_focus_strong, 'Reset view', _resetView),
          _iconButton(Icons.zoom_in, 'Zoom in', () => _zoomBy(1.2)),
          const _ToolbarDivider(),
          _iconButton(
            Icons.delete_outline,
            'Delete selected',
            _selected == null ? null : _deleteSelected,
          ),
          _iconButton(
            Icons.layers_clear_outlined,
            'Clear all',
            _elements.isEmpty ? null : _clearAll,
          ),
        ],
      ),
    );
  }

  Widget _toolButton(WhiteboardTool tool, IconData icon, String tooltip) {
    final selected = _tool == tool;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: () => setState(() => _tool = tool),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: selected
                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.18)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            icon,
            size: 18,
            color: selected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).iconTheme.color,
          ),
        ),
      ),
    );
  }

  Widget _iconButton(IconData icon, String tooltip, VoidCallback? onTap) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(
            icon,
            size: 18,
            color: onTap == null
                ? Theme.of(context).disabledColor
                : Theme.of(context).iconTheme.color,
          ),
        ),
      ),
    );
  }

  Widget _colorSwatch(int color) {
    final selected = _strokeColor == color;
    return Tooltip(
      message: 'Color',
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          setState(() => _strokeColor = color);
          final sel = _selected;
          if (sel != null) {
            sel.strokeColor = color;
            _commit();
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: Color(color),
              shape: BoxShape.circle,
              border: Border.all(
                color: selected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).dividerColor,
                width: selected ? 2 : 1,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _strokeWidthButton() {
    return Tooltip(
      message: 'Stroke width',
      child: PopupMenuButton<double>(
        initialValue: _strokeWidth,
        tooltip: '',
        onSelected: (value) {
          setState(() => _strokeWidth = value);
          final sel = _selected;
          if (sel != null) {
            sel.strokeWidth = value;
            _commit();
          }
        },
        itemBuilder: (context) => [
          for (final w in const [1.0, 2.0, 4.0, 6.0])
            PopupMenuItem(
              value: w,
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: w,
                    color: Theme.of(context).iconTheme.color,
                  ),
                  const SizedBox(width: 8),
                  Text('${w.toInt()}px'),
                ],
              ),
            ),
        ],
        child: const Padding(
          padding: EdgeInsets.all(6),
          child: Icon(Icons.line_weight, size: 18),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Viewport
  // ---------------------------------------------------------------------------

  void _onPointerSignal(PointerSignalEvent event) {
    if (event is PointerScrollEvent) {
      final delta = event.scrollDelta.dy;
      final factor = delta < 0 ? 1.08 : 1 / 1.08;
      _zoomAt(event.localPosition, factor);
    }
  }

  void _zoomBy(double factor) {
    final box = context.findRenderObject() as RenderBox?;
    final center = box != null
        ? Offset(box.size.width / 2, box.size.height / 2)
        : Offset.zero;
    _zoomAt(center, factor);
  }

  void _zoomAt(Offset focalScreen, double factor) {
    final newScale = (_scale * factor).clamp(0.2, 5.0);
    final canvasFocal = _screenToCanvas(focalScreen);
    setState(() {
      _scale = newScale;
      // Keep the focal point stationary on screen.
      _pan = focalScreen - canvasFocal * _scale;
    });
  }

  void _resetView() => setState(() {
        _scale = 1.0;
        _pan = Offset.zero;
      });

  // ---------------------------------------------------------------------------
  // Pointer interaction
  // ---------------------------------------------------------------------------

  void _onPointerDown(PointerDownEvent event) {
    _focusNode.requestFocus();
    final screen = event.localPosition;
    final canvas = _screenToCanvas(screen);
    _lastScreen = screen;
    _lastCanvas = canvas;

    final isDoubleTap = _registerTap(screen);

    switch (_tool) {
      case WhiteboardTool.selection:
        final hit = _hitTest(canvas);
        if (hit != null) {
          setState(() => _selectedId = hit.id);
          if (isDoubleTap && hit.type == WhiteboardElementType.text) {
            _editText(hit);
            _dragMode = _DragMode.none;
          } else {
            _dragMode = _DragMode.moving;
          }
        } else {
          setState(() => _selectedId = null);
          _dragMode = _DragMode.panning;
        }
        break;
      case WhiteboardTool.text:
        _dragMode = _DragMode.none;
        _createText(canvas);
        break;
      case WhiteboardTool.pen:
        _draft = WhiteboardElement(
          id: _newId(),
          type: WhiteboardElementType.freehand,
          points: [canvas],
          strokeColor: _strokeColor,
          strokeWidth: _strokeWidth,
        );
        _dragMode = _DragMode.drawing;
        break;
      case WhiteboardTool.rectangle:
      case WhiteboardTool.ellipse:
      case WhiteboardTool.line:
      case WhiteboardTool.arrow:
        _draft = WhiteboardElement(
          id: _newId(),
          type: _elementTypeForTool(_tool),
          points: [canvas, canvas],
          strokeColor: _strokeColor,
          strokeWidth: _strokeWidth,
        );
        _dragMode = _DragMode.drawing;
        break;
    }
  }

  void _onPointerMove(PointerMoveEvent event) {
    final screen = event.localPosition;
    final canvas = _screenToCanvas(screen);

    switch (_dragMode) {
      case _DragMode.panning:
        setState(() => _pan += screen - _lastScreen);
        break;
      case _DragMode.moving:
        final sel = _selected;
        if (sel != null) {
          setState(() => sel.translate(canvas - _lastCanvas));
        }
        break;
      case _DragMode.drawing:
        final draft = _draft;
        if (draft != null) {
          setState(() {
            if (draft.type == WhiteboardElementType.freehand) {
              draft.points.add(canvas);
            } else {
              draft.points[1] = canvas;
            }
          });
        }
        break;
      case _DragMode.none:
        break;
    }

    _lastScreen = screen;
    _lastCanvas = canvas;
  }

  void _onPointerUp(PointerUpEvent event) {
    switch (_dragMode) {
      case _DragMode.drawing:
        final draft = _draft;
        if (draft != null && _isMeaningful(draft)) {
          _elements.add(draft);
          _selectedId = draft.id;
          _commit();
        }
        setState(() => _draft = null);
        // Stay on the selection tool only for one-shot shapes? Keep current
        // tool so the user can draw multiple shapes in a row.
        break;
      case _DragMode.moving:
        _commit();
        break;
      case _DragMode.panning:
      case _DragMode.none:
        break;
    }
    _dragMode = _DragMode.none;
  }

  bool _registerTap(Offset screen) {
    final now = DateTime.now();
    final isDouble = _lastTapTime != null &&
        _lastTapScreen != null &&
        now.difference(_lastTapTime!) < const Duration(milliseconds: 350) &&
        (screen - _lastTapScreen!).distance < 24;
    _lastTapTime = now;
    _lastTapScreen = screen;
    return isDouble;
  }

  WhiteboardElement? _hitTest(Offset canvasPoint) {
    // Topmost (last drawn) first.
    for (var i = _elements.length - 1; i >= 0; i--) {
      if (_elements[i].hitTest(canvasPoint, tolerance: 8 / _scale)) {
        return _elements[i];
      }
    }
    return null;
  }

  bool _isMeaningful(WhiteboardElement element) {
    if (element.type == WhiteboardElementType.freehand) {
      return element.points.length > 1;
    }
    if (element.points.length < 2) return false;
    return (element.points.first - element.points.last).distance > 3;
  }

  WhiteboardElementType _elementTypeForTool(WhiteboardTool tool) {
    switch (tool) {
      case WhiteboardTool.rectangle:
        return WhiteboardElementType.rectangle;
      case WhiteboardTool.ellipse:
        return WhiteboardElementType.ellipse;
      case WhiteboardTool.line:
        return WhiteboardElementType.line;
      case WhiteboardTool.arrow:
        return WhiteboardElementType.arrow;
      case WhiteboardTool.pen:
      case WhiteboardTool.text:
      case WhiteboardTool.selection:
        return WhiteboardElementType.freehand;
    }
  }

  // ---------------------------------------------------------------------------
  // Text
  // ---------------------------------------------------------------------------

  Future<void> _createText(Offset canvasPoint) async {
    final value = await _promptText('');
    if (value == null || value.trim().isEmpty) return;
    final element = WhiteboardElement(
      id: _newId(),
      type: WhiteboardElementType.text,
      points: [canvasPoint],
      text: value,
      strokeColor: _strokeColor,
    );
    setState(() {
      _elements.add(element);
      _selectedId = element.id;
      _tool = WhiteboardTool.selection;
    });
    _commit();
  }

  Future<void> _editText(WhiteboardElement element) async {
    final value = await _promptText(element.text);
    if (value == null) return;
    if (value.trim().isEmpty) {
      setState(() => _elements.removeWhere((e) => e.id == element.id));
    } else {
      setState(() => element.text = value);
    }
    _commit();
  }

  Future<String?> _promptText(String initial) {
    final controller = TextEditingController(text: initial);
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Text'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: null,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Type here…',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Mutations
  // ---------------------------------------------------------------------------

  void _deleteSelected() {
    final id = _selectedId;
    if (id == null) return;
    setState(() {
      _elements.removeWhere((e) => e.id == id);
      _selectedId = null;
    });
    _commit();
  }

  void _clearAll() {
    setState(() {
      _elements.clear();
      _selectedId = null;
      _draft = null;
    });
    _commit();
  }

  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (_selectedId != null &&
        (event.logicalKey == LogicalKeyboardKey.delete ||
            event.logicalKey == LogicalKeyboardKey.backspace)) {
      _deleteSelected();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }
}

enum _DragMode { none, drawing, moving, panning }

class _ToolbarDivider extends StatelessWidget {
  const _ToolbarDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 20,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: Theme.of(context).dividerColor,
    );
  }
}

class _WhiteboardPainter extends CustomPainter {
  _WhiteboardPainter({
    required this.elements,
    required this.draft,
    required this.selectedId,
    required this.pan,
    required this.scale,
    required this.gridColor,
    required this.selectionColor,
  });

  final List<WhiteboardElement> elements;
  final WhiteboardElement? draft;
  final String? selectedId;
  final Offset pan;
  final double scale;
  final Color gridColor;
  final Color selectionColor;

  @override
  void paint(Canvas canvas, Size size) {
    _paintGrid(canvas, size);

    canvas.save();
    canvas.translate(pan.dx, pan.dy);
    canvas.scale(scale);

    for (final element in elements) {
      _paintElement(canvas, element);
      if (element.id == selectedId) {
        _paintSelection(canvas, element);
      }
    }

    final draftElement = draft;
    if (draftElement != null) {
      _paintElement(canvas, draftElement);
    }

    canvas.restore();
  }

  void _paintGrid(Canvas canvas, Size size) {
    const gridSize = 24.0;
    final paint = Paint()
      ..color = gridColor
      ..strokeWidth = 0.5;
    final spacing = gridSize * scale;
    if (spacing < 6) return;
    final startX = pan.dx % spacing;
    final startY = pan.dy % spacing;
    for (var x = startX; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = startY; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  void _paintElement(Canvas canvas, WhiteboardElement element) {
    final stroke = Paint()
      ..color = Color(element.strokeColor)
      ..strokeWidth = element.strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;

    switch (element.type) {
      case WhiteboardElementType.freehand:
        canvas.drawPath(_smoothPath(element.points), stroke);
        break;
      case WhiteboardElementType.rectangle:
        final rect = _rectOf(element);
        if (element.fillColor != null) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(rect, const Radius.circular(2)),
            Paint()..color = Color(element.fillColor!),
          );
        }
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(2)),
          stroke,
        );
        break;
      case WhiteboardElementType.ellipse:
        final rect = _rectOf(element);
        if (element.fillColor != null) {
          canvas.drawOval(rect, Paint()..color = Color(element.fillColor!));
        }
        canvas.drawOval(rect, stroke);
        break;
      case WhiteboardElementType.line:
        canvas.drawLine(element.points.first, element.points.last, stroke);
        break;
      case WhiteboardElementType.arrow:
        canvas.drawLine(element.points.first, element.points.last, stroke);
        _paintArrowHead(
          canvas,
          element.points.first,
          element.points.last,
          stroke,
        );
        break;
      case WhiteboardElementType.text:
        _paintText(canvas, element);
        break;
    }
  }

  Rect _rectOf(WhiteboardElement element) {
    return Rect.fromPoints(element.points.first, element.points.last);
  }

  Path _smoothPath(List<Offset> points) {
    final path = Path();
    if (points.isEmpty) return path;
    path.moveTo(points.first.dx, points.first.dy);
    if (points.length < 3) {
      for (final p in points.skip(1)) {
        path.lineTo(p.dx, p.dy);
      }
      return path;
    }
    for (var i = 1; i < points.length - 1; i++) {
      final mid = Offset(
        (points[i].dx + points[i + 1].dx) / 2,
        (points[i].dy + points[i + 1].dy) / 2,
      );
      path.quadraticBezierTo(points[i].dx, points[i].dy, mid.dx, mid.dy);
    }
    path.lineTo(points.last.dx, points.last.dy);
    return path;
  }

  void _paintArrowHead(Canvas canvas, Offset start, Offset end, Paint paint) {
    final angle = math.atan2(end.dy - start.dy, end.dx - start.dx);
    const headLength = 14.0;
    const headAngle = 0.5;
    final p1 = Offset(
      end.dx - headLength * math.cos(angle - headAngle),
      end.dy - headLength * math.sin(angle - headAngle),
    );
    final p2 = Offset(
      end.dx - headLength * math.cos(angle + headAngle),
      end.dy - headLength * math.sin(angle + headAngle),
    );
    canvas.drawLine(end, p1, paint);
    canvas.drawLine(end, p2, paint);
  }

  void _paintText(Canvas canvas, WhiteboardElement element) {
    final tp = TextPainter(
      text: TextSpan(
        text: element.text,
        style: TextStyle(
          color: Color(element.strokeColor),
          fontSize: element.fontSize,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, element.points.first);
  }

  void _paintSelection(Canvas canvas, WhiteboardElement element) {
    final rect = element.bounds.inflate(4);
    final paint = Paint()
      ..color = selectionColor
      ..strokeWidth = 1 / scale
      ..style = PaintingStyle.stroke;
    canvas.drawRect(rect, paint);
    final handlePaint = Paint()..color = selectionColor;
    for (final corner in [
      rect.topLeft,
      rect.topRight,
      rect.bottomLeft,
      rect.bottomRight,
    ]) {
      canvas.drawCircle(corner, 3 / scale, handlePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _WhiteboardPainter oldDelegate) {
    return true;
  }
}
