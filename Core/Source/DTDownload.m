//
//  DTDownload.m
//  DTFoundation
//
//  Created by Oliver Drobnik on 8/6/10.
//  Copyright 2010 Drobnik.com. All rights reserved.
//

#import "DTDownload.h"
#import "NSString+DTUtilities.h"

NSString * const DTDownloadDidStartNotification = @"DTDownloadDidStartNotification";
NSString * const DTDownloadDidFinishNotification = @"DTDownloadDidFinishNotification";
NSString * const DTDownloadProgressNotification = @"DTDownloadProgressNotification";

@interface DTDownload ()

@property (nonatomic, retain) NSString *internalDownloadFolder;
@property (nonatomic, retain) NSDate *lastPaketTimestamp;

- (void)_updateDownloadInfo;
- (void)_completeDownload;

@end

@implementation DTDownload
{
	NSURL *_URL;
	NSString *internalDownloadFolder;
	NSString *downloadEntityTag;
	NSDate *lastModifiedDate;
	NSString *downloadEntryIdentifier;
	
	NSString *folderForDownloading;
	
	// downloading
	NSURLConnection *urlConnection;
	NSMutableData *receivedData;
	
	NSDate *lastPaketTimestamp;
	float previousSpeed;
	
	long long receivedBytes;
	long long _totalBytes;
	
	NSString *_contentType;
	
	
	NSString *receivedDataFilePath;
	NSFileHandle *receivedDataFile;
	
	__unsafe_unretained id <DTDownloadDelegate> delegate;
	
	BOOL headOnly;
	
	BOOL _isLoading;
	BOOL _cancelled;
	
	// response handlers
	DTDownloadResponseHandler _responseHandler;
}

#pragma mark Downloading

- (id)initWithURL:(NSURL *)URL
{
	self = [super init];
	if (self)
	{
		_URL = URL;
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillTerminate:) name:UIApplicationWillTerminateNotification object:nil];
	}
	
	return self;
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	
	if (!headOnly && receivedBytes < _totalBytes)
	{
		// update resume info on disk
		[self _updateDownloadInfo];
	}
}

- (void)startHEAD
{
	NSMutableURLRequest *request=[NSMutableURLRequest requestWithURL:_URL
														 cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData
													 timeoutInterval:60.0];
	[request setHTTPMethod:@"HEAD"];
	
	// start downloading
	urlConnection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:NO];
	
	// without this special it would get paused during scrolling of scroll views
	[urlConnection scheduleInRunLoop:[NSRunLoop mainRunLoop] forMode: NSRunLoopCommonModes];
	[urlConnection start];
	
	// getting only a HEAD
	headOnly = YES;
}

- (void)startWithResume:(BOOL)shouldResume
{
	if (_isLoading)
	{
		return;
	}
	
	if (_cancelled)
	{
		_cancelled = NO;
	}
	
	_isLoading = YES;
	
	NSString *fileName = [[_URL path] lastPathComponent];
	self.internalDownloadFolder = [[self.folderForDownloading stringByAppendingPathComponent:fileName] stringByAppendingPathExtension:@"download"];
	
	receivedDataFilePath = [internalDownloadFolder stringByAppendingPathComponent:fileName];
	
	if ([[NSFileManager defaultManager] fileExistsAtPath:internalDownloadFolder])
	{
		// there is a paused download
		
		// load previous data
		
		NSString *infoPath = [internalDownloadFolder stringByAppendingPathComponent:@"Info.plist"];
		NSDictionary *infoDictionary = [NSDictionary dictionaryWithContentsOfFile:infoPath];
		NSDictionary *resumeInfo = [infoDictionary objectForKey:@"DownloadEntryResumeInformation"];
		
		_totalBytes = [[infoDictionary objectForKey:@"DownloadEntryProgressTotalToLoad"] longLongValue];
		receivedBytes = [[resumeInfo objectForKey:@"NSURLDownloadBytesReceived"] longLongValue];
		downloadEntryIdentifier = [infoDictionary objectForKey:@"DownloadEntryIdentifier"];
		if (!downloadEntryIdentifier)
		{
			downloadEntryIdentifier = [NSString stringWithUUID];
		}
		
		if ([delegate respondsToSelector:@selector(shouldResumeDownload:)])
		{
			if (!shouldResume || ![delegate shouldResumeDownload:self])
			{
				NSError *error = nil;
				if (![[NSFileManager defaultManager] removeItemAtPath:receivedDataFilePath error:&error])
				{
					NSLog(@"Cannot remove file at path %@, %@", receivedDataFilePath, [error localizedDescription]);
					return;
				}
				
				shouldResume = NO;
			}
		}
		
		if (shouldResume)
		{
			downloadEntityTag = [resumeInfo objectForKey:@"NSURLDownloadEntityTag"];

			
			// here we assume we should continue download
			receivedDataFile = [NSFileHandle fileHandleForWritingAtPath:receivedDataFilePath];
			[receivedDataFile seekToEndOfFile];
			
			// test if remembered length = received data length
			
			long long offset = [receivedDataFile offsetInFile];
			if (receivedBytes != offset)
			{
				// inconsistency, reset
				receivedBytes = 0;
				_totalBytes = 0;
				downloadEntityTag = nil;
				lastModifiedDate = nil;
				
				[receivedDataFile closeFile];
				
				NSError *error = nil;
				if (receivedDataFile && ![[NSFileManager defaultManager] removeItemAtPath:receivedDataFilePath error:&error])
				{
					NSLog(@"Cannot remove file at path %@, %@", receivedDataFilePath, [error localizedDescription]);
					return;
				}
				
				receivedDataFile = nil;
			}
			else 
			{
				if (receivedBytes && receivedBytes == _totalBytes)
				{
					// Already done!
					[self _completeDownload];
					return;
				}
			}
		}
		else 
		{
			// reset
			receivedBytes = 0;
			_totalBytes = 0;
			downloadEntityTag = nil;
			lastModifiedDate = nil;
		}
	}
	else 
	{
		// create download folder
		NSError *error = nil;
		
		if (![[NSFileManager defaultManager] createDirectoryAtPath:internalDownloadFolder withIntermediateDirectories:YES attributes:nil error:&error])
		{
			NSLog(@"Cannot create download folder %@, %@", internalDownloadFolder, [error localizedDescription]);
			return;
		}
		
		downloadEntryIdentifier = [NSString stringWithUUID];
	}
	
	NSMutableURLRequest *request=[NSMutableURLRequest requestWithURL:_URL
														 cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData
													 timeoutInterval:60.0];
	
	// set range header
	if (receivedBytes)
	{
		[request setValue:[NSString stringWithFormat:@"bytes=%lld-", receivedBytes] forHTTPHeaderField:@"Range"];
	}
	
	// send notification
	[[NSNotificationCenter defaultCenter] postNotificationName:DTDownloadDidStartNotification object:self];
	
	// start downloading
	urlConnection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:NO];

	// without this special it would get paused during scrolling of scroll views
	[urlConnection scheduleInRunLoop:[NSRunLoop mainRunLoop] forMode: NSRunLoopCommonModes];
	[urlConnection start];
	
	if (urlConnection) 
	{
		receivedData=[NSMutableData data];
	} 
}

- (void)cancel
{
	if (_cancelled) {
		return;
	}
	_cancelled = YES;
	self.delegate = nil;
	
    // update resume info on disk
    [self _updateDownloadInfo];
	
	[urlConnection cancel];
	
	receivedData = nil;
	urlConnection = nil;
	
	_isLoading = NO;
	
	// send notification
	[[NSNotificationCenter defaultCenter] postNotificationName:DTDownloadDidFinishNotification object:self];
}

- (void)_completeDownload
{
	NSError *error = nil;
	
	NSFileManager *fm = [NSFileManager defaultManager];
	
	NSString *fileName = [[_URL path] lastPathComponent];
	NSString *targetPath = [self.folderForDownloading stringByAppendingPathComponent:fileName];
	
	if ([fm fileExistsAtPath:targetPath])
	{
		// remove existing file
		if (![fm removeItemAtPath:targetPath error:&error])
		{
			NSLog(@"Cannot remove item %@", [error localizedDescription]);
			return;
		}
	}
	
	if (![fm moveItemAtPath:receivedDataFilePath toPath:targetPath error:&error])
	{
		NSLog(@"Cannot move item from %@ to %@, %@", receivedDataFilePath, targetPath, [error localizedDescription]);
		return;
	}
	
	// remove internal download folder
	if (![fm removeItemAtPath:self.internalDownloadFolder error:&error])
	{
		NSLog(@"Cannot remove item %@, %@", self.internalDownloadFolder, [error localizedDescription]);
		return;
	}
	
	// notify delegate
	if ([delegate respondsToSelector:@selector(download:didFinishWithFile:)])
	{
		[delegate download:self didFinishWithFile:targetPath];
	}
	
	if (_completionHandler)
	{
		_completionHandler(self);
	}
}

- (void)_updateDownloadInfo
{
    // no need to save resume info if we have not received any bytes yet, or download is complete
	if (receivedBytes==0 || (receivedBytes == _totalBytes))
	{
		return;
	}
    
	NSMutableDictionary *resumeDict = [NSMutableDictionary dictionary];
	
	[resumeDict setObject:[NSNumber numberWithLongLong:receivedBytes] forKey:@"NSURLDownloadBytesReceived"];
	
	if (downloadEntityTag)
	{
		[resumeDict setObject:downloadEntityTag forKey:@"NSURLDownloadEntityTag"];
	}
	
	[resumeDict setObject:[_URL description] forKey:@"DownloadEntryURL"];
	
	NSDictionary *writeDict = [NSDictionary dictionaryWithObjectsAndKeys:
							   [NSNumber numberWithInt:-999], @"DownloadEntryErrorCodeDictionaryKey",
							   @"NSURLErrorDomain", @"DownloadEntryErrorDomainDictionaryKey",
							   
							   downloadEntryIdentifier, @"DownloadEntryIdentifier",
							   receivedDataFilePath, @"DownloadEntryPath",
							   [NSNumber numberWithLongLong:receivedBytes], @"DownloadEntryProgressBytesSoFar",
							   [NSNumber numberWithLongLong:_totalBytes], @"DownloadEntryProgressTotalToLoad",
							   resumeDict, @"DownloadEntryResumeInformation",
							   [_URL description], @"DownloadEntryURL"
							   , nil];
	
	NSString *infoPath = [internalDownloadFolder stringByAppendingPathComponent:@"Info.plist"];
	
	[writeDict writeToFile:infoPath atomically:YES];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
	receivedData = nil;
	urlConnection = nil;
	
	[receivedDataFile closeFile];
	
	// update resume info on disk
	[self _updateDownloadInfo];
	
	// notify delegate of error
	if ([delegate respondsToSelector:@selector(download:didFailWithError:)])
	{
		[delegate download:self didFailWithError:error];
	}
	
	_isLoading = NO;
	
	// send notification
	[[NSNotificationCenter defaultCenter] postNotificationName:DTDownloadDidFinishNotification object:self];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{	
	if ([response isKindOfClass:[NSHTTPURLResponse class]])
	{
		NSHTTPURLResponse *http = (NSHTTPURLResponse *)response;
		_MIMEType = http.MIMEType;
		
		if (http.statusCode>=400)
		{
			NSDictionary *userInfo = [NSDictionary dictionaryWithObject:[NSHTTPURLResponse localizedStringForStatusCode:http.statusCode] forKey:NSLocalizedDescriptionKey];
			
			NSError *error = [NSError errorWithDomain:@"iCatalog" code:http.statusCode userInfo:userInfo];
			
			[connection cancel];
			
			[self connection:connection didFailWithError:error];
			return;
		}
		
		if (_totalBytes<=0)
		{
			_totalBytes = [response expectedContentLength];
		}
		
		NSString * currentEntityTag = [http.allHeaderFields objectForKey:@"Etag"];
		if (!downloadEntityTag)
		{
			downloadEntityTag = currentEntityTag;
		}
		else 
		{
			// check if it's the same as from last time
			if (![self.downloadEntityTag isEqualToString:currentEntityTag])
			{
				// file was changed on server restart from beginning
				[urlConnection cancel];
                
                // update loading flag to allow resume
                _isLoading = NO;
				[self startWithResume:NO];
			}
		}
		
		// get something to identify file
		NSString *modified = [http.allHeaderFields objectForKey:@"Last-Modified"];
		if (modified) 
		{
			NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
			[dateFormatter setDateFormat:@"EEE, dd MMM yyyy HH:mm:ss zzz"];
			NSLocale *locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
			[dateFormatter setLocale:locale];
			
			lastModifiedDate = [dateFormatter dateFromString:modified];
		}
		
		if (_responseHandler)
		{
			_responseHandler(self, [http allHeaderFields]);
		}
	}
	else 
	{
		[urlConnection cancel]; 
	}
	
	// could be redirections, so we set the Length to 0 every time
	[receivedData setLength:0];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
	if (!receivedDataFile)
	{
		// first chunk creates a new file
		[[NSFileManager defaultManager] createFileAtPath:receivedDataFilePath contents:data attributes:nil];
		receivedBytes += [data length];
		
		receivedDataFile = [NSFileHandle fileHandleForWritingAtPath:receivedDataFilePath];
		[receivedDataFile seekToEndOfFile];
		
		return;
	}
	
	// subsequent chunks get added to file
	[receivedDataFile writeData:data];
	receivedBytes += [data length];
	
	// calculate a transfer speed
	float downloadSpeed = 0;
	NSDate *now = [NSDate date];
	
	if (lastPaketTimestamp)
	{
		NSTimeInterval downloadDurationForPaket = [now timeIntervalSinceDate:self.lastPaketTimestamp];
		float instantSpeed = [data length] / downloadDurationForPaket;
		
		downloadSpeed = (previousSpeed * 0.9)+0.1 * instantSpeed;
	}
	
	self.lastPaketTimestamp = now;
	
	// notify delegate
	if ([delegate respondsToSelector:@selector(download:downloadedBytes:ofTotalBytes:withSpeed:)])
	{
		[delegate download:self downloadedBytes:receivedBytes ofTotalBytes:_totalBytes withSpeed:downloadSpeed];
	}
	
	// send notification
	if (_totalBytes)
	{
		NSDictionary *userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:(float)receivedBytes / (float)_totalBytes] forKey:@"ProgressPercent"];
		[[NSNotificationCenter defaultCenter] postNotificationName:DTDownloadProgressNotification object:self userInfo:userInfo];
	}
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	receivedData = nil;
	urlConnection = nil;

	_isLoading = NO;

	[receivedDataFile closeFile];
	receivedDataFile = nil;
	
	if (headOnly)
	{
		if ([delegate respondsToSelector:@selector(downloadDidFinishHEAD:)])
		{
			[delegate downloadDidFinishHEAD:self];
		}
	}
	else
	{
		[self _completeDownload];
	}
	
	// send notification
	[[NSNotificationCenter defaultCenter] postNotificationName:DTDownloadDidFinishNotification object:self];
}

#pragma mark Notifications
- (void)appWillTerminate:(NSNotification *)notification
{
	[self cancel];
}

#pragma mark Properties
- (NSString *)folderForDownloading
{
	if (!folderForDownloading)
	{
		NSString *md5 = [[_URL absoluteString] md5Checksum];
		
		self.folderForDownloading = [NSTemporaryDirectory() stringByAppendingPathComponent:md5];
	}
	
	return folderForDownloading;
}

- (BOOL)isLoading
{
	return _isLoading;
}

- (void)cleanup
{
	[self cancel];

	// remove cached file
	NSFileManager *fileManager = [[NSFileManager alloc] init];
	[fileManager removeItemAtPath:self.internalDownloadFolder error:nil];
}


@synthesize URL = _URL, internalDownloadFolder, downloadEntityTag, folderForDownloading, lastPaketTimestamp, delegate, lastModifiedDate;
@synthesize MIMEType = _MIMEType;
@synthesize totalBytes = _totalBytes;
@synthesize context;
@synthesize responseHandler = _responseHandler;
@synthesize completionHandler = _completionHandler;


@end
