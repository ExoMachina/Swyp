//
//  swypSwypableContentSuperview.m
//  libSwyp
//
//  Created by Alexander List on 1/31/12.
//  Copyright (c) 2012 ExoMachina. All rights reserved.
//

#import "swypSwypableContentSuperview.h"

@implementation swypSwypableContentSuperview
@synthesize superviewContentDelegate = _superviewContentDelegate, superviewWorkspaceDelegate = _superviewWorkspaceDelegate;

#pragma mark functionality
-(void)longPressChanged:(UILongPressGestureRecognizer*)recognizer{
	UIView * recognizerView	=	[self hitTest:[recognizer locationInView:self] withEvent:nil];
	if (recognizerView == self){
		return;
	}
	
	if (recognizer.state == UIGestureRecognizerStateBegan){
		for (UIView * nextTestView = recognizerView; recognizerView != self; nextTestView = [nextTestView superview]){
			if ([_superviewContentDelegate subview:nextTestView isSwypableWithSwypableContentSuperview:self]){
				//cause content to be added to datasource
				NSString * contentID =	[_superviewContentDelegate contentIDForSwypableSubview:recognizerView withinSwypableContentSuperview:self];
//				EXOLog(@"swypableContentView did begin swyp on %@",contentID);
				assert(contentID);
				
				//compute coordinate scheme origin difference
				CGPoint localLoc		=	CGPointZero;
				CGPoint workspaceLoc	=	[self convertPoint:localLoc toView:[_superviewWorkspaceDelegate workspaceView]];
				CGSize coordinateDiff	=	CGSizeMake(workspaceLoc.x-localLoc.x, workspaceLoc.y-localLoc.y);
				
				CGRect workspaceFrame	=	[recognizerView frame];
				
				if ([[UIScreen mainScreen] respondsToSelector:@selector(displayLinkWithTarget:selector:)] &&
					([UIScreen mainScreen].scale == 2.0)) {
					// Retina display
					workspaceFrame.origin.x	+=	coordinateDiff.width/2;
					workspaceFrame.origin.y	+=	coordinateDiff.height/2;					

				}else{
					workspaceFrame.origin.x	+=	coordinateDiff.width;
					workspaceFrame.origin.y	+=	coordinateDiff.height;					
				}
				
				//show workpace
				[_superviewWorkspaceDelegate presentContentSwypWorkspaceAtopViewController:[self _parentUIViewController] withContentView:self forContentOfID:contentID atRect:workspaceFrame];
				
				//forward touches
				//need to work on the following
//				[[_superviewWorkspaceDelegate workspaceView] touchesBegan:_trackedTouchesToForward withEvent:_storedEvent];
//				[_remoteTrackingTouches addObjectsFromArray:[_trackedTouchesToForward allObjects]];
//				[_trackedTouchesToForward removeAllObjects];
				
				break;//don't need to test next one up... we've won.
			}
		}
	}
}

#pragma mark UIView
/*
-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
	if ([_remoteTrackingTouches count]){
		[[_superviewWorkspaceDelegate workspaceView] touchesBegan:touches withEvent:event];
		[_remoteTrackingTouches addObjectsFromArray:[touches allObjects]];
	}else{
		[_trackedTouchesToForward addObjectsFromArray:[touches allObjects]];		
	}
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event{
	if ([_remoteTrackingTouches count]){
		[[_superviewWorkspaceDelegate workspaceView] touchesCancelled:touches withEvent:event];
	}
	
	for (UITouch * touch in touches){
		[_trackedTouchesToForward removeObject:touch];
		[_remoteTrackingTouches removeObject:touch];
	}
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event{
	if ([_remoteTrackingTouches count]){
		[[_superviewWorkspaceDelegate workspaceView] touchesEnded:touches withEvent:event];
	}
	
	for (UITouch * touch in touches){
		[_trackedTouchesToForward removeObject:touch];
		[_remoteTrackingTouches removeObject:touch];
	}
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event{
	if ([_remoteTrackingTouches count]){
		assert([_superviewWorkspaceDelegate workspaceView] != nil); //need to set superviewWorkspaceDelegate.. This isn't hard to setup.
		[[_superviewWorkspaceDelegate workspaceView] touchesMoved:touches withEvent:event];
	}
}
 */


- (id) _parentUIViewController {
    id nextResponder = [self nextResponder];
    if ([nextResponder isKindOfClass:[UIViewController class]]) {
        return nextResponder;
    } else if ([nextResponder isKindOfClass:[UIView class]]) {
        return [nextResponder _parentUIViewController];
    } else {
        return nil;
    }
}


#pragma mark NSObject
-(id)	initWithContentDelegate:(id<swypSwypableContentSuperviewContentDelegate>)contentDelegate workspaceDelegate:(id<swypSwypableContentSuperviewWorkspaceDelegate>)workspaceDelegate frame:(CGRect)frame{
	if (self = [super initWithFrame:frame]){
		_superviewContentDelegate	= contentDelegate;
		_superviewWorkspaceDelegate	= workspaceDelegate;
		
		_pressRecognizer			=	[[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressChanged:)];
		[self addGestureRecognizer:_pressRecognizer];
		
		_trackedTouchesToForward	=	[NSMutableSet new];
		_remoteTrackingTouches		=	[NSMutableSet new];
		
	}
	return self;
}
-(id)initWithFrame:(CGRect)frame{
	if (self = [self initWithContentDelegate:nil workspaceDelegate:nil frame:frame]){
		
	}
	return self;
}
-(id)init{
	if (self = [self initWithFrame:CGRectZero]){
		
	}
	return self;
}

-(void)dealloc{
	SRELS(_pressRecognizer);
	SRELS(_trackedTouchesToForward);
	SRELS(_remoteTrackingTouches);
	_superviewContentDelegate	=	nil;
	_superviewWorkspaceDelegate	=	nil;
	[super dealloc];
}


@end
