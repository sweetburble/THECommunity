import 'package:flutter/material.dart';

class HeartAnimationWidget extends StatefulWidget {
  final Widget child; // 애니메이션을 적용할 위젯
  final bool isAnimating; // 애니메이션을 실행할지, 종료할지 전달받는다
  final VoidCallback? onEnd; // 애니메이션이 끝났음을 알리는 콜백 함수

  const HeartAnimationWidget({
    super.key,
    required this.child,
    required this.isAnimating,
    required this.onEnd,
  });

  @override
  State<HeartAnimationWidget> createState() => _HeartAnimationWidgetState();
}

class _HeartAnimationWidgetState extends State<HeartAnimationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController; // 애니메이션의 진행상태를 제어하는 컨트롤러
  late Animation<double> scale; // 애니메이션의 상태값을 가진다

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      // vsync는 동작을 자연스럽게 하는 역할을 하고, SingleTickerProviderStateMixin를 필요로 한다
      duration: Duration(microseconds: 150), // 애니메이션 지속 시간
    );

    scale = Tween<double>(
            begin: 1, // 애니메이션을 적용시킬 위젯의 크기
            end: 1.2 // 따라서, 하트의 크기가 100에서 시작해서 120까지 커진다
            )
        .animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
  }

  /**
   * 애니메이션을 실행하는 함수
   */
  Future<void> playAnimation() async {
    if (widget.isAnimating) {
      await _animationController.forward();
      await _animationController
          .reverse(); // AnimationController에 정의한 애니메이션을 거꾸로 한다
    }

    // 애니메이션이 다 실행되고 나서, onEnd()가 실행되어야 한다!
    await Future.delayed(Duration(milliseconds: 300));

    if (widget.onEnd != null) {
      widget.onEnd!();
    }
  }

  /**
   * HeartAnimationWidget이 업데이트 되면, 이 함수가 실행된다
   * 좋아요 로직이 실행되면, FeedCardWidget이 다시 업데이트(그려지)니까,
   * 그 안에 존재하는 HeartAnimationWidget도 다시 업데이트될 것이다. -> 이 함수 자동으로 실행!
   */
  @override
  void didUpdateWidget(HeartAnimationWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isAnimating != oldWidget.isAnimating) {
      playAnimation();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: scale,
      child: widget.child,
    );
  }
}
