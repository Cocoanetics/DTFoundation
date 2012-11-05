//
//  DTBonjourServer.h
//  BonjourTest
//
//  Created by Oliver Drobnik on 01.11.12.
//  Copyright (c) 2012 Oliver Drobnik. All rights reserved.
//

#import "DTBonjourDataConnection.h"

@class DTBonjourServer;

@protocol DTBonjourServerDelegate <NSObject>
@optional
- (void)bonjourServer:(DTBonjourServer *)server didAcceptConnection:(DTBonjourDataConnection *)connection;
- (void)bonjourServer:(DTBonjourServer *)server didReceiveObject:(id)object onConnection:(DTBonjourDataConnection *)connection;
@end

/**
 This class represents a service that clients can connect to. It owns its inbound connections and thus you should never modify the delegate of the individual data connections.
 
 On iOS the server is automatically stopped if the app enters the background and restarted when the app comes back into the foreground.
 */
@interface DTBonjourServer : NSObject <DTBonjourDataConnectionDelegate>

/**
 Creates a server instances with the given bonjour type, e.g. "_servicename._tcp"
 */
- (id)initWithBonjourType:(NSString *)bonjourType;

/**
 Starts up the server, prepares it to be connected to and publishes the service via Bonjour
 @returns `YES` if the startup was successful
 */
- (BOOL)start;

/**
 Stops the service
 */
- (void)stop;

/**
 Sends the object to all currently connected clients.
 
 Note: any errors will be ignored. If you require finer-grained control then you should iterate over the individual connections.
 */
- (void)broadcastObject:(id)object;

/**
 The delegate that will be informed about activities happening on the server.
 */
@property (nonatomic, weak) id <DTBonjourServerDelegate> delegate;

/**
 The actual port bound to, valid after -start
 */
@property (nonatomic, assign, readonly ) NSUInteger port;   

/**
 The currently connected inbound DTBonjourDataConnection instances.
 */
@property (nonatomic, readonly) NSSet *connections;

/**
 The TXT Record attached to the Bonjour service.
 
 Updating this property while the server is running will update the broadcast TXTRecord. The server has its own instance of the TXTRecord so that it can be set even before calling start.
 */
@property (nonatomic, strong) NSDictionary *TXTRecord;

@end
