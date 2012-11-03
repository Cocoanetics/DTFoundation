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
	
	CFSocketRef _ipv4socket;
	CFSocketRef _ipv6socket;
	
	NSUInteger _port; // used port, assigned during start
	
	NSMutableSet *_connections;
	NSString *_bonjourType;
	
	__weak id <DTBonjourServerDelegate> _delegate;
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
	
	[self stop];
}

- (BOOL)start
{
	CFSocketContext context = {0, (__bridge void *)self, NULL, NULL, NULL};

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
	
	// should have a port number now
	_port = sin.sin_port;
	
	if (!_port)
	{
		return NO;
	}
	
	// create a CFSocket for the file descriptor
	_ipv4socket = CFSocketCreateWithNative(NULL, fd4, kCFSocketAcceptCallBack, ListeningSocketCallback, &context);
	
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
	
	// create a CFSocket for the file descriptor
	_ipv6socket = CFSocketCreateWithNative(NULL, fd6, kCFSocketAcceptCallBack, ListeningSocketCallback, &context);
	
	// Set up the run loop sources for the sockets.
	CFRunLoopSourceRef source4 = CFSocketCreateRunLoopSource(kCFAllocatorDefault, _ipv4socket, 0);
	CFRunLoopAddSource(CFRunLoopGetCurrent(), source4, kCFRunLoopCommonModes);
	CFRelease(source4);
	
	CFRunLoopSourceRef source6 = CFSocketCreateRunLoopSource(kCFAllocatorDefault, _ipv6socket, 0);
	CFRunLoopAddSource(CFRunLoopGetCurrent(), source6, kCFRunLoopCommonModes);
	CFRelease(source6);
	
	_service = [[NSNetService alloc] initWithDomain:@"" // use all available domains
															type:_bonjourType
															name:@"" // uses default name of system
															port:ntohs(_port)];
	
	[_service scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
	_service.delegate = self;
	
	[_service publish];

#if TARGET_OS_IPHONE
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];
#endif
	
	return YES;
}

- (void)stop
{
	// stop the bonjour advertising
	[_service stop];
	_service = nil;
	
	// Closes all the open connections.  The EchoConnectionDidCloseNotification notification will ensure
	// that the connection gets removed from the self.connections set.  To avoid mututation under iteration
	// problems, we make a copy of that set and iterate over the copy.
	for (DTBonjourDataConnection *connection in [_connections copy])
	{
		[connection close];
	}
	
	
	if (_ipv4socket)
	{
		CFSocketInvalidate(_ipv4socket);
		CFRelease(_ipv4socket);
		_ipv4socket = NULL;
	}
	
	if (_ipv6socket)
	{
		CFSocketInvalidate(_ipv6socket);
		CFRelease(_ipv6socket);
		_ipv6socket = NULL;
	}
}

- (void)_acceptConnection:(CFSocketNativeHandle)nativeSocketHandle
{
	DTBonjourDataConnection *newConnection = [[DTBonjourDataConnection alloc] initWithNativeSocketHandle:nativeSocketHandle];
	newConnection.delegate = self;
	[newConnection open];
	[_connections addObject:newConnection];
	
	if ([_delegate respondsToSelector:@selector(bonjourServer:didAcceptConnection:)])
	{
		[_delegate bonjourServer:self didAcceptConnection:newConnection];
	}
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

#pragma mark - Properties

@synthesize delegate = _delegate;

@end
