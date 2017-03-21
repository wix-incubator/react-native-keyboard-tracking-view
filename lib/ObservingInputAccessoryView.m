//
//  ObservingInputAccessoryView.m
//  ReactNativeChat
//
//  Created by Artal Druk on 11/04/2016.
//  Copyright © 2016 Wix.com All rights reserved.
//

#import "ObservingInputAccessoryView.h"

@implementation ObservingInputAccessoryView

- (void)willMoveToSuperview:(UIView *)newSuperview
{
	if (self.superview)
	{
		[self.superview removeObserver:self forKeyPath:@"center"];
		//    [self.superview removeObserver:self forKeyPath:@"frame"];
	}
	
	if (newSuperview != nil)
	{
		[newSuperview addObserver:self forKeyPath:@"center" options:0 context:nil];
		//    [newSuperview addObserver:self forKeyPath:@"frame" options:0 context:nil];
	}
	
	[super willMoveToSuperview:newSuperview];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if ((object == self.superview) && ([keyPath isEqualToString:@"center"] || [keyPath isEqualToString:@"frame"]))
	{
		[[NSNotificationCenter defaultCenter] postNotificationName:ObservingInputAccessoryViewFrameDidChangeNotification object:@(self.superview.frame.origin.y)];
	}
}

-(void)dealloc
{
	[self.superview removeObserver:self forKeyPath:@"center"];
	[self.superview removeObserver:self forKeyPath:@"frame"];
}

@end
