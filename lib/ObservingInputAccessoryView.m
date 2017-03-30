//
//  ObservingInputAccessoryView.m
//  ReactNativeChat
//
//  Created by Artal Druk on 11/04/2016.
//  Copyright © 2016 Wix.com All rights reserved.
//

#import "ObservingInputAccessoryView.h"

@implementation ObservingInputAccessoryView

- (instancetype)init
{
	self = [super init];
	
	if(self)
	{
        self.userInteractionEnabled = NO;
        self.translatesAutoresizingMaskIntoConstraints = NO;
		self.autoresizingMask = UIViewAutoresizingFlexibleHeight;
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_keyboardWillShowNotification:) name:UIKeyboardWillShowNotification object:nil];
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_keyboardDidShowNotification:) name:UIKeyboardDidShowNotification object:nil];
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_keyboardWillHideNotification:) name:UIKeyboardWillHideNotification object:nil];
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_keyboardDidHideNotification:) name:UIKeyboardDidHideNotification object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_keyboardWillChangeFrameNotification:) name:UIKeyboardWillChangeFrameNotification object:nil];
	}
	
	return self;
}

- (void)willMoveToSuperview:(UIView *)newSuperview
{
	if (self.superview)
	{
		[self.superview removeObserver:self forKeyPath:@"center"];
		[self.superview removeObserver:self forKeyPath:@"bounds"];
	}
	
	if (newSuperview != nil)
	{
		[newSuperview addObserver:self forKeyPath:@"center" options:0 context:nil];
		[newSuperview addObserver:self forKeyPath:@"bounds" options:0 context:nil];
	}
	
	[super willMoveToSuperview:newSuperview];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if ((object == self.superview) && ([keyPath isEqualToString:@"center"] || [keyPath isEqualToString:@"bounds"]))
	{
		_keyboardHeight = self.window.bounds.size.height - self.superview.frame.origin.y - self.intrinsicContentSize.height;
		
		[self.delegate observingInputAccessoryViewDidChangeFrame:self];
	}
}

-(void)dealloc
{
	[self.superview removeObserver:self forKeyPath:@"center"];
	[self.superview removeObserver:self forKeyPath:@"bounds"];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (CGSize)intrinsicContentSize
{
	return CGSizeMake(self.bounds.size.width, _keyboardState == KeyboardStateWillShow || _keyboardState == KeyboardStateWillHide ? 0 : _height);
}

- (void)setHeight:(CGFloat)height
{
	_height = height;
	
	[self invalidateIntrinsicContentSize];
}

- (void)_keyboardWillShowNotification:(NSNotification*)notification
{
	_keyboardState = KeyboardStateWillShow;
	
	[self invalidateIntrinsicContentSize];
}

- (void)_keyboardDidShowNotification:(NSNotification*)notification
{
	_keyboardState = KeyboardStateShown;
	
	[self invalidateIntrinsicContentSize];
}

- (void)_keyboardWillHideNotification:(NSNotification*)notification
{
	_keyboardState = KeyboardStateWillHide;
	
	[self invalidateIntrinsicContentSize];
}

- (void)_keyboardDidHideNotification:(NSNotification*)notification
{
	_keyboardState = KeyboardStateHidden;
	
	[self invalidateIntrinsicContentSize];
}

- (void)_keyboardWillChangeFrameNotification:(NSNotification*)notification
{
    if(self.window)
    {
        return;
    }
    
    _keyboardHeight = [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue].size.height;
    
    [self.delegate observingInputAccessoryViewDidChangeFrame:self];
}

@end
