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
- (NSUInteger)_currentDiskUsageInContext:(NSManagedObjectContext *)context;
- (void)_commitWorkerContext;

@end

@implementation DTDownloadCache
{
	// Core Data Stack
	NSManagedObjectModel *_managedObjectModel;
	NSPersistentStoreCoordinator *_persistentStoreCoordinator;
    
    NSManagedObjectContext *_writerContext;
    NSManagedObjectContext *_managedObjectContext;
    NSManagedObjectContext *_workerContext;
	
	// Internals
	NSMutableDictionary *_downloads;
	NSMutableArray *_downloadQueue;
	NSMutableSet *_activeDownloads;
	
	// memory cache for certain types, e.g. images
	NSCache *_memoryCache;
    NSCache *_entityCache;
	
	NSUInteger _maxNumberOfConcurrentDownloads;
	NSUInteger _diskCapacity;
	
	// completion handling
	NSMutableDictionary *_completionHandlers;
	
	// maintenance
    dispatch_queue_t _downloadQueueSyncQueue;
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
        _downloadQueueSyncQueue = dispatch_queue_create("DTDownloadCache Download Queue Sync Queue", 0);
        
		[self _setupCoreDataStack];
		
		_downloads = [[NSMutableDictionary alloc] init];
		_downloadQueue = [[NSMutableArray alloc] init];
		_activeDownloads = [[NSMutableSet alloc] init];
		
		_memoryCache = [[NSCache alloc] init];
        _entityCache = [[NSCache alloc] init];
		
		_maxNumberOfConcurrentDownloads = 1;
		_diskCapacity = 1024*1024*20; // 20 MB
		
		_completionHandlers = [[NSMutableDictionary alloc] init];
		
		// preload cached object identifiers to speed up initial access
        [self _preloadCachedFileIDs];
	}
	
	return self;
}

- (void)_preloadCachedFileIDs
{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"DTCachedFile"];
	request.fetchLimit = 0;
	
	NSError *error;
	NSArray *results = [_managedObjectContext executeFetchRequest:request error:&error];
	
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
}

#pragma mark Queue Handling

- (void)_enqueueDownloadForURL:(NSURL *)URL option:(DTDownloadCacheOption)option
{
	DTDownload *download = [[DTDownload alloc] initWithURL:URL];
	download.delegate = self;
	
	if (option == DTDownloadCacheOptionReturnCacheAndLoadIfChanged)
	{
		DTCachedFile *cachedFile = [self _cachedFileForURL:URL inContext:_managedObjectContext];
		
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
					[weakself _removeDownloadFromQueue:download];
				}
			};
		}
	}
    
	dispatch_sync(_downloadQueueSyncQueue, ^{
        [_downloads setObject:download forKey:URL];
        [_downloadQueue addObject:download];
    });
}

- (void)_removeDownloadFromQueue:(DTDownload *)download
{
    dispatch_sync(_downloadQueueSyncQueue, ^{
        [_activeDownloads removeObject:download];
        [_downloads removeObjectForKey:download.URL];
        [_downloadQueue removeObject:download];
    });
	
	// remove a handler if it exists
	DTDownloadCacheDataCompletionBlock completion = [_completionHandlers objectForKey:download.URL];
	
	if (completion)
	{
		[_completionHandlers removeObjectForKey:download.URL];
	}
}

- (void)_startNextQueuedDownload
{
    dispatch_sync(_downloadQueueSyncQueue, ^{
        
        NSUInteger numberLoading = 0;
        
        for (DTDownload *nextDownload in [_downloadQueue reverseObjectEnumerator])
        {
            if (numberLoading<_maxNumberOfConcurrentDownloads)
            {
                if (![nextDownload isLoading])
                {
                    [_activeDownloads addObject:nextDownload];
                    [nextDownload startWithResume:YES];
                }
                
                numberLoading++;
            }
        }
    });
}

- (void)_cancelDownloadsOverConcurrencyLimit
{
    dispatch_sync(_downloadQueueSyncQueue, ^{
        NSUInteger numberLoading = 0;
        
        for (DTDownload *nextDownload in [_downloadQueue reverseObjectEnumerator])
        {
            if ([nextDownload isLoading])
            {
                numberLoading++;
                
                if (numberLoading<=_maxNumberOfConcurrentDownloads)
                {
                    // leave it be
                }
                else
                {
                    // cancel
                    [nextDownload cancel];
                    
                    [_activeDownloads removeObject:nextDownload];
                    
                    // cancel ditches the delegate, lets restore that
                    nextDownload.delegate = self;
                }
                
            }
        }
        
        NSLog(@"Loading Downloads: %d", numberLoading);
    });
}


#pragma mark External Methods


- (NSData *)cachedDataForURL:(NSURL *)URL option:(DTDownloadCacheOption)option
{
    __block NSData *retData = nil;
    
    [_managedObjectContext performBlockAndWait:^{
        DTCachedFile *existingCacheEntry = [self _cachedFileForURL:URL inContext:_managedObjectContext];
        
        if (existingCacheEntry)
        {
            retData = existingCacheEntry.fileData;
            
            [_workerContext performBlock:^{
                // transfer the existing cache file entity to the temp context
                DTCachedFile *cacheEntry = (DTCachedFile *)[_workerContext objectWithID:existingCacheEntry.objectID];
                
                if (option == DTDownloadCacheOptionReturnCacheAndLoadAlways)
                {
                    [_workerContext deleteObject:cacheEntry];
                }
                else
                {
                    cacheEntry.lastAccessDate = [NSDate date];
                }
                
                [self _commitWorkerContext];
            }];
        }
        
        if (option == DTDownloadCacheOptionNeverLoad)
        {
            return; // retData is set
        }
        
        if (retData && option == DTDownloadCacheOptionLoadIfNotCached)
        {
            return; // retData is set
        }
        
        // we don't have a cache entry, need to load
        
        __block DTDownload *download;
        
        dispatch_sync(_downloadQueueSyncQueue, ^{
            download = [_downloads objectForKey:URL];
        });
        
        if (download)
        {
            // already in queue, give it higher prio
            if (![download isLoading])
            {
                dispatch_sync(_downloadQueueSyncQueue, ^{
                    // move it to end of LIFO queue
                    [_downloadQueue removeObject:download];
                    [_downloadQueue addObject:download];
                });
            }
            
            retData = nil;
            return; // retData is set
        }
        
        [self _enqueueDownloadForURL:URL option:option];
        [self _startNextQueuedDownload];
        
        return; // retData is set
    }];
    
    return retData;
}

- (NSUInteger)currentDiskUsage
{
	return [self _currentDiskUsageInContext:_managedObjectContext];
}

#pragma mark DTDownload

- (void)download:(DTDownload *)download didFailWithError:(NSError *)error
{
	[self _removeDownloadFromQueue:download];
	
	[self _startNextQueuedDownload];
}

- (void)download:(DTDownload *)download didFinishWithFile:(NSString *)path
{
    [_workerContext performBlock:^{
		// check if URL already exists
		DTCachedFile *cachedFile = [self _cachedFileForURL:download.URL inContext:_workerContext];
		
		if (!cachedFile)
		{
			// create a new entity
			cachedFile = (DTCachedFile *)[NSEntityDescription insertNewObjectForEntityForName:@"DTCachedFile" inManagedObjectContext:_workerContext];
		}
		
		cachedFile.lastAccessDate = [NSDate date];
		cachedFile.expirationDate = [NSDate distantFuture];
		cachedFile.lastModifiedDate = download.lastModifiedDate;
		NSData *data = [NSData dataWithContentsOfMappedFile:path];
		cachedFile.entityTagIdentifier = download.downloadEntityTag;
		cachedFile.fileData = data;
		cachedFile.fileSize = [NSNumber numberWithLongLong:download.totalBytes];
		cachedFile.contentType = download.MIMEType;
		cachedFile.remoteURL = [download.URL absoluteString];
		
		[self _commitWorkerContext];
        
        // we transfered the file into the database, so we don't need it any more
        [[DTAsyncFileDeleter sharedInstance] removeItemAtPath:path];
        
        // get reference to completion block if it exists
        DTDownloadCacheDataCompletionBlock completion = [_completionHandlers objectForKey:download.URL];
        
        // remove all traces of this download so that something triggered in completion block or notification gets the image right away
        [self _removeDownloadFromQueue:download];
        
		// completion block and notification
		dispatch_async(dispatch_get_main_queue(), ^{
			// execute completion block if there is one registered
			if (completion)
			{
				completion(download.URL, data);
			}
			
			// send notification
			[[NSNotificationCenter defaultCenter] postNotificationName:DTDownloadCacheDidCacheFileNotification object:download.URL];
		});
        
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
	[fileDataAttribute setOptional:NO];
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
	[contentTypeAttribute setOptional:NO];
	[properties addObject:contentTypeAttribute];

	NSAttributeDescription *fileSizeAttribute = [[NSAttributeDescription alloc] init];
	[fileSizeAttribute setName:@"fileSize"];
	[fileSizeAttribute setAttributeType:NSInteger32AttributeType];
	[fileSizeAttribute setOptional:NO];
	[properties addObject:fileSizeAttribute];
	
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
    
	// create main MOC (NOT for main thread!)
	_managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
	_managedObjectContext.parentContext = _writerContext;
    
    // create worker MOC for background operations
    _workerContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    _workerContext.parentContext = _managedObjectContext;
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
		
		[_managedObjectContext performBlock:^{
			NSError *error = nil;
			if (![_managedObjectContext save:&error])
			{
				NSLog(@"Error saving main context: %@", [error localizedDescription]);
				return;
			}
			
			[_writerContext performBlock:^{
				NSError *error = nil;
				if (![_writerContext save:&error])
				{
					NSLog(@"Error saving writer context: %@", [error localizedDescription]);
					return;
				}
			}];
		}];
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
		BOOL needsTrim = (maxNumberOfConcurrentDownloads < _maxNumberOfConcurrentDownloads);
		
		NSAssert(maxNumberOfConcurrentDownloads>0, @"maximum number of concurrent downloads cannot be zero");
		_maxNumberOfConcurrentDownloads = maxNumberOfConcurrentDownloads;

		NSLog(@"Concurrent Downloads set to %d", maxNumberOfConcurrentDownloads);
		
		// starts/stops enough downloads to match the max number
		[self _startNextQueuedDownload];
		
		if (needsTrim)
		{
			[self _cancelDownloadsOverConcurrencyLimit];
		}
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
