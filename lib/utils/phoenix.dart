import 'package:flutter/material.dart';

class Phoenix extends StatefulWidget {
  final Widget child;
  
  const Phoenix({Key? key, required this.child}) : super(key: key);
  
  static void rebirth(BuildContext context) {
    context.findAncestorStateOfType<_PhoenixState>()?.restartApp();
  }

  @override
  _PhoenixState createState() => _PhoenixState();
}

class _PhoenixState extends State<Phoenix> {
  Key key = UniqueKey();

  void restartApp() {
    setState(() {
      key = UniqueKey();
    });
  }

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: key,
      child: widget.child,
    );
  }
}