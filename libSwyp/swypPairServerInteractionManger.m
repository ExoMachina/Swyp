//
//  swypPairServerInteractionManger.m
//  swyp
//
//  Created by Alexander List on 1/5/12.
//  Copyright (c) 2012 ExoMachina. All rights reserved.
//

#import "swypPairServerInteractionManger.h"
static NSString * const swypPairServerURL	=	@"https://swyppair.heroku.com/";


@implementation swypPairServerInteractionManger
@synthesize delegate = _delegate, httpRequestManager = _httpRequestManager;

#pragma mark NSObject
-(id) initWithDelegate:(id<swypPairServerInteractionMangerDelegate>)delegate{
	if (self = [super init]){
		_delegate	= delegate;
	}
	return self;
}
-(void)dealloc{
	for (NSOperation * operation in  [[_httpRequestManager operationQueue] operations]){
		[operation cancel];
	}
	_delegate = nil;
	SRELS(_httpRequestManager);
	
	[super dealloc];
}
#pragma mark public
-(AFHTTPClient*)httpRequestManager{
	if (_httpRequestManager == nil){
		_httpRequestManager = [[AFHTTPClient alloc] initWithBaseURL:[NSURL URLWithString:swypPairServerURL]];
	}
	return _httpRequestManager;
}

#pragma mark server coms
-(void)postSwypToPairServer:(swypInfoRef*)swyp withUserInfo:(NSDictionary*)contextInfo{
	NSMutableDictionary * swypPairParameters	= [NSMutableDictionary dictionary];
	[swypPairParameters setValue:[contextInfo valueForKey:@"port"] forKey:@"port"];
	[swypPairParameters setValue:[[NSNumber numberWithDouble:[swyp velocity]] stringValue] forKey:@"velocity"];
	[swypPairParameters setValue:@"some publicKey" forKey:@"publicKey"];
	[swypPairParameters setValue:@"some where (longlat)" forKey:@"where"];
	
	NSString * pairPath					=	([swyp swypType] == swypInfoRefTypeSwypOut)? @"swyp_outs": @"swyp_ins";
	NSMutableURLRequest * pairRequest	=	[[self httpRequestManager] requestWithMethod:@"POST" path:pairPath parameters:swypPairParameters];
	
	AFHTTPRequestOperation	*	pairOperation	=	[AFHTTPRequestOperation  HTTPRequestOperationWithRequest:pairRequest success:^(id returned) {
		[self _processSwypPairResponse:(id)returned swypRef:swyp];
	} failure:^(NSHTTPURLResponse *response, NSError *error) {
		[self _processSwypPairConnectionFailureWithResponse:response error:error swypRef:swyp];
	}];
	
	[[self httpRequestManager] enqueueHTTPRequestOperation:pairOperation];
	
	EXOLog(@"Enqued postSwypToPairServer w/ port %@",[[contextInfo valueForKey:@"port"] stringValue]);
}
-(void)putSwypUpdateToPairServer:(swypInfoRef*)swyp swypToken:(NSString*)token withUserInfo:(NSDictionary*)contextInfo{
	
}
-(void)deleteSwypFromPairServer:(swypInfoRef*)swyp swypToken:(NSString*)token{
	
}
-(void)updateSwypPairStatus:(swypInfoRef*)swyp swypToken:(NSString*)token{
	if (StringHasText(token) == NO){
		[self _processSwypPairConnectionFailureWithResponse:nil error:nil swypRef:swyp];
		return;
	}
	NSString * pairPath					=	([swyp swypType] == swypInfoRefTypeSwypOut)? @"swyp_outs/": @"swyp_ins/";
	NSString * statusRequestPath		=	[pairPath stringByAppendingString:token];
	NSMutableURLRequest * pairRequest	=	[[self httpRequestManager] requestWithMethod:@"GET" path:statusRequestPath parameters:nil];
	
	AFHTTPRequestOperation	*	pairOperation	=	[AFHTTPRequestOperation  HTTPRequestOperationWithRequest:pairRequest success:^(id returned) {
		[self _processSwypPairResponse:(id)returned swypRef:swyp];
	} failure:^(NSHTTPURLResponse *response, NSError *error) {
		[self _processSwypPairConnectionFailureWithResponse:response error:error swypRef:swyp];
	}];
	
	[[self httpRequestManager] enqueueHTTPRequestOperation:pairOperation];	
	
	EXOLog(@"Enqued updateSwypPairStatus w/ token %@",token);
}

#pragma mark - Private
#pragma mark server response processing
-(void)_processSwypPairResponse:(id)response swypRef:(swypInfoRef*)swyp{
	NSString * responseString	=	[[[NSString alloc]  initWithBytes:(char *)[response bytes] length:[response length] encoding: NSUTF8StringEncoding] autorelease];
	EXOLog(@"_processSwypPairResponse data: %@", responseString);
	NSDictionary* responseDict	=	[NSDictionary dictionaryWithJSONString:responseString];
	
	NSString* swypToken			=	[responseDict valueForKey:@"swypToken"];
	if (StringHasText(swypToken) == NO){
		[_delegate swypPairServerInteractionManger:self didFailToGetSwypInfoForSwypRef:swyp orSwypToken:nil];
		return;
	}
	
	NSString * swypStatus		=	[responseDict valueForKey:@"status"];
	if (StringHasText(swypStatus) == NO || [swypStatus isEqualToString:@"failed"]){
		//failed pair
		[_delegate swypPairServerInteractionManger:self didFailToGetSwypInfoForSwypRef:swyp orSwypToken:swypToken];
		return;
	}
	
	NSDictionary * peerResponse	=	[responseDict valueForKey:@"peer"];
	NSMutableDictionary	* peerInfo	=	nil;
	if (peerResponse != nil && [peerResponse isKindOfClass:[NSNull class]] == NO){
		//we'll essentially trust the server not give us shitty responses, but still observe my conservative approach
		peerInfo		= [NSMutableDictionary dictionary];
		
		NSNumber * port	=  [peerResponse valueForKey:@"port"];
		if (port == nil || [port isKindOfClass:[NSNumber class]] == FALSE || [port intValue] <= 0){
			peerInfo = nil;
		}
		[peerInfo setValue:port forKey:@"port"];
		
		NSString * address	= [peerResponse valueForKey:@"address"];
		if (StringHasText(address) == NO){
			peerInfo = nil;
		}
		[peerInfo setValue:address forKey:@"address"];
	}
	
	//phew, we made it
	[_delegate swypPairServerInteractionManger:self didReturnSwypToken:swypToken forSwypRef:swyp withPeerInfo:peerInfo];
}

-(void)_processSwypPairConnectionFailureWithResponse:(id)response error:(NSError*)error swypRef:(swypInfoRef*)swyp{
	EXOLog(@"failed connection for swypOut cloud post, swypOut %@ date",[[swyp startDate] description]);
	[_delegate swypPairServerInteractionManger:self didFailToGetSwypInfoForSwypRef:swyp orSwypToken:nil];
}
@end
