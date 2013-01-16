//
//  DTDownloadQueue.m
//  DTFoundation
//
//  Created by René Pirringer on 1/8/13.
//  Copyright (c) 2013 Cocoanetics. All rights reserved.
//

#import "DTDownloadQueue.h"
#import "DTDownloadItem.h"

#pragma - DTDownloadTask declaration

@interface DTDownloadTask : NSObject <DTDownloadDelegate>

typedef enum {
	DTDownloadTaskStatusPending = 0,
	DTDownloadTaskStatusRunning,
	DTDownloadTaskStatusDone,
	DTDownloadTaskStatusDuplicate
} DTDownloadTaskStatus;

@property (nonatomic, strong) DTDownloadItem *downloadItem;
@property (nonatomic, strong) DTDownloadQueueCompletionBlock completion;
@property (nonatomic, strong) DTDownloadQueueProgressBlock progress;
@property (nonatomic, assign) DTDownloadTaskStatus status;

@property(nonatomic, strong) DTDownload *download;

- (id)initDownloadItem:(DTDownloadItem *)downloadItem completion:(DTDownloadQueueCompletionBlock)completion progress:(DTDownloadQueueProgressBlock)progress;

- (void)startDownloadWithDelegate:(id <DTDownloadDelegate>)delegate;

- (void)cancelDownload;
@end

#pragma - DTDownloadTask implementation

@interface DTDownloadTask ()

@end

@implementation DTDownloadTask
@synthesize download = _download;


- (id)initDownloadItem:(DTDownloadItem *)downloadItem completion:(DTDownloadQueueCompletionBlock)completion progress:(DTDownloadQueueProgressBlock)progress
{
	self = [super self];
	if (self) {
		self.downloadItem = downloadItem;
		self.completion = completion;
		self.progress = progress;
	}
 return self;
}

- (void)startDownloadWithDelegate:(id <DTDownloadDelegate>)delegate
{
	self.download = [[DTDownload alloc] initWithURL:self.downloadItem.URL withDestinationFile:self.downloadItem.destinationFile];
	self.download.context = self.downloadItem;
	self.download.delegate = delegate;
	dispatch_async(dispatch_get_main_queue(), ^{
		[self.download start];
	});
}

- (void)cancelDownload
{
	[self.download stop];
}

@end


@interface DTDownloadQueue () <DTDownloadDelegate>

@property(nonatomic, strong) NSMutableArray *queue;

@end


@implementation DTDownloadQueue

+ (DTDownloadQueue *)sharedInstance
{
	static dispatch_once_t onceToken;
	static DTDownloadQueue *_sharedInstance;

	dispatch_once(&onceToken, ^{
		_sharedInstance = [[DTDownloadQueue alloc] init];
	});
	return _sharedInstance;
}

- (id)init {
	self = [super init];
	if (self) {
		self.queue = [[NSMutableArray alloc] init];
		self.numberOfParallelDownloads = 1;
	}
	return self;
}

- (void)downloadItem:(DTDownloadItem *)downloadItem completion:(DTDownloadQueueCompletionBlock)completion progress:(DTDownloadQueueProgressBlock)progress {
	// do not download if the file already exists on the file system.
	NSFileManager *fileManager = [NSFileManager defaultManager];
	if ([fileManager fileExistsAtPath:downloadItem.destinationFile]) {
		if (completion) {
			completion(downloadItem, nil);
		}
		return;
	}

	DTDownloadTask *item = [[DTDownloadTask alloc] initDownloadItem:downloadItem completion:completion progress:progress];
	[self addItemToQueue:item];
	[self startNextPendingDownload];
}

- (void)cancelDownloadItem:(DTDownloadItem *)downloadItem {
	@synchronized (self.queue) {
		NSArray *downloadTasks = [self downloadTasksForItem:downloadItem];
		for (DTDownloadTask *task in downloadTasks) {
			[task cancelDownload];
		}
		[self.queue removeObjectsInArray:downloadTasks];
	}
}

- (void)addItemToQueue:(DTDownloadTask *)task
{
	@synchronized (self.queue) {
		for (DTDownloadTask *presentTask in self.queue) {
			if ([presentTask isEqual:task]) {
				task.status = DTDownloadTaskStatusDuplicate;
			}
		}
	}
	[self.queue addObject:task];
}

- (NSInteger)numberOfRunningDownloads {
	@synchronized (self.queue) {
		NSInteger result = 0;
		for (DTDownloadTask *item in self.queue)
		{
			if (item.status == DTDownloadTaskStatusRunning)
			{
				result++;
			}
		}
		return result;
	}
}

- (DTDownloadTask *)nextPendingDownload {
	@synchronized (self.queue) {
		for (DTDownloadTask *item in self.queue)
		{
			if (item.status == DTDownloadTaskStatusPending)
			{
				return item;
			}
		}
		return nil;
	}
}

- (void)startNextPendingDownload
{
	@synchronized (self.queue)
	{
		if ([self.queue count] > 0)
		{
			while ([self numberOfRunningDownloads] < self.numberOfParallelDownloads)
			{

				DTDownloadTask *task = [self nextPendingDownload];
				if (!task) {
					// no more items in queue;
					break;
				}
				task.status = DTDownloadTaskStatusRunning;

				[task startDownloadWithDelegate:self];
				NSLog(@"start download of %@", task.downloadItem.URL);

			}
		}
	}
}


- (NSArray *)downloadTasksForItem:(DTDownloadItem *)downloadItem
{
	NSMutableArray *result = [[NSMutableArray alloc] init];

	for (DTDownloadTask *task in self.queue)
	{
		if ([task.downloadItem isEqual:downloadItem]) {
			[result addObject:task];
		}
	}
	return result;
}

- (void)download:(DTDownload *)download didFailWithError:(NSError *)error
{
	@synchronized (self.queue) {
		NSArray *downloadTasks = [self downloadTasksForItem:download.context];
		[self.queue removeObjectsInArray:downloadTasks];
		for (DTDownloadTask *task in downloadTasks) {
			task.status = DTDownloadTaskStatusDone;
			if (task.completion) {
				task.completion(task.downloadItem, error);
			}
			NSLog(@"FAILED download of %@: %@", task.downloadItem.URL, [error localizedDescription]);
		}
		[self startNextPendingDownload];
	}
}


- (void)download:(DTDownload *)download didFinishWithFile:(NSString *)path
{
	@synchronized (self.queue) {
		NSArray *downloadTasks = [self downloadTasksForItem:download.context];
		[self.queue removeObjectsInArray:downloadTasks];
		for (DTDownloadTask *task in downloadTasks) {
			task.status = DTDownloadTaskStatusDone;
			if (task.completion) {
				task.completion(task.downloadItem, nil);
			}
			NSLog(@"finished download of %@", task.downloadItem.URL);
		}
		[self startNextPendingDownload];
	}
}

- (void)download:(DTDownload *)download downloadedBytes:(long long int)downloadedBytes ofTotalBytes:(long long int)totalBytes withSpeed:(float)speed
{
	@synchronized (self.queue) {
		NSArray *downloadTasks = [self downloadTasksForItem:download.context];
		for (DTDownloadTask *task in downloadTasks) {
			if (task.progress) {
				task.progress(task.downloadItem, downloadedBytes, totalBytes, speed);
			}
		}
		[self startNextPendingDownload];
	}
}

#pragma mark - Properties

@synthesize queue = _queue;

@end