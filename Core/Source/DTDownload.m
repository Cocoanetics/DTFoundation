//
//  CatalogDownloader.m
//  iCatalog
//
//  Created by Oliver Drobnik on 8/6/10.
//  Copyright 2010 Drobnik.com. All rights reserved.
//

#import "DTDownload.h"
#import "DTZipArchive.h"
#import "NSString+DTUtilities.h"

@interface DTDownload ()

@property (nonatomic, retain) NSString *internalDownloadFolder;
@property (nonatomic, retain) NSDate *lastPaketTimestamp;

- (void)updateInfoDictionary;
- (void)completeDownload;
- (void)startWithResume:(BOOL)shouldResume;

@end




@implementation DTDownload

@synthesize url = _url, internalDownloadFolder, downloadEntityTag, downloadEntryIdentifier, folderForDownloading, lastPaketTimestamp, delegate, lastModifiedDate;
@synthesize context;

#pragma mark Downloading

- (id)initWithURL:(NSURL *)url
{
  self = [super init];
	if (self)
	{
		self.url = url;
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillTerminate:) name:UIApplicationWillTerminateNotification object:nil];
	}
	
	return self;
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	
	if (!headOnly && receivedBytes < totalBytes)
	{
		// update resume info on disk
		[self updateInfoDictionary];
	}
}

- (void)startHEAD
{
	NSMutableURLRequest *request=[NSMutableURLRequest requestWithURL:_url
														 cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData
													 timeoutInterval:60.0];
	[request setHTTPMethod:@"HEAD"];
	
	// start downloading
	urlConnection=[[NSURLConnection alloc] initWithRequest:request delegate:self];
	
	// getting only a HEAD
	headOnly = YES;
}

- (void)startWithResume:(BOOL)shouldResume
{
	NSString *fileName = [[_url path] lastPathComponent];
	self.internalDownloadFolder = [[self.folderForDownloading stringByAppendingPathComponent:fileName] stringByAppendingPathExtension:@"download"];
	
	receivedDataFilePath = [internalDownloadFolder stringByAppendingPathComponent:fileName];
	
	if ([[NSFileManager defaultManager] fileExistsAtPath:internalDownloadFolder])
	{
		// there is a paused download
		
		// load previous data
		
		NSString *infoPath = [internalDownloadFolder stringByAppendingPathComponent:@"Info.plist"];
		NSDictionary *infoDictionary = [NSDictionary dictionaryWithContentsOfFile:infoPath];
		NSDictionary *resumeInfo = [infoDictionary objectForKey:@"DownloadEntryResumeInformation"];
		
		totalBytes = [[infoDictionary objectForKey:@"DownloadEntryProgressTotalToLoad"] longLongValue];
		receivedBytes = [[resumeInfo objectForKey:@"NSURLDownloadBytesReceived"] longLongValue];
		self.downloadEntryIdentifier = [infoDictionary objectForKey:@"DownloadEntryIdentifier"];
		if (!downloadEntryIdentifier)
		{
			self.downloadEntryIdentifier = [NSString stringWithUUID];
		}
		
		self.downloadEntityTag = [resumeInfo objectForKey:@"NSURLDownloadEntityTag"];
		
		
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
			// here we assume we should continue download
			receivedDataFile = [NSFileHandle fileHandleForWritingAtPath:receivedDataFilePath];
			[receivedDataFile seekToEndOfFile];
			
			// test if remembered length = received data length
			
			long long offset = [receivedDataFile offsetInFile];
			if (receivedBytes != offset)
			{
				// inconsistency, reset
				receivedBytes = 0;
				totalBytes = 0;
				self.downloadEntityTag = nil;
				self.lastModifiedDate = nil;
				
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
				if (receivedBytes && receivedBytes == totalBytes)
				{
					NSLog(@"Already done!");
					
					//[self completeDownload];
					[self performSelectorInBackground:@selector(completeDownload) withObject:nil];
					return;
				}
			}
		}
	}
	else 
	{
		// create download folder
		NSError *error = nil;
		
		if (![[NSFileManager defaultManager] createDirectoryAtPath:internalDownloadFolder withIntermediateDirectories:NO attributes:nil error:&error])
		{
			NSLog(@"Cannot create download folder %@, %@", internalDownloadFolder, [error localizedDescription]);
			return;
		}
		
		self.downloadEntryIdentifier = [NSString stringWithUUID];
	}
	
	
	
	NSMutableURLRequest *request=[NSMutableURLRequest requestWithURL:_url
														 cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData
													 timeoutInterval:60.0];
	
	// set range header
	if (receivedBytes)
	{
		[request setValue:[NSString stringWithFormat:@"bytes=%d-", receivedBytes] forHTTPHeaderField:@"Range"];
	}
	
	// start downloading
	urlConnection=[[NSURLConnection alloc] initWithRequest:request delegate:self];
	
	if (urlConnection) 
	{
		receivedData=[NSMutableData data];
	} 
}

- (void)cancel
{
	self.delegate = nil;
	
	if (receivedBytes < totalBytes)
	{
		// update resume info on disk
		[self updateInfoDictionary];
	}
	
	[urlConnection cancel];
	
	receivedData = nil;
	urlConnection = nil;
}

- (void)notifyDelegateOfSuccessWithFiles:(NSArray *)files
{
	// notify delegate
	if ([delegate respondsToSelector:@selector(download:didFinishWithFiles:)])
	{
		[delegate download:self didFinishWithFiles:files];
	}
}

- (void)notifyDelegateOfError:(NSError *)error
{
	if ([delegate respondsToSelector:@selector(download:didFailWithError:)])
	{
		[delegate download:self didFailWithError:error];
	}
}


- (void)completeDownload
{
	@autoreleasepool 
	{
	
	NSError *error = nil;
	
	NSFileManager *fm = [NSFileManager defaultManager];
	
	NSMutableArray *downloadedFiles = [NSMutableArray array];
	
	NSString *extension = [[[_url path] pathExtension] lowercaseString];
	
	if ([extension isEqualToString:@"zip"])
	{
		// notify delegate
		if ([delegate respondsToSelector:@selector(downloadWillStartUncompressing:)])
		{
			[(id)delegate performSelectorOnMainThread:@selector(downloadWillStartUncompressing:) withObject:self waitUntilDone:YES];
		}
		
		// create unzip folder
		NSString *unzipPath = [self.internalDownloadFolder stringByAppendingPathComponent:@"unzip"];
		
		if ([fm fileExistsAtPath:unzipPath])
		{
			if (![fm removeItemAtPath:unzipPath error:&error])
			{
				NSLog(@"Cannot remove item %@, %@", unzipPath, [error localizedDescription]);
				return;
			}
		}
		
		if (![fm createDirectoryAtPath:unzipPath withIntermediateDirectories:NO attributes:nil error:&error])
		{
			NSLog(@"Cannot create directory %@, %@", unzipPath, [error localizedDescription]);
			return;
		}
		
		DTZipArchive *zip = [[DTZipArchive alloc] init];
		
		[zip enumerateUncompressedFilesAsDataUsingBlock:^(NSString *fileName, NSData *data, BOOL *stop) {
			NSString *filePath = [unzipPath stringByAppendingPathComponent:fileName];
			[data writeToFile:filePath atomically:YES];
		}];					 
							 
		// make list of unzipped result files
		NSArray *unzippedFiles = [fm contentsOfDirectoryAtPath:unzipPath error:&error];
		
		// move resulting files into final location
		for (NSString *oneFile in unzippedFiles)
		{
			if (![oneFile isEqualToString:@"__MACOSX"])
			{
				
				NSString *fullPath = [unzipPath stringByAppendingPathComponent:oneFile];
				NSString *targetPath = [self.folderForDownloading stringByAppendingPathComponent:oneFile];
				
				if ([fm fileExistsAtPath:targetPath])
				{
					// remove existing file
					if (![fm removeItemAtPath:targetPath error:&error])
					{
						NSLog(@"Cannot remove item %@", [error localizedDescription]);
						return;
					}
				}
				
				if (![fm moveItemAtPath:fullPath toPath:targetPath error:&error])
				{
					NSLog(@"Cannot move item from %@ to %@, %@", fullPath, targetPath, [error localizedDescription]);
					return;
				}
				
				[downloadedFiles addObject:targetPath];
			}
		}
	}
	else 
	{
		// just a single file
		NSString *fileName = [[_url path] lastPathComponent];
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
		
		[downloadedFiles addObject:targetPath];
	}
	
	// remove internal download folder
	if (![fm removeItemAtPath:self.internalDownloadFolder error:&error])
	{
		NSLog(@"Cannot remove item %@, %@", self.internalDownloadFolder, [error localizedDescription]);
		return;
	}
	
	// notify delegate
	NSArray *files = [downloadedFiles copy];
	
	[self performSelectorOnMainThread:@selector(notifyDelegateOfSuccessWithFiles:) withObject:files waitUntilDone:YES];

	}
}

-(void) ErrorMessage:(NSString*) msg
{
	NSError *error = [NSError errorWithDomain:@"UnZip" code:1 userInfo:[NSDictionary dictionaryWithObject:msg forKey:NSLocalizedDescriptionKey]];
	[self performSelectorOnMainThread:@selector(notifyDelegateOfError:) withObject:error waitUntilDone:YES];
}



- (void)updateInfoDictionary
{
	NSMutableDictionary *resumeDict = [NSMutableDictionary dictionary];
	
	[resumeDict setObject:[NSNumber numberWithLongLong:receivedBytes] forKey:@"NSURLDownloadBytesReceived"];
	
	if (downloadEntityTag)
	{
		[resumeDict setObject:downloadEntityTag forKey:@"NSURLDownloadEntityTag"];
	}
	
	[resumeDict setObject:[_url description] forKey:@"DownloadEntryURL"];
	
	NSDictionary *writeDict = [NSDictionary dictionaryWithObjectsAndKeys:
							   [NSNumber numberWithInt:-999], @"DownloadEntryErrorCodeDictionaryKey",
							   @"NSURLErrorDomain", @"DownloadEntryErrorDomainDictionaryKey",
							   
							   downloadEntryIdentifier, @"DownloadEntryIdentifier",
							   receivedDataFilePath, @"DownloadEntryPath",
							   [NSNumber numberWithLongLong:receivedBytes], @"DownloadEntryProgressBytesSoFar",
							   [NSNumber numberWithLongLong:totalBytes], @"DownloadEntryProgressTotalToLoad",
							   resumeDict, @"DownloadEntryResumeInformation",
							   [_url description], @"DownloadEntryURL"
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
	[self updateInfoDictionary];
	
	
	if ([delegate respondsToSelector:@selector(download:didFailWithError:)])
	{
		[delegate download:self didFailWithError:error];
	}
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{	
	if ([response isKindOfClass:[NSHTTPURLResponse class]])
	{
		NSHTTPURLResponse *http = (NSHTTPURLResponse *)response;
		//NSString* contentType = [http.allHeaderFields objectForKey:@"Content-Type"];
		
		
		if (http.statusCode>=400)
		{
			NSDictionary *userInfo = [NSDictionary dictionaryWithObject:[NSHTTPURLResponse localizedStringForStatusCode:http.statusCode] forKey:NSLocalizedDescriptionKey];

			NSError *error = [NSError errorWithDomain:@"iCatalog" code:http.statusCode userInfo:userInfo];
			
			[connection cancel];
			
			[self connection:connection didFailWithError:error];
			return;
		}
			
		if (totalBytes<=0)
		{
			totalBytes = [response expectedContentLength];
		}
		
		NSString * currentEntityTag = [http.allHeaderFields objectForKey:@"Etag"];
		if (!downloadEntityTag)
		{
			self.downloadEntityTag = currentEntityTag;
		}
		else 
		{
			// check if it's the same as from last time
			if (![self.downloadEntityTag isEqualToString:currentEntityTag])
			{
				// file was changed on server restart from beginning
				[urlConnection cancel];
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
			
			self.lastModifiedDate = [dateFormatter dateFromString:modified];
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
		[delegate download:self downloadedBytes:receivedBytes ofTotalBytes:totalBytes withSpeed:downloadSpeed];
	}
	
}


- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	receivedData = nil;
	urlConnection = nil;
	
	[receivedDataFile closeFile];
	
	if (headOnly)
	{
		if ([delegate respondsToSelector:@selector(downloadDidFinishHEAD:)])
		{
			[delegate downloadDidFinishHEAD:self];
		}
	}
	else
	{
		//[self completeDownload];
		[self performSelectorInBackground:@selector(completeDownload) withObject:nil];
	}
}

#pragma mark Properties
- (NSString *)folderForDownloading
{
	if (!folderForDownloading)
	{
		// default = NSCachesDirectory
		self.folderForDownloading = NSTemporaryDirectory();
	}
	
	return folderForDownloading;
}

#pragma mark Formatting
+ (NSString *)stringByFormattingBytesAsHumanReadable:(long long)bytes
{
	if (bytes>1024*1024)
	{
		float mb = bytes/(1024.0*1024.0);
		return [NSString stringWithFormat:@"%.2f MB", mb];
	}
	else if (bytes>1024)
	{
		float kb = bytes/(1024.0);
		return [NSString stringWithFormat:@"%.2f KB", kb];
	}
	else 
	{
		return [NSString stringWithFormat:@"%.0f B", bytes];
	}
}

#pragma mark Notifications
- (void)appWillTerminate:(NSNotification *)notification
{
	[self cancel];
}

@end
