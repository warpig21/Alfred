import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';

import 'slash_menu_item_builder.dart';

final _keywords = [
  'whiteboard',
  'canvas',
  'draw',
  'drawing',
  'sketch',
  'diagram',
];

/// Inserts a freehand whiteboard / canvas block.
SelectionMenuItem whiteboardSlashMenuItem = SelectionMenuItem.node(
  getName: () => 'Whiteboard',
  keywords: _keywords,
  nodeBuilder: (editorState, _) => whiteboardNode(),
  replace: (_, node) => node.delta?.isEmpty ?? false,
  nameBuilder: slashMenuItemNameBuilder,
  iconBuilder: (editorState, isSelected, style) => Icon(
    Icons.gesture,
    size: 18,
    color: isSelected
        ? style.selectionMenuItemSelectedIconColor
        : style.selectionMenuItemIconColor,
  ),
);
