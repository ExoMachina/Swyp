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
@synthesize contentDataSource = _contentDataSource;
@synthesize contentViewsByContentID = _contentViewsByContentID;

#pragma public

+(NSArray*)	supportedReceiptFileTypes{	
	return supportedReceiveFileTypes;
}

-(void)		updateSupportedReceiptTypes{
	NSMutableArray * types	=	[NSMutableArray array];
	for (id <swypConnectionSessionDataDelegate> delelgate in [_dataDelegates reverseObjectEnumerator]){
		[types addObjectsFromArray:[delelgate supportedFileTypesForReceipt]];
	}
	
	SRELS(supportedReceiveFileTypes);
	supportedReceiveFileTypes	=	[types retain];
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
	for (id<swypConnectionSessionDataDelegate> dDel in _dataDelegates){
		[session addDataDelegate:dDel];
	}
	
	[session addConnectionSessionInfoDelegate:self];
}

-(void)		stopMaintainingViewControllerForSwypSession:(swypConnectionSession*)session{
	[session removeDataDelegate:self];
	for (id <swypConnectionSessionDataDelegate> dataDelegate in _dataDelegates){
		[session removeDataDelegate:dataDelegate];	
	}
	[session removeConnectionSessionInfoDelegate:self];
	
	swypSessionViewController*	sessionViewController	=	[self maintainedSwypSessionViewControllerForSession:session];
	
	for (swypThumbView * thumb in [sessionViewController contentLoadingThumbs]){
		
		NSString * contentID	= [_thumbnailLoadingViewsByContentID keyForObject:thumb];
		
		for (UIViewController <swypContentDisplayViewController>* contentDisplay in [_contentDisplayControllerByWorkspaceView allValues]){
			if ([[contentDisplay allDisplayedObjectIDs] containsObject:contentID]){
				[contentDisplay removeContentFromDisplayWithID:contentID animated:TRUE];				
			}
		}
		[_thumbnailLoadingViewsByContentID removeObjectForKey:contentID];
	}
	
	[UIView animateWithDuration:.75 animations:^{
		sessionViewController.view.alpha = 0;
	}completion:^(BOOL completed){
		[sessionViewController.view removeFromSuperview];		
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

-(void) addDataDelegate: (id <swypConnectionSessionDataDelegate> )		dataDelegate{
	NSUInteger existingIndex	=	[_dataDelegates indexOfObject:dataDelegate];
	if (existingIndex != NSNotFound){
		[_dataDelegates removeObjectAtIndex:existingIndex];
	}
	[_dataDelegates addObject:dataDelegate];
	
	for (NSValue * connectionSession in [_sessionViewControllersBySession allKeys]){
		[[connectionSession nonretainedObjectValue] addDataDelegate:dataDelegate];
	}
	[self updateSupportedReceiptTypes];
}

-(void) removeDataDelegate: (id <swypConnectionSessionDataDelegate> )	dataDelegate{
	NSUInteger existingIndex	=	[_dataDelegates indexOfObject:dataDelegate];
	if (existingIndex != NSNotFound){
		[_dataDelegates removeObjectAtIndex:existingIndex];
	}	
	
	for (NSValue * connectionSession in [_sessionViewControllersBySession allKeys]){
		[[connectionSession nonretainedObjectValue] removeDataDelegate:dataDelegate];
	}
	[self updateSupportedReceiptTypes];
}

-(void)	setContentDataSource:(NSObject<swypContentDataSourceProtocol> *)contentDataSource{
	if (_contentDataSource == contentDataSource){
		return;
	}
		
	SRELS(supportedReceiveFileTypes);
	if ([_contentDataSource respondsToSelector:@selector(setDatasourceDelegate:)]){
		[_contentDataSource setDatasourceDelegate:nil];
	}
	SRELS(_contentDataSource);
	
	if (contentDataSource == nil)
		return;
	
	_contentDataSource	=	[contentDataSource retain];
	if ([_contentDataSource respondsToSelector:@selector(setDatasourceDelegate:)]){
		[_contentDataSource setDatasourceDelegate:self];
	}
	
	[self updateSupportedReceiptTypes];
	
	for (UIViewController <swypContentDisplayViewController>* contentDisplay in [_contentDisplayControllerByWorkspaceView allValues]){
		[contentDisplay reloadAllData];
	}

}

-(UIViewController<swypContentDisplayViewController>*)	currentActiveContentDisplayController{
	UIViewController<swypContentDisplayViewController>* activeDisplay	=	[_contentDisplayControllerByWorkspaceView objectForKey:[NSValue valueWithNonretainedObject:_mainWorkspaceView]];
	
	for (UIViewController<swypContentDisplayViewController>* testDisplayC in [_contentDisplayControllerByWorkspaceView allValues]){
		//careful here, the testView might be nil; if so, you've probably released the view elsewhere without removing it from interaciton manager
		
		if ([testDisplayC.view isDescendantOfView:[[UIApplication sharedApplication] keyWindow]]){
			activeDisplay = testDisplayC;
		}
	}
	
	return activeDisplay;
}

-(UIViewController<swypContentDisplayViewController>*)	displayControllerForContentID:(NSString*)contentID{
	for (UIViewController<swypContentDisplayViewController>* testDisplayC in [_contentDisplayControllerByWorkspaceView allValues]){
		if ([[testDisplayC allDisplayedObjectIDs] containsObject:contentID]){
			return testDisplayC;
		}
	}
	return nil;
}

-(void)	addSwypWorkspaceViewToInteractionLoop:(swypWorkspaceView*)worksapceView{
	assert([_contentDisplayControllerByWorkspaceView objectForKey:[NSValue valueWithNonretainedObject:worksapceView]] == nil);
	[self _addContentDisplayControllerToWorkspaceView:worksapceView];
}

-(void)	removeSwypWorkspaceViewFromInteractionLoop:(swypWorkspaceView*)worksapceView{
	UIViewController * existingVC	=	[_contentDisplayControllerByWorkspaceView objectForKey:[NSValue valueWithNonretainedObject:worksapceView]];
	assert(existingVC != nil);
	
	[UIView animateWithDuration:.75 animations:^{
		existingVC.view.alpha = 0;
	}completion:^(BOOL complet){
		[existingVC.view removeFromSuperview];
	}];
	
	[_contentDisplayControllerByWorkspaceView removeObjectForKey:[NSValue valueWithNonretainedObject:worksapceView]];
}


-(void)		sendContentWithID: (NSString*)contentID	throughConnectionSession: (swypConnectionSession*)	session{

	//If you display content, you must be able to send it
	assert ([_contentDataSource respondsToSelector:@selector(supportedFileTypesForContentWithID:)]);
	
	NSString * fileTypeToUse	= 	[[[session representedCandidate] supportedFiletypes] firstObjectCommonWithArray:[_contentDataSource supportedFileTypesForContentWithID:contentID]];
	
	if (fileTypeToUse == nil){
		[[[[UIAlertView alloc] initWithTitle:@"No Support" message:@"The recipient app doesn't want any form of this file... This is a bug on one of your apps' part" delegate:nil cancelButtonTitle:@"okay" otherButtonTitles:nil] autorelease] show];
		return;
	}
	
	NSString * tag	=	@"userContent";
	
	assert([_contentDataSource respondsToSelector:@selector(iconImageForContentWithID:ofMaxSize:)]);
	NSData * thumbnailImageData	=	UIImageJPEGRepresentation([_contentDataSource iconImageForContentWithID:contentID ofMaxSize:[[self currentActiveContentDisplayController] choiceMaxSizeForContentDisplay]], .8);
	if (thumbnailImageData != nil){
		NSInputStream*	thumbnailSendStream	=	[NSInputStream inputStreamWithData:thumbnailImageData];
		[session beginSendingFileStreamWithTag:tag type:[NSString swypWorkspaceThumbnailFileType] dataStreamForSend:thumbnailSendStream length:[thumbnailImageData length]];
	}
	
	
	NSUInteger dataLength 		= 0;
	

	NSInputStream*	dataSendStream	=	nil;
	
	if ([_contentDataSource respondsToSelector:@selector(dataForContentWithID:fileType:)]){
		NSData * streamData	=	[_contentDataSource dataForContentWithID:contentID fileType:fileTypeToUse];

		if (streamData != nil && [streamData length] > 0){
			dataSendStream	=	[NSInputStream inputStreamWithData:streamData];
			dataLength		=	[streamData length];
		}

	}else if ([_contentDataSource respondsToSelector:@selector(inputStreamForContentWithID:fileType:length:)]){
		dataSendStream	= 	[_contentDataSource inputStreamForContentWithID:contentID fileType:fileTypeToUse length:&dataLength];
	}else{
		[NSException raise:@"_contentDataSource didn't implement any swypContentDataSourceProtocol methods for 'Providing data'" format:nil];
	}
	
	if (dataSendStream != nil){
		[session beginSendingFileStreamWithTag:tag type:fileTypeToUse dataStreamForSend:dataSendStream length:dataLength];
	}else{
		EXOLog(@"No stream created for content id '%@'; send aborted!,",contentID);
	}
}

-(void)		handleContentSwypOfContentWithID:(NSString*)contentID withContentImage:(UIImage*)contentImage toRect:(CGRect)destination{

	UIImageView * imageView	= [self _gloirifiedFramedImageViewWithUIImage:contentImage];
		
	[[self displayControllerForContentID:contentID] removeContentFromDisplayWithID:contentID animated:FALSE];
	
	[_contentViewsByContentID setValue:imageView forKey:contentID];
	[[self currentActiveContentDisplayController] addContentToDisplayWithID:contentID animated:TRUE];
	
	if ([[self currentActiveContentDisplayController] respondsToSelector:@selector(moveContentWithID:toFrame:animated:)]){
		[[self currentActiveContentDisplayController] moveContentWithID:contentID toFrame:destination animated:FALSE];
	}
}

#pragma mark NSObject

-(id)	initWithMainWorkspaceView: (swypWorkspaceView*)workspaceView{
	if (self = [super init]){
		_sessionViewControllersBySession	=	[[NSMutableDictionary alloc] init];
		_contentViewsByContentID			=	[[swypBidirectionalMutableDictionary alloc] init];
		_thumbnailLoadingViewsByContentID	=	[[swypBidirectionalMutableDictionary alloc] init];
		_dataDelegates						=	[[NSMutableArray alloc] init];

		_mainWorkspaceView							=	[workspaceView retain];
		_contentDisplayControllerByWorkspaceView	=	[[NSMutableDictionary alloc] init];
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
	SRELS(_dataDelegates);
	SRELS(_contentDisplayControllerByWorkspaceView);
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
-(void)	updatedProgressToPercentage:(double)complete withDiscernedInputStream:(swypDiscernedInputStream*)discernedStream{
	swypSessionViewController * sessionVC	=	[_sessionViewControllersBySession objectForKey:[NSValue valueWithNonretainedObject:[discernedStream sourceConnectionSession]]];
	
	if (sessionVC == nil){
		[discernedStream removeStatusDelegate:self];
		return;
	}
	
	for( swypThumbView * thumProgView in [sessionVC contentLoadingThumbs]){
		[thumProgView setProgress:complete];
	}
	
}
-(void)	discernedInputStreamCompletedReceivingData:(swypDiscernedInputStream*)discernedStream{
	swypSessionViewController * sessionVC	=	[_sessionViewControllersBySession objectForKey:[NSValue valueWithNonretainedObject:[discernedStream sourceConnectionSession]]];
		
	for( swypThumbView * thumProgView in [[[sessionVC contentLoadingThumbs] copy] autorelease]){
		EXOLog(@"Done tracking content receipt for type: %@", [discernedStream streamType]);
		
		NSString * contentID	= [_thumbnailLoadingViewsByContentID keyForObject:thumProgView];
		
		[thumProgView setLoading:FALSE];
		
		[UIView animateWithDuration:.5 delay:0 options:UIViewAnimationOptionAllowAnimatedContent|UIViewAnimationOptionCurveEaseIn|UIViewAnimationOptionAllowUserInteraction animations:^{
			[thumProgView setOrigin:CGPointMake(100, 100)];
			
		}completion:^(BOOL completed){
			[UIView animateWithDuration:1 delay:0 options:UIViewAnimationOptionCurveEaseOut|UIViewAnimationOptionBeginFromCurrentState|UIViewAnimationOptionAllowAnimatedContent|UIViewAnimationOptionAllowUserInteraction animations:^{

				[thumProgView setTransform:CGAffineTransformMakeScale(.1, .1)];
				[thumProgView setCenter:CGPointMake([[self displayControllerForContentID:contentID] view].size.width/2, 20)];
			}completion:^(BOOL completed){				
				
				[_thumbnailLoadingViewsByContentID removeObjectForKey:contentID];

				[[self displayControllerForContentID:contentID] removeContentFromDisplayWithID:contentID animated:TRUE];
			}];
		}];

		//settm loose
		[[sessionVC contentLoadingThumbs] removeObject:thumProgView];
	}
	[discernedStream removeStatusDelegate:self];

}
-(void)	discernedInputStreamFailedReceivingData:(swypDiscernedInputStream*)discernedStream{
	swypSessionViewController * sessionVC	=	[_sessionViewControllersBySession objectForKey:[NSValue valueWithNonretainedObject:[discernedStream sourceConnectionSession]]];
	
	for( swypThumbView * thumProgView in [[[sessionVC contentLoadingThumbs] copy] autorelease]){
		NSString * contentID	= [_thumbnailLoadingViewsByContentID keyForObject:thumProgView];
		
		[[self displayControllerForContentID:contentID] removeContentFromDisplayWithID:contentID animated:TRUE];
		[_thumbnailLoadingViewsByContentID removeObjectForKey:contentID];
		
		
		//settm loose
		[[sessionVC contentLoadingThumbs] removeObject:thumProgView];
	}
	[discernedStream removeStatusDelegate:self];
}

#pragma mark swypConnectionSessionDataDelegate
-(void) didBeginReceivingDataInDiscernedStream:(swypDiscernedInputStream *)stream withConnectionSession:(swypConnectionSession *)session{
	if ([supportedReceiveFileTypes containsObject:[stream streamType]]){
		[stream addStatusDelegate:self];
	}
	[[self maintainedSwypSessionViewControllerForSession:session] indicateTransferringData:YES];

}

-(void) didFinnishReceivingDataInDiscernedStream:(swypDiscernedInputStream *)stream withConnectionSession:(swypConnectionSession *)session{
	[[self maintainedSwypSessionViewControllerForSession:session] indicateTransferringData:NO];

}

-(NSArray*) supportedFileTypesForReceipt{
	return [NSArray arrayWithObjects:[NSString swypWorkspaceThumbnailFileType], nil];
}

-(void)	yieldedData:(NSData*)streamData ofType:(NSString *)streamType fromDiscernedStream:(swypDiscernedInputStream *)discernedStream inConnectionSession:(swypConnectionSession *)session{

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
		[[self currentActiveContentDisplayController] addContentToDisplayWithID:thumbID animated:TRUE];

		
		swypSessionViewController * sessionView =	[_sessionViewControllersBySession objectForKey:[NSValue valueWithNonretainedObject:session]];
		[[sessionView contentLoadingThumbs] addObject:thumbView];

		swypInfoRef * swypInfo = [[session representedCandidate] matchedLocalSwypInfo];
		
		[thumbView setCenter:[[sessionView view] center]];
		
		
		CGRect thumbFrame			= [thumbView frame];
		CGRect newTranslationFrame	= CGRectZero;
		double velocity				= [swypInfo velocity];
		
        /*
		CGRect leftRect		= CGRectMake(0, 0, 150, 1200);
		CGRect rightRect	= CGRectMake(self.contentDisplayController.view.width-150, 0, 150, 1200);
		CGRect bottomRect	= CGRectMake(0, self.contentDisplayController.view.height-200, 1200, 200);
		CGRect topRect	= CGRectMake(0, 0, 1200, 200);
         */

        switch ([swypInfo screenEdgeOfSwyp]) {
            case swypScreenEdgeTypeLeft:
                newTranslationFrame = CGRectApplyAffineTransform(thumbFrame,CGAffineTransformMakeTranslation(velocity * .5, 0));
                break;
            
            case swypScreenEdgeTypeRight:
                newTranslationFrame = CGRectApplyAffineTransform(thumbFrame,CGAffineTransformMakeTranslation(velocity * -0.5, 0));
                break;
            case swypScreenEdgeTypeBottom:
                newTranslationFrame = CGRectApplyAffineTransform(thumbFrame,CGAffineTransformMakeTranslation(0, velocity * -0.5));
                break;
            case swypScreenEdgeTypeTop:
                newTranslationFrame = CGRectApplyAffineTransform(thumbFrame,CGAffineTransformMakeTranslation(0, velocity * 0.5));
                break;
            default:
                newTranslationFrame = thumbFrame;
                break;
        }
		
		EXOLog(@"Org %@, Dest %@",rectDescriptionString(thumbFrame),rectDescriptionString(newTranslationFrame));

		[UIView animateWithDuration:.25 delay:0 options:UIViewAnimationOptionAllowUserInteraction|UIViewAnimationOptionAllowAnimatedContent|UIViewAnimationOptionBeginFromCurrentState|UIViewAnimationOptionCurveEaseOut animations:^{
			[thumbView setFrame:newTranslationFrame];
		}completion:nil];
		
	}
}



-(void)	failedSendingStream:(NSInputStream*)stream error:(NSError*)error connectionSession:(swypConnectionSession*)session{
	[[self maintainedSwypSessionViewControllerForSession:session] indicateTransferringData:NO];
}
-(void) completedSendingStream:(NSInputStream*)stream connectionSession:(swypConnectionSession*)session{
	EXOLog(@"Completed sending stream in session!:%@", [session description]);
	[[self maintainedSwypSessionViewControllerForSession:session] indicateTransferringData:NO];
}

#pragma mark swypConnectionSessionInfoDelegate
-(void) sessionDied:			(swypConnectionSession*)session withError:(NSError*)error{
	[self stopMaintainingViewControllerForSwypSession:session];
}

#pragma mark swyp

#pragma mark swypContentDisplayViewControllerDelegate
-(void)	contentWithIDUnderwentSwypOut:(NSString*)contentID inController:(UIViewController<swypContentDisplayViewController>*)contentDisplayController{
	
	UIView * content		= [_contentViewsByContentID objectForKey:contentID];
	if (content == nil)
		return;
	
	CGRect contentRect		=	[content frame];
	
	swypSessionViewController*	overlapSession	=	[self _sessionViewControllerInMainViewOverlappingRect:contentRect];

	if (overlapSession){
		[self sendContentWithID:contentID throughConnectionSession:[overlapSession connectionSession]];
		
		[overlapSession indicateTransferringData:YES];
	}

}

-(void) contentWithIDWasDraggedOffWorkspace:(NSString*)contentID inController:(UIViewController<swypContentDisplayViewController>*)contentDisplayController{
	if ([[_contentDataSource idsForAllContent] containsObject:contentID]){
		[_contentDataSource contentWithIDWasDraggedOffWorkspace:contentID];
	}else if ([[_thumbnailLoadingViewsByContentID allKeys] containsObject:contentID]){
		[[self displayControllerForContentID:contentID] removeContentFromDisplayWithID:contentID animated:FALSE];
		[_thumbnailLoadingViewsByContentID removeObjectForKey:contentID];
	}
}

-(UIView*)		viewForContentWithID:(NSString*)contentID ofMaxSize:(CGSize)maxIconSize inController:(UIViewController<swypContentDisplayViewController>*)contentDisplayController{
	
	UIView * cachedView	=	[_contentViewsByContentID valueForKey:contentID];
	if (cachedView == nil){
		cachedView = [_thumbnailLoadingViewsByContentID valueForKey:contentID];
	}
	
	if (cachedView == nil){
		//If you've got content, you must implem
		assert([_contentDataSource respondsToSelector:@selector(iconImageForContentWithID:ofMaxSize:)]);
		UIImage * previewImage =	[_contentDataSource iconImageForContentWithID:contentID ofMaxSize:maxIconSize];
		
		//you should remove from view first, then remove from local storage
		assert(previewImage != nil);
		
		UIImageView * photoTileView	=	[self _gloirifiedFramedImageViewWithUIImage:previewImage];
		
		[_contentViewsByContentID setValue:photoTileView forKey:contentID];
		cachedView = photoTileView;
	}
	return cachedView;
	
}

-(NSArray*)		allIDsForContentInController:(UIViewController<swypContentDisplayViewController>*)contentDisplayController{
	if (contentDisplayController != [_contentDisplayControllerByWorkspaceView objectForKey:[NSValue valueWithNonretainedObject:_mainWorkspaceView]]){
		return nil;
	}

	NSMutableArray * ids = [NSMutableArray array];
	if ([_contentDataSource respondsToSelector:@selector(idsForAllContent)]){
		[ids addObjectsFromArray:[_contentDataSource idsForAllContent]];
	}
	[ids addObjectsFromArray:[_thumbnailLoadingViewsByContentID allKeys]];
	return ids;
}


#pragma mark swypContentDataSourceDelegate 
-(void)	datasourceInsertedContentWithID:(NSString*)insertID withDatasource:	(id<swypContentDataSourceProtocol>)datasource{
	[[self currentActiveContentDisplayController] addContentToDisplayWithID:insertID animated:TRUE];
}

-(void)	datasourceRemovedContentWithID:(NSString*)removeID withDatasource:	(id<swypContentDataSourceProtocol>)datasource{
	[_contentViewsByContentID removeObjectForKey:removeID];
	[[self displayControllerForContentID:removeID] removeContentFromDisplayWithID:removeID animated:TRUE];
}

-(void)	datasourceSignificantlyModifiedContent:	(id<swypContentDataSourceProtocol>)datasource{
	[_contentViewsByContentID removeAllObjects];
	
	
	for (UIViewController <swypContentDisplayViewController>* contentDisplay in [_contentDisplayControllerByWorkspaceView allValues]){
		[contentDisplay reloadAllData];
	}
}


#pragma mark -
#pragma mark private
-(UIImageView*)	_gloirifiedFramedImageViewWithUIImage:(UIImage*)image{
	UIImageView * photoTileView	=	[[UIImageView alloc] initWithImage:image];
	
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
	
	return [photoTileView autorelease];
}

-(swypSessionViewController*)	_sessionViewControllerInMainViewOverlappingRect:(CGRect) testRect{
	
	
	for (swypSessionViewController * sessionViewController in [_sessionViewControllersBySession allValues]){
		//CGRectApplyAffineTransform(sessionViewController.view.frame, CGAffineTransformMakeTranslation(_contentDisplayController.view.frame.origin.x, _contentDisplayController.view.frame.origin.y))
		if ([[[self currentActiveContentDisplayController].view subviews]containsObject:sessionViewController.view]){		
			if (CGRectIntersectsRect(sessionViewController.view.frame, testRect)){
				return sessionViewController;
			}
		}
	}
	
	return nil;
}

-(void) _addContentDisplayControllerToWorkspaceView:(swypWorkspaceView*)view{
	UIViewController<swypContentDisplayViewController>* contentDisplayVC = [_contentDisplayControllerByWorkspaceView objectForKey:[NSValue valueWithNonretainedObject:view]];
	
	if (contentDisplayVC == nil){
		contentDisplayVC	=	[[swypPhotoPlayground alloc] initWithPhotoSize:CGSizeMake(250, 200)];
		[contentDisplayVC.view setFrame:view.bounds];
		[contentDisplayVC.view setAutoresizingMask:UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight];

		[contentDisplayVC setContentDisplayControllerDelegate:self];
		[_contentDisplayControllerByWorkspaceView setObject:contentDisplayVC forKey:[NSValue valueWithNonretainedObject:view]];
	}

	if (contentDisplayVC.view.superview == nil){
		[contentDisplayVC.view setOrigin:CGPointMake(0, 0)];
		[contentDisplayVC.view		setAlpha:0];

		[view.backgroundView	addSubview:contentDisplayVC.view];
		[UIView animateWithDuration:.75 animations:^{
			contentDisplayVC.view.alpha = 1;
		}completion:nil];
		[contentDisplayVC reloadAllData];
	}
	
}


@end
