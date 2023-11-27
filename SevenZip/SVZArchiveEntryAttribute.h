//
//  SVZArchiveEntryAttribute.h
//  SevenZip
//
//  Created by Tamas Lustyik on 2015. 12. 01..
//  Copyright © 2015. Tamas Lustyik. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 * Attribute values used in `SVZArchiveEntry`
 */
typedef NS_OPTIONS(uint32_t, SVZArchiveEntryAttributes) {
    // Windows file attributes
    kSVZArchiveEntryAttributeWinReadOnly = 1 << 0,
    kSVZArchiveEntryAttributeWinHidden = 1 << 1,
    kSVZArchiveEntryAttributeWinSystem = 1 << 2,
    kSVZArchiveEntryAttributeWinVolume = 1 << 3,
    kSVZArchiveEntryAttributeWinDirectory = 1 << 4,
    kSVZArchiveEntryAttributeWinArchive = 1 << 5,
    
    // UNIX permissions (see mode_t)
    kSVZArchiveEntryAttributeUnixUserR = S_IRUSR << 16,
    kSVZArchiveEntryAttributeUnixUserW = S_IWUSR << 16,
    kSVZArchiveEntryAttributeUnixUserX = S_IXUSR << 16,
    kSVZArchiveEntryAttributeUnixGroupR = S_IRGRP << 16,
    kSVZArchiveEntryAttributeUnixGroupW = S_IWGRP << 16,
    kSVZArchiveEntryAttributeUnixGroupX = S_IXGRP << 16,
    kSVZArchiveEntryAttributeUnixOtherR = S_IROTH << 16,
    kSVZArchiveEntryAttributeUnixOtherW = S_IWOTH << 16,
    kSVZArchiveEntryAttributeUnixOtherX = S_IXOTH << 16,
    kSVZArchiveEntryAttributeUnixSUID = S_ISUID << 16,
    kSVZArchiveEntryAttributeUnixSGID = S_ISGID << 16,
    kSVZArchiveEntryAttributeUnixSticky = S_ISVTX << 16,
    
    // UNIX file types (see mode_t)
    kSVZArchiveEntryAttributeUnixNamedPipe = (unsigned)S_IFIFO << 16,
    kSVZArchiveEntryAttributeUnixCharacterDevice = (unsigned)S_IFCHR << 16,
    kSVZArchiveEntryAttributeUnixDirectory = (unsigned)S_IFDIR << 16,
    kSVZArchiveEntryAttributeUnixBlockDevice = (unsigned)S_IFBLK << 16,
    kSVZArchiveEntryAttributeUnixRegularFile = (unsigned)S_IFREG << 16,
    kSVZArchiveEntryAttributeUnixSymlink = (unsigned)S_IFLNK << 16,
    kSVZArchiveEntryAttributeUnixSocket = (unsigned)S_IFSOCK << 16
};
