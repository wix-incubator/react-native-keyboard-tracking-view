//
//  KeyboardTrackingViewManager.m
//  ReactNativeChat
//
//  Created by Artal Druk on 19/04/2016.
//  Copyright © 2016 Wix.com All rights reserved.
//

#import "KeyboardTrackingViewManager.h"
#import "ObservingInputAccessoryView.h"

#if __has_include(<React/RCTTextView.h>)
#import <React/RCTTextView.h>
#else
#import "RCTTextView.h"
#endif

#if __has_include(<React/RCTTextField.h>)
#import <React/RCTTextField.h>
#else
#import "RCTTextField.h"
#endif

#if __has_include(<React/RCTUITextView.h>)
#import <React/RCTUITextView.h>
#else
#import "RCTUITextView.h"
#endif

#if __has_include(<React/RCTUITextField.h>)
#import <React/RCTUITextField.h>
#else
#import "RCTUITextField.h"
#endif

#if __has_include(<React/RCTScrollView.h>)
#import <React/RCTScrollView.h>
#else
#import "RCTScrollView.h"
#endif

#if __has_include(<React/RCTBridge.h>)
#import <React/RCTBridge.h>
#else
#import "RCTBridge.h"
#endif


#if __has_include(<React/RCTUIManager.h>)
#import <React/RCTUIManager.h>
#else
#import "RCTUIManager.h"
#endif

#if __has_include(<React/UIView+React.h>)
#import <React/UIView+React.h>
#else
#import "UIView+React.h"
#endif

#import <objc/runtime.h>


NSUInteger const kInputViewKey = 101010;
NSUInteger const kMaxDeferedInitializeAccessoryViews = 15;


typedef NS_ENUM(NSUInteger, KeyboardTrackingScrollBehavior) {
    KeyboardTrackingScrollBehaviorNone,
    KeyboardTrackingScrollBehaviorScrollToBottomInvertedOnly,
    KeyboardTrackingScrollBehaviorFixedOffset
};

@interface KeyboardTrackingView : UIView
{
    Class _newClass;
    NSMapTable *_inputViewsMap;
}

@property (nonatomic, strong) UIScrollView *scrollViewToManage;
@property (nonatomic) BOOL scrollIsInverted;
@property (nonatomic) BOOL revealKeyboardInteractive;
@property (nonatomic) BOOL isDraggingScrollView;
@property (nonatomic) BOOL manageScrollView;
@property (nonatomic) BOOL requiresSameParentToManageScrollView;
@property (nonatomic) NSUInteger deferedInitializeAccessoryViewsCount;
@property (nonatomic) CGFloat originalHeight;
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
        _deferedInitializeAccessoryViewsCount = 0;
        [ObservingInputAccessoryView sharedInstance].delegate = self;

        _manageScrollView = YES;

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(rctContentDidAppearNotification:) name:RCTContentDidAppearNotification object:nil];
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
        class_addMethod(_newClass, @selector(inputAccessoryView), imp_implementationWithBlock(^(id _self){return [ObservingInputAccessoryView sharedInstance];}), method_getTypeEncoding(method));

        objc_registerClassPair(_newClass);
    }

    object_setClass(subview, _newClass);
    [subview reloadInputViews];
}

- (void)initializeAccessoryViewsAndHandleInsets
{
    NSArray<UIView*>* allSubviews = [self getBreadthFirstSubviewsForView:[self getRootView]];
    NSMutableArray<RCTScrollView*>* rctScrollViewsArray = [NSMutableArray array];

    for (UIView* subview in allSubviews) {

        if(_manageScrollView)
        {
            if(_scrollViewToManage == nil)
            {
                if(_requiresSameParentToManageScrollView && [subview isKindOfClass:[RCTScrollView class]] && subview.superview == self.superview)
                {
                    _scrollViewToManage = ((RCTScrollView*)subview).scrollView;
                }
                else if([subview isKindOfClass:[UIScrollView class]])
                {
                    _scrollViewToManage = (UIScrollView*)subview;
                }

                if(_scrollViewToManage != nil)
                {
                    _scrollIsInverted = CGAffineTransformEqualToTransform(_scrollViewToManage.superview.transform, CGAffineTransformMakeScale(1, -1));
                }
            }

            if([subview isKindOfClass:[RCTScrollView class]])
            {
                [rctScrollViewsArray addObject:(RCTScrollView*)subview];
            }
        }

        if ([subview isKindOfClass:[RCTTextField class]])
        {
            [(RCTUITextField*)[(RCTTextField*)subview backedTextInputView] setInputAccessoryView:[ObservingInputAccessoryView sharedInstance]];
            [(RCTUITextField*)[(RCTTextField*)subview backedTextInputView] reloadInputViews];

            [_inputViewsMap setObject:subview forKey:@(kInputViewKey)];
        }
        else if ([subview isKindOfClass:[RCTTextView class]])
        {
            UITextView *textView = (RCTUITextView*)[(RCTTextView*)subview backedTextInputView];
            if (textView != nil)
            {
                [textView setInputAccessoryView:[ObservingInputAccessoryView sharedInstance]];
                [textView reloadInputViews];

                [_inputViewsMap setObject:textView forKey:@(kInputViewKey)];
            }
        }
        else if ([subview isKindOfClass:[UIWebView class]])
        {
            [self _swizzleWebViewInputAccessory:(UIWebView*)subview];
        }
    }

    for (RCTScrollView *scrollView in rctScrollViewsArray)
    {
        if(scrollView.scrollView == _scrollViewToManage)
        {
            [scrollView removeScrollListener:self];
            [scrollView addScrollListener:self];
            break;
        }
    }

    [self _updateScrollViewInsets];

    _originalHeight = [ObservingInputAccessoryView sharedInstance].height;
}

-(void) deferedInitializeAccessoryViewsAndHandleInsets
{
    if(self.window == nil)
    {
        return;
    }

    if ([ObservingInputAccessoryView sharedInstance].height == 0 && self.deferedInitializeAccessoryViewsCount < kMaxDeferedInitializeAccessoryViews)
    {
        self.deferedInitializeAccessoryViewsCount++;

        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self deferedInitializeAccessoryViewsAndHandleInsets];
        });
    }
    else
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self initializeAccessoryViewsAndHandleInsets];
        });
    }
}

-(void)didMoveToWindow
{
    [super didMoveToWindow];

    self.deferedInitializeAccessoryViewsCount = 0;

    [self deferedInitializeAccessoryViewsAndHandleInsets];
}

-(void)dealloc
{
    [self removeObserver:self forKeyPath:@"bounds"];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
{
    [ObservingInputAccessoryView sharedInstance].height = self.bounds.size.height;
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
        CGFloat bottomInset = MAX(self.bounds.size.height, [ObservingInputAccessoryView sharedInstance].keyboardHeight + [ObservingInputAccessoryView sharedInstance].height);
        CGFloat originalBottomInset = self.scrollIsInverted ? insets.top : insets.bottom;
        CGPoint originalOffset = self.scrollViewToManage.contentOffset;
        if(self.scrollIsInverted)
        {
            insets.top = bottomInset;
        }
        else
        {
            insets.bottom = bottomInset;
        }
        self.scrollViewToManage.contentInset = insets;

        if(self.scrollBehavior == KeyboardTrackingScrollBehaviorScrollToBottomInvertedOnly && _scrollIsInverted)
        {
            BOOL fisrtTime = [ObservingInputAccessoryView sharedInstance].keyboardHeight == 0 && [ObservingInputAccessoryView sharedInstance].keyboardState == KeyboardStateHidden;
            BOOL willOpen = [ObservingInputAccessoryView sharedInstance].keyboardHeight != 0 && [ObservingInputAccessoryView sharedInstance].keyboardState == KeyboardStateHidden;
            BOOL isOpen = [ObservingInputAccessoryView sharedInstance].keyboardHeight != 0 && [ObservingInputAccessoryView sharedInstance].keyboardState == KeyboardStateShown;
            if(fisrtTime || willOpen || (isOpen && !self.isDraggingScrollView))
            {
                [self.scrollViewToManage setContentOffset:CGPointMake(self.scrollViewToManage.contentOffset.x, -self.scrollViewToManage.contentInset.top) animated:!fisrtTime];
            }
        }
        else if(self.scrollBehavior == KeyboardTrackingScrollBehaviorFixedOffset && !self.isDraggingScrollView)
        {
            CGFloat insetsDiff = (bottomInset - originalBottomInset) * (self.scrollIsInverted ? -1 : 1);
            self.scrollViewToManage.contentOffset = CGPointMake(originalOffset.x, originalOffset.y + insetsDiff);
        }

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

#pragma RCTRootView notifications

- (void) rctContentDidAppearNotification:(NSNotification*)notification
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if(notification.object == [self getRootView] && _manageScrollView && _scrollViewToManage == nil)
        {
            [self initializeAccessoryViewsAndHandleInsets];
        }
    });
}

#pragma mark - ObservingInputAccessoryViewDelegate methods

- (void)observingInputAccessoryViewDidChangeFrame:(ObservingInputAccessoryView*)observingInputAccessoryView
{
    CGFloat accessoryTranslation = MIN(0, -[ObservingInputAccessoryView sharedInstance].keyboardHeight);
    self.transform = CGAffineTransformMakeTranslation(0, accessoryTranslation);

    [self _updateScrollViewInsets];
}

#pragma mark - UIScrollViewDelegate methods

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if([ObservingInputAccessoryView sharedInstance].keyboardState != KeyboardStateHidden || !self.revealKeyboardInteractive)
    {
        return;
    }

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

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    self.isDraggingScrollView = YES;
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset
{
    self.isDraggingScrollView = NO;
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    self.isDraggingScrollView = NO;
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
RCT_REMAP_VIEW_PROPERTY(manageScrollView, manageScrollView, BOOL)
RCT_REMAP_VIEW_PROPERTY(requiresSameParentToManageScrollView, requiresSameParentToManageScrollView, BOOL)

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
