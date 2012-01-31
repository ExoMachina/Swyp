//
//  swypSwypableContentSuperview.h
//  libSwyp
//
//  Created by Alexander List on 1/31/12.
//  Copyright (c) 2012 ExoMachina. All rights reserved.
//

#import <Foundation/Foundation.h>

@class swypSwypableContentSuperview;
/**
 Delegate protocol for the swypSwypableContentSuperview. Usually a UIViewController that knows about the views contained within.
 
 Whenever a long press, uninterrupted by cancelled touches or other recognizers, occurs on the view, it asks its swypSwypableContentSuperviewContentDelegate whether it's a swypableContentView, if so it asks what the ID for the content is, then it proceeds to automatically display the swypWorkspaceViewController, forwarding UITouches to the workpace so that one continuous gesture can swyp a content off of the device. 
 */
@protocol swypSwypableContentSuperviewContentDelegate <NSObject>
/** User long-pressed a subview of the swypSwypableContentSuperview
 One can have non-content subviews, so we want to know whether this content is swypable.
 */
-(BOOL)	subview:(UIView*)subview isSwypableWithSwypableContentSuperview:(swypSwypableContentSuperview*)superview;

/** Gets the model ID for the content on the swypable subview. 

	@return	This corresponds to a newly added value in swypWorkspaceViewController's contentDataSource. You've just added it before you return the contentID. 
 */
-(NSString*)contentIDForSwypableSubview:(UIView*)view withinSwypableContentSuperview:(swypSwypableContentSuperview*)superview;
@end

///This delegate protocol should aim directly at the swypWorkpaceViewContoller
@protocol swypSwypableContentSuperviewWorkspaceDelegate <NSObject>
///The view for touch forwarding; the swyp workspace
-(UIView*)workspaceView;
///Causes the workspace to appear, and automatically positions the content of contentID under the user's finger
-(void)	presentContentSwypWorkspaceAtopSwypableContentSuperview:(swypSwypableContentSuperview*)superview forContentOfID:(NSString*)contentID atRect:(CGRect)contentRect;
@end


/**
 Init with the swypSwypableContentSuperviewWorkspaceDelegate and swypSwypableContentSuperviewDelegate, then insert into a view, adding subviews to it. 
 Whenever a long press, uninterrupted by cancelled touches or other recognizers, occurs on the view, it asks its swypSwypableContentSuperviewContentDelegate whether it's a swypableContentView, if so it asks what the ID for the content is, then it proceeds to automatically display the swypWorkspaceViewController, forwarding UITouches to the workpace so that one continuous gesture can swyp a content off of the device. 
 
 @warning after the longPress recognizer has recognized, no subview should expect to receive touch notifications; they should expect them to be ended.
 */
@interface swypSwypableContentSuperview : UIView{
	id<swypSwypableContentSuperviewContentDelegate>			_superviewContentDelegate;
	id<swypSwypableContentSuperviewWorkspaceDelegate>		_superviewWorkspaceDelegate;
}

/** The one and only init function supported.
 @param contentDelegate
 @param workspaceDelegate always the swypWorkspaceViewController .
 
 @warning Doing this requires you to initiallize the workspace. Right now network connectivity begins after the workspace is intiallized. We're working on a fix for this undesired behavior.
 */
-(id)	initWithContentDelegate:(id<swypSwypableContentSuperviewContentDelegate>)contentDelegate workspaceDelegate:(id<swypSwypableContentSuperviewWorkspaceDelegate>)workspaceDelegate frame:(CGRect)frame;
@end
