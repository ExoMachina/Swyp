/*
 *  libSwyp.h
 *  swyp
 *
 *  Created by Alexander List on 8/1/11.
 *	Copyright 2011 ExoMachina. Some rights reserved -- see included 'license' file.
 *
 */


/*
 ===========================
 Add swyp to your project with minimal effort
 
 Import the swyp lib '#import <libSwyp/libSwyp.h>'
 Create a swypWorkspaceViewController
 Add a datasource to [workspaceViewController contentManager]
 [[workspaceViewController contentManager] setContentDataSource:(id<swypContentDataSourceProtocol>)newDataSource]
 display the swypWorkspaceViewController
 */

// Uncomment the following if you wish to support bluetooth; only support iOS5+ 
// be sure to include CoreBluetooth Framework; this still needs some work, as I'm getting weird issues with
//		core bluetooth telling me that CBCentralManagerState is always 2 (low-power unsupported)
//#define BLUETOOTH_ENABLED

//the main workspace view controller to show the "Swÿp interface"
#import "swypWorkspaceViewController.h"

//the following are how you determine what files are available to share on swyp
#import "swypContentDataSourceProtocol.h"
//here is an example of a photo datasource
#import "swypPhotoArrayDatasource.h"
//and one that tells when you receive a photo
#import "swypBackedPhotoDataSource.h"
//supported filetypes are generally specified as constants somehow, like in the following file
#import "swypFileTypeString.h"

//photo playground is a viewController class that is set as the "contentDisplayController" in the interaction manager
//the photo playground makes a nice interface for browsing images on a background
#import "swypPhotoPlayground.h"
#import "swypContentInteractionManager.h"

#import "swypConnectionSession.h"

#import "swyp.h"