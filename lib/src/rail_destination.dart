part of "custom_navigation_rail.dart";

const double _kCircularIndicatorDiameter = 56;
const double _kIndicatorHeight = 32;

class RailDestination extends StatefulWidget {
  const RailDestination({
    required this.icon,
    required this.label,
    this.minWidth,
    this.minExtendedWidth,
    this.destinationAnimation,
    this.extendedTransitionAnimation,
    this.labelType,
    this.selected,
    this.iconTheme,
    this.labelTextStyle,
    this.onTap,
    this.indexLabel,
    this.useIndicator,
    this.padding,
    this.margin,
    this.indicatorColor,
    this.indicatorShape,
    this.disabled = false,
    this.extended = true,
    super.key,
  });

  final double? minWidth;
  final double? minExtendedWidth;
  final Widget icon;
  final Widget label;
  final Animation<double>? destinationAnimation;
  final NavigationRailLabelType? labelType;
  final bool? selected;
  final Animation<double>? extendedTransitionAnimation;
  final IconThemeData? iconTheme;
  final TextStyle? labelTextStyle;
  final VoidCallback? onTap;
  final String? indexLabel;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final bool? useIndicator;
  final Color? indicatorColor;
  final ShapeBorder? indicatorShape;
  final bool disabled;
  final bool extended;

  @override
  State<RailDestination> createState() => _RailDestinationState();
}

class _RailDestinationState extends State<RailDestination>
    with TickerProviderStateMixin {
  late CurvedAnimation _positionAnimation;
  late Animation<double> _destinationAnimation;
  late AnimationController _extendedController;
  late CurvedAnimation _extendedAnimation;

  @override
  void initState() {
    super.initState();

    _initControllers();
    _setPositionAnimation();
  }

  @override
  void didUpdateWidget(RailDestination oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.destinationAnimation != oldWidget.destinationAnimation) {
      _positionAnimation.dispose();
      _setPositionAnimation();
    }
  }

  void _initControllers() {
    _destinationAnimation = widget.destinationAnimation ??
        AnimationController(
          duration: kThemeAnimationDuration,
          vsync: this,
        )
      ..addListener(() {
        setState(() {});
      });

    _extendedController = AnimationController(
      duration: kThemeAnimationDuration,
      vsync: this,
      value: widget.extended ? 1.0 : 0.0,
    );
    _extendedAnimation = CurvedAnimation(
      parent: _extendedController,
      curve: Curves.easeInOut,
    );
    _extendedController.addListener(() {
      setState(() {});
    });
  }

  void _setPositionAnimation() {
    _positionAnimation = CurvedAnimation(
      parent: ReverseAnimation(_destinationAnimation),
      curve: Curves.easeInOut,
      reverseCurve: Curves.easeInOut.flipped,
    );
  }

  @override
  void dispose() {
    _positionAnimation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final NavigationRailThemeData navigationRailTheme =
        NavigationRailTheme.of(context);
    final NavigationRailThemeData defaults = Theme.of(context).useMaterial3
        ? _NavigationRailDefaultsM3(context)
        : _NavigationRailDefaultsM2(context);

    final bool useIndicator = widget.useIndicator ??
        navigationRailTheme.useIndicator ??
        defaults.useIndicator!;

    assert(
      useIndicator || widget.indicatorColor == null,
      "[NavigationRail.indicatorColor] does not have an effect when [NavigationRail.useIndicator] is false",
    );

    final ThemeData theme = Theme.of(context);
    final TextDirection textDirection = Directionality.of(context);
    final bool material3 = theme.useMaterial3;
    final EdgeInsets destinationPadding =
        (widget.padding ?? EdgeInsets.zero).resolve(textDirection);
    Offset indicatorOffset;
    bool applyXOffset = false;

    final double minWidth = (widget.minWidth ??
            navigationRailTheme.minWidth ??
            defaults.minWidth!) -
        (widget.padding ?? EdgeInsets.zero).horizontal -
        (widget.margin ?? EdgeInsets.zero).horizontal;
    final double minExtendedWidth = (widget.minExtendedWidth ??
            navigationRailTheme.minExtendedWidth ??
            defaults.minExtendedWidth!) -
        (widget.padding ?? EdgeInsets.zero).horizontal -
        (widget.margin ?? EdgeInsets.zero).horizontal;

    final bool selected = widget.selected ?? false;

    final IconThemeData unselectedIconTheme =
        (selected ? null : widget.iconTheme) ??
            navigationRailTheme.unselectedIconTheme ??
            defaults.unselectedIconTheme!;
    final IconThemeData selectedIconTheme =
        (selected ? widget.iconTheme : null) ??
            navigationRailTheme.selectedIconTheme ??
            defaults.selectedIconTheme!;

    final TextStyle unselectedLabelTextStyle =
        (selected ? null : widget.labelTextStyle) ??
            navigationRailTheme.unselectedLabelTextStyle ??
            defaults.unselectedLabelTextStyle!;
    final TextStyle selectedLabelTextStyle =
        (selected ? widget.labelTextStyle : null) ??
            navigationRailTheme.selectedLabelTextStyle ??
            defaults.selectedLabelTextStyle!;

    final NavigationRailLabelType labelType = widget.labelType ??
        navigationRailTheme.labelType ??
        defaults.labelType!;

    final IconThemeData iconTheme =
        selected ? selectedIconTheme : unselectedIconTheme;

    final TextStyle labelTextStyle =
        selected ? selectedLabelTextStyle : unselectedLabelTextStyle;

    final Widget themedIcon = IconTheme(
      data: widget.disabled
          ? iconTheme.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.38),
            )
          : iconTheme,
      child: widget.icon,
    );
    final Widget styledLabel = DefaultTextStyle(
      style: widget.disabled
          ? labelTextStyle.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.38),
            )
          : labelTextStyle,
      child: widget.label,
    );

    final Animation<double> extendedAnimation =
        widget.extendedTransitionAnimation ?? _extendedAnimation;

    Widget content;

    // The indicator height is fixed and equal to _kIndicatorHeight.
    // When the icon height is larger than the indicator height the indicator
    // vertical offset is used to vertically center the indicator.
    final bool isLargeIconSize =
        iconTheme.size != null && iconTheme.size! > _kIndicatorHeight;
    final double indicatorVerticalOffset =
        isLargeIconSize ? (iconTheme.size! - _kIndicatorHeight) / 2 : 0;

    switch (labelType) {
      case NavigationRailLabelType.none:
        // Split the destination spacing across the top and bottom to keep the icon centered.
        final Widget? spacing = material3
            ? const SizedBox(height: _verticalDestinationSpacingM3 / 2)
            : null;
        indicatorOffset = Offset(
          minWidth / 2 + destinationPadding.left,
          _verticalDestinationSpacingM3 / 2 +
              destinationPadding.top +
              indicatorVerticalOffset,
        );
        final Widget iconPart = Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if (spacing != null) spacing,
            SizedBox(
              width: minWidth,
              height: material3 ? null : minWidth,
              child: Center(
                // _AddIndicator is only shown on selected menu items.
                child: _AddIndicator(
                  addIndicator: useIndicator,
                  indicatorColor: widget.indicatorColor,
                  indicatorShape: widget.indicatorShape,
                  isCircular: !material3,
                  indicatorAnimation: _destinationAnimation,
                  child: themedIcon,
                ),
              ),
            ),
            if (spacing != null) spacing,
          ],
        );
        if (extendedAnimation.value == 0) {
          // This is the icon-only view of a collapsed navigation rail (i.e., no label)
          content = Padding(
            padding: widget.padding ?? EdgeInsets.zero,
            child: Stack(
              children: <Widget>[
                iconPart,
                // For semantics when label is not showing,
                SizedBox.shrink(
                  child: Visibility.maintain(
                    visible: false,
                    child: widget.label,
                  ),
                ),
              ],
            ),
          );
        } else {
          final Animation<double> labelFadeAnimation = extendedAnimation
              .drive(CurveTween(curve: const Interval(0.0, 0.25)));
          applyXOffset = true;
          // This is the content of an expanded nav item (i.e., with a label)
          content = Padding(
            padding: widget.padding ?? EdgeInsets.zero,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: lerpDouble(
                  minWidth,
                  minExtendedWidth,
                  _extendedAnimation.value,
                )!,
              ),
              child: ClipRect(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    iconPart,
                    // This is the text label
                    Flexible(
                      child: Align(
                        heightFactor: 1.0,
                        widthFactor: extendedAnimation.value,
                        alignment: AlignmentDirectional.centerStart,
                        child: FadeTransition(
                          alwaysIncludeSemantics: true,
                          opacity: labelFadeAnimation,
                          child: styledLabel,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: _horizontalDestinationPadding *
                          extendedAnimation.value,
                    ),
                  ],
                ),
              ),
            ),
          );
        }
      case NavigationRailLabelType.selected:
        final double appearingAnimationValue = 1 - _positionAnimation.value;
        final double verticalPadding = lerpDouble(
          _verticalDestinationPaddingNoLabel,
          _verticalDestinationPaddingWithLabel,
          appearingAnimationValue,
        )!;
        final Interval interval =
            selected ? const Interval(0.25, 0.75) : const Interval(0.75, 1.0);
        final Animation<double> labelFadeAnimation =
            _destinationAnimation.drive(CurveTween(curve: interval));
        final double minHeight = material3 ? 0 : minWidth;

        final Widget topSpacing =
            SizedBox(height: material3 ? 0 : verticalPadding);
        final Widget labelSpacing = SizedBox(
          height: material3
              ? lerpDouble(
                  0,
                  _verticalIconLabelSpacingM3,
                  appearingAnimationValue,
                )!
              : 0,
        );
        final Widget bottomSpacing = SizedBox(
          height: material3 ? _verticalDestinationSpacingM3 : verticalPadding,
        );
        final double indicatorHorizontalPadding =
            (destinationPadding.left / 2) - (destinationPadding.right / 2);
        final double indicatorVerticalPadding = destinationPadding.top;
        indicatorOffset = Offset(
          minWidth / 2 + indicatorHorizontalPadding,
          indicatorVerticalPadding + indicatorVerticalOffset,
        );
        if (minWidth < _NavigationRailDefaultsM2(context).minWidth!) {
          indicatorOffset = Offset(
            minWidth / 2 + _horizontalDestinationSpacingM3,
            indicatorVerticalPadding + indicatorVerticalOffset,
          );
        }
        content = Container(
          constraints: BoxConstraints(
            minWidth: minWidth,
            minHeight: minHeight,
          ),
          padding: widget.padding ??
              const EdgeInsets.symmetric(
                horizontal: _horizontalDestinationPadding,
              ),
          child: ClipRect(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                topSpacing,
                // _AddIndicator is only shown on selected menu items.
                _AddIndicator(
                  addIndicator: useIndicator,
                  indicatorColor: widget.indicatorColor,
                  indicatorShape: widget.indicatorShape,
                  isCircular: false,
                  indicatorAnimation: _destinationAnimation,
                  child: Row(
                    children: [
                      themedIcon,
                      labelSpacing,
                      Align(
                        alignment: Alignment.topCenter,
                        heightFactor: appearingAnimationValue,
                        widthFactor: 1.0,
                        child: FadeTransition(
                          alwaysIncludeSemantics: true,
                          opacity: labelFadeAnimation,
                          child: styledLabel,
                        ),
                      ),
                    ],
                  ),
                ),
                bottomSpacing,
              ],
            ),
          ),
        );
      case NavigationRailLabelType.all:
        final double minHeight = material3 ? 0 : minWidth;
        final Widget topSpacing = SizedBox(
          height: material3 ? 0 : _verticalDestinationPaddingWithLabel,
        );
        final Widget labelSpacing =
            SizedBox(height: material3 ? _verticalIconLabelSpacingM3 : 0);
        final Widget bottomSpacing = SizedBox(
          height: material3
              ? _verticalDestinationSpacingM3
              : _verticalDestinationPaddingWithLabel,
        );
        final double indicatorHorizontalPadding =
            (destinationPadding.left / 2) - (destinationPadding.right / 2);
        final double indicatorVerticalPadding = destinationPadding.top;
        indicatorOffset = Offset(
          minWidth / 2 + indicatorHorizontalPadding,
          indicatorVerticalPadding + indicatorVerticalOffset,
        );
        if (minWidth < _NavigationRailDefaultsM2(context).minWidth!) {
          indicatorOffset = Offset(
            minWidth / 2 + _horizontalDestinationSpacingM3,
            indicatorVerticalPadding + indicatorVerticalOffset,
          );
        }
        content = Container(
          constraints: BoxConstraints(
            minWidth: minWidth,
            minHeight: minHeight,
          ),
          padding: widget.padding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              topSpacing,
              // _AddIndicator is only shown on selected menu items.
              _AddIndicator(
                addIndicator: useIndicator,
                indicatorColor: widget.indicatorColor,
                indicatorShape: widget.indicatorShape,
                isCircular: false,
                indicatorAnimation: _destinationAnimation,
                child: Row(
                  children: [
                    themedIcon,
                    labelSpacing,
                    styledLabel,
                  ],
                ),
              ),
              bottomSpacing,
            ],
          ),
        );
    }

    final ColorScheme colors = Theme.of(context).colorScheme;
    final Color splashColor =
        theme.navigationRailTheme.indicatorColor ?? colors.primary;
    final bool primaryColorAlphaModified = splashColor.alpha < 255.0;

    final Color effectiveSplashColor =
        primaryColorAlphaModified ? splashColor : splashColor.withOpacity(0.12);
    final Color effectiveHoverColor =
        primaryColorAlphaModified ? splashColor : splashColor.withOpacity(0.04);

    return Semantics(
      container: true,
      selected: widget.selected,
      child: Material(
        type: MaterialType.transparency,
        child: Container(
          margin: widget.margin,
          child: Stack(
            children: <Widget>[
              // This is the splash overlay when hovering on an item
              _IndicatorInkWell(
                onTap: widget.disabled ? null : widget.onTap,
                borderRadius: BorderRadius.all(
                  Radius.circular(minWidth / 2.0),
                ),
                customBorder: widget.indicatorShape,
                splashColor: effectiveSplashColor,
                hoverColor: effectiveHoverColor,
                useMaterial3: material3,
                indicatorOffset: indicatorOffset,
                applyXOffset: applyXOffset,
                textDirection: textDirection,
                child: content,
              ),
              Semantics(
                label: widget.indexLabel,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IndicatorInkWell extends InkResponse {
  const _IndicatorInkWell({
    required this.useMaterial3,
    required this.indicatorOffset,
    required this.applyXOffset,
    required this.textDirection,
    super.child,
    super.onTap,
    ShapeBorder? customBorder,
    BorderRadius? borderRadius,
    super.splashColor,
    super.hoverColor,
  }) : super(
          containedInkWell: true,
          highlightShape: BoxShape.rectangle,
          borderRadius: useMaterial3 ? null : borderRadius,
          customBorder: useMaterial3 ? customBorder : null,
        );

  final bool useMaterial3;

  // The offset used to position Ink highlight.
  final Offset indicatorOffset;

  // Whether the horizontal offset from indicatorOffset should be used to position Ink highlight.
  // If true, Ink highlight uses the indicator horizontal offset. If false, Ink highlight is centered horizontally.
  final bool applyXOffset;

  // The text direction used to adjust the indicator horizontal offset.
  final TextDirection textDirection;

  @override
  RectCallback? getRectCallback(RenderBox referenceBox) {
    if (useMaterial3) {
      final double boxWidth = referenceBox.size.width;
      double indicatorHorizontalCenter =
          applyXOffset ? indicatorOffset.dx : boxWidth / 2;
      if (textDirection == TextDirection.rtl) {
        indicatorHorizontalCenter = boxWidth - indicatorHorizontalCenter;
      }
      return () {
        // Defines the bounds of the hover/splash rectangle
        return Rect.fromLTRB(
          0,
          0,
          referenceBox.size.width,
          referenceBox.size.height,
        );
      };
    }
    return null;
  }
}

/// When [addIndicator] is `true`, puts [child] center aligned in a [Stack] with
/// a [NavigationIndicator] behind it, otherwise returns [child].
///
/// When [isCircular] is true, the indicator will be a circle, otherwise the
/// indicator will be a stadium shape.
class _AddIndicator extends StatelessWidget {
  const _AddIndicator({
    required this.addIndicator,
    required this.isCircular,
    required this.indicatorColor,
    required this.indicatorShape,
    required this.indicatorAnimation,
    required this.child,
  });

  final bool addIndicator;
  final bool isCircular;
  final Color? indicatorColor;
  final ShapeBorder? indicatorShape;
  final Animation<double> indicatorAnimation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!addIndicator) {
      return child;
    }
    late final Widget indicator;
    if (isCircular) {
      indicator = NavigationIndicator(
        animation: indicatorAnimation,
        height: _kCircularIndicatorDiameter,
        width: _kCircularIndicatorDiameter,
        borderRadius: BorderRadius.circular(_kCircularIndicatorDiameter / 2),
        color: indicatorColor,
      );
    } else {
      indicator = NavigationIndicator(
        animation: indicatorAnimation,
        width: _kCircularIndicatorDiameter,
        shape: indicatorShape,
        // This is the color of the indicator around a selected navigation item.
        color: indicatorColor,
      );
    }

    return Stack(
      alignment: Alignment.center,
      children: <Widget>[
        indicator,
        child,
      ],
    );
  }
}

class _ExtendedNavigationRailAnimation extends InheritedWidget {
  const _ExtendedNavigationRailAnimation({
    required this.animation,
    required super.child,
  });

  final Animation<double> animation;

  @override
  bool updateShouldNotify(_ExtendedNavigationRailAnimation old) =>
      animation != old.animation;
}

// There don't appear to be tokens for these values, but they are
// shown in the spec.
const double _horizontalDestinationPadding = 8.0;
const double _verticalDestinationPaddingNoLabel = 24.0;
const double _verticalDestinationPaddingWithLabel = 16.0;
const Widget _verticalSpacer = SizedBox(height: 8.0);
const double _verticalIconLabelSpacingM3 = 4.0;
const double _verticalDestinationSpacingM3 = 12.0;
const double _horizontalDestinationSpacingM3 = 12.0;

// Hand coded defaults based on Material Design 2.
class _NavigationRailDefaultsM2 extends NavigationRailThemeData {
  _NavigationRailDefaultsM2(BuildContext context)
      : _theme = Theme.of(context),
        _colors = Theme.of(context).colorScheme,
        super(
          elevation: 0,
          groupAlignment: -1,
          labelType: NavigationRailLabelType.none,
          useIndicator: false,
          minWidth: 72.0,
          minExtendedWidth: 256,
        );

  final ThemeData _theme;
  final ColorScheme _colors;

  @override
  Color? get backgroundColor => _colors.surface;

  @override
  TextStyle? get unselectedLabelTextStyle {
    return _theme.textTheme.bodyLarge!
        .copyWith(color: _colors.onSurface.withOpacity(0.64));
  }

  @override
  TextStyle? get selectedLabelTextStyle {
    return _theme.textTheme.bodyLarge!.copyWith(color: _colors.primary);
  }

  @override
  IconThemeData? get unselectedIconTheme {
    return IconThemeData(
      size: 24.0,
      color: _colors.onSurface,
      opacity: 0.64,
    );
  }

  @override
  IconThemeData? get selectedIconTheme {
    return IconThemeData(
      size: 24.0,
      color: _colors.primary,
      opacity: 1.0,
    );
  }
}

// BEGIN GENERATED TOKEN PROPERTIES - NavigationRail

// Do not edit by hand. The code between the "BEGIN GENERATED" and
// "END GENERATED" comments are generated from data in the Material
// Design token database by the script:
//   dev/tools/gen_defaults/bin/gen_defaults.dart.

class _NavigationRailDefaultsM3 extends NavigationRailThemeData {
  _NavigationRailDefaultsM3(this.context)
      : super(
          elevation: 0.0,
          groupAlignment: -1,
          labelType: NavigationRailLabelType.none,
          useIndicator: true,
          minWidth: 80.0,
          minExtendedWidth: 256,
        );

  final BuildContext context;
  late final ColorScheme _colors = Theme.of(context).colorScheme;
  late final TextTheme _textTheme = Theme.of(context).textTheme;

  @override
  Color? get backgroundColor => _colors.surface;

  @override
  TextStyle? get unselectedLabelTextStyle {
    return _textTheme.labelMedium!.copyWith(color: _colors.onSurface);
  }

  @override
  TextStyle? get selectedLabelTextStyle {
    return _textTheme.labelMedium!.copyWith(color: _colors.onSurface);
  }

  @override
  IconThemeData? get unselectedIconTheme {
    return IconThemeData(
      size: 24.0,
      color: _colors.onSurfaceVariant,
    );
  }

  @override
  IconThemeData? get selectedIconTheme {
    return IconThemeData(
      size: 24.0,
      color: _colors.onSecondaryContainer,
    );
  }

  @override
  Color? get indicatorColor => _colors.secondaryContainer;

  @override
  ShapeBorder? get indicatorShape => const StadiumBorder();
}

// END GENERATED TOKEN PROPERTIES - NavigationRail
