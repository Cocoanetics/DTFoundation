//
//  NSScanner+DTBonjour.h
//  DTFoundation
//
//  Created by Oliver Drobnik on 15.11.12.
//  Copyright (c) 2012 Cocoanetics. All rights reserved.
//

@interface NSScanner (DTBonjour)

- (BOOL)scanBonjourConnectionHeaders:(NSDictionary **)headers;

@end
