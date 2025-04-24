import 'package:flutter/material.dart';

class EmptyExpanded extends StatelessWidget {
  final int flex;

  const EmptyExpanded({
    super.key,
    this.flex = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Container(),
    );
  }
}

/**
 * 플러터의 기본 위젯인 Spacer로 대체할 수 있다!!!
 */
const emptyExpanded = Spacer();
