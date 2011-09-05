//
//  swypContentInteractionManager.m
//  swyp
//
//  Created by Alexander List on 7/27/11.
//  Copyright 2011 ExoMachina. Some rights reserved -- see included 'license' file.
//

#import "swypContentInteractionManager.h"
#import "swypContentScrollTrayController.h"
#import <QuartzCore/QuartzCore.h>

@implementation swypContentInteractionManager
@synthesize contentDataSource, contentDisplayController = _contentDisplayController;

#pragma public

+(NSArray*)	supportedFileTypes{
	return [NSArray arrayWithObjects:[NSString imagePNGFileType], nil];
}

-(swypSessionViewController*)	maintainedSwypSessionViewControllerForSession:(swypConnectionSession*)session{
	if (session == nil)
		return nil;
	return  [_sessionViewControllersBySession objectForKey:[NSValue valueWithNonretainedObject:session]];
}

-(void)		maintainSwypSessionViewController:(swypSessionViewController*)sessionViewController{
	swypConnectionSession * session =	[sessionViewController connectionSession];
	[_sessionViewControllersBySession setObject:sessionViewController forKey:[NSValue valueWithNonretainedObject:session]];
	[session addDataDelegate:self];
	[session addConnectionSessionInfoDelegate:self];
	if ([_sessionViewControllersBySession count] == 1){
		[self _setupForFirstSessionAdded];
	}
}

-(void)		stopMaintainingViewControllerForSwypSession:(swypConnectionSession*)session{
	[session removeDataDelegate:self];
	[session removeConnectionSessionInfoDelegate:self];
	
	swypSessionViewController*	sessionView	=	[self maintainedSwypSessionViewControllerForSession:session];
	[UIView animateWithDuration:.75 animations:^{
		sessionView.view.alpha = 0;
	}completion:^(BOOL completed){
		[sessionView.view removeFromSuperview];		
	}];
	
	[_sessionViewControllersBySession removeObjectForKey:[NSValue valueWithNonretainedObject:session]];
	if ([_sessionViewControllersBySession count] == 0){
		[self _setupForAllSessionsRemoved];
	}
}

-(void)		stopMaintainingAllSessionViewControllers{
	for (NSValue * sessionValue	in [_sessionViewControllersBySession allKeys]){ 
		//not modifying enumerator, because enumerator is static nsarray
		swypConnectionSession * session = [sessionValue nonretainedObjectValue];
		[self stopMaintainingViewControllerForSwypSession:session];
	}
}

#pragma mark NSObject

-(id)	initWithMainWorkspaceView: (UIView*)	workspaceView{
	if (self = [super init]){
		_sessionViewControllersBySession	=	[[NSMutableDictionary alloc] init];
		_mainWorkspaceView					=	[workspaceView retain];
	}
	return self;
}

-(id) init{
	if (self = [self initWithMainWorkspaceView:nil]){
		
	}
	return  self;
}

-(void) dealloc{
	[self stopMaintainingAllSessionViewControllers];
	_contentDataSource	=	nil;
	SRELS(_contentDisplayController);
	SRELS(_mainWorkspaceView);
	
	[super dealloc];
}

#pragma mark -
#pragma mark delegation
#pragma mark swypConnectionSessionDataDelegate
-(BOOL) delegateWillHandleDiscernedStream:(swypDiscernedInputStream*)discernedStream wantsAsData:(BOOL *)wantsProvidedAsNSData inConnectionSession:(swypConnectionSession*)session{

	if ([self maintainedSwypSessionViewControllerForSession:session] == nil)
		return FALSE;
	
	if ([[NSSet setWithArray:[swypContentInteractionManager supportedFileTypes]] containsObject:[discernedStream streamType]]){
		*wantsProvidedAsNSData = TRUE;
		return TRUE;
	}else{
		EXOLog(@"Unsupported filetype: %@", [discernedStream streamType]);
		return FALSE;
	}
}

-(void)	yieldedData:(NSData*)streamData discernedStream:(swypDiscernedInputStream*)discernedStream inConnectionSession:(swypConnectionSession*)session{
	EXOLog(@"Successfully received data of type %@",[discernedStream streamType]);
}


-(void)	failedSendingStream:(NSInputStream*)stream error:(NSError*)error connectionSession:(swypConnectionSession*)session{
	
}
-(void) completedSendingStream:(NSInputStream*)stream connectionSession:(swypConnectionSession*)session{
	
}

#pragma mark swypConnectionSessionInfoDelegate
-(void) sessionDied:			(swypConnectionSession*)session withError:(NSError*)error{
	[self stopMaintainingViewControllerForSwypSession:session];
}

#pragma mark swypContentDisplayViewControllerDelegate
-(void)	contentAtIndex: (NSUInteger)index wasDraggedToFrame: (CGRect)draggedFrame inController:(UIViewController*)contentDisplayController{
	swypSessionViewController*	overlapSession	=	[self _sessionViewControllerInMainViewOverlappingRect:draggedFrame];
	if (overlapSession){
		[UIView animateWithDuration:.75 animations:^{
			overlapSession.view.layer.borderColor	=	[[UIColor whiteColor] CGColor];
		}completion:^(BOOL completed){
			[UIView animateWithDuration:.75 delay:1 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
				overlapSession.view.layer.borderColor	=	[[UIColor blackColor] CGColor];
			 }completion:nil];
		}
		 ];
	}
}
-(void)	contentAtIndex: (NSUInteger)index wasReleasedWithFrame: (CGRect)draggedFrame inController:(UIViewController*)contentDisplayController{
	swypSessionViewController*	overlapSession	=	[self _sessionViewControllerInMainViewOverlappingRect:draggedFrame];
	if (overlapSession){
		NSInputStream*	inputStream	=	[_contentDataSource inputStreamForContentAtIndex:index fileType:[[_contentDataSource supportedFileTypesForContentAtIndex:index] lastObject]];
		EXOLog(@"Queuing content at index: %i", index);
	}
}

-(UIImage*)		imageForContentAtIndex:	(NSUInteger)index	inController:(UIViewController*)contentDisplayController{
	return [_contentDataSource iconImageForContentAtIndex:index];
}
-(NSInteger)	totalContentCountInController:(UIViewController*)contentDisplayController{
	return [_contentDataSource countOfContent];
}

#pragma mark -
#pragma mark private
-(swypSessionViewController*)	_sessionViewControllerInMainViewOverlappingRect:(CGRect) testRect{
	for (swypSessionViewController * sessionViewController in [_sessionViewControllersBySession allValues]){
		//CGRectApplyAffineTransform(sessionViewController.view.frame, CGAffineTransformMakeTranslation(_contentDisplayController.view.frame.origin.x, _contentDisplayController.view.frame.origin.y))
		if (CGRectIntersectsRect(sessionViewController.view.frame, testRect)){
			return sessionViewController;
		}
	}
	
	return nil;
}

-(void)		_setupForAllSessionsRemoved{
	if (_contentDisplayController != nil){
		[UIView animateWithDuration:.75 animations:^{
			_contentDisplayController.view.alpha = 0;
		}completion:^(BOOL completed){
			[_contentDisplayController.view removeFromSuperview];		
		}];
	}
}
-(void)		_setupForFirstSessionAdded{
	if (_contentDisplayController == nil){
		_contentDisplayController	=	[[swypContentScrollTrayController alloc] init];
	}
	[_contentDisplayController setContentDisplayControllerDelegate:self];
	[_contentDisplayController.view		setAlpha:0];
	[_mainWorkspaceView	addSubview:_contentDisplayController.view];
	[UIView animateWithDuration:.75 animations:^{
		_contentDisplayController.view.alpha = 1;
	}completion:nil];

}


@end
