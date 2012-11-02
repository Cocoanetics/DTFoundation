//
//  DTBonjourServer.m
//  BonjourTest
//
//  Created by Oliver Drobnik on 01.11.12.
//  Copyright (c) 2012 Oliver Drobnik. All rights reserved.
//

#import "DTBonjourServer.h"

#include <sys/socket.h>
#include <netinet/in.h>
#include <unistd.h>

#import <CoreFoundation/CoreFoundation.h>

#import "DTBonjourDataConnection.h"

#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#endif

@interface DTBonjourServer() <NSNetServiceDelegate, DTBonjourDataConnectionDelegate>

- (void)_acceptConnection:(CFSocketNativeHandle)nativeSocketHandle;

@end


void ListeningSocketCallback(CFSocketRef s, CFSocketCallBackType type, CFDataRef address, const void *data, void *info);

void ListeningSocketCallback(CFSocketRef s, CFSocketCallBackType type, CFDataRef address, const void *data, void *info)
{
	DTBonjourServer *server = (__bridge DTBonjourServer *)info;
	
	// For an accept callback, the data parameter is a pointer to a CFSocketNativeHandle.
	[server _acceptConnection:*(CFSocketNativeHandle *)data];
}


@implementation DTBonjourServer
{
	NSNetService *_service;
	
	NSInputStream *_inputStream;
	NSOutputStream *_outputStream;
	
	NSMutableData *_inputBuffer;
	NSMutableData *_outputBuffer;
	
	BOOL isInputConnected;
	BOOL isOutputConnected;
	
	NSMutableSet *_connections;
	NSString *_bonjourType;
}

- (id)init
{
	self = [super init];
	
	if (self)
	{
		if (![_bonjourType length])
		{
			return nil;
		}
		
		_connections = [[NSMutableSet alloc] init];
	}
	
	return self;
}

- (id)initWithBonjourType:(NSString *)bonjourType
{
	if (!bonjourType)
	{
		return nil;
	}
	
	_bonjourType = bonjourType;
	
	self = [self init];
	
	if (self)
	{
		
	}
	
	return self;
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)_addRunLoopSourceForFileDescriptor:(int)fd
{
	CFSocketContext context = {0, (__bridge void *)self, NULL, NULL, NULL};
	CFSocketRef sock;
	CFRunLoopSourceRef rls;
	
	sock = CFSocketCreateWithNative(NULL, fd, kCFSocketAcceptCallBack, ListeningSocketCallback, &context);
	rls = CFSocketCreateRunLoopSource(NULL, sock, 0);
	CFRunLoopAddSource(CFRunLoopGetCurrent(), rls, kCFRunLoopCommonModes);
	
	CFRelease(rls);
	CFRelease(sock);
}

- (void)startListening
{
	// create IPv4 socket
	int fd4 = socket(AF_INET, SOCK_STREAM, 0);
	
	// allow for reuse of local address
	static const int yes = 1;
	int err = setsockopt(fd4, SOL_SOCKET, SO_REUSEADDR, (const void *) &yes, sizeof(yes));

	// a structure for the socket address
	struct sockaddr_in sin;
	memset(&sin, 0, sizeof(sin));
	sin.sin_family = AF_INET;
	sin.sin_len = sizeof(sin);
	sin.sin_port = htons(0);  // asks kernel for arbitrary port number

	err = bind(fd4, (const struct sockaddr *) &sin, sin.sin_len);
	
	socklen_t addrLen = sizeof(sin);
	err = getsockname(fd4, (struct sockaddr *)&sin, &addrLen);
	err = listen(fd4, 5);

	// create IPv6 socket
	int fd6 = socket(AF_INET6, SOCK_STREAM, 0);
	
	int one = 1;
	err = setsockopt(fd6, IPPROTO_IPV6, IPV6_V6ONLY, &one, sizeof(one));
	err = setsockopt(fd6, SOL_SOCKET, SO_REUSEADDR, (const void *) &yes, sizeof(yes));
	
	struct sockaddr_in sin6;
	memset(&sin6, 0, sizeof(sin6));
	sin6.sin_family = AF_INET6;
	sin6.sin_len = sizeof(sin6);
	sin6.sin_port = sin.sin_port;  // uses same port as IPv4
	
	err = bind(fd6, (const struct sockaddr *) &sin6, sin6.sin_len);
	
	err = listen(fd6, 5);
	
	
	[self _addRunLoopSourceForFileDescriptor:fd4];
	[self _addRunLoopSourceForFileDescriptor:fd6];
	
	_service = [[NSNetService alloc] initWithDomain:@"" // use all available domains
															type:_bonjourType
															name:@"" // uses default name of system
															port:ntohs(sin.sin_port)];
	
	/*
	 Misspelled type: _typ instead of _tcp:
	 
	 Error publishing: {
    NSNetServicesErrorCode = "-72004";
    NSNetServicesErrorDomain = 10;
	 }
	 
	 */
	
	[_service scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
	_service.delegate = self;
	
	[_service publish];

#if TARGET_OS_IPHONE
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];
#endif
}

- (void)_acceptConnection:(CFSocketNativeHandle)nativeSocketHandle
{
	DTBonjourDataConnection *newConnection = [[DTBonjourDataConnection alloc] initWithNativeSocketHandle:nativeSocketHandle];
	newConnection.delegate = self;
	[newConnection open];
	[_connections addObject:newConnection];
}

#pragma mark - NSNetService Delegate

- (void)netService:(NSNetService *)sender didNotPublish:(NSDictionary *)errorDict
{
	NSLog(@"Error publishing: %@", errorDict);
}

- (void)netServiceDidPublish:(NSNetService *)sender
{
	NSLog(@"My name: %@ port: %d", [sender name], (int)sender.port);
}

#pragma mark - DTBonjourDataConnection Delegate
- (void)connectionDidClose:(DTBonjourDataConnection *)connection
{
	[_connections removeObject:connection];
}

#pragma mark - Notifications

- (void)appDidEnterBackground:(NSNotification *)notification
{
	[_service stop];
}

- (void)appWillEnterForeground:(NSNotification *)notification
{
	[_service publish];
}

@end
