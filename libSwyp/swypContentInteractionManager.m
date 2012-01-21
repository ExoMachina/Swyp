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
#import "swypThumbView.h"

static NSArray * supportedReceiveFileTypes =  nil;

@implementation swypContentInteractionManager
@synthesize contentDataSource = _contentDataSource, contentDisplayController = _contentDisplayController;
@synthesize contentViewsByContentID = _contentViewsByContentID;

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
	
	for (swypThumbView * thumb in [sessionView contentLoadingThumbs]){
		
		NSString * contentID	= [_thumbnailLoadingViewsByContentID keyForObject:thumb];
		
		[_contentDisplayController removeContentFromDisplayWithID:contentID animated:TRUE];
		[_thumbnailLoadingViewsByContentID removeObjectForKey:contentID];
	}
	
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

-(void)		sendContentWithID: (NSString*)contentID	throughConnectionSession: (swypConnectionSession*)	session{
	
	NSString * fileTypeToUse	= [[[session representedCandidate] supportedFiletypes] firstObjectCommonWithArray:[_contentDataSource supportedFileTypesForContentWithID:contentID]];
	
	if (fileTypeToUse == nil){
		[[[[UIAlertView alloc] initWithTitle:@"No Support" message:@"The recipient app doesn't want any form of this file... This is a bug on one of your apps' part" delegate:nil cancelButtonTitle:@"okay" otherButtonTitles:nil] autorelease] show];
		return;
	}
	
	NSString * tag	=	@"userContent";
	
	NSData * thumbnailImageData	=	UIImageJPEGRepresentation([_contentDataSource iconImageForContentWithID:contentID ofMaxSize:[_contentDisplayController choiceMaxSizeForContentDisplay]], .8);
	if (thumbnailImageData != nil){
		NSInputStream*	thumbnailSendStream	=	[NSInputStream inputStreamWithData:thumbnailImageData];
		[session beginSendingFileStreamWithTag:tag type:[NSString swypWorkspaceThumbnailFileType] dataStreamForSend:thumbnailSendStream length:[thumbnailImageData length]];
	}
	
	
	NSUInteger dataLength 		= 0;

	NSInputStream*	dataSendStream	=	[_contentDataSource inputStreamForContentWithID:contentID fileType:fileTypeToUse length:&dataLength];
	[session beginSendingFileStreamWithTag:tag type:fileTypeToUse dataStreamForSend:dataSendStream length:dataLength];

}


#pragma mark NSObject

-(id)	initWithMainWorkspaceView: (UIView*)workspaceView{
	if (self = [super init]){
		_sessionViewControllersBySession	=	[[NSMutableDictionary alloc] init];
		_contentViewsByContentID			=	[[swypBidirectionalMutableDictionary alloc] init];
		_thumbnailLoadingViewsByContentID	=	[[swypBidirectionalMutableDictionary alloc] init];
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
	SRELS(_contentViewsByContentID);
	SRELS(_thumbnailLoadingViewsByContentID);
	
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[super dealloc];
}


- (void)didReceiveMemoryWarning {
	
}

#pragma mark -
#pragma mark delegation
#pragma mark swypDiscernedInputStreamStatusDelegate
-(void)	updatedProgressToPercentage:(double)complete withDiscernedInputStream:(swypDiscernedInputStream*)inputStream{
	
}
-(void)	discernedInputStreamCompletedReceivingData:(swypDiscernedInputStream*)inputStream{
	_thumbnailViewsByDiscernedInputStream;
}
-(void)	discernedInputStreamFailedReceivingData:(swypDiscernedInputStream*)inputStream{
}

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
	
	if ([[discernedStream streamType] isFileType:[NSString swypWorkspaceThumbnailFileType]]){
		*wantsProvidedAsNSData = TRUE;
		return TRUE;
	}
	
	return FALSE;//we wont be handling here.. the datasource should
}

-(void)	yieldedData:(NSData*)streamData discernedStream:(swypDiscernedInputStream*)discernedStream inConnectionSession:(swypConnectionSession*)session{

	EXOLog(@"Successfully received data of type %@",[discernedStream streamType]);
	if ([[discernedStream streamType] isFileType:[NSString swypWorkspaceThumbnailFileType]]){
		
		NSInteger thumbNum	= [_thumbnailLoadingViewsByContentID count];
		NSString * thumbID	= [NSString stringWithFormat:@"thumbLoad_%i",thumbNum];
		while ([_thumbnailLoadingViewsByContentID objectForKey:thumbID] != nil) {
			thumbID = [NSString stringWithFormat:@"thumbLoad_%i",thumbNum];
		}
		
		swypThumbView * thumbView	=	[swypThumbView thumbViewWithImage:[UIImage imageWithData:streamData]];
		[thumbView setLoading:YES];

		[_thumbnailLoadingViewsByContentID setObject:thumbView forKey:thumbID];
		[_contentDisplayController addContentToDisplayWithID:thumbID animated:TRUE];

		
		swypSessionViewController * sessionView =	[_sessionViewControllersBySession objectForKey:[NSValue valueWithNonretainedObject:session]];
		[[sessionView contentLoadingThumbs] addObject:thumbView];

		swypInfoRef * swypInfo = [[session representedCandidate] matchedLocalSwypInfo];
		
		[thumbView setCenter:[[sessionView view] center]];
		
		
		CGRect thumbFrame			= [thumbView frame];
		CGRect newTranslationFrame	= CGRectZero;
		double velocity				= [swypInfo velocity];
		
		CGRect leftRect		= CGRectMake(0, 0, 150, 1200);
		CGRect rightRect	= CGRectMake(self.contentDisplayController.view.width-150, 0, 150, 1200);
		CGRect bottomRect	= CGRectMake(0, self.contentDisplayController.view.height-200, 1200, 200);
		CGRect topRect	= CGRectMake(0, 0, 1200, 200);

		if (CGRectIntersectsRect(leftRect, thumbFrame)){
			newTranslationFrame = CGRectApplyAffineTransform(thumbFrame,CGAffineTransformMakeTranslation(velocity * .5, 0));
		}else if (CGRectIntersectsRect(rightRect, thumbFrame)){
			newTranslationFrame = CGRectApplyAffineTransform(thumbFrame,CGAffineTransformMakeTranslation(velocity * -0.5, 0));
		}else if (CGRectIntersectsRect(bottomRect, thumbFrame)){
			newTranslationFrame = CGRectApplyAffineTransform(thumbFrame,CGAffineTransformMakeTranslation(0, velocity * -0.5));
		}else if (CGRectIntersectsRect(topRect, thumbFrame)){
			newTranslationFrame = CGRectApplyAffineTransform(thumbFrame,CGAffineTransformMakeTranslation(0, velocity * 0.5));
		}else{
			newTranslationFrame = thumbFrame;
		}
		
		EXOLog(@"Org %@, Dest %@",rectDescriptionString(thumbFrame),rectDescriptionString(newTranslationFrame));

		[UIView animateWithDuration:.25 delay:0 options:UIViewAnimationOptionAllowUserInteraction|UIViewAnimationOptionAllowAnimatedContent|UIViewAnimationOptionBeginFromCurrentState|UIViewAnimationOptionCurveEaseOut animations:^{
			[thumbView setFrame:newTranslationFrame];
		}completion:nil];
		
	}
}



-(void)	failedSendingStream:(NSInputStream*)stream error:(NSError*)error connectionSession:(swypConnectionSession*)session{
	
}
-(void) completedSendingStream:(NSInputStream*)stream connectionSession:(swypConnectionSession*)session{
	EXOLog(@"Completed sending stream in session!:%@", [session description]);
}

#pragma mark swypConnectionSessionInfoDelegate
-(void) sessionDied:			(swypConnectionSession*)session withError:(NSError*)error{
	[self stopMaintainingViewControllerForSwypSession:session];
}

#pragma mark swyp

#pragma mark swypContentDisplayViewControllerDelegate
-(void)	contentWithID:(NSString*)contentID underwentSwypOutWithInfoRef:(swypInfoRef*)ref inController:(UIViewController<swypContentDisplayViewController>*)contentDisplayController{
	
	CGRect contentRect		=	[[_contentViewsByContentID objectForKey:contentID] frame];
	
//	EXOLog(@"underwentSwypOutWithInfoRef contentRect: {x,y,w,h}, {%f,%f,%f,%f}",contentRect.origin.x,contentRect.origin.y,contentRect.size.width,contentRect.size.height);
	EXOLog(@"TODO: %@",@"setup tragectory calculation");
	
	swypSessionViewController*	overlapSession	=	[self _sessionViewControllerInMainViewOverlappingRect:contentRect];

	if (overlapSession){
		[self sendContentWithID:contentID throughConnectionSession:[overlapSession connectionSession]];
		
		[overlapSession setShowActiveTransferIndicator:TRUE];
	}

}

-(UIView*)		viewForContentWithID:(NSString*)contentID ofMaxSize:(CGSize)maxIconSize inController:(UIViewController<swypContentDisplayViewController>*)contentDisplayController{
	
	UIView * cachedView	=	[_contentViewsByContentID valueForKey:contentID];
	if (cachedView == nil){
		cachedView = [_thumbnailLoadingViewsByContentID valueForKey:contentID];
	}
	
	if (cachedView == nil){
		UIImage * previewImage =	[_contentDataSource iconImageForContentWithID:contentID ofMaxSize:maxIconSize];
		
		assert(previewImage != nil);
		
		UIImageView * photoTileView	=	[[UIImageView alloc] initWithImage:previewImage];
		
		[photoTileView setUserInteractionEnabled:TRUE];
		[photoTileView setBackgroundColor:[UIColor blackColor]];
		
		CALayer	*layer	=	photoTileView.layer;
		[layer setBorderColor: [[UIColor whiteColor] CGColor]];
		[layer setBorderWidth:8.0f];
		[layer setShadowColor: [[UIColor blackColor] CGColor]];
		[layer setShadowOpacity:0.9f];
		[layer setShadowOffset: CGSizeMake(1, 3)];
		[layer setShadowRadius:4.0];
		CGMutablePathRef shadowPath		=	CGPathCreateMutable();
		CGPathAddRect(shadowPath, NULL, CGRectMake(0, 0, photoTileView.size.width, photoTileView.size.height));
		[layer setShadowPath:shadowPath];
        CFRelease(shadowPath);
		[photoTileView setClipsToBounds:NO];
		
		
		[_contentViewsByContentID setValue:photoTileView forKey:contentID];
		cachedView = photoTileView;
		SRELS(photoTileView);
	}
	return cachedView;
	
}

-(NSArray*)		allIDsForContentInController:(UIViewController<swypContentDisplayViewController>*)contentDisplayController{
	NSMutableArray * ids = [NSMutableArray array];
	[ids addObjectsFromArray:[_contentDataSource idsForAllContent]];
	[ids addObjectsFromArray:[_thumbnailLoadingViewsByContentID allKeys]];
	return ids;
}


#pragma mark swypContentDataSourceDelegate 
-(void)	datasourceInsertedContentWithID:(NSString*)insertID withDatasource:	(id<swypContentDataSourceProtocol>)datasource{
	[_contentDisplayController addContentToDisplayWithID:insertID animated:TRUE];
}

-(void)	datasourceRemovedContentWithID:(NSString*)removeID withDatasource:	(id<swypContentDataSourceProtocol>)datasource{
	[_contentViewsByContentID removeObjectForKey:removeID];
	[_contentDisplayController removeContentFromDisplayWithID:removeID animated:TRUE];
}

-(void)	datasourceSignificantlyModifiedContent:	(id<swypContentDataSourceProtocol>)datasource{
	[_contentViewsByContentID removeAllObjects];
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
