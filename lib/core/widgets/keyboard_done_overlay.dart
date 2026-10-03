import 'package:flutter/material.dart';

/// Gives decimal and multiline keyboards a consistent way to close them.
class KeyboardDoneOverlay extends StatelessWidget {
  const KeyboardDoneOverlay({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.viewInsetsOf(context).bottom;
    return Stack(
      children: [
        child,
        if (keyboardHeight > 0)
          Positioned(
            left: 0,
            right: 0,
            bottom: keyboardHeight,
            child: Material(
              color: Theme.of(context).colorScheme.surface,
              elevation: 2,
              child: SafeArea(
                top: false,
                bottom: false,
                child: Align(
                  alignment: Alignment.centerRight,
                  heightFactor: 1,
                  child: TextButton(
                    onPressed: () =>
                        FocusManager.instance.primaryFocus?.unfocus(),
                    child: const Text('Done'),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
