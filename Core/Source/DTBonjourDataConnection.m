//
//  DTBonjourDataConnection.m
//  BonjourTest
//
//  Created by Oliver Drobnik on 01.11.12.
//  Copyright (c) 2012 Oliver Drobnik. All rights reserved.
//

#import "DTBonjourDataConnection.h"
#import "DTBonjourDataChunk.h"
#import "NSScanner+DTBonjour.h"

#import <Foundation/NSJSONSerialization.h>

NSString * DTBonjourDataConnectionErrorDomain = @"DTBonjourDataConnection";

@interface DTBonjourDataConnection () <NSStreamDelegate>

@end

@interface DTBonjourDataChunk (private)

// make read-only property assignable
@property (nonatomic, assign) NSUInteger sequenceNumber;

@end

typedef enum
{
	DTBonjourDataConnectionExpectedDataTypeNothing,
	DTBonjourDataConnectionExpectedDataTypeHeader,
	DTBonjourDataConnectionExpectedDataTypeData
} DTBonjourDataConnectionExpectedDataType;

@implementation DTBonjourDataConnection
{
	NSInputStream *_inputStream;
	NSOutputStream *_outputStream;
	
	NSMutableArray *_outputQueue;
	DTBonjourDataChunk *_receivingChunk;

	NSUInteger _chunkSequenceNumber;
	
	__weak id <DTBonjourDataConnectionDelegate> _delegate;
}

- (id)initWithNativeSocketHandle:(CFSocketNativeHandle)nativeSocketHandle
{
	self = [super init];
	
	if (self)
	{
		CFReadStreamRef readStream = NULL;
		CFWriteStreamRef writeStream = NULL;
		CFStreamCreatePairWithSocket(kCFAllocatorDefault, nativeSocketHandle, &readStream, &writeStream);
		
		if (readStream && writeStream)
		{
			CFReadStreamSetProperty(readStream, kCFStreamPropertyShouldCloseNativeSocket, kCFBooleanTrue);
			CFWriteStreamSetProperty(writeStream, kCFStreamPropertyShouldCloseNativeSocket, kCFBooleanTrue);
			
			_inputStream = (__bridge_transfer NSInputStream *)readStream;
			_outputStream = (__bridge_transfer NSOutputStream *)writeStream;
			
			_outputQueue = [[NSMutableArray alloc] init];
		}
		else
		{
			close(nativeSocketHandle);
			
			return nil;
		}
	}
	
	return self;
}

- (id)initWithService:(NSNetService *)service
{
	self = [super init];
	
	if (self)
	{
		if (![service getInputStream:&_inputStream outputStream:&_outputStream])
		{
			return nil;
		}
		
		_outputQueue = [[NSMutableArray alloc] init];
	}
	
	return self;
}

- (void)dealloc
{
	_delegate = nil;
	[self close];
}

- (BOOL)open
{
	[_inputStream  setDelegate:self];
	[_outputStream setDelegate:self];
	[_inputStream  scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
	[_outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
	[_inputStream  open];
	[_outputStream open];
	
	return YES;
}

- (void)close
{
	if (!_inputStream&&!_outputStream)
	{
		return;
	}
	
	[_inputStream  setDelegate:nil];
	[_outputStream setDelegate:nil];
	[_inputStream  close];
	[_outputStream close];
	[_inputStream  removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
	[_outputStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
	_inputStream = nil;
	_outputStream = nil;
	
	if ([_delegate respondsToSelector:@selector(connectionDidClose:)])
	{
		[_delegate connectionDidClose:self];
	}
}

- (BOOL)isOpen
{
	return (_inputStream&&_outputStream);
}

- (void)_startOutput
{
	if (![_outputQueue count])
	{
		return;
	}
	
	DTBonjourDataChunk *chunk = _outputQueue[0];
	
	if (chunk.numberOfTransferredBytes==0)
	{
		// nothing sent yet
		if ([_delegate respondsToSelector:@selector(connection:willStartSendingChunk:)])
		{
			[_delegate connection:self willStartSendingChunk:chunk];
		}
	}
	
	NSUInteger writtenBytes = [chunk writeToOutputStream:_outputStream];
	
	if (writtenBytes > 0)
	{
		if ([_delegate respondsToSelector:@selector(connection:didSendBytes:ofChunk:)])
		{
			[_delegate connection:self didSendBytes:writtenBytes ofChunk:chunk];
		}
		
		// If we didn't write all the bytes we'll continue writing them in response to the next
		// has-space-available event.
		
		if ([chunk isTransmissionComplete])
		{
			[_outputQueue removeObject:chunk];
			
			if ([_delegate respondsToSelector:@selector(connection:didFinishSendingChunk:)])
			{
				[_delegate connection:self didFinishSendingChunk:chunk];
			}
		}
	}
	else
	{
		// A non-positive result from -write:maxLength: indicates a failure of some form; in this
		// simple app we respond by simply closing down our connection.
		[self close];
	}
}

#pragma mark - Public Interface

- (BOOL)sendObject:(id)object error:(NSError **)error
{
	if (![self isOpen])
	{
		if (error)
		{
			NSDictionary *userInfo = @{NSLocalizedDescriptionKey:@"Connection is not open"};
			*error = [NSError errorWithDomain:@"DTBonjourDataConnection" code:1 userInfo:userInfo];
		}
		
		return NO;
	}
	
	DTBonjourDataChunk *newChunk = [[DTBonjourDataChunk alloc] initWithObject:object encoding:self.sendingContentType error:error];
	
	if (!newChunk)
	{
		return NO;
	}
	
	newChunk.sequenceNumber = _chunkSequenceNumber;

	BOOL queueWasEmpty = (![_outputQueue count]);
	
	[_outputQueue addObject:newChunk];
	
	if (queueWasEmpty && _outputStream.streamStatus == NSStreamStatusOpen)
	{
		[self _startOutput];
	}

	return YES;
}

#pragma mark - NSStream Delegate

- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)streamEvent
{
	switch(streamEvent)
	{
		case NSStreamEventOpenCompleted:
		{
			break;
		}
			
		case NSStreamEventHasBytesAvailable:
		{
			if (!_receivingChunk)
			{
				// start reading a new chunk
				_receivingChunk = [[DTBonjourDataChunk alloc] initForReading];
                
                // nothing received yet
                if ([_delegate respondsToSelector:@selector(connection:willStartReceivingChunk:)])
                {
                    [_delegate connection:self willStartReceivingChunk:_receivingChunk];
                }
			}
			
			// continue reading
			NSInteger actuallyRead = [_receivingChunk readFromInputStream:_inputStream];
			
			if (actuallyRead<0)
			{
				[self close];
				break;
			}
            
            if ([_delegate respondsToSelector:@selector(connection:didReceiveBytes:ofChunk:)])
            {
                [_delegate connection:self didReceiveBytes:actuallyRead ofChunk:_receivingChunk];
            }
			
			if ([_receivingChunk isTransmissionComplete])
			{
                if ([_delegate respondsToSelector:@selector(connection:didFinishReceivingChunk:)])
                {
                    [_delegate connection:self didFinishReceivingChunk:_receivingChunk];
                }
                
				if ([_delegate respondsToSelector:@selector(connection:didReceiveObject:)])
				{
					id decodedObject = [_receivingChunk decodedObject];
					
					[_delegate connection:self didReceiveObject:decodedObject];
				}

				// we're done with this chunk
				_receivingChunk = nil;
			}
			
			break;
		}
			
		case NSStreamEventErrorOccurred:
		{
			NSLog(@"Error occurred: %@", [aStream.streamError localizedDescription]);
		}
			
		case NSStreamEventEndEncountered:
		{
			[self close];
			
			break;
		}
			
		case NSStreamEventHasSpaceAvailable:
		{
			if ([_outputQueue count])
			{
				[self _startOutput];
			}
			
			break;
		}
			
		default:
		{
			// do nothing
			break;
		} 
	}
}


#pragma mark - Properties

@synthesize delegate = _delegate;

@end
