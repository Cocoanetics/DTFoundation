//
//  DTBonjourDataConnection.m
//  BonjourTest
//
//  Created by Oliver Drobnik on 01.11.12.
//  Copyright (c) 2012 Oliver Drobnik. All rights reserved.
//

#import "DTBonjourDataConnection.h"
#import <Foundation/NSJSONSerialization.h>

NSString * DTBonjourDataConnectionErrorDomain = @"DTBonjourDataConnection";

@interface DTBonjourDataConnection () <NSStreamDelegate>

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
	
	NSMutableData *_outputBuffer;
	NSMutableData *_inputBuffer;
	
	DTBonjourDataConnectionExpectedDataType _expectedDataType;
	long long _expectedDataLength;
	DTBonjourDataConnectionContentType _expectedContentType;
	Class _receivingDataClass;
	
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
			
			_inputBuffer = [[NSMutableData alloc] init];
			_outputBuffer = [[NSMutableData alloc] init];
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
		
		_inputBuffer = [[NSMutableData alloc] init];
		_outputBuffer = [[NSMutableData alloc] init];
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
	if (![_outputBuffer length])
	{
		return;
	}
	
	NSUInteger bufferLength = [_outputBuffer length];
	
	NSInteger actuallyWritten = [_outputStream write:[_outputBuffer bytes] maxLength:bufferLength];
	
	if (actuallyWritten > 0)
	{
		[_outputBuffer replaceBytesInRange:NSMakeRange(0, (NSUInteger) actuallyWritten) withBytes:NULL length:0];
		// If we didn't write all the bytes we'll continue writing them in response to the next
		// has-space-available event.
		
		if ([_delegate respondsToSelector:@selector(connection:didSendBytes:ofBufferLength:)])
		{
			[_delegate connection:self didSendBytes:actuallyWritten ofBufferLength:bufferLength];
		}
	}
	else
	{
		// A non-positive result from -write:maxLength: indicates a failure of some form; in this
		// simple app we respond by simply closing down our connection.
		[self close];
	}
}

- (void)_sendData:(NSData *)data
{
	BOOL wasEmpty = ([_outputBuffer length] == 0);
	
	[_outputBuffer appendData:data];
	
	if (wasEmpty && _outputStream.streamStatus == NSStreamStatusOpen)
	{
		[self _startOutput];
	}
}

- (void)_startDecoding
{
	while ([_inputBuffer length])
	{
		
		if (_expectedDataType == DTBonjourDataConnectionExpectedDataTypeHeader)
		{
			// find end of header, \r\n\r\n
			NSData *headerEnd = [@"\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding];
			
			NSRange headerEndRange = [_inputBuffer rangeOfData:headerEnd options:0 range:NSMakeRange(0, [_inputBuffer length])];
			
			if (headerEndRange.location == NSNotFound)
			{
				// we don't have a complete header
				break;
			}
			NSString *string = [[NSString alloc] initWithBytesNoCopy:(void *)[_inputBuffer bytes] length:headerEndRange.location encoding:NSUTF8StringEncoding freeWhenDone:NO];
			
			if (!string)
			{
				return;
			}
			
			NSScanner *scanner = [NSScanner scannerWithString:string];
			scanner.charactersToBeSkipped = [NSCharacterSet whitespaceAndNewlineCharacterSet];
			
			if (![scanner scanString:@"PUT" intoString:NULL])
			{
				return;
			}
			
			if (![scanner scanString:@"Class:" intoString:NULL])
			{
				return;
			}
			
			NSString *type;
			if (![scanner scanUpToCharactersFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet] intoString:&type])
			{
				return;
			}
			
			_receivingDataClass = NSClassFromString(type);
			
			
			if ([scanner scanString:@"Content-Type:" intoString:NULL])
			{
				NSString *contentType;
				if (![scanner scanUpToCharactersFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet] intoString:&contentType])
				{
					return;
				}
				
				if ([contentType isEqualToString:@"application/json"])
				{
					_expectedContentType = DTBonjourDataConnectionContentTypeJSON;
				}
				else if ([contentType isEqualToString:@"application/octet-stream"])
				{
					_expectedContentType = DTBonjourDataConnectionContentTypeNSCoding;
				}
				else
				{
					NSLog(@"Unknown transport type: %@", contentType);
					return;
				}
			}
			
			if (![scanner scanString:@"Content-Length:" intoString:NULL])
			{
				return;
			}
			
			long long length;
			if (![scanner scanLongLong:&length])
			{
				return;
			}
			
			_expectedDataLength = length;
			_expectedDataType = DTBonjourDataConnectionExpectedDataTypeData;
			
			NSRange headerRange = NSMakeRange(0, headerEndRange.location + headerEndRange.length);
			[_inputBuffer replaceBytesInRange:headerRange withBytes:NULL length:0];
			
		}
		
		if (_expectedDataType == DTBonjourDataConnectionExpectedDataTypeData)
		{
			if (_expectedDataLength && [_inputBuffer length] >= _expectedDataLength)
			{
				NSRange payloadRange = NSMakeRange(0, _expectedDataLength);
				NSData *data = [_inputBuffer subdataWithRange:payloadRange];
				
				// decode data
				id object = nil;
				
				if (_expectedContentType == DTBonjourDataConnectionContentTypeJSON)
				{
					object = [NSJSONSerialization JSONObjectWithData:data options:0 error:NULL];
				}
				else if (_expectedContentType == DTBonjourDataConnectionContentTypeNSCoding)
				{
					object = [NSKeyedUnarchiver unarchiveObjectWithData:data];
				}
				
				if (!object)
				{
					NSLog(@"Unable to decode object");
					return;
				}
				
				if ([_delegate respondsToSelector:@selector(connection:didReceiveObject:)])
				{
					[_delegate connection:self didReceiveObject:object];
				}
				
				[_inputBuffer replaceBytesInRange:payloadRange withBytes:NULL length:0];
				_expectedDataType = DTBonjourDataConnectionExpectedDataTypeHeader;
				
				NSLog(@"received %@: %@", NSStringFromClass(_receivingDataClass), object);
			}
			else
			{
				// we don't have sufficient data for decoding this object yet
				break;
			}
		}
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
	
	NSData *archivedData = nil;
	NSString *contentType = nil;
	
	switch (self.sendingContentType )
	{
		case DTBonjourDataConnectionContentTypeJSON:
		{
			// check if our sending encoding type permits this object
			if (![NSJSONSerialization isValidJSONObject:object])
			{
				if (error)
				{
					NSString *errorMsg = [NSString stringWithFormat:@"Object %@ is not a valid root object for JSON serialization", object];
					NSDictionary *userInfo = @{NSLocalizedDescriptionKey:errorMsg};
					*error = [NSError errorWithDomain:DTBonjourDataConnectionErrorDomain code:1 userInfo:userInfo];
				}
				
				return NO;
			}
			
			archivedData = [NSJSONSerialization dataWithJSONObject:object options:0 error:error];
			
			if (!archivedData)
			{
				return NO;
			}
			
			contentType = @"application/json";
			
			break;
		}
			
		case DTBonjourDataConnectionContentTypeNSCoding:
		{
			// check if our sending encoding type permits this object
			if (![object conformsToProtocol:@protocol(NSCoding)])
			{
				if (error)
				{
					NSString *errorMsg = [NSString stringWithFormat:@"Object %@ does not conform to NSCoding", object];
					NSDictionary *userInfo = @{NSLocalizedDescriptionKey:errorMsg};
					*error = [NSError errorWithDomain:DTBonjourDataConnectionErrorDomain code:1 userInfo:userInfo];
				}
				
				return NO;
			}
			
			archivedData = [NSKeyedArchiver archivedDataWithRootObject:object];
			contentType = @"application/octet-stream";
			
			break;
		}
			
		default:
		{
			if (error)
			{
				NSString *errorMsg = [NSString stringWithFormat:@"Unknown encoding type %d", self.sendingContentType];
				NSDictionary *userInfo = @{NSLocalizedDescriptionKey:errorMsg};
				*error = [NSError errorWithDomain:DTBonjourDataConnectionErrorDomain code:1 userInfo:userInfo];
			}
			
			return NO;
		}
	}
	
	NSString *type = NSStringFromClass([object class]);
	NSString *header = [NSString stringWithFormat:@"PUT\r\nClass: %@\r\nContent-Type: %@\r\nContent-Length:%ld\r\n\r\n", type, contentType, (long)[archivedData length]];
	NSData *headerData = [header dataUsingEncoding:NSUTF8StringEncoding];
	
	[self _sendData:headerData];
	[self _sendData:archivedData];
	
	NSLog(@"sent %ld + %ld", (long)[headerData length] , (long)[archivedData length]);
	return YES;
}


#pragma mark - NSStream Delegate

- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)streamEvent
{
	switch(streamEvent)
	{
		case NSStreamEventOpenCompleted:
		{
			_expectedDataType = DTBonjourDataConnectionExpectedDataTypeHeader;
			
			break;
		}
			
		case NSStreamEventHasBytesAvailable:
		{
			uint8_t buffer[2048];
			NSInteger actuallyRead = [_inputStream read:(uint8_t *)buffer maxLength:sizeof(buffer)];
			
			if (actuallyRead > 0)
			{
				[_inputBuffer appendBytes:buffer length:actuallyRead];
				
				[self _startDecoding];
				
				// empty buffer
			}
			else
			{
				// A non-positive value from -read:maxLength: indicates either end of file (0) or
				// an error (-1).  In either case we just wait for the corresponding stream event
				// to come through.
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
			if ([_outputBuffer length] != 0)
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
