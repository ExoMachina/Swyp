//
//  swypContentInteractionManager.m
//  swyp
//
//  Created by Alexander List on 7/27/11.
//  Copyright 2011 ExoMachina. Some rights reserved -- see included 'license' file.
//

#import "swypContentInteractionManager.h"
#import "swypPhotoPlayground.h"
#import <QuartzCore/QuartzCore.h>

static NSArray * supportedReceiveFileTypes =  nil;

@implementation swypContentInteractionManager
@synthesize contentDataSource = _contentDataSource, contentDisplayController = _contentDisplayController;

#pragma public

+(NSArray*)	supportedReceiptFileTypes{	
	return supportedReceiveFileTypes;
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
}

-(void)		stopMaintainingAllSessionViewControllers{
	for (NSValue * sessionValue	in [_sessionViewControllersBySession allKeys]){ 
		//not modifying enumerator, because enumerator is static nsarray
		swypConnectionSession * session = [sessionValue nonretainedObjectValue];
		[self stopMaintainingViewControllerForSwypSession:session];
	}
}
-(void) setContentDisplayController:(UIViewController<swypContentDisplayViewController> *)contentDisplayController{
	//we make it nicely sized for you!
	CGRect contentRect	=	CGRectMake(0,0, [_mainWorkspaceView bounds].size.width,[_mainWorkspaceView bounds].size.height);
	[contentDisplayController.view setFrame:contentRect];
	[contentDisplayController.view setAutoresizingMask:UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight];
	
	SRELS(_contentDisplayController);
	_contentDisplayController = [contentDisplayController retain];
	[_contentDisplayController setContentDisplayControllerDelegate:self];
}

-(void)	setContentDataSource:(NSObject<swypContentDataSourceProtocol,swypConnectionSessionDataDelegate> *)contentDataSource{
	for (swypConnectionSession * connectionSession in [_sessionViewControllersBySession allKeys]){
		[connectionSession removeDataDelegate:contentDataSource];
	}
	SRELS(supportedReceiveFileTypes);
	[_contentDataSource setDatasourceDelegate:nil];
	SRELS(_contentDataSource);
	
	_contentDataSource	=	[contentDataSource retain];
	[_contentDataSource setDatasourceDelegate:self];
	supportedReceiveFileTypes = [[_contentDataSource supportedFileTypesForReceipt] retain];
	
	for (swypConnectionSession * connectionSession in [_sessionViewControllersBySession allKeys]){
		[connectionSession addDataDelegate:contentDataSource];
	}
	
	
	[[self contentDisplayController] reloadAllData];
}

-(void)		initializeInteractionWorkspace{
	
	[self _displayContentDisplayController:TRUE];
}

-(void) sendContentAtIndex: (NSUInteger)index	throughConnectionSession: (swypConnectionSession*)	session{
	NSUInteger dataLength 		= 0;
	
	NSString * fileTypeToUse	= [[[session representedCandidate] supportedFiletypes] firstObjectCommonWithArray:[_contentDataSource supportedFileTypesForContentAtIndex:index]];
	
	if (fileTypeToUse == nil){
		[[[[UIAlertView alloc] initWithTitle:@"No Support" message:@"The recipient app doesn't want any form of this file... This is a bug on one of your apps' part" delegate:nil cancelButtonTitle:@"okay" otherButtonTitles:nil] autorelease] show];
		return;
	}
	
	NSInputStream*	dataSendStream	=	[_contentDataSource inputStreamForContentAtIndex:index fileType:fileTypeToUse length:&dataLength];
	[session beginSendingFileStreamWithTag:@"photo" type:fileTypeToUse dataStreamForSend:dataSendStream length:dataLength];
	
}

-(void)		temporarilyExagerateContentAtIndex:	(NSUInteger)index{
	
}

#pragma mark NSObject

-(id)	initWithMainWorkspaceView: (UIView*)workspaceView{
	if (self = [super init]){
		_sessionViewControllersBySession	=	[[NSMutableDictionary alloc] init];
		_mainWorkspaceView					=	[workspaceView retain];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveMemoryWarning) name:UIApplicationDidReceiveMemoryWarningNotification object:self];
	}
	return self;
}

-(id) init{
	EXOLog(@"Invalid initialization of %@; simple 'init' not supported",@"interactionManager");
	return nil;
}

-(void) dealloc{
	[self stopMaintainingAllSessionViewControllers];
	SRELS(_contentDisplayController);
	SRELS(_contentDataSource);
	SRELS(_mainWorkspaceView);
	
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[super dealloc];
}


- (void)didReceiveMemoryWarning {
	
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
	
	[_contentDisplayController returnContentAtIndexToNormalLocation:-1 animated:TRUE ];	
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
		
		[self sendContentAtIndex:index throughConnectionSession:[overlapSession connectionSession]];
				
		[overlapSession setShowActiveTransferIndicator:TRUE];
		EXOLog(@"Queuing content at index: %i", index);
	}else{
		//not all implmentations will wish for this functionality
//		if ([_contentDisplayController respondsToSelector:@selector(returnContentAtIndexToNormalLocation:animated:)]){
//			[_contentDisplayController returnContentAtIndexToNormalLocation:index animated:TRUE];	
//		}
		
		for (swypSessionViewController * sessionViewController in [_sessionViewControllersBySession allValues]){
			sessionViewController.view.layer.borderColor	= [[UIColor blackColor] CGColor];
		}
	}
}


-(UIImage*)		imageForContentAtIndex:	(NSUInteger)index ofMaxSize:(CGSize)maxIconSize	inController:(UIViewController*)contentDisplayController{
	return [_contentDataSource iconImageForContentAtIndex:index ofMaxSize:maxIconSize];
}
-(NSInteger)	totalContentCountInController:(UIViewController*)contentDisplayController{
	return [_contentDataSource countOfContent];
}
#pragma mark swypContentDataSourceDelegate 
-(void)	datasourceInsertedContentAtIndex:(NSUInteger)insertIndex withDatasource:(id<swypContentDataSourceProtocol>)datasource withSession:(swypConnectionSession*)session{
	
	CGPoint contentShowLocation	=	CGPointZero;
	if (session){
		contentShowLocation		=	[[[session representedCandidate] matchedLocalSwypInfo] endPoint];
	}
	[_contentDisplayController insertContentToDisplayAtIndex:insertIndex animated:TRUE fromStartLocation:contentShowLocation];
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

-(void) _displayContentDisplayController:(BOOL)display{
	if (display){
		
		if (_contentDisplayController == nil){
			_contentDisplayController	=	[[swypPhotoPlayground alloc] init];
			[_contentDisplayController setContentDisplayControllerDelegate:self];
		}
					

		if (_contentDisplayController.view.superview == nil){
			[_contentDisplayController.view setOrigin:CGPointMake(0, 0)];
			[_contentDisplayController.view		setAlpha:0];
#pragma mark CLUDGE: TGTBSB
			[_mainWorkspaceView	insertSubview:_contentDisplayController.view atIndex:1];
			[UIView animateWithDuration:.75 animations:^{
				_contentDisplayController.view.alpha = 1;
			}completion:nil];
			[_contentDisplayController reloadAllData];
		}

	}else{
		[UIView animateWithDuration:.75 animations:^{
			_contentDisplayController.view.alpha = 0;
		}completion:^(BOOL completed){
			[_contentDisplayController.view removeFromSuperview];	
			
		}];
	}
	
}


@end
