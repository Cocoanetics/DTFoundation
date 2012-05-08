//
//  DTCachedFile.h
//  DTFoundation
//
//  Created by Oliver Drobnik on 4/20/12.
//  Copyright (c) 2012 Cocoanetics. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface DTCachedFile : NSManagedObject

@property (nonatomic, retain) NSString *remoteURL;
@property (nonatomic, retain) NSData *fileData;
@property (nonatomic, retain) NSDate *lastAccessDate;
@property (nonatomic, retain) NSDate *lastModifiedDate;
@property (nonatomic, retain) NSDate *expirationDate;
@property (nonatomic, retain) NSString *contentType;
@property (nonatomic, retain) NSNumber *fileSize;
@property (nonatomic, retain) NSString *entityTagIdentifier;

@end
