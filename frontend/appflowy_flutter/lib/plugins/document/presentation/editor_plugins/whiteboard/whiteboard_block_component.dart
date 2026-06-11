import 'package:appflowy/plugins/document/presentation/editor_plugins/actions/mobile_block_action_buttons.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:universal_platform/universal_platform.dart';

import 'whiteboard_canvas.dart';
import 'whiteboard_element.dart';

class WhiteboardBlockKeys {
  const WhiteboardBlockKeys._();

  static const String type = 'whiteboard';

  /// The serialized list of whiteboard elements.
  ///
  /// The value is a JSON-encoded String produced by
  /// [encodeWhiteboardElements].
  static const String elements = 'elements';
}

Node whiteboardNode({
  String elements = '',
}) {
  return Node(
    type: WhiteboardBlockKeys.type,
    attributes: {
      WhiteboardBlockKeys.elements: elements,
    },
  );
}

class WhiteboardBlockComponentBuilder extends BlockComponentBuilder {
  WhiteboardBlockComponentBuilder({
    super.configuration,
  });

  @override
  BlockComponentWidget build(BlockComponentContext blockComponentContext) {
    final node = blockComponentContext.node;
    return WhiteboardBlockComponentWidget(
      key: node.key,
      node: node,
      configuration: configuration,
      showActions: showActions(node),
      actionBuilder: (context, state) => actionBuilder(
        blockComponentContext,
        state,
      ),
      actionTrailingBuilder: (context, state) => actionTrailingBuilder(
        blockComponentContext,
        state,
      ),
    );
  }

  @override
  BlockComponentValidate get validate => (node) =>
      node.children.isEmpty &&
      node.attributes[WhiteboardBlockKeys.elements] is String;
}

class WhiteboardBlockComponentWidget extends BlockComponentStatefulWidget {
  const WhiteboardBlockComponentWidget({
    super.key,
    required super.node,
    super.showActions,
    super.actionBuilder,
    super.actionTrailingBuilder,
    super.configuration = const BlockComponentConfiguration(),
  });

  @override
  State<WhiteboardBlockComponentWidget> createState() =>
      _WhiteboardBlockComponentWidgetState();
}

class _WhiteboardBlockComponentWidgetState
    extends State<WhiteboardBlockComponentWidget>
    with BlockComponentConfigurable {
  @override
  BlockComponentConfiguration get configuration => widget.configuration;

  @override
  Node get node => widget.node;

  late final editorState = context.read<EditorState>();

  List<WhiteboardElement> get _elements => decodeWhiteboardElements(
        widget.node.attributes[WhiteboardBlockKeys.elements] as String?,
      );

  void _onChanged(List<WhiteboardElement> elements) {
    final encoded = encodeWhiteboardElements(elements);
    if (encoded ==
        (widget.node.attributes[WhiteboardBlockKeys.elements] as String?)) {
      return;
    }
    final transaction = editorState.transaction
      ..updateNode(widget.node, {
        WhiteboardBlockKeys.elements: encoded,
      });
    editorState.apply(transaction);
  }

  @override
  Widget build(BuildContext context) {
    Widget child = WhiteboardCanvas(
      // Re-create the canvas state when the persisted content identity changes
      // from outside (e.g. switching documents), but keep it stable across
      // local edits so interaction is not interrupted.
      elements: _elements,
      readOnly: !editorState.editable,
      onChanged: _onChanged,
    );

    if (widget.showActions && widget.actionBuilder != null) {
      child = BlockComponentActionWrapper(
        node: node,
        actionBuilder: widget.actionBuilder!,
        actionTrailingBuilder: widget.actionTrailingBuilder,
        child: child,
      );
    }

    if (UniversalPlatform.isMobile) {
      child = MobileBlockActionButtons(
        node: node,
        editorState: editorState,
        child: child,
      );
    }

    return Padding(
      padding: padding,
      child: child,
    );
  }
}
