import 'package:flutter/material.dart';

class ExpandableFab extends StatefulWidget {
  final double distance;
  final List<ActionButton> children;

  const ExpandableFab({
    Key? key,
    required this.distance,
    required this.children,
  }) : super(key: key);

  @override
  State<ExpandableFab> createState() => _ExpandableFABState();
}

class _ExpandableFABState extends State<ExpandableFab> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          bottom: 16.0, // Adjust this value as needed
          right: 16.0, // Adjust this value to move to the right
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (int index = 0; index < widget.children.length; index++)
                Column(
                  children: [
                    _open ? Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.0),
                      child: widget.children[index],
                    ) : Container(),
                    SizedBox(height: 14.0),
                  ],
                ),
              SizedBox(height: 10),
              FloatingActionButton(
                heroTag: 'uniqueTag1',
                onPressed: () {
                  setState(() {
                    _open = !_open;
                  });
                },
                tooltip: _open ? 'Close' : 'Expand',
                child: Icon(_open ? Icons.keyboard_arrow_down_rounded : Icons.keyboard_arrow_up_rounded),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class ActionButton extends StatelessWidget {
  final VoidCallback onPressed;
  final Widget icon;

  const ActionButton({
    Key? key,
    required this.onPressed,
    required this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: onPressed,
      tooltip: 'Add',
      child: icon,
    );
  }
}