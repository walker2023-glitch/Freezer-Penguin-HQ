import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'preview_store.dart';

Future<T?> pushPreview<T>(BuildContext context, Widget page) {
  final store = context.read<PreviewKitchenStore>();
  return Navigator.of(context).push<T>(
    MaterialPageRoute(
      builder: (_) => ChangeNotifierProvider.value(
        value: store,
        child: page,
      ),
    ),
  );
}
