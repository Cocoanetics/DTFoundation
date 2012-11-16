//
//  DTBonjourDataConnection.h
//  BonjourTest
//
//  Created by Oliver Drobnik on 01.11.12.
//  Copyright (c) 2012 Oliver Drobnik. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreFoundation/CoreFoundation.h>

/**
 Type of encoding to use for sending objects
 */
typedef enum
{
	DTBonjourDataConnectionContentTypeNSCoding = 0,
	DTBonjourDataConnectionContentTypeJSON,
} DTBonjourDataConnectionContentType;

extern NSString * DTBonjourDataConnectionErrorDomain;

@class DTBonjourDataConnection, DTBonjourDataChunk;

@protocol DTBonjourDataConnectionDelegate <NSObject>
@optional

// sending
- (void)connection:(DTBonjourDataConnection *)connection willStartSendingChunk:(DTBonjourDataChunk *)chunk;
- (void)connection:(DTBonjourDataConnection *)connection didSendBytes:(NSUInteger)bytesSent ofChunk:(DTBonjourDataChunk *)chunk;
- (void)connection:(DTBonjourDataConnection *)connection didFinishSendingChunk:(DTBonjourDataChunk *)chunk;

// receiving
- (void)connection:(DTBonjourDataConnection *)connection willStartReceivingChunk:(DTBonjourDataChunk *)chunk;
- (void)connection:(DTBonjourDataConnection *)connection didReceiveBytes:(NSUInteger)bytesReceived ofChunk:(DTBonjourDataChunk *)chunk;
- (void)connection:(DTBonjourDataConnection *)connection didFinishReceivingChunk:(DTBonjourDataChunk *)chunk;

- (void)connection:(DTBonjourDataConnection *)connection didReceiveObject:(id)object;

// connection
- (void)connectionDidClose:(DTBonjourDataConnection *)connection;
@end

/**
 This class represents a data connection, established via file handle or Bonjour `NSNetService`
 
 It can be used by itself to establish a connection as a client to a remote server. In the context of a `DTBonjourServer` there might be any number of live connections. In the server context you should not modify the connection delegate as the connections are owned and maintained by the server.
 */
@interface DTBonjourDataConnection : NSObject

/**
 Initializes the receiver from a native Posix file handle representing a socket.
 */
- (id)initWithNativeSocketHandle:(CFSocketNativeHandle)nativeSocketHandle;

/**
 Initialized the receiver from a Bonjour `NSNetService`
 */
- (id)initWithService:(NSNetService *)service;

/**
 Opens the connection and establishes the input and output streams.
 @returns `YES` if the connection could be established.
 */
- (BOOL)open;

/**
 Closes the connection
 */
- (void)close;

/**
 @returns `YES` if the connection is open and can be used to send or receive data
 */
- (BOOL)isOpen;

/**
 Encodes the passed object via the current sendingContentType and adds it to the output stream.
 
 Note: The return parameter does not tell if the actual sending has already taken place, only if the object could be encoded and enqueued for sending.
 @param object Can be any object that is supported by the current sending content type.
 @param error An option error output parameter
 @returns `YES` if the object was successfully encoded and enqueued for sending
 */
- (BOOL)sendObject:(id)object error:(NSError **)error;

/**
 A delegate to be informed about activities of the connection. If the connection is owned by a `DTBonjourServer` you should not modify this property.
 */
@property (nonatomic, weak) id <DTBonjourDataConnectionDelegate> delegate;

/**
 The type of how objects are to be encoded for transit. The default is to encode with NSCoding, JSON is also available as an option.
 
 Note: JSON can only encode `NSArray` and `NSDictionary` root objects.
 */
@property (nonatomic, assign) DTBonjourDataConnectionContentType sendingContentType;

@end
