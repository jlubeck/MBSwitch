//
//  MBSwitch.m
//  MBSwitchDemo
//
//  Created by Mathieu Bolard on 22/06/13.
//  Copyright (c) 2013 Mathieu Bolard. All rights reserved.
//

#import "MBSwitch.h"
#import <QuartzCore/QuartzCore.h>


@interface MBSwitch () <UIGestureRecognizerDelegate> {
    CAShapeLayer *_thumbLayer;
    CAShapeLayer *_fillLayer;
    CAShapeLayer *_backLayer;
    CAShapeLayer *_textLayer;
    BOOL _dragging;
	BOOL _on;
	float _thumbPadding;
}
@property (nonatomic, assign) BOOL pressed;
- (void) setBackgroundOn:(BOOL)on animated:(BOOL)animated;
- (void) showFillLayer:(BOOL)show animated:(BOOL)animated;
- (CGRect) thumbFrameForState:(BOOL)isOn;
@end

@implementation MBSwitch

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self configure];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    if( (self = [super initWithCoder:aDecoder]) ){
        [self layoutIfNeeded];
        [self configure];
    }
    return self;
}

- (void) configure {
    //Check width > height
    if (self.frame.size.height > self.frame.size.width*0.65) {
        self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, self.frame.size.width, ceilf(0.6*self.frame.size.width));
    }
    
    [self setBackgroundColor:[UIColor clearColor]];
    
    _onTintColor = [[UIColor colorWithRed:0.27f green:0.85f blue:0.37f alpha:1.00f] retain];
    [self setBacklayerOnTintColorIfNeeded];
    
    _tintColor = [[UIColor colorWithRed:0.90f green:0.90f blue:0.90f alpha:1.00f] retain];
    [self setBacklayerTintColorIfNeeded];
    
    _on = NO;
    _pressed = NO;
    _dragging = NO;
	_thumbPadding = 3.0;
	
    _backLayer = [[CAShapeLayer layer] retain];
    _backLayer.backgroundColor = [[UIColor clearColor] CGColor];
    _backLayer.frame = self.bounds;
    _backLayer.cornerRadius = self.bounds.size.height/2.0;
    CGPathRef path1 = [UIBezierPath bezierPathWithRoundedRect:_backLayer.bounds cornerRadius:floorf(_backLayer.bounds.size.height/2.0)].CGPath;
    _backLayer.path = path1;
    [_backLayer setValue:[NSNumber numberWithBool:NO] forKey:@"isOn"];
    _backLayer.fillColor = [_tintColor CGColor];
    [self.layer addSublayer:_backLayer];
    
    _fillLayer = [[CAShapeLayer layer] retain];
    _fillLayer.backgroundColor = [[UIColor clearColor] CGColor];
    _fillLayer.frame = self.bounds;
    CGPathRef path = [UIBezierPath bezierPathWithRoundedRect:_fillLayer.bounds cornerRadius:floorf(_fillLayer.bounds.size.height/2.0)].CGPath;
    _fillLayer.path = path;
    [_fillLayer setValue:[NSNumber numberWithBool:YES] forKey:@"isVisible"];
    _fillLayer.fillColor = [[UIColor whiteColor] CGColor];
    [self.layer addSublayer:_fillLayer];
    
    
    _thumbLayer = [[CAShapeLayer layer] retain];
    _thumbLayer.backgroundColor = [[UIColor clearColor] CGColor];
    _thumbLayer.frame = CGRectMake(_thumbPadding, _thumbPadding, self.bounds.size.height-(_thumbPadding*2), self.bounds.size.height-(_thumbPadding*2));
    _thumbLayer.cornerRadius = _thumbLayer.frame.size.height/2.0;
    CGPathRef knobPath = [UIBezierPath bezierPathWithRoundedRect:_thumbLayer.bounds cornerRadius:floorf(_thumbLayer.bounds.size.height/2.0)].CGPath;
    _thumbLayer.path = knobPath;
    _thumbLayer.fillColor = [UIColor whiteColor].CGColor;
    _thumbLayer.shadowColor = [UIColor blackColor].CGColor;
    _thumbLayer.shadowOffset = CGSizeMake(0.0, 3.0);
    _thumbLayer.shadowRadius = 3.0;
    _thumbLayer.shadowOpacity = 0.3;
    [self.layer addSublayer:_thumbLayer];
    
    _textLayer = [[CATextLayer alloc] init];
    _textLayer.contentsScale = [[UIScreen mainScreen] scale];
    [_textLayer setFont:@"Helvetica-Bold"];
    [_textLayer setFontSize:20];
    [_textLayer setFrame:CGRectMake(0, 13, self.bounds.size.height-(_thumbPadding*2), self.bounds.size.height-(_thumbPadding*2))];
    [_textLayer setString:@"OFF"];
    [_textLayer setAlignmentMode:kCAAlignmentCenter];
    [_thumbLayer addSublayer:_textLayer];
    
	UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                            action:@selector(tapped:)];
	[tapGestureRecognizer setDelegate:self];
	[self addGestureRecognizer:tapGestureRecognizer];
    
	UIPanGestureRecognizer *panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self
                                                                                            action:@selector(toggleDragged:)];
    //[panGestureRecognizer requireGestureRecognizerToFail:tapGestureRecognizer];
	[panGestureRecognizer setDelegate:self];
	[self addGestureRecognizer:panGestureRecognizer];
    
    [tapGestureRecognizer release];
    [panGestureRecognizer release];
}

#pragma mark -
#pragma mark Animations

- (BOOL) isOn {
    return _on;
}

- (void) setOn:(BOOL)on {
    [self setOn:on animated:YES];
}

- (void)setOn:(BOOL)on animated:(BOOL)animated {
    
    if (_on != on) {
        [self willChangeValueForKey:@"on"];
        _on = on;
        [self didChangeValueForKey:@"on"];
        [self sendActionsForControlEvents:UIControlEventValueChanged];
    }

    [CATransaction begin];
    if (animated) {
        [CATransaction setAnimationDuration:0.3];
        [CATransaction setDisableActions:NO];
        _thumbLayer.frame = [self thumbFrameForState:_on];
    }else {
        [CATransaction setDisableActions:YES];
        _thumbLayer.frame = [self thumbFrameForState:_on];
    }
    [CATransaction commit];

    [self setBackgroundOn:_on animated:animated];
    [self showFillLayer:!_on animated:animated];
}

- (void) setBackgroundOn:(BOOL)on animated:(BOOL)animated {
    BOOL isOn = [[_backLayer valueForKey:@"isOn"] boolValue];
    if (on != isOn) {
        [_backLayer setValue:[NSNumber numberWithBool:on] forKey:@"isOn"];
        [_textLayer setString: on ? @"ON" : @"OFF"];
        if (animated) {
            CABasicAnimation *animateColor = [CABasicAnimation animationWithKeyPath:@"fillColor"];
            CABasicAnimation *animateTextColor = [CABasicAnimation animationWithKeyPath:@"foregroundColor"];
            animateColor.duration = 0.22;
            animateColor.fromValue = on ? (id)_tintColor.CGColor : (id)_onTintColor.CGColor;
            animateColor.toValue = on ? (id)_onTintColor.CGColor : (id)_tintColor.CGColor;
            animateColor.removedOnCompletion = NO;
            animateColor.fillMode = kCAFillModeForwards;
            animateTextColor.duration = animateColor.duration;
            animateTextColor.fromValue = on ? (id)_fillLayer.fillColor : (id)_onTintColor.CGColor;
            animateTextColor.toValue = on ? (id)_onTintColor.CGColor : (id)_fillLayer.fillColor;
            animateTextColor.removedOnCompletion = animateColor.removedOnCompletion;
            animateTextColor.fillMode = animateColor.fillMode;
            [_backLayer addAnimation:animateColor forKey:@"animateColor"];
            [_textLayer addAnimation:animateTextColor forKey:@"animateColor"];
            [CATransaction commit];
        }else {
            [_backLayer removeAllAnimations];
            _backLayer.fillColor = on ? _onTintColor.CGColor : _tintColor.CGColor;
            [_textLayer removeAllAnimations];
            [_textLayer setForegroundColor: _backLayer.fillColor];
        }
    }
}

- (void) showFillLayer:(BOOL)show animated:(BOOL)animated {
    BOOL isVisible = [[_fillLayer valueForKey:@"isVisible"] boolValue];
    if (isVisible != show) {
        [_fillLayer setValue:[NSNumber numberWithBool:show] forKey:@"isVisible"];
        CGFloat scale = show ? 1.0 : 0.0;
        if (animated) {
            CGFloat from = show ? 0.0 : 1.0;
            CABasicAnimation *animateScale = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
            animateScale.duration = 0.22;
            animateScale.fromValue = [NSValue valueWithCATransform3D:CATransform3DMakeScale(from, from, 1.0)];
            animateScale.toValue = [NSValue valueWithCATransform3D:CATransform3DMakeScale(scale, scale, 1.0)];
            animateScale.removedOnCompletion = NO;
            animateScale.fillMode = kCAFillModeForwards;
            animateScale.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
            [_fillLayer addAnimation:animateScale forKey:@"animateScale"];
        }else {
            [_fillLayer removeAllAnimations];
            _fillLayer.transform = CATransform3DMakeScale(scale,scale,1.0);
        }
    }
}

- (void) setPressed:(BOOL)pressed {
    if (_pressed != pressed) {
        _pressed = pressed;
        
        if (!_on) {
            [self showFillLayer:!_pressed animated:YES];
        }
    }
}

- (float) thumbPadding {
	return _thumbPadding;
}

- (void) setThumbPadding:(float)thumbPadding {
	_thumbPadding = thumbPadding;
	_thumbLayer.frame = CGRectMake(_thumbPadding, _thumbPadding, self.bounds.size.height-(_thumbPadding*2), self.bounds.size.height-(_thumbPadding*2));
	[self layoutIfNeeded];
}

#pragma mark -
#pragma mark Appearance

- (void) setTintColor:(UIColor *)tintColor {
    [_tintColor autorelease];
    _tintColor = [tintColor retain];
    [self setBacklayerTintColorIfNeeded];
}

- (void)setBacklayerTintColorIfNeeded
{
    if (![[_backLayer valueForKey:@"isOn"] boolValue]) {
        _backLayer.fillColor = [_tintColor CGColor];
    }
}

- (void) setOnTintColor:(UIColor *)onTintColor {
    [_onTintColor autorelease];
    _onTintColor = [onTintColor retain];
    [self setBacklayerOnTintColorIfNeeded];
}

- (void)setBacklayerOnTintColorIfNeeded
{
    if ([[_backLayer valueForKey:@"isOn"] boolValue]) {
        _backLayer.fillColor = [_onTintColor CGColor];
    }
}

- (void) setOffTintColor:(UIColor *)offTintColor {
    _fillLayer.fillColor = [offTintColor CGColor];
    [_textLayer setForegroundColor:_fillLayer.fillColor];
}

- (UIColor *) offTintColor {
    return [UIColor colorWithCGColor:_fillLayer.fillColor];
}

- (void) setThumbTintColor:(UIColor *)thumbTintColor {
    _thumbLayer.fillColor = [thumbTintColor CGColor];
}

- (UIColor *) thumbTintColor {
    return [UIColor colorWithCGColor:_thumbLayer.fillColor];
}

- (void) setEnabled:(BOOL)enabled
{
    self.alpha = enabled ? 1.f : .5f;
    [super setEnabled:enabled];
}

#pragma mark -
#pragma mark Interaction

- (void)tapped:(UITapGestureRecognizer *)gesture
{
	if (gesture.state == UIGestureRecognizerStateEnded)
		[self setOn:!self.on animated:YES];
}

- (void)toggleDragged:(UIPanGestureRecognizer *)gesture
{
	CGFloat minToggleX = _thumbPadding;
	CGFloat maxToggleX = self.bounds.size.width-self.bounds.size.height+_thumbPadding;
    
	if (gesture.state == UIGestureRecognizerStateBegan)
	{
		self.pressed = YES;
        _dragging = YES;
	}
	else if (gesture.state == UIGestureRecognizerStateChanged)
	{
		CGPoint translation = [gesture translationInView:self];
        
		[CATransaction setDisableActions:YES];
        
		self.pressed = YES;
        
		CGFloat newX = _thumbLayer.frame.origin.x + translation.x;
		if (newX < minToggleX) newX = minToggleX;
		if (newX > maxToggleX) newX = maxToggleX;
		_thumbLayer.frame = CGRectMake(newX,
                                       _thumbLayer.frame.origin.y,
                                       _thumbLayer.frame.size.width,
                                       _thumbLayer.frame.size.height);
        
        if (CGRectGetMidX(_thumbLayer.frame) > CGRectGetMidX(self.bounds)
            && ![[_backLayer valueForKey:@"isOn"] boolValue]) {
            [self setBackgroundOn:YES animated:YES];
        }else if (CGRectGetMidX(_thumbLayer.frame) < CGRectGetMidX(self.bounds)
                  && [[_backLayer valueForKey:@"isOn"] boolValue]){
            [self setBackgroundOn:NO animated:YES];
        }
        
        
		[gesture setTranslation:CGPointZero inView:self];
	}
	else if (gesture.state == UIGestureRecognizerStateEnded)
	{
		CGFloat toggleCenter = CGRectGetMidX(_thumbLayer.frame);
        [self setOn:(toggleCenter > CGRectGetMidX(self.bounds)) animated:YES];
        _dragging = NO;
        self.pressed = NO;
	}
    
	CGPoint locationOfTouch = [gesture locationInView:self];
	if (CGRectContainsPoint(self.bounds, locationOfTouch))
		[self sendActionsForControlEvents:UIControlEventTouchDragInside];
	else
		[self sendActionsForControlEvents:UIControlEventTouchDragOutside];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	[super touchesBegan:touches withEvent:event];
    
    self.pressed = YES;
	
	[self sendActionsForControlEvents:UIControlEventTouchDown];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
	[super touchesEnded:touches withEvent:event];
    if (!_dragging) {
        self.pressed = NO;
    }
	[self sendActionsForControlEvents:UIControlEventTouchUpInside];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
	[super touchesCancelled:touches withEvent:event];
    if (!_dragging) {
        self.pressed = NO;
    }
	[self sendActionsForControlEvents:UIControlEventTouchUpOutside];
}

#pragma mark -
#pragma mark Thumb Frame

- (CGRect) thumbFrameForState:(BOOL)isOn {
    return CGRectMake(isOn ? self.bounds.size.width-self.bounds.size.height+_thumbPadding : _thumbPadding,
                      _thumbPadding,
                      self.bounds.size.height-(_thumbPadding*2),
                      self.bounds.size.height-(_thumbPadding*2));
}

#pragma mark -
#pragma mark Dealloc

- (void) dealloc {
    [_tintColor release], _tintColor = nil;
    [_onTintColor release], _onTintColor = nil;
    
    [_thumbLayer release], _thumbLayer = nil;
    [_fillLayer release], _fillLayer = nil;
    [_backLayer release], _backLayer = nil;
    [super dealloc];
}

@end
