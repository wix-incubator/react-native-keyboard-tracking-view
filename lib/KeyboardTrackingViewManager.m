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

@interface KeyboardTrackingView : UIView
{
	ObservingInputAccessoryView* _observingAccessoryView;
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

- (void)didUpdateReactSubviews
{
	[super didUpdateReactSubviews];
	
	NSArray<UIView*>* allSubviews = [self getAllSubviewsForView:self];
	
	for (UIView* subview in allSubviews) {
		if ([subview isKindOfClass:[RCTTextField class]])
		{
			UIView *inputAccesorry = self.observingAccessoryView;
			[((RCTTextField*)subview) setInputAccessoryView:inputAccesorry];
		}
		else if ([subview isKindOfClass:[RCTTextView class]])
		{
			UITextView *textView = [subview valueForKey:@"_textView"];
			if (textView != nil)
			{
				UIView *inputAccesorry = self.observingAccessoryView;
				[textView setInputAccessoryView:inputAccesorry];
			}
		}
	}
	
	[self _updateScrollViewInsets];
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

- (NSArray*)getAllSubviewsForView:(UIView*)view
{
	NSMutableArray *allSubviews = [NSMutableArray new];
	for (UIView *subview in view.reactSubviews)
	{
		[allSubviews addObject:subview];
		[allSubviews addObjectsFromArray:[self getAllSubviewsForView:subview]];
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
	UIEdgeInsets insets = self.scrollViewToManage.contentInset;
	insets.bottom = MAX(self.bounds.size.height, self.observingAccessoryView.keyboardHeight + self.observingAccessoryView.height);
	self.scrollViewToManage.contentInset = insets;
	insets = self.scrollViewToManage.scrollIndicatorInsets;
	insets.bottom = MAX(self.bounds.size.height, self.observingAccessoryView.keyboardHeight + self.observingAccessoryView.height);
	self.scrollViewToManage.scrollIndicatorInsets = insets;
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

@implementation KeyboardTrackingManager

@synthesize bridge=_bridge;

- (dispatch_queue_t)methodQueue
{
	return dispatch_get_main_queue();
}

RCT_EXPORT_MODULE(KeyboardTrackingManager)

RCT_EXPORT_METHOD(setScrollViewRef:(nonnull NSNumber *)scrollviewReactTag trackingViewReactTag:(nonnull NSNumber *)trackingViewReactTag)
{
	KeyboardTrackingView* trackingView = (id)[self.bridge.uiManager viewForReactTag:trackingViewReactTag];
	RCTScrollView* rctScrollView = (id)[self.bridge.uiManager viewForReactTag:scrollviewReactTag];
	if(trackingView && rctScrollView) {
		trackingView.scrollViewToManage = rctScrollView.scrollView;
	}
}

@end
