//
//  SVZArchiveEntry.m
//  SevenZip
//
//  Created by Tamas Lustyik on 2015. 11. 19..
//  Copyright © 2015. Tamas Lustyik. All rights reserved.
//

#import "SVZArchiveEntry.h"
#import "SVZArchiveEntry_Private.h"

static const uint64_t kSVZInvalidSize = ~0;

static const SVZArchiveEntryAttributes kSVZDefaultFileAttributes =
    kSVZArchiveEntryAttributeUnixRegularFile |
    kSVZArchiveEntryAttributeUnixUserR |
    kSVZArchiveEntryAttributeUnixUserW |
    kSVZArchiveEntryAttributeUnixGroupR |
    kSVZArchiveEntryAttributeUnixOtherR;

static const SVZArchiveEntryAttributes kSVZDefaultDirectoryAttributes =
    kSVZArchiveEntryAttributeUnixDirectory |
    kSVZArchiveEntryAttributeUnixUserR |
    kSVZArchiveEntryAttributeUnixUserW |
    kSVZArchiveEntryAttributeUnixUserX |
    kSVZArchiveEntryAttributeUnixGroupR |
    kSVZArchiveEntryAttributeUnixGroupX |
    kSVZArchiveEntryAttributeUnixOtherR |
    kSVZArchiveEntryAttributeUnixOtherX;

SVZStreamBlock SVZStreamBlockCreateWithFileURL(NSURL* aURL) {
    NSCAssert([aURL isFileURL], @"url must point to a local file");
    return ^NSInputStream*(unsigned long long* size, NSError** error) {
        NSNumber* sizeValue = nil;
        if (![aURL getResourceValue:&sizeValue forKey:NSURLFileSizeKey error:error]) {
            return nil;
        }
        
        *size = sizeValue.unsignedLongLongValue;
        return [NSInputStream inputStreamWithURL:aURL];
    };
}

SVZStreamBlock SVZStreamBlockCreateWithData(NSData* aData) {
    NSCParameterAssert(aData);
    return ^NSInputStream*(unsigned long long* size, NSError** error) {
        *size = aData.length;
        return [NSInputStream inputStreamWithData:aData];
    };
}

@implementation SVZArchiveEntry

+ (instancetype)archiveEntryWithFileName:(NSString*)aFileName
                           contentsOfURL:(NSURL*)aURL {
    NSParameterAssert(aURL);

    NSDictionary* attributes = [aURL resourceValuesForKeys:@[NSURLCreationDateKey,
                                                             NSURLContentAccessDateKey,
                                                             NSURLContentModificationDateKey,
                                                             NSURLFileSecurityKey]
                                                     error:NULL];
    if (!attributes) {
        return nil;
    }
    
    NSFileSecurity* fs = attributes[NSURLFileSecurityKey];
    mode_t permissions = 0;
    if (!CFFileSecurityGetMode((__bridge CFFileSecurityRef)fs, &permissions)) {
        return nil;
    }

    return [[self alloc] initWithName:aFileName
                           attributes:(SVZArchiveEntryAttributes)permissions << 16
                         creationDate:attributes[NSURLCreationDateKey]
                     modificationDate:attributes[NSURLContentModificationDateKey]
                           accessDate:attributes[NSURLContentAccessDateKey]
                          streamBlock:SVZStreamBlockCreateWithFileURL(aURL)];
}

+ (instancetype)archiveEntryWithFileName:(NSString*)aFileName
                             streamBlock:(SVZStreamBlock)aStreamBlock {
    NSDate* now = [NSDate date];
    return [[self alloc] initWithName:aFileName
                           attributes:kSVZDefaultFileAttributes
                         creationDate:now
                     modificationDate:now
                           accessDate:now
                          streamBlock:aStreamBlock];
}

+ (instancetype)archiveEntryWithDirectoryName:(NSString*)aDirName {
    NSDate* now = [NSDate date];
    return [[self alloc] initWithName:aDirName
                           attributes:kSVZDefaultDirectoryAttributes
                         creationDate:now
                     modificationDate:now
                           accessDate:now
                          streamBlock:nil];
}

+ (instancetype)archiveEntryWithName:(NSString*)aName
                          attributes:(SVZArchiveEntryAttributes)aAttributes
                        creationDate:(NSDate*)aCTime
                    modificationDate:(NSDate*)aMTime
                          accessDate:(NSDate*)aATime
                         streamBlock:(SVZStreamBlock)aStreamBlock {
    NSDate* now = [NSDate date];
    return [[self alloc] initWithName:aName
                           attributes:aAttributes
                         creationDate:aCTime ?: now
                     modificationDate:aMTime ?: now
                           accessDate:aATime ?: now
                          streamBlock:aStreamBlock];
}

- (instancetype)initWithName:(NSString*)aName
                  attributes:(SVZArchiveEntryAttributes)aAttributes
                creationDate:(NSDate*)aCTime
            modificationDate:(NSDate*)aMTime
                  accessDate:(NSDate*)aATime
                 streamBlock:(SVZStreamBlock)aStreamBlock {
    NSParameterAssert(aName);
    NSParameterAssert(aCTime);
    NSParameterAssert(aMTime);
    NSParameterAssert(aATime);
    
    uint64_t dataSize = 0;
    NSInputStream* dataStream = nil;
    
    if (aStreamBlock) {
        NSError* error = nil;
        dataSize = kSVZInvalidSize;
        dataStream = aStreamBlock(&dataSize, &error);
        NSAssert(dataStream, @"returned stream must not be nil, consider nilling out the block instead");
        NSAssert(dataSize != kSVZInvalidSize, @"size of the streamed data must be provided");
    }

    self = [super init];
    if (self) {
        _name = [aName copy];
        _attributes = aAttributes;
        _creationDate = aCTime;
        _modificationDate = aMTime;
        _accessDate = aATime;
        _uncompressedSize = dataSize;
        _dataStream = dataStream;
    }
    
    return self;
}

- (BOOL)isDirectory {
    return self.attributes & kSVZArchiveEntryAttributeWinDirectory ||
           self.attributes & kSVZArchiveEntryAttributeUnixDirectory;
}

- (mode_t)mode {
    return self.attributes >> 16;
}

- (NSData*)extractedData:(NSError**)aError {
    return [self extractedDataWithPassword:nil error:aError];
}

- (NSData*)extractedDataWithPassword:(NSString*)aPassword
                               error:(NSError**)aError {
    NSOutputStream* memoryStream = [NSOutputStream outputStreamToMemory];
    if (![self extractToStream:memoryStream
                  withPassword:aPassword
                         error:aError]) {
        return nil;
    }
    
    NSData* data = [memoryStream propertyForKey:NSStreamDataWrittenToMemoryStreamKey];
    return data;
}

- (BOOL)extractToDirectoryAtURL:(NSURL*)aDirURL
                          error:(NSError**)aError {
    return [self extractToDirectoryAtURL:aDirURL
                            withPassword:nil
                                   error:aError];
}

- (BOOL)extractToDirectoryAtURL:(NSURL*)aDirURL
                   withPassword:(NSString*)aPassword
                          error:(NSError**)aError {
    NSURL* entryURL = [aDirURL URLByAppendingPathComponent:self.name];
    if (![[[self class] fileManager] createDirectoryAtURL:self.isDirectory? entryURL: entryURL.URLByDeletingLastPathComponent
                              withIntermediateDirectories:YES
                                               attributes:nil
                                                    error:aError]) {
        return NO;
    }
    
    if (self.isDirectory) {
        return YES;
    }
    
    NSOutputStream* fileStream = [NSOutputStream outputStreamWithURL:entryURL append:NO];
    BOOL success = [self extractToStream:fileStream
                            withPassword:aPassword
                                   error:aError];
    if (!success) {
        [[[self class] fileManager] removeItemAtURL:entryURL
                                              error:NULL];
    }
    
    return success;
}

- (BOOL)extractToStream:(NSOutputStream*)aOutputStream
                  error:(NSError**)aError {
    return [self extractToStream:aOutputStream
                    withPassword:nil
                           error:aError];
}

- (BOOL)extractToStream:(NSOutputStream*)aOutputStream
           withPassword:(NSString*)aPassword
                  error:(NSError**)aError {
    return NO;
}

- (NSString*)description {
    return [NSString stringWithFormat:@"<%@:%p> kind:%@ path:%@%@",
            [self class],
            self,
            self.isDirectory? @"DIR": @"FILE",
            self.name,
            self.isDirectory? @"": [NSString stringWithFormat:@" size:%lld", self.uncompressedSize]];
}

#pragma mark - UT helpers:

+ (NSFileManager*)fileManager {
    return [NSFileManager defaultManager];
}

@end
