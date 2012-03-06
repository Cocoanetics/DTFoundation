//
//  DTVersionTest.m
//  iCatalog
//
//  Created by Rene Pirringer on 20.07.11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

#import "DTVersionTest.h"
#import "DTVersion.h"

@implementation DTVersionTest

- (void)testCreate
{
	DTVersion *version = [DTVersion versionWithString:@"foobar"];
	STAssertNil(version, @"DTVersion object should not be create of an unsupported string");

	version = [DTVersion versionWithString:@"1.-1"];
	STAssertNil(version, @"DTVersion object should not be create of an unsupported string");

	version = [DTVersion versionWithString:@"1.2.3"];
	STAssertNotNil(version, @"DTVersion object should be create");
	STAssertEquals(1, (int)version.majorVersion, @"version.major is not the correct value %d", version.majorVersion);
	STAssertEquals(2, (int)version.minorVersion, @"version.minor is not the correct value %d", version.minorVersion);
	STAssertEquals(3, (int)version.maintenanceVersion, @"version.maintenance is not the correct value %d", version.maintenanceVersion);

	version = [DTVersion versionWithString:@"2.9999"];
	STAssertNotNil(version, @"DTVersion object should be create");
	STAssertEquals(2, (int)version.majorVersion, @"version.major is not the correct value %d", version.majorVersion);
	STAssertEquals(9999, (int)version.minorVersion, @"version.minor is not the correct value %d", version.minorVersion);
	STAssertEquals(0, (int)version.maintenanceVersion, @"version.maintenance is not the correct value %d", version.maintenanceVersion);

	version = [DTVersion versionWithString:@"1"];
	STAssertNotNil(version, @"DTVersion object should be create");
	STAssertEquals(1, (int)version.majorVersion, @"version.major is not the correct value %d", version.majorVersion);
	STAssertEquals(0, (int)version.minorVersion, @"version.minor is not the correct value %d", version.minorVersion);
	STAssertEquals(0, (int)version.maintenanceVersion, @"version.maintenance is not the correct value %d", version.maintenanceVersion);
}


- (void)testEquals
{
	DTVersion *first = [DTVersion versionWithString:@"1.2.3"];
	DTVersion *second = [DTVersion versionWithString:@"1.2.3"];
	
	STAssertTrue([first isEqualToVersion:second], @"first version is not equal to second, but should");
	STAssertTrue([first isEqual:second], @"first version is not equal to second, but should");

	second = [DTVersion versionWithString:@"1.2"];
	STAssertFalse([first isEqualToVersion:second], @"first version is equal to second, but should not");
	STAssertFalse([first isEqual:second], @"first version is equal to second, but should not");

	
	first = [DTVersion versionWithString:@"1.0.0"];
	second = [DTVersion versionWithString:@"1"];
	STAssertTrue([first isEqualToVersion:second], @"first version is not equal to second, but should");
	STAssertTrue([first isEqual:second], @"first version is not equal to second, but should");

	second = [DTVersion versionWithString:@"1.0"];
	STAssertTrue([first isEqualToVersion:second], @"first version is not equal to second, but should");
	STAssertTrue([first isEqual:second], @"first version is not equal to second, but should");
	
	STAssertTrue([first isEqualToString:@"1.0.0"], @"first version is not equal to second, but should");
	STAssertTrue([first isEqual:@"1.0.0"], @"first version is not equal to second, but should");
	STAssertTrue([first isEqualToString:@"1.0"], @"first version is not equal to second, but should");
	STAssertTrue([first isEqualToString:@"1"], @"first version is not equal to second, but should");

	STAssertFalse([first isEqualToString:@"1.2"], @"first version is equal to second, but should not");
	STAssertFalse([first isEqualToString:@"1.1.1"], @"first version is equal to second, but should not");
	STAssertFalse([first isEqualToString:@"foobar"], @"first version is equal to second, but should not");
	STAssertFalse([first isEqualToString:@"0.0.0"], @"first version is equal to second, but should not");
}


- (void)testCompare
{
	DTVersion *first = [DTVersion versionWithString:@"1.2.3"];
	DTVersion *second = [DTVersion versionWithString:@"1.2.3"];

	STAssertEquals(NSOrderedSame, [first compare:second], @"should be the same");

	second = [DTVersion versionWithString:@"1.2.0"];
	STAssertEquals(NSOrderedDescending, [first compare:second], @"%@ should be larger then %@", first, second);

	second = [DTVersion versionWithString:@"1.2.4"];
	STAssertEquals(NSOrderedAscending, [first compare:second], @"%@ should be smaller then %@", first, second);

	second = [DTVersion versionWithString:@"0.9.9"];
	STAssertEquals(NSOrderedDescending, [first compare:second], @"%@ should be smaller then %@", first, second);


	second = [DTVersion versionWithString:@"0.9.9"];
	STAssertEquals(NSOrderedDescending, [first compare:nil], @"%@ should be smaller then %@", first, second);

}


@end
