import 'package:flutter/material.dart';
import '../../../../core/theme/app_pallete.dart';

class SlideActionButton extends StatefulWidget {
  final VoidCallback onSlideComplete;
  const SlideActionButton({super.key, required this.onSlideComplete});

  @override
  State<SlideActionButton> createState() => _SlideActionButtonState();
}

class _SlideActionButtonState extends State<SlideActionButton>
    with SingleTickerProviderStateMixin {
  double _dragValue = 0.0;
  double _maxWidth = 0.0;
  bool _submitted = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _maxWidth =
            constraints.maxWidth - 60; // Button width - drag handle width
        return Container(
          height: 60,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              // Placeholder Text
              Center(
                child: Opacity(
                  opacity: 1 - (_dragValue / _maxWidth).clamp(0.0, 1.0),
                  child: const Text(
                    "Get Started >>",
                    style: TextStyle(
                      color: AppPallete.primary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              // Draggable Handle
              Positioned(
                left: _dragValue,
                child: GestureDetector(
                  onHorizontalDragUpdate: (details) {
                    if (_submitted) return;
                    setState(() {
                      _dragValue = (_dragValue + details.delta.dx).clamp(
                        0.0,
                        _maxWidth,
                      );
                    });
                  },
                  onHorizontalDragEnd: (details) {
                    if (_submitted) return;
                    if (_dragValue > _maxWidth * 0.8) {
                      setState(() {
                        _dragValue = _maxWidth;
                        _submitted = true;
                      });
                      widget.onSlideComplete();
                    } else {
                      setState(() {
                        _dragValue = 0.0;
                      });
                    }
                  },
                  child: Container(
                    height: 50,
                    width: 50,
                    margin: const EdgeInsets.all(5),
                    decoration: const BoxDecoration(
                      color: AppPallete.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_forward, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
