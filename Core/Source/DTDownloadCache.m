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

NSString *DTDownloadCacheDidCacheFileNotification = @"DTDownloadCacheDidCacheFile";

@interface DTDownloadCache ()

- (void)_setupCoreDataStack;
- (DTCachedFile *)_cachedFileForURL:(NSURL *)URL inContext:(NSManagedObjectContext *)context;
- (NSUInteger)_currentDiskUsageInContext:(NSManagedObjectContext *)context;
- (void)_commitContext:(NSManagedObjectContext *)context;

@end

@implementation DTDownloadCache
{
	// Core Data Stack
	NSManagedObjectModel *_managedObjectModel;
	NSPersistentStoreCoordinator *_persistentStoreCoordinator;
	NSManagedObjectContext *_managedObjectContext;
	
	// Internals
	NSMutableDictionary *_downloads;
	NSMutableArray *_downloadQueue;
	NSMutableSet *_activeDownloads;
	
	// memory cache for certain types, e.g. images
	NSCache *_memoryCache;
	
	NSUInteger _maxNumberOfConcurrentDownloads;
	NSUInteger _diskCapacity;
	
	// maintenance
	dispatch_queue_t _maintenanceQueue;
	dispatch_queue_t _storeQueue;
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
		_maintenanceQueue = dispatch_queue_create("DTDownloadCache Maintenance", 0);
		_storeQueue = dispatch_queue_create("DTDownloadCache Store", 0);

		[self _setupCoreDataStack];
		
		_downloads = [[NSMutableDictionary alloc] init];
		_downloadQueue = [[NSMutableArray alloc] init];
		_activeDownloads = [[NSMutableSet alloc] init];
		
		_memoryCache = [[NSCache alloc] init];
		
		_maxNumberOfConcurrentDownloads = 5;
		_diskCapacity = 1024*1024*20; // 20 MB
	}
	
	return self;
}

#pragma mark Queue Handling

- (void)_enqueueDownloadForURL:(NSURL *)URL
{
	DTDownload *download = [[DTDownload alloc] initWithURL:URL];
	download.delegate = self;
	
	[_downloads setObject:download forKey:URL];
	[_downloadQueue addObject:download];
}

- (void)_removeDownloadFromQueue:(DTDownload *)download
{
	[_activeDownloads removeObject:download];
	[_downloads removeObjectForKey:download.URL];
	[_downloadQueue removeObject:download];
}

- (void)_startNextQueuedDownload
{
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
}


#pragma mark External Methods


- (NSData *)cachedDataForURL:(NSURL *)URL shouldLoad:(BOOL)shouldLoad
{
	// TODO: make this thread-safe so it can be called from background threads
	if (dispatch_get_current_queue() != dispatch_get_main_queue())
	{
		__block NSData *retData;
		
		dispatch_sync(dispatch_get_main_queue(), ^{
			retData = [self cachedDataForURL:URL shouldLoad:shouldLoad];
		});
		
		return retData;
	}
	
	DTCachedFile *existingCacheEntry = [self _cachedFileForURL:URL inContext:_managedObjectContext];
	
	if (existingCacheEntry)
	{
		existingCacheEntry.lastAccessDate = [NSDate date];
		[self _commitContext:_managedObjectContext];
		
		return existingCacheEntry.fileData;
	}
	
	if (!shouldLoad)
	{
		return nil;
	}
	
	// we don't have a cache entry, need to load
	
	DTDownload *download = [_downloads objectForKey:URL];
	
	if (download)
	{
		// already in queue, give it higher prio
		if (![download isLoading])
		{
			// move it to end of LIFO queue
			[_downloadQueue removeObject:download];
			[_downloadQueue addObject:download];
		}
		
		return nil;
	}
	
	[self _enqueueDownloadForURL:URL];
	[self _startNextQueuedDownload];
	
	return nil;
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
	dispatch_async(_storeQueue, ^{
		// create context for background
		NSManagedObjectContext *tmpContext = [[NSManagedObjectContext alloc] init];
		tmpContext.persistentStoreCoordinator = _persistentStoreCoordinator;
		
		DTCachedFile *cachedFile = (DTCachedFile *)[NSEntityDescription insertNewObjectForEntityForName:@"DTCachedFile" 
																				 inManagedObjectContext:tmpContext];	
		cachedFile.lastAccessDate = [NSDate date];
		cachedFile.expirationDate = [NSDate distantFuture];
		cachedFile.lastModifiedDate = download.lastModifiedDate;
		NSData *data = [NSData dataWithContentsOfMappedFile:path];
		cachedFile.entityTagIdentifier = download.downloadEntityTag;
		cachedFile.fileData = data;
		cachedFile.fileSize = [NSNumber numberWithLongLong:download.totalBytes];
		cachedFile.contentType = download.MIMEType;
		cachedFile.remoteURL = [download.URL absoluteString];
		
		[self _commitContext:tmpContext];
		
		dispatch_sync(dispatch_get_main_queue(), ^{
			[[NSNotificationCenter defaultCenter] postNotificationName:DTDownloadCacheDidCacheFileNotification object:download.URL];
		});
	});
	
	[self _removeDownloadFromQueue:download];
	
	[self _startNextQueuedDownload];
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

	// create MOC
	_managedObjectContext = [[NSManagedObjectContext alloc] init];
	[_managedObjectContext setPersistentStoreCoordinator:_persistentStoreCoordinator];
	
	// subscribe to change notifications
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_mocDidSaveNotification:) name:NSManagedObjectContextDidSaveNotification object:nil];
}

// returned objects can only be used from the same context
- (DTCachedFile *)_cachedFileForURL:(NSURL *)URL inContext:(NSManagedObjectContext *)context
{
	NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"DTCachedFile"];
	
	request.predicate = [NSPredicate predicateWithFormat:@"remoteURL == %@", [URL absoluteString]];
	request.fetchLimit = 1;
	
	NSError *error;
	NSArray *results = [context executeFetchRequest:request error:&error];
	
	if (!results)
	{
		NSLog(@"error occured fetching %@", [error localizedDescription]);
	}
	
	return [results lastObject];
}

- (void)_commitContext:(NSManagedObjectContext *)context
{
	NSError *error;
	
	if (![context save:&error])
	{
		NSLog(@"error occured saving %@", [error localizedDescription]);
	}
}

- (void)_mocDidSaveNotification:(NSNotification *)notification
{
	// ignore change notifications for the main MOC
	
	if (_managedObjectContext == [notification object])
	{
		return;
	}
	
	dispatch_sync(dispatch_get_main_queue(), ^{
		// merge in the changes
		[_managedObjectContext mergeChangesFromContextDidSaveNotification:notification];
		
		// shedule a maintenance run after a couple of seconds
		SEL selector = @selector(_runMaintenance);
		[NSObject cancelPreviousPerformRequestsWithTarget:self selector:selector object:nil];
		[self performSelector:selector withObject:nil afterDelay:10.0f];
	});
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
	
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"DTCachedFile" 
											  inManagedObjectContext:context];
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
	dispatch_async(_maintenanceQueue, ^{
		// create context for background
		NSManagedObjectContext *tmpContext = [[NSManagedObjectContext alloc] init];
		tmpContext.persistentStoreCoordinator = _persistentStoreCoordinator;

		NSUInteger diskUsageBeforeMaintenance = [self _currentDiskUsageInContext:tmpContext];

		// remove all expired files
		[self _removeExpiredFilesInContext:tmpContext];
		
		// prune oldest accessed files so that we get below disk usage limit
		if (diskUsageBeforeMaintenance>_diskCapacity)
		{
			[self _removeFilesOverCapacity:_diskCapacity inContext:tmpContext];
		}
		
		// only commit if there are actually modifications
		if ([tmpContext hasChanges])
		{
			[self _commitContext:tmpContext];
		}
		
		NSUInteger diskUsageAfterMaintenance = [self _currentDiskUsageInContext:tmpContext];
		
		NSLog(@"Running Maintenance, Usage Before: %@, After: %@", [NSString stringByFormattingBytes:diskUsageBeforeMaintenance], [NSString stringByFormattingBytes:diskUsageAfterMaintenance]);
	});
}

#pragma mark Properties

- (void)setMaxNumberOfConcurrentDownloads:(NSUInteger)maxNumberOfConcurrentDownloads
{
	NSAssert(maxNumberOfConcurrentDownloads>0, @"maximum number of concurrent downloads cannot be zero");
	_maxNumberOfConcurrentDownloads = maxNumberOfConcurrentDownloads;
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

- (UIImage *)cachedImageForURL:(NSURL *)URL shouldLoad:(BOOL)shouldLoad
{
	// try memory cache first
	UIImage *cachedImage = [_memoryCache objectForKey:URL];
	
	if (cachedImage)
	{
		return cachedImage;
	}

	// try file cache
	NSData *data = [self cachedDataForURL:URL shouldLoad:shouldLoad];
	
	if (!data)
	{
		return nil;
	}
	
//	// use ImageIO to make sure it stays cached
//	NSDictionary *dict = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES]
//													 forKey:(id)kCGImageSourceShouldCache];
//	
//	CGImageSourceRef source = CGImageSourceCreateWithData((__bridge CFDataRef)data, NULL);
//	CGImageRef cgImage = CGImageSourceCreateImageAtIndex(source, 0, (__bridge CFDictionaryRef)dict);
//	
//	cachedImage = [UIImage imageWithCGImage:cgImage];
//	CGImageRelease(cgImage);
//	CFRelease(source);
	
	cachedImage = [UIImage imageWithData:data];
	
	if (!cachedImage)
	{
		NSLog(@"Illegal Data cached for %@", URL);	
		return nil;
	}
	
	// put in memory cache
	NSUInteger cost = (NSUInteger)(cachedImage.size.width * cachedImage.size.height);
	[_memoryCache setObject:cachedImage forKey:URL cost:cost];
	
	return cachedImage;
}

@end
