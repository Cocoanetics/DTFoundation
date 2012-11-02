//
//  DTBonjourDataConnection.h
//  BonjourTest
//
//  Created by Oliver Drobnik on 01.11.12.
//  Copyright (c) 2012 Oliver Drobnik. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreFoundation/CoreFoundation.h>

// type of encoding to use for sending objects
typedef enum
{
	DTBonjourDataConnectionContentTypeJSON = 0,
	DTBonjourDataConnectionContentTypeNSCoding
} DTBonjourDataConnectionContentType;

@class DTBonjourDataConnection;

@protocol DTBonjourDataConnectionDelegate
- (void)connectionDidClose:(DTBonjourDataConnection *)connection;
@end

@interface DTBonjourDataConnection : NSObject

- (id)initWithNativeSocketHandle:(CFSocketNativeHandle)nativeSocketHandle;
- (id)initWithService:(NSNetService *)service;

- (BOOL)open;
- (void)close;

- (BOOL)sendObject:(id)object error:(NSError **)error;

@property (nonatomic, weak) id <DTBonjourDataConnectionDelegate> delegate;

@property (nonatomic, assign) DTBonjourDataConnectionContentType sendingContentType;

@end
