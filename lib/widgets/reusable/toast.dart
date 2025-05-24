import 'package:flutter/material.dart';
import 'dart:async';

enum ToastPosition {
  top,
  center,
  bottom,
  topLeft,
  topRight,
  bottomLeft,
  bottomRight,
}

// Define a type for a button action
class ToastAction {
  final String label;
  final VoidCallback onPressed;
  final Color? textColor;
  final Color? backgroundColor;

  ToastAction({
    required this.label,
    required this.onPressed,
    this.textColor,
    this.backgroundColor,
  });
}

class ToastService {
  static OverlayEntry? _currentOverlayEntry;
  static Timer? _timer;

  static void show(
    BuildContext context, {
    String? title,
    required String message,
    ToastPosition position = ToastPosition.bottom,
    Duration duration = const Duration(seconds: 3),
    Color backgroundColor = Colors.black87,
    Color textColor = Colors.white,
    EdgeInsetsGeometry padding = const EdgeInsets.symmetric(
      horizontal: 16.0,
      vertical: 10.0,
    ),
    EdgeInsetsGeometry margin = const EdgeInsets.all(20.0),
    double borderRadius = 8.0,
    double fontSize = 14.0,
    bool showCloseButton = false,
    VoidCallback? onClose,
    List<ToastAction>? actions,
    Color? titleColor,
    double? titleFontSize,
    FontWeight? titleFontWeight,
  }) {
    // remove any existing toast before showing a new one
    dismiss();

    OverlayState overlayState = Overlay.of(context);
    _currentOverlayEntry = OverlayEntry(
      builder: (context) {
        return ToastWidget(
          title: title,
          message: message,
          position: position,
          backgroundColor: backgroundColor,
          textColor: textColor,
          padding: padding,
          margin: margin,
          borderRadius: borderRadius,
          fontSize: fontSize,
          showCloseButton: showCloseButton,
          onClose: onClose,
          onDismiss: dismiss,
          actions: actions,
          titleColor: titleColor,
          titleFontSize: titleFontSize,
          titleFontWeight: titleFontWeight,
        );
      },
    );

    overlayState.insert(_currentOverlayEntry!);

    _timer = Timer(duration, () {
      dismiss();
    });
  }

  /// Dismiss the current toast if it exists
  /// and cancel the timer if it is running.
  /// This method can be called to manually dismiss the toast.
  /// It is also called automatically after the specified duration.
  static void dismiss() {
    _timer?.cancel();
    _currentOverlayEntry?.remove();
    _currentOverlayEntry = null;
  }
}

class ToastWidget extends StatefulWidget {
  final String? title;
  final String message;
  final ToastPosition position;
  final Color backgroundColor;
  final Color textColor;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final double borderRadius;
  final double fontSize;
  final bool showCloseButton;
  final VoidCallback? onClose;
  final VoidCallback? onDismiss;
  final List<ToastAction>? actions;
  final Color? titleColor;
  final double? titleFontSize;
  final FontWeight? titleFontWeight;

  const ToastWidget({
    Key? key,
    this.title,
    required this.message,
    this.position = ToastPosition.bottom,
    this.backgroundColor = Colors.black87,
    this.textColor = Colors.white,
    this.padding = const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
    this.margin = const EdgeInsets.all(20.0),
    this.borderRadius = 8.0,
    this.fontSize = 14.0,
    this.showCloseButton = false,
    this.onClose,
    this.onDismiss,
    this.actions,
    this.titleColor,
    this.titleFontSize,
    this.titleFontWeight,
  }) : super(key: key);

  @override
  _ToastWidgetState createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<ToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Alignment alignment;
    switch (widget.position) {
      case ToastPosition.top:
        alignment = Alignment.topCenter;
        break;
      case ToastPosition.center:
        alignment = Alignment.center;
        break;
      case ToastPosition.bottom:
        alignment = Alignment.bottomCenter;
        break;
      case ToastPosition.topLeft:
        alignment = Alignment.topLeft;
        break;
      case ToastPosition.topRight:
        alignment = Alignment.topRight;
        break;
      case ToastPosition.bottomLeft:
        alignment = Alignment.bottomLeft;
        break;
      case ToastPosition.bottomRight:
        alignment = Alignment.bottomRight;
        break;
    }

    return Positioned.fill(
      child: Align(
        alignment: alignment,
        child: FadeTransition(
          opacity: _animation,
          child: Padding(
            padding: widget.margin,
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: widget.padding,
                decoration: BoxDecoration(
                  color: widget.backgroundColor,
                  borderRadius: BorderRadius.circular(widget.borderRadius),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: Offset(0, 3), // shadow position
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.title != null || widget.showCloseButton)
                      Padding(
                        padding: EdgeInsets.only(
                          bottom: widget.title != null ? 8.0 : 0.0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            if (widget.title != null)
                              Flexible(
                                child: Text(
                                  widget.title!,
                                  style: TextStyle(
                                    color:
                                        widget.titleColor ?? widget.textColor,
                                    fontSize:
                                        widget.titleFontSize ??
                                        widget.fontSize * 1.2,
                                    fontWeight:
                                        widget.titleFontWeight ??
                                        FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            if (widget.showCloseButton)
                              GestureDetector(
                                onTap: () {
                                  if (widget.onClose != null) {
                                    widget.onClose!();
                                  }
                                  if (widget.onDismiss != null) {
                                    widget.onDismiss!();
                                  }
                                },
                                child: Icon(
                                  Icons.close,
                                  color: widget.textColor.withValues(
                                    alpha: 0.8,
                                  ),
                                  size: widget.fontSize * 1.2,
                                ),
                              ),
                          ],
                        ),
                      ),
                    SelectableText(
                      widget.message,
                      style: TextStyle(
                        color: widget.textColor,
                        fontSize: widget.fontSize,
                      ),
                    ),
                    if (widget.actions != null && widget.actions!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Wrap(
                          spacing: 8.0, // space between buttons
                          runSpacing: 4.0, // space between rows of buttons
                          children:
                              widget.actions!.map((action) {
                                return ElevatedButton(
                                  onPressed: () {
                                    action.onPressed();
                                  },
                                  style: ElevatedButton.styleFrom(
                                    foregroundColor:
                                        action.textColor ??
                                        widget.backgroundColor,
                                    backgroundColor:
                                        action.backgroundColor ??
                                        widget.textColor,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    minimumSize: Size.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: Text(
                                    action.label,
                                    style: TextStyle(
                                      fontSize: widget.fontSize * 0.9,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                );
                              }).toList(),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
