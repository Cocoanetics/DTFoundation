//
//  DTDownload.m
//  DTFoundation
//
//  Created by Oliver Drobnik on 8/6/10.
//  Copyright 2010 Drobnik.com. All rights reserved.
//

#import "DTDownload.h"

NSString *const DTDownloadDidStartNotification = @"DTDownloadDidStartNotification";
NSString *const DTDownloadDidFinishNotification = @"DTDownloadDidFinishNotification";
NSString *const DTDownloadDidCancelNotification = @"DTDownloadDidCancelNotification";
NSString *const DTDownloadProgressNotification = @"DTDownloadProgressNotification";

static NSString *const DownloadEntryErrorCodeDictionaryKey = @"DownloadEntryErrorCodeDictionaryKey";
static NSString *const DownloadEntryErrorDomainDictionaryKey = @"DownloadEntryErrorDomainDictionaryKey";
static NSString *const DownloadEntryPath = @"DownloadEntryPath";
static NSString *const DownloadEntryProgressBytesSoFar = @"DownloadEntryProgressBytesSoFar";
static NSString *const DownloadEntryProgressTotalToLoad = @"DownloadEntryProgressTotalToLoad";
static NSString *const DownloadEntryResumeInformation = @"DownloadEntryResumeInformation";
static NSString *const DownloadEntryURL = @"DownloadEntryURL";
static NSString *const NSURLDownloadBytesReceived = @"NSURLDownloadBytesReceived";
static NSString *const NSURLDownloadEntityTag = @"NSURLDownloadEntityTag";

@interface DTDownload () <NSURLConnectionDelegate>

@property(nonatomic, retain) NSString *downloadBundlePath;
@property(nonatomic, retain) NSDate *lastPacketTimestamp;

- (void)storeDownloadInfo;

- (void)_completeWithSuccess;

- (void)_completeWithError:(NSError *)error;

@end

@implementation DTDownload
{
	NSURL *_URL;
	NSString *_downloadBundlePath;
	NSString *_downloadEntityTag;
	NSDate *_lastModifiedDate;

	NSString *_destinationPath;
	NSString *_destinationFileName;

	// downloading
	NSURLConnection *_urlConnection;
	NSMutableData *_receivedData;

	NSDate *_lastPacketTimestamp;
	float _previousSpeed;

	long long _receivedBytes;
	long long _expectedContentLength;
	long long _resumeFileOffset;

	NSString *_contentType;

	NSString *_destinationBundleFilePath;
	NSFileHandle *_destinationFileHandle;

	__unsafe_unretained id <DTDownloadDelegate> _delegate;

	BOOL _headOnly;

	// response handlers
	DTDownloadResponseHandler _responseHandler;
	DTDownloadCompletionHandler _completionHandler;
}

#pragma mark Downloading

- (id)initWithURL:(NSURL *)URL {
	return [self initWithURL:URL withDestinationPath:nil];
}

- (id)initWithURL:(NSURL *)URL withDestinationPath:(NSString *)destinationPath;
{
	NSAssert(![URL isFileURL], @"File URL is illegal parameter for DTDownload");

	self = [super init];
	if (self)
	{
		_URL = URL;
		_resumeFileOffset = 0;
		_destinationPath = destinationPath;
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillTerminate:) name:UIApplicationWillTerminateNotification object:nil];
	}
	return self;
}

- (id)initWithURL:(NSURL *)URL withDestinationFile:(NSString *)destinationFile {
	self = [self initWithURL:URL withDestinationPath:[destinationFile stringByDeletingLastPathComponent]];
	_destinationFileName = [destinationFile lastPathComponent];
	return self;
}



- (id)initWithDictionary:(NSDictionary *)dictionary atBundlePath:(NSString *)path;
{
	self = [super init];
	if (self)
	{
		[self setInfoDictionary:dictionary];

		// update the destination path so that the path is correct also if the download bundle was moved
		_destinationBundleFilePath = [path stringByAppendingPathComponent:[_destinationBundleFilePath lastPathComponent]];

		NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:_destinationBundleFilePath error:nil];
		NSNumber *fileSize = [fileAttributes objectForKey:NSFileSize];
		if ([fileSize longLongValue] < _resumeFileOffset) {
			_resumeFileOffset = 0;
		}
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillTerminate:) name:UIApplicationWillTerminateNotification object:nil];
	}
	return self;
}


+ (DTDownload *)downloadForURL:(NSURL *)URL atPath:(NSString *)path
{
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSDirectoryEnumerator *enumerator = [fileManager enumeratorAtPath:path];
	NSString *file;
	while (file = [enumerator nextObject])
	{
		if ([[file pathExtension] isEqualToString:@"download"])
		{
			NSString *bundlePath = [path stringByAppendingPathComponent:file];
			NSString *infoFile = [bundlePath stringByAppendingPathComponent:@"Info.plist"];
			NSDictionary *dictionary = [NSDictionary dictionaryWithContentsOfFile:infoFile];
			NSString *infoFileURL = [dictionary objectForKey:DownloadEntryURL];
			if ([infoFileURL isEqualToString:[URL description]])
			{
				return [[DTDownload alloc] initWithDictionary:dictionary atBundlePath:bundlePath];
			}

		}
	}
	return [[DTDownload alloc] initWithURL:URL withDestinationPath:path];
}


- (void)dealloc
{
	_urlConnection = nil;
	[[NSNotificationCenter defaultCenter] removeObserver:self];

	[self closeDestinationFile];
	// stop connection if still in flight
	[self stop];
}

- (void)startHEAD
{
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:_URL
																												 cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData
																										 timeoutInterval:60.0];
	[request setHTTPMethod:@"HEAD"];

	// startNext downloading
	_urlConnection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:NO];

	// without this special it would get paused during scrolling of scroll views
	[_urlConnection scheduleInRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
	[_urlConnection start];

	// getting only a HEAD
	_headOnly = YES;
}


- (void)start
{
	if (_urlConnection)
	{
		return;
	}


	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:_URL
																												 cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData
																										 timeoutInterval:60.0];


	if (_receivedBytes && _receivedBytes == _expectedContentLength)
	{
		// Already done!
		[self _completeWithSuccess];
		return;
	}

	if (_resumeFileOffset) {
		[request setValue:[NSString stringWithFormat:@"bytes=%lld-", _resumeFileOffset] forHTTPHeaderField:@"Range"];
	}

	[[NSNotificationCenter defaultCenter] postNotificationName:DTDownloadDidStartNotification object:self];

	_urlConnection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:NO];

	// without this special it would get paused during scrolling of scroll views
	[_urlConnection scheduleInRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];

	// start urlConnection on the main queue, because when download lots of small file, we had a crash when this is done on a background thread
	dispatch_async(dispatch_get_main_queue(), ^
	{
		[_urlConnection start];
	});

	if (_urlConnection)
	{
		_receivedData = [NSMutableData data];
	}
}

- (void)stop
{
	if (!_urlConnection)
	{
		return;
	}

	// update resume info on disk if necessary
	[self storeDownloadInfo];
	_resumeFileOffset = _receivedBytes;

	// only send cancel notification if it was loading

	// cancel the connection
	[_urlConnection cancel];
	_urlConnection = nil;

	// send notification
	[[NSNotificationCenter defaultCenter] postNotificationName:DTDownloadDidCancelNotification object:self];

	if ([_delegate respondsToSelector:@selector(downloadDidCancel:)])
	{
		[_delegate downloadDidCancel:self];
	}
	_receivedData = nil;
}

- (void)cleanup
{
	[self stop];

	// remove cached file
	NSFileManager *fileManager = [[NSFileManager alloc] init];
	[fileManager removeItemAtPath:_destinationBundleFilePath error:nil];
	[fileManager removeItemAtPath:[self.downloadBundlePath stringByAppendingPathComponent:@"Info.plist"] error:nil];
	[fileManager removeItemAtPath:self.downloadBundlePath error:nil];

}

- (NSString *)description
{
	return [NSString stringWithFormat:@"<%@ URL='%@'>", NSStringFromClass([self class]), self.URL];
}

#pragma mark - Internal Utilities

- (void)_completeWithError:(NSError *)error
{
	// notify delegate of error
	if ([_delegate respondsToSelector:@selector(download:didFailWithError:)])
	{
		[_delegate download:self didFailWithError:error];
	}

	// call completion handler
	if (_completionHandler)
	{
		_completionHandler(nil, error);
	}

	_urlConnection = nil;
	// send notification
	[[NSNotificationCenter defaultCenter] postNotificationName:DTDownloadDidFinishNotification object:self];
}

- (void)_completeWithSuccess
{

	if (_headOnly)
	{
		// only a HEAD request
		if ([_delegate respondsToSelector:@selector(downloadDidFinishHEAD:)])
		{
			[_delegate downloadDidFinishHEAD:self];
		}
	}
	else
	{
		// normal GET request
		NSError *error = nil;

		NSFileManager *fileManager = [NSFileManager defaultManager];

		NSString *fileName = [_destinationBundleFilePath lastPathComponent];
		NSString *targetPath = [[[_destinationBundleFilePath stringByDeletingLastPathComponent] stringByDeletingLastPathComponent]	stringByAppendingPathComponent:fileName];

		if (![fileManager moveItemAtPath:_destinationBundleFilePath toPath:targetPath error:&error])
		{
			NSLog(@"Cannot move item from %@ to %@, %@", _destinationBundleFilePath, targetPath, [error localizedDescription]);
			[self _completeWithError:error];
			return;
		}

		if (![fileManager removeItemAtPath:[_destinationBundleFilePath stringByDeletingLastPathComponent] error:&error]) {
			NSLog(@"Cannot remove item from %@, %@ ", [_destinationBundleFilePath stringByDeletingLastPathComponent], [error localizedDescription]);

		}

		// notify delegate
		if ([_delegate respondsToSelector:@selector(download:didFinishWithFile:)])
		{
			[_delegate download:self didFinishWithFile:targetPath];
		}

		// run completion handler
		if (_completionHandler)
		{
			_completionHandler(targetPath, nil);
		}
	}

	// nil the completion handlers in case they captured self
	_urlConnection = nil;

	// send notification
	[[NSNotificationCenter defaultCenter] postNotificationName:DTDownloadDidFinishNotification object:self];
}


- (void)setInfoDictionary:(NSDictionary *)infoDictionary
{
	_URL = [NSURL URLWithString:[infoDictionary objectForKey:DownloadEntryURL]];
	_destinationBundleFilePath = [infoDictionary objectForKey:DownloadEntryPath];
	_expectedContentLength = [[infoDictionary objectForKey:DownloadEntryProgressTotalToLoad] longLongValue];
	NSDictionary *resumeInfo = [infoDictionary objectForKey:DownloadEntryResumeInformation];
	_resumeFileOffset = [[resumeInfo objectForKey:NSURLDownloadBytesReceived] longLongValue];
	_downloadEntityTag = [infoDictionary objectForKey:NSURLDownloadEntityTag];
	_expectedContentLength = [[infoDictionary objectForKey:DownloadEntryProgressTotalToLoad] longLongValue];
}

- (NSDictionary *)infoDictionary
{
	NSMutableDictionary *resumeDictionary = [NSMutableDictionary dictionary];
	[resumeDictionary setObject:[NSNumber numberWithLongLong:_receivedBytes] forKey:NSURLDownloadBytesReceived];
	if (_downloadEntityTag)
	{
		[resumeDictionary setObject:_downloadEntityTag forKey:NSURLDownloadEntityTag];
	}
	[resumeDictionary setObject:[_URL description] forKey:DownloadEntryURL];
	NSDictionary *infoDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
					[NSNumber numberWithInt:-999], DownloadEntryErrorCodeDictionaryKey,
					NSURLErrorDomain, DownloadEntryErrorDomainDictionaryKey,
					_destinationBundleFilePath, DownloadEntryPath,
					[NSNumber numberWithLongLong:_receivedBytes], DownloadEntryProgressBytesSoFar,
					[NSNumber numberWithLongLong:_expectedContentLength], DownloadEntryProgressTotalToLoad,
					resumeDictionary, DownloadEntryResumeInformation,
					[_URL description], DownloadEntryURL
					, nil];

	return infoDictionary;
}

- (void)storeDownloadInfo
{
	// no need to save resume info if we have not received any bytes yet, or download is complete
	if (_receivedBytes == 0 || (_receivedBytes >= _expectedContentLength) || _headOnly)
	{
		return;
	}

	NSString *infoPath = [self.downloadBundlePath stringByAppendingPathComponent:@"Info.plist"];
	[[self infoDictionary] writeToFile:infoPath atomically:YES];
}


#pragma mark - NSURLConnection Delegate

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
	_receivedData = nil;
	_urlConnection = nil;

	[self closeDestinationFile];

	// update resume info on disk
	[self storeDownloadInfo];

	[self _completeWithError:error];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
	if ([response isKindOfClass:[NSHTTPURLResponse class]])
	{
		NSHTTPURLResponse *http = (NSHTTPURLResponse *) response;
		_contentType = http.MIMEType;

		if (http.statusCode >= 400)
		{
			NSDictionary *userInfo = [NSDictionary dictionaryWithObject:[NSHTTPURLResponse localizedStringForStatusCode:http.statusCode] forKey:NSLocalizedDescriptionKey];

			NSError *error = [NSError errorWithDomain:@"iCatalog" code:http.statusCode userInfo:userInfo];

			[connection cancel];

			[self connection:connection didFailWithError:error];
			return;
		}

		if (_expectedContentLength <= 0)
		{
			_expectedContentLength = [response expectedContentLength];

			if (_expectedContentLength < 0)
			{
				NSLog(@"No expected content length for %@", _URL);
			}
		}

		NSString *currentEntityTag = [http.allHeaderFields objectForKey:@"Etag"];
		if (!_downloadEntityTag)
		{
			_downloadEntityTag = currentEntityTag;
		}
		else
		{
			// check if it's the same as from last time
			if (![self.downloadEntityTag isEqualToString:currentEntityTag])
			{
				// file was changed on server restart from beginning
				[_urlConnection cancel];
				_urlConnection = nil;
				// update loading flag to allow resume
				[self start];
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

			_lastModifiedDate = [dateFormatter dateFromString:modified];
		}

		if (_responseHandler)
		{
			BOOL shouldCancel = NO;
			_responseHandler([http allHeaderFields], &shouldCancel);

			if (shouldCancel)
			{
				[self stop];
			}
		}

		_destinationBundleFilePath = [self createBundleFilePathForFilename:[self filenameFromHeader:http.allHeaderFields]];
		NSLog(@"store result in %@", _destinationBundleFilePath);

	}
	else
	{
		[_urlConnection cancel];
	}
	// could be redirections, so we set the Length to 0 every time
	[_receivedData setLength:0];
}

- (NSString *)createBundleFilePathForFilename:(NSString *)fileName
{
	if (_destinationFileName) {
		fileName = _destinationFileName;
	}
	else if (!fileName)
	{
		fileName = [[_URL path] lastPathComponent];
	}
	NSString *folderForDownloading = _destinationPath;
	if (!folderForDownloading)
	{
		folderForDownloading = NSTemporaryDirectory();
	}

	NSString *fullFileName = [self uniqueFileNameForFile:fileName atDestinationPath:folderForDownloading];

	self.downloadBundlePath = [folderForDownloading stringByAppendingPathComponent:[fullFileName stringByAppendingPathExtension:@"download"]];
	NSFileManager *fileManager = [NSFileManager defaultManager];

	if (![fileManager fileExistsAtPath:self.downloadBundlePath])
	{
		NSError *error;
		if (![fileManager createDirectoryAtPath:_downloadBundlePath withIntermediateDirectories:YES attributes:nil error:&error])
		{
			NSLog(@"Cannot create download folder %@, %@", _downloadBundlePath, [error localizedDescription]);
			[self _completeWithError:error];
			return nil;
		}

	}
	return [_downloadBundlePath stringByAppendingPathComponent:fullFileName];
}


- (NSString *)uniqueFileNameForFile:(NSString *)fileName atDestinationPath:(NSString *)path {

	NSString *resultFileName = [path stringByAppendingPathComponent:fileName];
	NSFileManager *fileManager = [NSFileManager defaultManager];

	int i=1;
	while ([fileManager fileExistsAtPath:resultFileName] || [fileManager fileExistsAtPath:[resultFileName stringByAppendingPathExtension:@"download"]]) {
		NSString *extension = [fileName pathExtension];
		if ([extension length] > 0) {
			NSInteger endIndex = [fileName length]- [extension length] - 1;
			NSString *basename = [NSString stringWithFormat: @"%@-%d", [fileName substringToIndex:endIndex], i];
			resultFileName = [[path stringByAppendingPathComponent:basename] stringByAppendingPathExtension:extension];
		} else {
			resultFileName = [path stringByAppendingPathComponent:[NSString stringWithFormat: @"%@-%d", fileName, i]];
		}

		i++;
	}
	return [resultFileName lastPathComponent];

}

- (NSString *)filenameFromHeader:(NSDictionary *)headerDictionary
{
	NSString *contentDisposition = [headerDictionary objectForKey:@"Content-disposition"];

	NSRange range = [contentDisposition rangeOfString:@"filename=\""];
	if (range.location != NSNotFound)
	{
		NSUInteger startIndex = range.location + range.length;
		NSUInteger length = contentDisposition.length - startIndex - 1;
		NSRange newRange = NSMakeRange(startIndex, length);
		return [contentDisposition substringWithRange:newRange];
	}
	return nil;
}


- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
	[self writeToDestinationFile:data];

	// calculate a transfer speed
	float downloadSpeed = 0;
	NSDate *now = [NSDate date];
	if (self.lastPacketTimestamp)
	{
		NSTimeInterval downloadDurationForPacket = [now timeIntervalSinceDate:self.lastPacketTimestamp];
		float instantSpeed = [data length] / downloadDurationForPacket;

		downloadSpeed = (_previousSpeed * 0.9) + 0.1 * instantSpeed;
	}
	self.lastPacketTimestamp = now;
	// calculation speed done


	// send notification
	if (_expectedContentLength > 0)
	{
		// notify delegate
		if ([_delegate respondsToSelector:@selector(download:downloadedBytes:ofTotalBytes:withSpeed:)])
		{
			[_delegate download:self downloadedBytes:_receivedBytes ofTotalBytes:_expectedContentLength withSpeed:downloadSpeed];
		}

		NSDictionary *userInfo = @{@"ProgressPercent" : [NSNumber numberWithFloat:(float) _receivedBytes / (float) _expectedContentLength], @"TotalBytes" : [NSNumber numberWithLongLong:_expectedContentLength], @"ReceivedBytes" : [NSNumber numberWithLongLong:_receivedBytes]};
		[[NSNotificationCenter defaultCenter] postNotificationName:DTDownloadProgressNotification object:self userInfo:userInfo];
	}
}


- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	_receivedData = nil;
	_urlConnection = nil;

	[self closeDestinationFile];

	[self _completeWithSuccess];
}

#pragma mark Notifications
- (void)appWillTerminate:(NSNotification *)notification
{
	[self stop];
}

/**
* Writes to the destination file the given data to the end of the file.
* Also the destination file is opened lazy if needed.
*/
- (void)writeToDestinationFile:(NSData *)data
{
	if (!_destinationBundleFilePath) {
		// should never happen because in didReceiveResponse the _destinationBundleFilePath is set
		NSDictionary *userInfo = @{NSLocalizedDescriptionKey: @"Cannot store the downloaded data"};
		NSError *error = [[NSError alloc] initWithDomain:@"DTDownload" code:100 userInfo:userInfo];
		[self _completeWithError:error];
		return;
	}

	if (!_destinationFileHandle)
	{
		NSFileManager *fileManager = [NSFileManager defaultManager];
		if (![fileManager fileExistsAtPath:_destinationBundleFilePath])
		{
			// if file does not exist then create it
			[fileManager createFileAtPath:_destinationBundleFilePath contents:data attributes:nil];
			_receivedBytes += [data length];
			_resumeFileOffset = 0;
			_destinationFileHandle = [NSFileHandle fileHandleForWritingAtPath:_destinationBundleFilePath];
			[_destinationFileHandle seekToEndOfFile];
			// we are done here, so exit
			return;
		} else {
			_destinationFileHandle = [NSFileHandle fileHandleForWritingAtPath:_destinationBundleFilePath];
			[_destinationFileHandle seekToFileOffset:_resumeFileOffset];
			_receivedBytes = _resumeFileOffset;
		}
	}
	//NSLog(@"write %d bytes for %@", [data length], _URL);
	[_destinationFileHandle writeData:data];
	_receivedBytes += [data length];
}

- (void)closeDestinationFile {
	[_destinationFileHandle closeFile];
	_destinationFileHandle = nil;
}

#pragma mark Properties

- (BOOL)isRunning
{
	return (_urlConnection != nil);
}


- (BOOL)canResume
{
	return _resumeFileOffset > 0;
}


@synthesize URL = _URL;
@synthesize downloadBundlePath = _downloadBundlePath;
@synthesize downloadEntityTag = _downloadEntityTag;
//@synthesize folderForDownloading = _folderForDownloading;
@synthesize lastPacketTimestamp = _lastPacketTimestamp;
@synthesize delegate = _delegate;
@synthesize lastModifiedDate = _lastModifiedDate;
@synthesize contentType = _contentType;
@synthesize expectedContentLength = _expectedContentLength;
@synthesize context = _context;
@synthesize responseHandler = _responseHandler;
@synthesize completionHandler = _completionHandler;

@end
