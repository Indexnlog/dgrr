import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// 탭 전환 시 해당 탭만 로딩하는 Lazy IndexedStack.
/// 방문한 탭만 위젯 트리에 포함하여 초기 빌드 비용을 절감합니다.
class LazyIndexedStack extends StatefulWidget {
  const LazyIndexedStack({
    super.key,
    required this.navigationShell,
    required this.children,
  });

  final StatefulNavigationShell navigationShell;
  final List<Widget> children;

  @override
  State<LazyIndexedStack> createState() => _LazyIndexedStackState();
}

class _LazyIndexedStackState extends State<LazyIndexedStack> {
  final Set<int> _visitedIndices = {};

  @override
  void initState() {
    super.initState();
    _visitedIndices.add(widget.navigationShell.currentIndex);
  }

  @override
  void didUpdateWidget(LazyIndexedStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    _visitedIndices.add(widget.navigationShell.currentIndex);
  }

  @override
  Widget build(BuildContext context) {
    _visitedIndices.add(widget.navigationShell.currentIndex);
    final index = widget.navigationShell.currentIndex;
    final children = <Widget>[];
    for (var i = 0; i < widget.children.length; i++) {
      children.add(
        _visitedIndices.contains(i) ? widget.children[i] : const SizedBox.shrink(),
      );
    }
    return IndexedStack(
      index: index,
      sizing: StackFit.expand,
      children: children,
    );
  }
}
