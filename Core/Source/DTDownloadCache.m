//
//  DTDownloadCache.m
//  DTFoundation
//
//  Created by Oliver Drobnik on 4/20/12.
//  Copyright (c) 2012 Cocoanetics. All rights reserved.
//

#import "DTDownloadCache.h"

#import "NSString+DTPaths.h"
#import "DTCachedFile.h"
#import "DTDownload.h"
#import "NSString+DTUtilities.h"

#import <ImageIO/CGImageSource.h>
#import "NSString+DTFormatNumbers.h"
#import "DTAsyncFileDeleter.h"

NSString *DTDownloadCacheDidCacheFileNotification = @"DTDownloadCacheDidCacheFile";

@interface DTDownloadCache ()

- (void)_setupCoreDataStack;
- (DTCachedFile *)_cachedFileForURL:(NSURL *)URL inContext:(NSManagedObjectContext *)context;
- (NSArray *)_filesThatNeedToBeDownloadedInContext:(NSManagedObjectContext *)context;
- (NSUInteger)_currentDiskUsageInContext:(NSManagedObjectContext *)context;
- (void)_resetDownloadStatus;
- (void)_commitWorkerContext;

@end

@implementation DTDownloadCache
{
	// Core Data Stack
	NSManagedObjectModel *_managedObjectModel;
	NSPersistentStoreCoordinator *_persistentStoreCoordinator;
    
    NSManagedObjectContext *_writerContext;
    NSManagedObjectContext *_workerContext;
	
	// Internals
	NSMutableSet *_activeDownloads;
	
	// memory cache for certain types, e.g. images
	NSCache *_memoryCache;
    NSCache *_entityCache;
	
	NSUInteger _maxNumberOfConcurrentDownloads;
	NSUInteger _diskCapacity;
	
	// completion handling
	NSMutableDictionary *_completionHandlers;
	
	// timer that frequently writes the MOC
	NSTimer *saveTimer;
}

+ (DTDownloadCache *)sharedInstance
{
	static dispatch_once_t onceToken;
	static DTDownloadCache *_sharedInstance;
	
	dispatch_once(&onceToken, ^{
		_sharedInstance = [[DTDownloadCache alloc] init];
	});
	
	return _sharedInstance;
}

- (id)init
{
	self = [super init];
	{
		[self _setupCoreDataStack];
		
		_activeDownloads = [[NSMutableSet alloc] init];
		
		_memoryCache = [[NSCache alloc] init];
        _entityCache = [[NSCache alloc] init];
		
		_maxNumberOfConcurrentDownloads = 1;
		_diskCapacity = 1024*1024*20; // 20 MB
		
		_completionHandlers = [[NSMutableDictionary alloc] init];
		
		// preload cached object identifiers to speed up initial access
        [self _preloadCachedFileIDs];
		
		// reset status of downloads
		[self _resetDownloadStatus];
		
		saveTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(saveTimerTick:) userInfo:nil repeats:YES];
	}
	
	return self;
}

// should never be called, since this is a singleton
- (void)dealloc
{
	[saveTimer invalidate];
	[self saveTimerTick:nil];
}

- (void)_preloadCachedFileIDs
{
	[_workerContext performBlockAndWait:^{
		NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"DTCachedFile"];
		request.fetchLimit = 0;
		
		NSError *error;
		NSArray *results = [_workerContext executeFetchRequest:request error:&error];
		
		if (!results)
		{
			NSLog(@"error occured fetching %@", [error localizedDescription]);
		}
		
		for (DTCachedFile *cachedFile in results)
		{
			// cache the file entity for this URL
			NSURL *remoteURL = [NSURL URLWithString:cachedFile.remoteURL];
			[_entityCache setObject:cachedFile.objectID forKey:remoteURL];
		}
	}];
}

#pragma mark Queue Handling

// only called from _workerContext
- (void)_startDownloadForURL:(NSURL *)URL shouldAbortIfNotNewer:(BOOL)shouldAbortIfNotNewer
{
	DTDownload *download = [[DTDownload alloc] initWithURL:URL];
	download.delegate = self;
	
	if (shouldAbortIfNotNewer)
	{
		DTCachedFile *cachedFile = [self _cachedFileForURL:URL inContext:_workerContext];
		
		if (cachedFile)
		{
			NSString *cachedETag = cachedFile.entityTagIdentifier;
			NSDate *lastModifiedDate = cachedFile.lastModifiedDate;
			
			__weak DTDownloadCache *weakself = self;
			
			download.responseHandler = ^(DTDownload *download, NSDictionary *headers) {
				BOOL shouldCancel = NO;
				
				if (cachedETag)
				{
					if ([download.downloadEntityTag isEqualToString:cachedETag])
					{
						shouldCancel = YES;
					}
				}
				
				if (lastModifiedDate)
				{
					if ([download.lastModifiedDate isEqualToDate:lastModifiedDate])
					{
						shouldCancel = YES;
					}
				}
				
				if (shouldCancel)
				{
					[download cancel];
					[weakself _removeDownloadFromActiveDownloads:download];
				}
			};
		}
	}
	
	
	[_activeDownloads addObject:download];
	[download startWithResume:YES];
}

- (void)_removeDownloadFromActiveDownloads:(DTDownload *)download
{
	[_workerContext performBlock:^{
        [_activeDownloads removeObject:download];
		
		// remove a handler if it exists
		DTDownloadCacheDataCompletionBlock completion = [_completionHandlers objectForKey:download.URL];
		
		if (completion)
		{
			[_completionHandlers removeObjectForKey:download.URL];
		}
	}];
}

- (void)_startNextQueuedDownload
{
	[_workerContext performBlockAndWait:^{
        NSArray *filesToDownload = [self _filesThatNeedToBeDownloadedInContext:_workerContext];
		
		NSUInteger activeDownloads = [_activeDownloads count];
		
		for (DTCachedFile *oneFile in filesToDownload)
		{
			if (activeDownloads < _maxNumberOfConcurrentDownloads)
			{
				oneFile.isLoading = [NSNumber numberWithBool:YES];
				
				BOOL shouldAbortIfNotNewer = [oneFile.abortDownloadIfNotChanged boolValue];
				
				NSURL *URL = [NSURL URLWithString:oneFile.remoteURL];
				[self _startDownloadForURL:URL shouldAbortIfNotNewer:shouldAbortIfNotNewer];
				
				activeDownloads++;
			}
		}
    }];
}

#pragma mark External Methods

- (NSData *)cachedDataForURL:(NSURL *)URL option:(DTDownloadCacheOption)option
{
    __block NSData *retData = nil;
	
    [_workerContext performBlockAndWait:^{
        DTCachedFile *cachedFile = [self _cachedFileForURL:URL inContext:_workerContext];
		
		if (cachedFile)
		{
			retData = cachedFile.fileData;
		}
		else
		{
			// always create the DTCachedFile for a new request
			
			cachedFile = (DTCachedFile *)[NSEntityDescription insertNewObjectForEntityForName:@"DTCachedFile" inManagedObjectContext:_workerContext];
			
			cachedFile.remoteURL = [URL absoluteString];
			cachedFile.expirationDate = [NSDate distantFuture];
			cachedFile.forceLoad = [NSNumber numberWithBool:YES];
			cachedFile.isLoading = [NSNumber numberWithBool:NO];
		}
		
		cachedFile.lastAccessDate = [NSDate date];
		
		switch (option)
		{
			case DTDownloadCacheOptionNeverLoad:
			{
				break;
			}
				
			case DTDownloadCacheOptionLoadIfNotCached:
			{
				if (retData)
				{
					cachedFile.forceLoad = [NSNumber numberWithBool:NO];
				}
				else
				{
					cachedFile.forceLoad = [NSNumber numberWithBool:YES];
				}
				
				break;
			}
				
			case DTDownloadCacheOptionReturnCacheAndLoadAlways:
			{
				cachedFile.forceLoad = [NSNumber numberWithBool:YES];
				
				break;
			}
				
			case DTDownloadCacheOptionReturnCacheAndLoadIfChanged:
			{
				cachedFile.forceLoad = [NSNumber numberWithBool:YES];
				cachedFile.abortDownloadIfNotChanged = [NSNumber numberWithBool:YES];
				
				break;
			}
		}
		
		// save this
		[self _commitWorkerContext];
        
		
		if (![_activeDownloads count])
		{
			[self _startNextQueuedDownload];
		}
        
        return; // retData is set
    }];
    
    return retData;
}

- (NSUInteger)currentDiskUsage
{
	return [self _currentDiskUsageInContext:_workerContext];
}

#pragma mark DTDownload

- (void)download:(DTDownload *)download didFailWithError:(NSError *)error
{
	[self _removeDownloadFromActiveDownloads:download];
	
	[self _startNextQueuedDownload];
}

- (void)download:(DTDownload *)download didFinishWithFile:(NSString *)path
{
	NSURL *URL = download.URL;
	
    [_workerContext performBlock:^{
		NSData *data = [NSData dataWithContentsOfMappedFile:path];
		
		// only add cached file if we actually got data in it
		if (data)
		{
			// check if URL already exists
			DTCachedFile *cachedFile = [self _cachedFileForURL:URL inContext:_workerContext];
			
			NSAssert(cachedFile, @"Problem, there was no file in the queue for a finished download!");
			
			cachedFile.lastModifiedDate = download.lastModifiedDate;
			cachedFile.entityTagIdentifier = download.downloadEntityTag;
			cachedFile.fileData = data;
			cachedFile.fileSize = [NSNumber numberWithLongLong:download.totalBytes];
			cachedFile.contentType = download.MIMEType;
			cachedFile.remoteURL = [URL absoluteString];
			
			// make sure that this is no longer picked up by files needing download
			cachedFile.forceLoad = [NSNumber numberWithBool:NO];
			cachedFile.isLoading = [NSNumber numberWithBool:NO];
			cachedFile.abortDownloadIfNotChanged = [NSNumber numberWithBool:NO];
			
			[self _commitWorkerContext];
			
			// we transfered the file into the database, so we don't need it any more
			[[DTAsyncFileDeleter sharedInstance] removeItemAtPath:path];
			
			// get reference to completion block if it exists
			DTDownloadCacheDataCompletionBlock completion = [_completionHandlers objectForKey:URL];
			
			// remove from active downloads
			[self _removeDownloadFromActiveDownloads:download];
			
			// completion block and notification
			dispatch_async(dispatch_get_main_queue(), ^{
				// execute completion block if there is one registered
				if (completion)
				{
					completion(URL, data);
				}
				
				// send notification
				NSDictionary *info = @{@"URL": URL};
				[[NSNotificationCenter defaultCenter] postNotificationName:DTDownloadCacheDidCacheFileNotification object:self userInfo:info];
			});
		}
		
		[self _startNextQueuedDownload];
    }];
}


#pragma mark CoreData Stack

- (NSManagedObjectModel *)_model
{
	NSManagedObjectModel *model = [[NSManagedObjectModel alloc] init];
	
	// create the entity
	NSEntityDescription *entity = [[NSEntityDescription alloc] init];
	[entity setName:@"DTCachedFile"];
	[entity setManagedObjectClassName:@"DTCachedFile"];
	
	// create the attributes
	NSMutableArray *properties = [NSMutableArray array];
	
	NSAttributeDescription *remoteURLAttribute = [[NSAttributeDescription alloc] init];
	[remoteURLAttribute setName:@"remoteURL"];
	[remoteURLAttribute setAttributeType:NSStringAttributeType];
	[remoteURLAttribute setOptional:NO];
	[remoteURLAttribute setIndexed:YES];
	[properties addObject:remoteURLAttribute];
	
	NSAttributeDescription *fileDataAttribute = [[NSAttributeDescription alloc] init];
	[fileDataAttribute setName:@"fileData"];
	[fileDataAttribute setAttributeType:NSBinaryDataAttributeType];
	[fileDataAttribute setOptional:YES];
	[fileDataAttribute setAllowsExternalBinaryDataStorage:YES];
	[properties addObject:fileDataAttribute];
	
	NSAttributeDescription *lastAccessDateAttribute = [[NSAttributeDescription alloc] init];
	[lastAccessDateAttribute setName:@"lastAccessDate"];
	[lastAccessDateAttribute setAttributeType:NSDateAttributeType];
	[lastAccessDateAttribute setOptional:NO];
	[properties addObject:lastAccessDateAttribute];
	
	NSAttributeDescription *lastModifiedDateAttribute = [[NSAttributeDescription alloc] init];
	[lastModifiedDateAttribute setName:@"lastModifiedDate"];
	[lastModifiedDateAttribute setAttributeType:NSDateAttributeType];
	[lastModifiedDateAttribute setOptional:YES];
	[properties addObject:lastModifiedDateAttribute];
	
	NSAttributeDescription *expirationDateAttribute = [[NSAttributeDescription alloc] init];
	[expirationDateAttribute setName:@"expirationDate"];
	[expirationDateAttribute setAttributeType:NSDateAttributeType];
	[expirationDateAttribute setOptional:NO];
	[properties addObject:expirationDateAttribute];
	
	NSAttributeDescription *contentTypeAttribute = [[NSAttributeDescription alloc] init];
	[contentTypeAttribute setName:@"contentType"];
	[contentTypeAttribute setAttributeType:NSStringAttributeType];
	[contentTypeAttribute setOptional:YES];
	[properties addObject:contentTypeAttribute];
	
	NSAttributeDescription *fileSizeAttribute = [[NSAttributeDescription alloc] init];
	[fileSizeAttribute setName:@"fileSize"];
	[fileSizeAttribute setAttributeType:NSInteger32AttributeType];
	[fileSizeAttribute setOptional:YES];
	[properties addObject:fileSizeAttribute];
	
	NSAttributeDescription *forceLoadAttribute = [[NSAttributeDescription alloc] init];
	[forceLoadAttribute setName:@"forceLoad"];
	[forceLoadAttribute setAttributeType:NSBooleanAttributeType];
	[forceLoadAttribute setOptional:YES];
	[properties addObject:forceLoadAttribute];
	
	NSAttributeDescription *abortAttribute = [[NSAttributeDescription alloc] init];
	[abortAttribute setName:@"abortDownloadIfNotChanged"];
	[abortAttribute setAttributeType:NSBooleanAttributeType];
	[abortAttribute setOptional:YES];
	[properties addObject:abortAttribute];
	
	NSAttributeDescription *loadingAttribute = [[NSAttributeDescription alloc] init];
	[loadingAttribute setName:@"isLoading"];
	[loadingAttribute setAttributeType:NSBooleanAttributeType];
	[loadingAttribute setOptional:NO];
	[properties addObject:loadingAttribute];
	
	NSAttributeDescription *entityTagIdentifierAttribute = [[NSAttributeDescription alloc] init];
	[entityTagIdentifierAttribute setName:@"entityTagIdentifier"];
	[entityTagIdentifierAttribute setAttributeType:NSStringAttributeType];
	[entityTagIdentifierAttribute setOptional:YES];
	[properties addObject:entityTagIdentifierAttribute];
	
	// add attributes to entity
	[entity setProperties:properties];
	
	// add entity to model
	[model setEntities:[NSArray arrayWithObject:entity]];
	
	return model;
}

- (void)_setupCoreDataStack
{
	// setup managed object model
	
	/*
     NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"DTDownloadCache" withExtension:@"momd"];
     _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
	 */
	
	// in code
    _managedObjectModel = [self _model];
	
	// setup persistent store coordinator
	NSURL *storeURL = [NSURL fileURLWithPath:[[NSString cachesPath] stringByAppendingPathComponent:@"DTDownload.cache"]];
	
	NSError *error = nil;
	_persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:_managedObjectModel];
	
	if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error])
	{
		// inconsistent model/store
		[[NSFileManager defaultManager] removeItemAtURL:storeURL error:NULL];
		
		// retry once
		if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error])
		{
			NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
			abort();
		}
	}
    
    // create writer MOC
    _writerContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
	[_writerContext setPersistentStoreCoordinator:_persistentStoreCoordinator];
    
    // create worker MOC for background operations
    _workerContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    _workerContext.parentContext = _writerContext;
}

// returned objects can only be used from the same context
- (DTCachedFile *)_cachedFileForURL:(NSURL *)URL inContext:(NSManagedObjectContext *)context
{
    NSManagedObjectID *cachedIdentifier = [_entityCache objectForKey:URL];
    
    if (cachedIdentifier)
    {
        DTCachedFile *cachedFile = (DTCachedFile *)[context objectWithID:cachedIdentifier];
        
        return cachedFile;
    }
    
    
	NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"DTCachedFile"];
	
	request.predicate = [NSPredicate predicateWithFormat:@"remoteURL == %@", [URL absoluteString]];
	request.fetchLimit = 1;
	
	NSError *error;
	NSArray *results = [context executeFetchRequest:request error:&error];
	
	if (!results)
	{
		NSLog(@"error occured fetching %@", [error localizedDescription]);
	}
	
    DTCachedFile *cachedFile = [results lastObject];
    
    if (cachedFile)
    {
        // cache the file entity for this URL
        [_entityCache setObject:cachedFile.objectID forKey:URL];
    }
	
	return cachedFile;
}

- (NSArray *)_filesThatNeedToBeDownloadedInContext:(NSManagedObjectContext *)context
{
	NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"DTCachedFile"];
	
	NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"lastAccessDate" ascending:NO];
	request.sortDescriptors = [NSArray arrayWithObject:sort];
	
	request.predicate = [NSPredicate predicateWithFormat:@"forceLoad == YES and isLoading == NO"];
	request.fetchLimit = _maxNumberOfConcurrentDownloads;
	
	NSError *error;
	
	NSArray *results = [context executeFetchRequest:request error:&error];
	if (!results)
	{
		NSLog(@"Error fetching download files: %@", [error localizedDescription]);
	}
	
	return results;
}

// only call this from within a worker performBlock
- (void)_commitWorkerContext
{
	if ([_workerContext hasChanges])
	{
		NSError *error = nil;
		if (![_workerContext save:&error])
		{
			NSLog(@"Error saving worker context: %@", [error localizedDescription]);
			return;
		}
	}
}

#pragma mark Maintenance

- (NSUInteger)_currentDiskUsageInContext:(NSManagedObjectContext *)context
{
	NSExpression *ex = [NSExpression expressionForFunction:@"sum:"
												 arguments:[NSArray arrayWithObject:[NSExpression expressionForKeyPath:@"fileSize"]]];
	
    NSExpressionDescription *ed = [[NSExpressionDescription alloc] init];
    [ed setName:@"result"];
    [ed setExpression:ex];
    [ed setExpressionResultType:NSInteger64AttributeType];
	
    NSArray *properties = [NSArray arrayWithObject:ed];
	
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setPropertiesToFetch:properties];
    [request setResultType:NSDictionaryResultType];
	
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"DTCachedFile" inManagedObjectContext:context];
    [request setEntity:entity];
	
    NSArray *results = [context executeFetchRequest:request error:nil];
    NSDictionary *resultsDictionary = [results objectAtIndex:0];
    NSNumber *resultValue = [resultsDictionary objectForKey:@"result"];
	
    return [resultValue unsignedIntegerValue];
}

- (void)_removeExpiredFilesInContext:(NSManagedObjectContext *)context
{
	NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"DTCachedFile"];
	request.propertiesToFetch = [NSArray arrayWithObject:@"expirationDate"];
	
	request.predicate = [NSPredicate predicateWithFormat:@"expirationDate < %@", [NSDate date]];
	
	NSError *error;
	NSArray *results = [context executeFetchRequest:request error:&error];
	
	if (!results)
	{
		NSLog(@"error occured fetching %@", [error localizedDescription]);
		return;
	}
	
	for (NSManagedObject *oneObject in results)
	{
		[context deleteObject:oneObject];
	}
}

- (void)_removeFilesOverCapacity:(NSUInteger)capacity inContext:(NSManagedObjectContext *)context
{
	NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"DTCachedFile"];
	request.propertiesToFetch = [NSArray arrayWithObjects:@"fileSize", @"lastAccessDate", nil];
	
	NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"lastAccessDate" ascending:NO];
	request.sortDescriptors = [NSArray arrayWithObject:sort];
	
	NSError *error;
	NSArray *results = [context executeFetchRequest:request error:&error];
	
	if (!results)
	{
		NSLog(@"error occured fetching %@", [error localizedDescription]);
		return;
	}
	
	long long capacitySoFar = 0;
	
	for (DTCachedFile *cachedFile in results)
	{
		long long fileSize = [cachedFile.fileSize longLongValue];
		
		capacitySoFar += fileSize;
		
		if (capacitySoFar > capacity)
		{
			NSLog(@"over capacity: removed: %@ %lld", cachedFile.remoteURL, capacitySoFar);
			[context deleteObject:cachedFile];
		}
	}
}

- (void)_runMaintenance
{
    [_workerContext performBlock:^{
		NSUInteger diskUsageBeforeMaintenance = [self _currentDiskUsageInContext:_workerContext];
        
		// remove all expired files
		[self _removeExpiredFilesInContext:_workerContext];
		
		// prune oldest accessed files so that we get below disk usage limit
		if (diskUsageBeforeMaintenance>_diskCapacity)
		{
			[self _removeFilesOverCapacity:_diskCapacity inContext:_workerContext];
		}
		
		// only commit if there are actually modifications
        [self _commitWorkerContext];
		
		NSUInteger diskUsageAfterMaintenance = [self _currentDiskUsageInContext:_workerContext];
		
		NSLog(@"Running Maintenance, Usage Before: %@, After: %@", [NSString stringByFormattingBytes:diskUsageBeforeMaintenance], [NSString stringByFormattingBytes:diskUsageAfterMaintenance]);
    }];
}

- (void)_resetDownloadStatus
{
	[_workerContext performBlockAndWait:^{
		NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"DTCachedFile"];
		
		NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"lastAccessDate" ascending:NO];
		request.sortDescriptors = [NSArray arrayWithObject:sort];
		
		request.predicate = [NSPredicate predicateWithFormat:@"isLoading == YES"];
		
		NSError *error;
		
		NSArray *results = [_workerContext executeFetchRequest:request error:&error];
		if (!results)
		{
			NSLog(@"Error cleaning up download status: %@", [error localizedDescription]);
		}
		
		for (DTCachedFile *oneFile in results)
		{
			oneFile.isLoading = [NSNumber numberWithBool:NO];
		}
		
		[self _commitWorkerContext];
	}];
}

- (void)saveTimerTick:(NSTimer *)timer
{
	[_writerContext performBlock:^{
		if ([_writerContext hasChanges])
		{
			NSError *error = nil;
			if (![_writerContext save:&error])
			{
				NSLog(@"Error saving writer context: %@", [error localizedDescription]);
				return;
			}
		}
	}];
}

#pragma mark Completion Blocks

- (void)_registerCompletion:(DTDownloadCacheDataCompletionBlock)completion forURL:(NSURL *)URL
{
	[_completionHandlers setObject:[completion copy] forKey:URL];
}

#pragma mark Properties

- (void)setMaxNumberOfConcurrentDownloads:(NSUInteger)maxNumberOfConcurrentDownloads
{
	if (_maxNumberOfConcurrentDownloads != maxNumberOfConcurrentDownloads)
	{
		NSAssert(maxNumberOfConcurrentDownloads>0, @"maximum number of concurrent downloads cannot be zero");
		_maxNumberOfConcurrentDownloads = maxNumberOfConcurrentDownloads;
	}
}

- (void)setDiskCapacity:(NSUInteger)diskCapacity
{
	if (diskCapacity!=_diskCapacity)
	{
		_diskCapacity = diskCapacity;
		
		[self _runMaintenance];
	}
}

@synthesize maxNumberOfConcurrentDownloads = _maxNumberOfConcurrentDownloads;
@synthesize diskCapacity = _diskCapacity;

@end



@implementation DTDownloadCache (Images)

//TODO: make this thread-safe to be called from background threads

- (UIImage *)cachedImageForURL:(NSURL *)URL option:(DTDownloadCacheOption)option
{
	// try memory cache first
	UIImage *cachedImage = [_memoryCache objectForKey:URL];
	
	if (cachedImage)
	{
		return cachedImage;
	}
	
	// try file cache
	NSData *data = [self cachedDataForURL:URL option:option];
	
	if (!data)
	{
		return nil;
	}
	
    @try {
        cachedImage = [UIImage imageWithData:data];
    }
    @catch (NSException *exception) {
        NSLog(@"%@", exception);
    }
    @finally {
    }
	
	if (!cachedImage)
	{
		NSLog(@"Illegal Data cached for %@", URL);
        
        [_memoryCache removeObjectForKey:URL];
		return nil;
	}
	
	// put in memory cache
	NSUInteger cost = (NSUInteger)(cachedImage.size.width * cachedImage.size.height);
	[_memoryCache setObject:cachedImage forKey:URL cost:cost];
	
	return cachedImage;
}

- (UIImage *)cachedImageForURL:(NSURL *)URL option:(DTDownloadCacheOption)option completion:(DTDownloadCacheImageCompletionBlock)completion
{
	UIImage *cachedImage = [self cachedImageForURL:URL option:option];
	
	if (cachedImage)
	{
		return cachedImage;
	}
	
	// register handler
	if (completion)
	{
		DTDownloadCacheDataCompletionBlock internalBlock = ^(NSURL *URL, NSData *data)
		{
			// make an image out of the data
			UIImage *cachedImage = [UIImage imageWithData:data];
			
			if (!cachedImage)
			{
				NSLog(@"Illegal Data cached for %@", URL);
				return;
			}
			
			// put in memory cache
			NSUInteger cost = (NSUInteger)(cachedImage.size.width * cachedImage.size.height);
			[_memoryCache setObject:cachedImage forKey:URL cost:cost];
			
			// execute wrapped completion block
			completion(URL, cachedImage);
		};
		
		[self _registerCompletion:internalBlock forURL:URL];
	}
	
	return nil;
}


@end
