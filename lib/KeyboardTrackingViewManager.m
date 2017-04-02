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
#import "RCTBridge.h"
#import "RCTUIManager.h"
#import "UIView+React.h"
#import <objc/runtime.h>

@interface KeyboardTrackingView : UIView
{
    ObservingInputAccessoryView* _observingAccessoryView;
    Class _newClass;
}

@property (nonatomic, strong) UIScrollView *scrollViewToManage;

@end

@interface KeyboardTrackingView () <ObservingInputAccessoryViewDelegate>

@end

@implementation KeyboardTrackingView

-(instancetype)init
{
    self = [super init];
    
    if (self)
    {
        [self addObserver:self forKeyPath:@"bounds" options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:NULL];
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
        return view;
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
            
            for (UIView* subview in allSubviews) {
                
                if(_scrollViewToManage == nil && [subview isKindOfClass:[UIScrollView class]])
                {
                    _scrollViewToManage = subview;
                }
                
                if ([subview isKindOfClass:[RCTTextField class]])
                {
                    UIView *inputAccesorry = self.observingAccessoryView;
                    [((RCTTextField*)subview) setInputAccessoryView:inputAccesorry];
                    [((RCTTextField*)subview) reloadInputViews];
                }
                else if ([subview isKindOfClass:[RCTTextView class]])
                {
                    UITextView *textView = [subview valueForKey:@"_textView"];
                    if (textView != nil)
                    {
                        UIView *inputAccesorry = self.observingAccessoryView;
                        [textView setInputAccessoryView:inputAccesorry];
                        [textView reloadInputViews];
                    }
                }
                else if ([subview isKindOfClass:[UIWebView class]])
                {
                    [self _swizzleWebViewInputAccessory:subview];
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

- (void)observingInputAccessoryViewDidChangeFrame:(ObservingInputAccessoryView*)observingInputAccessoryView
{
    CGFloat accessoryTranslation = MIN(0, -self.observingAccessoryView.keyboardHeight);
    self.transform = CGAffineTransformMakeTranslation(0, accessoryTranslation);
    
    [self _updateScrollViewInsets];
}

- (void)_updateScrollViewInsets
{
    if(self.scrollViewToManage != nil)
    {
        UIEdgeInsets insets = self.scrollViewToManage.contentInset;
        insets.bottom = MAX(self.bounds.size.height, self.observingAccessoryView.keyboardHeight + self.observingAccessoryView.height);
        self.scrollViewToManage.contentInset = insets;
        insets = self.scrollViewToManage.scrollIndicatorInsets;
        insets.bottom = MAX(self.bounds.size.height, self.observingAccessoryView.keyboardHeight + self.observingAccessoryView.height);
        self.scrollViewToManage.scrollIndicatorInsets = insets;
    }
}

@end

@implementation KeyboardTrackingViewManager

@synthesize bridge = _bridge;

RCT_EXPORT_MODULE()

- (UIView *)view
{
    return [[KeyboardTrackingView alloc] init];
}

@end
