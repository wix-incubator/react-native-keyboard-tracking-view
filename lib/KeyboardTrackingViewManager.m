//
//  KeyboardTrackingViewManager.m
//  ReactNativeChat
//
//  Created by Artal Druk on 19/04/2016.
//  Copyright © 2016 Wix.com All rights reserved.
//

#import "KeyboardTrackingViewManager.h"
#import "ObservingInputAccessoryView.h"
#import "RCTTextView.h"
#import "RCTTextField.h"
#import "RCTScrollView.h"
#import "RCTUIManager.h"
#import "UIView+React.h"
#import <React/RCTBridge.h>
#import <objc/runtime.h>

NSUInteger const kInputViewKey = 101010;

typedef NS_ENUM(NSUInteger, KeyboardTrackingScrollBehavior) {
    KeyboardTrackingScrollBehaviorNone,
    KeyboardTrackingScrollBehaviorScrollToBottomInvertedOnly,
    KeyboardTrackingScrollBehaviorFixedOffset
};

@interface KeyboardTrackingView : UIView
{
    ObservingInputAccessoryView* _observingAccessoryView;
    Class _newClass;
    NSMapTable *_inputViewsMap;
}

@property (nonatomic, strong) UIScrollView *scrollViewToManage;
@property (nonatomic) BOOL scrollIsInverted;
@property (nonatomic) BOOL revealKeyboardInteractive;
@property (nonatomic) KeyboardTrackingScrollBehavior scrollBehavior;

@end

@interface KeyboardTrackingView () <ObservingInputAccessoryViewDelegate, UIScrollViewDelegate>

@end

@implementation KeyboardTrackingView

-(instancetype)init
{
    self = [super init];

    if (self)
    {
        [self addObserver:self forKeyPath:@"bounds" options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:NULL];
        _inputViewsMap = [NSMapTable weakToWeakObjectsMapTable];
    }

    return self;
}

-(RCTRootView*)getRootView
{
    UIView *view = self;
    while (view.superview != nil)
    {
        view = view.superview;
        if ([view isKindOfClass:[RCTRootView class]])
            break;
    }

    if ([view isKindOfClass:[RCTRootView class]])
    {
        return (RCTRootView*)view;
    }
    return nil;
}

-(void)_swizzleWebViewInputAccessory:(UIWebView*)webview
{
    UIView* subview;
    for (UIView* view in webview.scrollView.subviews)
    {
        if([[view.class description] hasPrefix:@"UIWeb"])
        {
            subview = view;
        }
    }

    if(_newClass == nil)
    {
        NSString* name = [NSString stringWithFormat:@"%@_Tracking_%p", subview.class, self];
        _newClass = NSClassFromString(name);

        _newClass = objc_allocateClassPair(subview.class, [name cStringUsingEncoding:NSASCIIStringEncoding], 0);
        if(!_newClass) return;

        Method method = class_getInstanceMethod([UIResponder class], @selector(inputAccessoryView));
        __weak typeof(self) weakSelf = self;
        class_addMethod(_newClass, @selector(inputAccessoryView), imp_implementationWithBlock(^(id _self){return weakSelf.observingAccessoryView;}), method_getTypeEncoding(method));

        objc_registerClassPair(_newClass);
    }

    object_setClass(subview, _newClass);
    [subview reloadInputViews];
}

-(void)didMoveToWindow
{
    [super didMoveToWindow];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            NSArray<UIView*>* allSubviews = [self getBreadthFirstSubviewsForView:[self getRootView]];
            NSMutableArray<RCTScrollView*>* rctScrollViewsArray = [NSMutableArray array];

            for (UIView* subview in allSubviews) {

                if(_scrollViewToManage == nil && [subview isKindOfClass:[UIScrollView class]])
                {
            _scrollViewToManage = (UIScrollView*)subview;
                    _scrollIsInverted = CGAffineTransformEqualToTransform(_scrollViewToManage.superview.transform, CGAffineTransformMakeScale(1, -1));
                }

                if([subview isKindOfClass:[RCTScrollView class]])
                {
            [rctScrollViewsArray addObject:(RCTScrollView*)subview];
                }

                if ([subview isKindOfClass:[RCTTextField class]])
                {
                    [((RCTTextField*)subview) setInputAccessoryView:self.observingAccessoryView];
                    [((RCTTextField*)subview) reloadInputViews];

                    [_inputViewsMap setObject:subview forKey:@(kInputViewKey)];
                }
                else if ([subview isKindOfClass:[RCTTextView class]])
                {
                    UITextView *textView = [subview valueForKey:@"_textView"];
                    if (textView != nil)
                    {
                        [textView setInputAccessoryView:self.observingAccessoryView];
                        [textView reloadInputViews];

                        [_inputViewsMap setObject:textView forKey:@(kInputViewKey)];
                    }
                }
                else if ([subview isKindOfClass:[UIWebView class]])
                {
                    [self _swizzleWebViewInputAccessory:subview];
                }
            }

            if(self.revealKeyboardInteractive)
            {
                for (RCTScrollView *scrollView in rctScrollViewsArray)
                {
                    if(scrollView.scrollView == _scrollViewToManage)
                    {
                        [scrollView removeScrollListener:self];
                        [scrollView addScrollListener:self];
                        break;
                    }
                }
            }

            [self _updateScrollViewInsets];
        });
    });

}

-(void)dealloc
{
    [self removeObserver:self forKeyPath:@"bounds"];
}

- (ObservingInputAccessoryView*)observingAccessoryView
{
    if(_observingAccessoryView == nil)
    {
        _observingAccessoryView = [ObservingInputAccessoryView new];
        _observingAccessoryView.delegate = self;
    }

    return _observingAccessoryView;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
{
    self.observingAccessoryView.height = self.bounds.size.height;
}

- (NSArray*)getBreadthFirstSubviewsForView:(UIView*)view
{
    if(view == nil)
    {
        return nil;
    }

    NSMutableArray *allSubviews = [NSMutableArray new];
    NSMutableArray *queue = [NSMutableArray new];

    [allSubviews addObject:view];
    [queue addObject:view];

    while ([queue count] > 0) {
        UIView *current = [queue lastObject];
        [queue removeLastObject];

        for (UIView *n in current.subviews)
        {
            [allSubviews addObject:n];
            [queue insertObject:n atIndex:0];
        }
    }
    return allSubviews;
}

- (NSArray*)getAllReactSubviewsForView:(UIView*)view
{
    NSMutableArray *allSubviews = [NSMutableArray new];
    for (UIView *subview in view.reactSubviews)
    {
        [allSubviews addObject:subview];
        [allSubviews addObjectsFromArray:[self getAllReactSubviewsForView:subview]];
    }
    return allSubviews;
}

- (void)_updateScrollViewInsets
{
    if(self.scrollViewToManage != nil)
    {
        UIEdgeInsets insets = self.scrollViewToManage.contentInset;
        CGFloat bottomInset = MAX(self.bounds.size.height, self.observingAccessoryView.keyboardHeight + self.observingAccessoryView.height);
        if(self.scrollIsInverted)
        {
            insets.top = bottomInset;
        }
        else
        {
            insets.bottom = bottomInset;
        }
        self.scrollViewToManage.contentInset = insets;

        insets = self.scrollViewToManage.scrollIndicatorInsets;
        if(self.scrollIsInverted)
        {
            insets.top = bottomInset;
        }
        else
        {
            insets.bottom = bottomInset;
        }
        self.scrollViewToManage.scrollIndicatorInsets = insets;
    }
}

#pragma mark - ObservingInputAccessoryViewDelegate methods

- (void)observingInputAccessoryViewDidChangeFrame:(ObservingInputAccessoryView*)observingInputAccessoryView
{
    CGFloat accessoryTranslation = MIN(0, -self.observingAccessoryView.keyboardHeight);
    self.transform = CGAffineTransformMakeTranslation(0, accessoryTranslation);

    [self _updateScrollViewInsets];
}

-(void)observingInputAccessoryViewKeyboardWillAppear:(ObservingInputAccessoryView *)observingInputAccessoryView keyboardDelta:(CGFloat)delta
{
    if(self.scrollViewToManage != nil)
    {
        if(self.scrollBehavior == KeyboardTrackingScrollBehaviorScrollToBottomInvertedOnly && _scrollIsInverted)
        {
            self.scrollViewToManage.contentOffset = CGPointMake(self.scrollViewToManage.contentOffset.x, -self.scrollViewToManage.contentInset.top);
        }
        else if(self.scrollBehavior == KeyboardTrackingScrollBehaviorFixedOffset)
        {
            self.scrollViewToManage.contentOffset = CGPointMake(self.scrollViewToManage.contentOffset.x, self.scrollViewToManage.contentOffset.y + delta * (self.scrollIsInverted ? -1 : 1));
        }
    }
}

#pragma mark - UIScrollViewDelegate methods

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    UIView *inputView = [_inputViewsMap objectForKey:@(kInputViewKey)];
    if (inputView != nil && scrollView.contentOffset.y * (self.scrollIsInverted ? -1 : 1) > (self.scrollIsInverted ? scrollView.contentInset.top : scrollView.contentInset.bottom) + 50 && ![inputView isFirstResponder])
    {
        for (UIGestureRecognizer *gesture in scrollView.gestureRecognizers)
        {
            if([gesture isKindOfClass:[UIPanGestureRecognizer class]])
            {
                gesture.enabled = NO;
                gesture.enabled = YES;
            }
        }

        if([inputView respondsToSelector:@selector(reactWillMakeFirstResponder)])
        {
            [inputView performSelector:@selector(reactWillMakeFirstResponder)];
        }
        [inputView becomeFirstResponder];
        if([inputView respondsToSelector:@selector(reactDidMakeFirstResponder)])
        {
            [inputView performSelector:@selector(reactDidMakeFirstResponder)];
        }
    }
}

@end

@implementation RCTConvert (KeyboardTrackingScrollBehavior)
RCT_ENUM_CONVERTER(KeyboardTrackingScrollBehavior, (@{ @"KeyboardTrackingScrollBehaviorNone": @(KeyboardTrackingScrollBehaviorNone),
                                                       @"KeyboardTrackingScrollBehaviorScrollToBottomInvertedOnly": @(KeyboardTrackingScrollBehaviorScrollToBottomInvertedOnly),
                                                       @"KeyboardTrackingScrollBehaviorFixedOffset": @(KeyboardTrackingScrollBehaviorFixedOffset)}),
                   KeyboardTrackingScrollBehaviorNone, unsignedIntegerValue)
@end

@implementation KeyboardTrackingViewManager

@synthesize bridge = _bridge;

RCT_EXPORT_MODULE()

RCT_REMAP_VIEW_PROPERTY(scrollBehavior, scrollBehavior, KeyboardTrackingScrollBehavior)
RCT_REMAP_VIEW_PROPERTY(revealKeyboardInteractive, revealKeyboardInteractive, BOOL)

- (NSDictionary<NSString *, id> *)constantsToExport
{
    return @{
             @"KeyboardTrackingScrollBehaviorNone": @(KeyboardTrackingScrollBehaviorNone),
             @"KeyboardTrackingScrollBehaviorScrollToBottomInvertedOnly": @(KeyboardTrackingScrollBehaviorScrollToBottomInvertedOnly),
             @"KeyboardTrackingScrollBehaviorFixedOffset": @(KeyboardTrackingScrollBehaviorFixedOffset),
             };
}

- (UIView *)view
{
    return [[KeyboardTrackingView alloc] init];
}

@end
