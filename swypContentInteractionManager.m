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
@synthesize contentDataSource = _contentDataSource, contentDisplayController = _contentDisplayController;

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
	[session addDataDelegate:_contentDataSource];
	[session addConnectionSessionInfoDelegate:self];
	if ([_sessionViewControllersBySession count] == 1){
		[self _setupForFirstSessionAdded];
	}
}

-(void)		stopMaintainingViewControllerForSwypSession:(swypConnectionSession*)session{
	[session removeDataDelegate:self];
	[session removeDataDelegate:_contentDataSource];
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

-(void)	setContentDataSource:(NSObject<swypContentDataSourceProtocol,swypConnectionSessionDataDelegate> *)contentDataSource{
	for (swypConnectionSession * connectionSession in [_sessionViewControllersBySession allKeys]){
		[connectionSession removeDataDelegate:contentDataSource];
	}
	[_contentDataSource setDatasourceDelegate:nil];
	SRELS(_contentDataSource);
	_contentDataSource	=	[contentDataSource retain];
	[_contentDataSource setDatasourceDelegate:self];
	for (swypConnectionSession * connectionSession in [_sessionViewControllersBySession allKeys]){
		[connectionSession addDataDelegate:contentDataSource];
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
	SRELS(_contentDisplayController);
	SRELS(_contentDataSource);
	SRELS(_mainWorkspaceView);
	
	[super dealloc];
}

#pragma mark -
#pragma mark delegation
#pragma mark swypConnectionSessionDataDelegate
-(void)	didBeginReceivingDataInConnectionSession:(swypConnectionSession*)session{
	[[self maintainedSwypSessionViewControllerForSession:session] setShowActiveTransferIndicator:TRUE];

}

-(void) didFinnishReceivingDataInConnectionSession:(swypConnectionSession*)session{
	[[self maintainedSwypSessionViewControllerForSession:session] setShowActiveTransferIndicator:FALSE];
}

-(BOOL) delegateWillHandleDiscernedStream:(swypDiscernedInputStream*)discernedStream wantsAsData:(BOOL *)wantsProvidedAsNSData inConnectionSession:(swypConnectionSession*)session{

	if ([self maintainedSwypSessionViewControllerForSession:session] == nil){
		return FALSE;
	}
	
	return FALSE;//we wont be handling here.. the datasource should
}

-(void)	yieldedData:(NSData*)streamData discernedStream:(swypDiscernedInputStream*)discernedStream inConnectionSession:(swypConnectionSession*)session{
	EXOLog(@"Successfully received data of type %@",[discernedStream streamType]);
}


-(void)	failedSendingStream:(NSInputStream*)stream error:(NSError*)error connectionSession:(swypConnectionSession*)session{
	
}
-(void) completedSendingStream:(NSInputStream*)stream connectionSession:(swypConnectionSession*)session{
	
	[_contentDisplayController returnContentAtIndexToNormalLocation:-1 animated:TRUE];	
	for (swypSessionViewController * sessionViewController in [_sessionViewControllersBySession allValues]){
		[sessionViewController setShowActiveTransferIndicator:FALSE];
		sessionViewController.view.layer.borderColor	= [[UIColor blackColor] CGColor];
	}
}

#pragma mark swypConnectionSessionInfoDelegate
-(void) sessionDied:			(swypConnectionSession*)session withError:(NSError*)error{
	[self stopMaintainingViewControllerForSwypSession:session];
}

#pragma mark swypContentDisplayViewControllerDelegate
-(void)	contentAtIndex: (NSUInteger)index wasDraggedToFrame: (CGRect)draggedFrame inController:(UIViewController*)contentDisplayController{
	CGRect newXlatedRect	=	[contentDisplayController.view convertRect:draggedFrame toView:_mainWorkspaceView];
	swypSessionViewController*	overlapSession	=	[self _sessionViewControllerInMainViewOverlappingRect:newXlatedRect];
	if (overlapSession){
		
		if (CGColorEqualToColor([[UIColor whiteColor] CGColor], overlapSession.view.layer.borderColor) == NO){
		
			overlapSession.view.layer.borderColor	=	[[UIColor whiteColor] CGColor];
			
		}
	}
}
-(void)	contentAtIndex: (NSUInteger)index wasReleasedWithFrame: (CGRect)draggedFrame inController:(UIViewController*)contentDisplayController{
	
	CGRect newXlatedRect	=	[contentDisplayController.view convertRect:draggedFrame toView:_mainWorkspaceView];
	
	swypSessionViewController*	overlapSession	=	[self _sessionViewControllerInMainViewOverlappingRect:newXlatedRect];
	if (overlapSession){
		NSUInteger dataLength 		= 0;
		NSInputStream*	dataSendStream	=	[_contentDataSource inputStreamForContentAtIndex:index fileType:[[_contentDataSource supportedFileTypesForContentAtIndex:index] lastObject] length:&dataLength];
		[[overlapSession connectionSession] beginSendingFileStreamWithTag:@"photo" type:[NSString imagePNGFileType] dataStreamForSend:dataSendStream length:dataLength];
		
		[overlapSession setShowActiveTransferIndicator:TRUE];
		EXOLog(@"Queuing content at index: %i", index);
	}else{
		if ([_contentDisplayController respondsToSelector:@selector(returnContentAtIndexToNormalLocation:animated:)]){
			[_contentDisplayController returnContentAtIndexToNormalLocation:index animated:TRUE];	
		}
		
		for (swypSessionViewController * sessionViewController in [_sessionViewControllersBySession allValues]){
			sessionViewController.view.layer.borderColor	= [[UIColor blackColor] CGColor];

		}

	}
}

-(UIImage*)		imageForContentAtIndex:	(NSUInteger)index	inController:(UIViewController*)contentDisplayController{
	return [_contentDataSource iconImageForContentAtIndex:index];
}
-(NSInteger)	totalContentCountInController:(UIViewController*)contentDisplayController{
	return [_contentDataSource countOfContent];
}


#pragma mark swypContentDataSourceDelegate 
-(void)	datasourceInsertedContentAtIndex:(NSUInteger)insertIndex withDatasource:	(id<swypContentDataSourceProtocol>)datasource{
	[_contentDisplayController insertContentToDisplayAtIndex:insertIndex animated:TRUE];
}
-(void)	datasourceRemovedContentAtIndex:(NSUInteger)removeIndex withDatasource:	(id<swypContentDataSourceProtocol>)datasource{
	[_contentDisplayController removeContentFromDisplayAtIndex:removeIndex animated:TRUE];
}
-(void)	datasourceSignificantlyModifiedContent:	(id<swypContentDataSourceProtocol>)datasource{
	[_contentDisplayController reloadAllData];
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
	[_contentDisplayController.view setOrigin:CGPointMake(0, 200)];
	[_contentDisplayController setContentDisplayControllerDelegate:self];
	[_contentDisplayController.view		setAlpha:0];
	[_mainWorkspaceView	addSubview:_contentDisplayController.view];
	[_contentDisplayController reloadAllData];
	[UIView animateWithDuration:.75 animations:^{
		_contentDisplayController.view.alpha = 1;
	}completion:nil];

}


@end
