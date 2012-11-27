//
//  DTPDFTextBox.h
//  DTFoundation
//
//  Created by Oliver Drobnik on 27.11.12.
//  Copyright (c) 2012 Cocoanetics. All rights reserved.
//

@class DTPDFOperator;

@interface DTPDFTextBox : NSObject

/**
 Appends the operator to the text box
 */
- (void)appendOperator:(DTPDFOperator *)operator;

/**
 The initial position transform
 */
@property (nonatomic, assign) CGAffineTransform transform;

/*
 The reconstructed string of the box
 */
@property (nonatomic, readonly) NSString *string;


- (NSComparisonResult)compareByTransformToOtherBox:(DTPDFTextBox *)otherBox;

@end
