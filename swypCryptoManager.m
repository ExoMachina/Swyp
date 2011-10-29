//
//  swypCryptoManager.m
//  swyp
//
//  Created by Alexander List on 7/27/11.
//  Copyright 2011 ExoMachina. Some rights reserved -- see included 'license' file.
//


#import "swypCryptoManager.h"
#import "NSStringAdditions.h"
#import "NSData+Base64.h"

static NSString * const	kLocalIdentityKeychainLabel	=	@"com.exomachina.swyp.localIdentity";

static swypCryptoManager *	sharedCryptoManager;

@implementation swypCryptoManager
@synthesize delegate = _delegate, sessionsPendingCryptoSetup = _sessionsPendingCryptoSetup;

#pragma mark -
#pragma mark public
+(NSString*)			localpersistentPeerID{
	NSString * toHash	= [[NSString localAppName] stringByAppendingString:[[UIDevice currentDevice] name]];
	return	[toHash SHA1AlphanumericHash];
}

+(swypCryptoManager*)	sharedCryptoManager{
	if (sharedCryptoManager == nil){
		sharedCryptoManager = [[swypCryptoManager alloc] init];
	}
	return sharedCryptoManager;
}

-(SecIdentityRef)		localSecIdentity{
	if ([self _retrieveLocalCryptoIdentity]){
		EXOLog(@"Retrieved pre-existing local crypto identity");
		return _localCryptoIdentity;	
	}else if ([self _generateNewLocalCryptoIdentity]){
		EXOLog(@"Generated new local crypto identity");
		return _localCryptoIdentity;
	}
	EXOLog(@"NO local crypto identity... None generated.");
	return NULL;
}


#pragma mark NSObject
-(id)	init{
	if (self = [super init]){
	}
	
	return self;
}

-(void)dealloc{
	if (_localCryptoIdentity != NULL){
		CFRelease(_localCryptoIdentity);
		_localCryptoIdentity = NULL;
	}

	[super dealloc];
}

#pragma mark -
#pragma mark private
//secure key generation
-(SecIdentityRef)		_generateNewLocalCryptoIdentity{
	if (_localCryptoIdentity != NULL){
		EXOLog(@"Must have removed old identity first");
		return _localCryptoIdentity;
	}
	
	//for now we'll differentiate between ipad and iphone for different keys
	OSStatus securityError	= noErr ;
	SecIdentityRef	generatedIdentity	=	NULL;
	SecTrustRef		generatedTrust		=	NULL;

	NSString *certPath		= nil; 
	if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone){
		certPath = [[NSBundle mainBundle] pathForResource:@"Alexander H. List" ofType:@"p12"];		
	}else{
		certPath = [[NSBundle mainBundle] pathForResource:@"AList Pad" ofType:@"p12"];		
	}
	
	NSData *certData		= [[NSData alloc] initWithContentsOfFile:certPath];
	
	NSString* keyPassword				= @"";
	NSDictionary *	optionsDictionary	= [NSDictionary dictionaryWithObjectsAndKeys:
										 keyPassword,kSecImportExportPassphrase,
//										   kLocalIdentityKeychainLabel,kSecImportItemLabel,
										 nil];	
	
    CFArrayRef items = CFArrayCreate(NULL, 0, 0, NULL);
    securityError = SecPKCS12Import((CFDataRef)certData,
                                    (CFDictionaryRef) optionsDictionary,
                                    &items);                    // 7
	
	
    //
    if (securityError == 0) {                                   // 8
        CFDictionaryRef myIdentityAndTrust = CFArrayGetValueAtIndex (items, 0);
        const void *tempIdentity = NULL;
        tempIdentity = CFDictionaryGetValue (myIdentityAndTrust,
											 kSecImportItemIdentity);
        generatedIdentity = (SecIdentityRef)tempIdentity;
        const void *tempTrust = NULL;
        tempTrust = CFDictionaryGetValue (myIdentityAndTrust, kSecImportItemTrust);
        generatedTrust = (SecTrustRef)tempTrust;
    }
	

	CFTypeRef returnedValRef = NULL;
	if (generatedIdentity != NULL){
		
		NSDictionary *addIdentityOptionsDict	=	[NSMutableDictionary dictionary];
		[addIdentityOptionsDict setValue: (id)kCFBooleanTrue forKey:(id)kSecReturnAttributes];
		[addIdentityOptionsDict setValue:(id)generatedIdentity forKey:kSecValueRef];
//		[addIdentityOptionsDict setValue:[NSData dataWithBytes:[kLocalIdentityKeychainLabel UTF8String] length:[kLocalIdentityKeychainLabel length]+1] forKey:kSecAttrApplicationTag];

		securityError = SecItemAdd((CFDictionaryRef) addIdentityOptionsDict, &returnedValRef);

	}

	if (securityError != noErr || securityError == errSecItemNotFound){ 
		EXOLog( @"Error generating private key, OSStatus == %ld", securityError );
	}
	if (returnedValRef != NULL){
		EXOLog(@"add identity returned attributes:%@", [(NSDictionary*) returnedValRef description]);
		_localCryptoIdentity	= generatedIdentity;
		CFRelease(returnedValRef);
	}
	
	//http://stackoverflow.com/questions/2773191/how-to-add-security-identity-certificate-private-key-to-iphone-keychain
	//try using the label property on the key itself
	
	return  _localCryptoIdentity;
}

-(SecIdentityRef)	_retrieveLocalCryptoIdentity{
	if (_localCryptoIdentity != NULL){
		return _localCryptoIdentity;
	}
	
	OSStatus securityError = noErr ;
	NSMutableDictionary * localIdentitiyQuery = [[NSMutableDictionary alloc] init];
	
	// Set the identity query dictionary.
	[localIdentitiyQuery setObject:(id)kSecClassIdentity forKey:(id)kSecClass];
	[localIdentitiyQuery setValue: (id)kCFBooleanTrue forKey:(id)kSecReturnRef];

	
//seems like 
//	[localIdentitiyQuery setValue:[NSData dataWithBytes:[kLocalIdentityKeychainLabel UTF8String] length:[kLocalIdentityKeychainLabel length]+1] forKey:kSecAttrApplicationTag];
	
	CFTypeRef	ref	=	NULL;
	
	securityError	=	SecItemCopyMatching((CFDictionaryRef)localIdentitiyQuery, &ref);
	if (ref !=	NULL){
		_localCryptoIdentity	=	(SecIdentityRef) ref;
	}
	if (securityError != noErr || securityError == errSecItemNotFound){ 
		EXOLog( @"Error retrieving private key, OSStatus == %ld", securityError );
	}

	SRELS(localIdentitiyQuery);
	
	return _localCryptoIdentity;
}

-(void)				_deleteLocalCryptoIdentity{
	OSStatus securityError = noErr ;
	NSMutableDictionary * localIdentitiyQuery = [[NSMutableDictionary alloc] init];
	
	// Set the identity query dictionary.
	[localIdentitiyQuery setObject:(id)kSecClassIdentity forKey:(id)kSecClass];
	[localIdentitiyQuery setObject:kLocalIdentityKeychainLabel forKey:(id)kSecAttrApplicationLabel];
		
	// Delete the private key.
	securityError = SecItemDelete((CFDictionaryRef)localIdentitiyQuery);
	if (securityError == noErr || securityError == errSecItemNotFound) EXOLog( @"Error removing private key, OSStatus == %ld", securityError );
	
	[localIdentitiyQuery release];
	
	if (_localCryptoIdentity != NULL){
		CFRelease(_localCryptoIdentity);
		_localCryptoIdentity = NULL;
	}
}

@end
