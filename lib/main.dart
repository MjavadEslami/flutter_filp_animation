import 'dart:math';

import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Flutter Demo',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        debugShowCheckedModeBanner: false,
        home: HomePage());
  }
}

class HomePage extends StatelessWidget {
  HomePage({Key? key}) : super(key: key);

  final pageFlipKey = GlobalKey<PageFlipBuilderState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: PageFlipBuilder(
            key: pageFlipKey,
            frontBuilder: (_) => FrontPage(
              onFlip: () {
                pageFlipKey.currentState?.flip();
              },
            ),
            backBuilder: (_) => BackPage(
              onFlip: () {
                pageFlipKey.currentState?.flip();
              },
            ),
          ),
        ),
      ),
    );
  }
}

class PageFlipBuilder extends StatefulWidget {
  const PageFlipBuilder({
    Key? key,
    required this.frontBuilder,
    required this.backBuilder,
  }) : super(key: key);
  final WidgetBuilder frontBuilder;
  final WidgetBuilder backBuilder;

  @override
  State<PageFlipBuilder> createState() => PageFlipBuilderState();
}

class PageFlipBuilderState extends State<PageFlipBuilder>
    with SingleTickerProviderStateMixin {
  bool _showFrontSide = true;
  late final AnimationController _animationController;

  @override
  void initState() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _animationController.addStatusListener(_updateStatus);
    super.initState();
  }

  @override
  void dispose() {
    _animationController.removeStatusListener(_updateStatus);
    _animationController.dispose();
    super.dispose();
  }

  void _updateStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed ||
        status == AnimationStatus.dismissed) {
      setState(() {
        _showFrontSide = !_showFrontSide;
      });
    }
  }

  void flip() {
    if (_showFrontSide) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  void _handelDargUpdate(DragUpdateDetails details) {
    final screenWidth = MediaQuery.of(context).size.width;
    _animationController.value += details.primaryDelta! / screenWidth;
  }

  void _handelDargEnd(DragEndDetails details) {
    if (_animationController.isAnimating ||
        _animationController.status == AnimationStatus.completed ||
        _animationController.status == AnimationStatus.dismissed) return;

    final screenWidth = MediaQuery.of(context).size.width;
    final currentVelocity = details.velocity.pixelsPerSecond.dx / screenWidth;

    if (_animationController.value == 0.0 && currentVelocity == 0.0) {
      return;
    }

    const flingVelocity = 2.0;
    if (_animationController.value > 0.5 ||
        _animationController.value > 0.0 && currentVelocity > flingVelocity) {
      _animationController.fling(velocity: flingVelocity);
    } else if (_animationController.value < -0.5 ||
        _animationController.value < 0.0 && currentVelocity < -flingVelocity) {
      _animationController.fling(velocity: -flingVelocity);
    } else if (_animationController.value > 0.0 ||
        _animationController.value > 0.5 && currentVelocity < -flingVelocity) {
      _animationController.value -= 1.0;
      setState(() {
        _showFrontSide = !_showFrontSide;
      });
      _animationController.fling(velocity: -flingVelocity);
    } else if (_animationController.value > -0.5 ||
        _animationController.value < -0.5 && currentVelocity > flingVelocity) {
      _animationController.value += 1.0;
      setState(() {
        _showFrontSide = !_showFrontSide;
      });
      _animationController.fling(velocity: flingVelocity);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragUpdate: _handelDargUpdate,
      onHorizontalDragEnd: _handelDargEnd,
      child: AnimatedPageFlipBuilder(
        animation: _animationController,
        showFrontSide: _showFrontSide,
        frontBuilder: widget.frontBuilder,
        backBuilder: widget.backBuilder,
      ),
    );
  }
}

class AnimatedPageFlipBuilder extends StatelessWidget {
  const AnimatedPageFlipBuilder(
      {super.key,
      required this.animation,
      required this.showFrontSide,
      required this.frontBuilder,
      required this.backBuilder});
  final Animation<double> animation;
  final bool showFrontSide;
  final WidgetBuilder frontBuilder;
  final WidgetBuilder backBuilder;

  bool get _isAnimationFirstHalf => animation.value.abs() < 0.5;

  double _getTilt() {
    var tilt = (animation.value - 0.5).abs() - 0.5;
    if (animation.value < -0.5) {
      tilt = 1.0 + animation.value;
    }
    return tilt * (_isAnimationFirstHalf ? -0.003 : 0.003);
  }

  double _rotaionAngel() {
    final rotaionValue = animation.value * pi;
    if (animation.value > 0.5) {
      return pi - rotaionValue;
    } else if (animation.value > -0.5) {
      return rotaionValue;
    } else {
      return -pi - rotaionValue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final child = _isAnimationFirstHalf
            ? frontBuilder(context)
            : backBuilder(context);
        return Transform(
          transform: Matrix4.rotationY(_rotaionAngel())
            ..setEntry(3, 0, _getTilt()),
          alignment: Alignment.center,
          child: child,
        );
      },
    );
  }
}

class FrontPage extends StatelessWidget {
  const FrontPage({
    Key? key,
    this.onFlip,
  }) : super(key: key);
  final VoidCallback? onFlip;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onFlip,
      child: Image.asset('assets/images/happy.webp'),
    );
  }
}

class BackPage extends StatelessWidget {
  const BackPage({
    Key? key,
    this.onFlip,
  }) : super(key: key);
  final VoidCallback? onFlip;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onFlip,
      child: Image.asset('assets/images/upset.png'),
    );
  }
}
