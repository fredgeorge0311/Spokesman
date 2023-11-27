//
//  MainCanvasViewController.m
//  Spokesman
//
//  Created by chaitanya venneti on 24/01/16.
//  Copyright © 2016 troomobile. All rights reserved.
//

#import "MainCanvasViewController.h"
#import "AAPLMovieMutator.h"
#import "AAPLMovieTimeline.h"
#import "TimelineCollectionViewItem.h"

#import "AWSCore/AWSCore.h"
#import "AWSS3/AWSS3.h"
#import "AppConstant.h"
//#import "AFNetworking.h"
#import "AWSKinesisRecorder.h"

#import "FMDB.h"

#import "Project.h"
#import "Asset.h"
#import "EDL.h"
#import "AssetItem.h"
#import "ADTile.h"
#import "LibraryItem.h"

#import "ProjectsCellView.h"
#import "ItemSelectionCellView.h"
#import "BFColorPickerPopover.h"
#import "MouseDownTextField.h"

#import <pop/POP.h>
#import "NSColor+Hex.h"
#import "ExportViewController.h"

#import "InviteUserModalController.h"
#import "SearchUserWindowController.h"
#import "CreateArtistController.h"
#import "CreateBrandController.h"
#import "CreateLocationController.h"
#import "CreateProductController.h"
#import "SearchArtistsController.h"
#import "SearchProductsController.h"
#import "CreateSeriesViewController.h"
#import "PopUpController.h"

#import "ctatileview.h"

#import "AVTimecodeReader.h"
#import "AVTimecodeWriter.h"

#import "AnimationSliderViewController.h"

#import "Frame.h"
#import "TileAnimationProperties.h"

/////////////////START MVIDMAKER CODE//////////////////
#import <Cocoa/Cocoa.h>

#import "CGFrameBuffer.h"
#import "AVCustomFrame.h"
#import "AVMvidFileWriter.h"
#import "AVMvidFrameDecoder.h"
#import "SegmentedMappedData.h"

/*ffmpeg*/
#include "libavcodec/avcodec.h"
#include "libavformat/avformat.h"

// private properties declaration for class AVMvidFrameDecoder, used here
// to implete looking directly into the file header.

@interface AVMvidFrameDecoder ()
@property (nonatomic, assign, readonly) void *mvFrames;
@end

#include "maxvid_encode.h"
#include "maxvid_deltas.h"
#import "movdata.h"
#import "MvidFileMetaData.h"

#import "XCDYouTubeKit.h"

CGSize _movieDimensions;
NSString *movie_prefix;
CGFrameBuffer *prevFrameBuffer = nil;

// Define this symbol to create a -test option that can be run from the command line.
#define TESTMODE

// Define to enable mode that will split the RGB+A into RGB and A in two different mvid files
#define SPLITALPHA

// A MovieOptions struct is filled in as the user passes
// specific command line options.

typedef struct
{
    float framerate;
    int   bpp;
    int   keyframe;
    int   deltas;
} MovieOptions;

// BGRA is iOS native pixel format, it is the most optimal format since
// pixels need not be swapped when reading from a file format.

static inline
uint32_t rgba_to_bgra(uint32_t red, uint32_t green, uint32_t blue, uint32_t alpha)
{
    return (alpha << 24) | (red << 16) | (green << 8) | blue;
}

void process_frame_file_write_nodeltas(BOOL isKeyframe,
                                       CGFrameBuffer *cgBuffer,
                                       AVMvidFileWriter *mvidWriter);

#if MV_ENABLE_DELTAS

void process_frame_file_write_deltas(BOOL isKeyframe,
                                     CGFrameBuffer *cgBuffer,
                                     CGFrameBuffer *emptyInitialFrameBuffer,
                                     AVMvidFileWriter *mvidWriter);

#endif // MV_ENABLE_DELTAS

// ------------------------------------------------------------------------
//
// mvidmoviemaker
//
// To convert a .mov to .mvid (Quicktime to optimized .mvid) execute.
//
// mvidmoviemaker movie.mov movie.mvid
//
// The following arguments can be used to create a .mvid video file
// from a series of PNG or other images. The -fps option indicates
// that the framerate is 15 frames per second. By default, the
// system will assume 24bpp "Millions". If input images make use
// of an alpha channel, then 32bpp "Millions+" will be used automatically.
//
// mvidmoviemaker FRAMES/Frame001.png movie.mvid -fps 15
//
// To extract the contents of an .mvid movie to PNG images:
//
// mvidmoviemaker -extract movie.mvid ?FILEPREFIX?"
//
// The optional FILEPREFIX should be specified as "DumpFile" to get
// frames files named "DumpFile0001.png" and "DumpFile0002.png" and so on.
//
//  To see a summary of MVID header info for a specific file.
//
//  mvidmoviemaker -info movie.mvid
// ------------------------------------------------------------------------

static
char *usageArray =
"usage: mvidmoviemaker FIRSTFRAME.png OUTFILE.mvid ?OPTIONS?" "\n"
"or   : mvidmoviemaker -extract FILE.mvid ?FILEPREFIX?" "\n"
"or   : mvidmoviemaker -info movie.mvid" "\n"
"or   : mvidmoviemaker -crop \"X Y WIDTH HEIGHT\" INFILE.mvid OUTFILE.mvid" "\n"
"or   : mvidmoviemaker -resize OPTIONS_RESIZE INFILE.mvid OUTFILE.mvid" "\n"
#if defined(SPLITALPHA)
"or   : mvidmoviemaker -splitalpha FILE.mvid (writes FILE_rgb.mvid and FILE_alpha.mvid)" "\n"
"or   : mvidmoviemaker -joinalpha FILE.mvid (reads FILE_rgb.mvid and FILE_alpha.mvid)" "\n"
"or   : mvidmoviemaker -mixalpha FILE.mvid (writes FILE_mix.mvid)" "\n"
"or   : mvidmoviemaker -unmixalpha FILE.mvid (reads FILE_mix.mvid)" "\n"
"or   : mvidmoviemaker -mixstraight RGB.mvid ALPHA.mvid MIXED.mvid" "\n"
#endif
"options that are less commonly used" "\n"
"or   : mvidmoviemaker -flatten INORIG.mvid FLAT.png" "\n"
"or   : mvidmoviemaker -unflatten INORIG.mvid FLAT.png OUT.mvid" "\n"
"or   : mvidmoviemaker -upgrade FILE.mvid ?OUTFILE.mvid?" "\n"
"or   : mvidmoviemaker -4up INFILE.mvid" "\n"
"or   : mvidmoviemaker -pixels movie.mvid" "\n"
"or   : mvidmoviemaker -extractpixels FILE.mvid ?FILEPREFIX?" "\n"
"or   : mvidmoviemaker -extractcodec FILE.mvid ?FILEPREFIX?" "\n"
"or   : mvidmoviemaker -alphamap FILE.mvid OUTFILE.mvid MAPSPEC" "\n"
"or   : mvidmoviemaker -rdelta INORIG.mvid INMOD.mvid OUTFILE.mvid" "\n"
"or   : mvidmoviemaker -adler movie.mvid" "\n"
"or   : mvidmoviemaker -fps movie.mvid" "\n"
"OPTIONS:\n"
"-fps FLOAT : required when creating .mvid from a series of images\n"
"-framerate FLOAT : alternative way to indicate 1.0/fps\n"
"-bpp INTEGER : 16, 24, or 32 (Thousands, Millions, Millions+)\n"
"-keyframe INTEGER : create a keyframe every N frames, 1 for all keyframes\n"
"-deltas BOOL : 1 or true to enable frame deltas mode\n"
"OPTIONS_RESIZE:\n"
"\"WIDTH HEIGHT\" : pass integer width and height to scale to specific dimensions\n"
"DOUBLE : resize to 2x input width and height with special 4up pixel copy logic\n"
"HALF : resize to 1/2 input width and height\n"
;

#define USAGE (char*)usageArray

// Create a CGImageRef given a filename. Image data is read from the file

CGImageRef createImageFromFile(NSString *filenameStr)
{
    CGImageSourceRef sourceRef;
    CGImageRef imageRef;
    
    if (FALSE) {
        // FIXME : values not the same after read from rgb24 -> rgb555 -> rbg24
        
        // This input PNG was downsampled from a smooth 24BPP gradient
        filenameStr = @"RGBGradient16BPP_SRGB.png";
    }
    
    if (FALSE) {
        filenameStr = @"SunriseFunkyColorspace.jpg";
    }
    
    if (FALSE) {
        filenameStr = @"RGBGradient24BPP_SRGB.png";
    }
    
    if (FALSE) {
        // Device RGB colorspace
        filenameStr = @"TestBlack.png";
    }
    
    if (FALSE) {
        filenameStr = @"TestOpaque.png";
    }
    
    if (FALSE) {
        filenameStr = @"TestAlphaOnOrOff.png";
    }
    
    if (FALSE) {
        filenameStr = @"TestAlpha.png";
    }
    
    if (FALSE) {
        filenameStr = @"Colorbands_sRGB.png";
    }
    
    NSData *image_data = [NSData dataWithContentsOfFile:filenameStr];
    if (image_data == nil) {
        fprintf(stderr, "can't read image data from file \"%s\"\n", [filenameStr UTF8String]);
        exit(1);
    }
    
    // Create image object from src image data.
    
    sourceRef = CGImageSourceCreateWithData((CFDataRef)image_data, NULL);
    
    // Make sure the image source exists before continuing
    
    if (sourceRef == NULL) {
        fprintf(stderr, "can't create image data from file \"%s\"\n", [filenameStr UTF8String]);
        exit(1);
    }
    
    // Create an image from the first item in the image source.
    
    imageRef = CGImageSourceCreateImageAtIndex(sourceRef, 0, NULL);
    
    CFRelease(sourceRef);
    
    return imageRef;
}

// Make a new MVID file writing object in the autorelease pool and configure
// with the indicated framerate, total number of frames, and bpp.

AVMvidFileWriter* makeMVidWriter(
                                 NSString *mvidFilename,
                                 NSUInteger bpp,
                                 NSTimeInterval frameRate,
                                 NSUInteger totalNumFrames
                                 )
{
    AVMvidFileWriter *mvidWriter = [AVMvidFileWriter aVMvidFileWriter];
    //assert(mvidWriter);
    
    mvidWriter.mvidPath = mvidFilename;
    mvidWriter.bpp = bpp;
    // Note that we don't know the movie size until the first frame is read
    
    mvidWriter.frameDuration = frameRate;
    mvidWriter.totalNumFrames = totalNumFrames;
    
    mvidWriter.genAdler = TRUE;
    mvidWriter.genV3 = TRUE;
    
    BOOL worked = [mvidWriter open];
    if (worked == FALSE) {
        fprintf(stderr, "error: Could not open .mvid output file \"%s\"\n", (char*)[mvidFilename UTF8String]);
        exit(1);
    }
    
    return mvidWriter;
}

// This method is invoked with a path that contains the frame
// data and the offset into the frame array that this specific
// frame data is found at. A writer is passed to this method
// to indicate where to write to, unless an initial scan in
// needed and then no write is done.
//
// If the input image is in another colorspace,
// then it will be converted to sRGB. If the RGB data is not
// tagged with a specific colorspace (aka GenericRGB) then
// it is assumed to be sRGB data.
//
// mvidWriter  : Output destination for MVID frame data. If NULL, no output will be written.
// filenameStr : Name of .png file that contains the frame data
// existingImageRef : If NULL, image is loaded from filenameStr instead
// frameIndex  : Frame index (starts at zero)
// mvidFileMetaData : container for info found while scanning/writing
// isKeyframe  : TRUE if this specific frame should be stored as a keyframe (as opposed to a delta frame)
// optionsPtr : command line options settings

int process_frame_file(AVMvidFileWriter *mvidWriter,
                       NSString *filenameStr,
                       CGImageRef existingImageRef,
                       int frameIndex,
                       MvidFileMetaData *mvidFileMetaData,
                       BOOL isKeyframe,
                       MovieOptions *optionsPtr)
{
    // Push pool after creating global resources
    
    //NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    CGImageRef imageRef;
    if (existingImageRef == NULL) {
        imageRef = createImageFromFile(filenameStr);
    } else {
        imageRef = existingImageRef;
        CGImageRetain(imageRef);
    }
    //assert(imageRef);
    
    // General logic is to assume sRGB colorspace since that is what the iOS device assumes.
    //
    // SRGB
    // https://gist.github.com/1130831
    // http://www.mailinglistarchive.com/html/quartz-dev@lists.apple.com/2010-04/msg00076.html
    // http://www.w3.org/Graphics/Color/sRGB.html (see alpha masking topic)
    //
    // Render from input (if it has an ICC profile) into sRGB, this could involve conversions
    // but it makes the results portable and it basically better because it is still as
    // lossless as possible given the constraints. We only deal with sRGB tagged data
    // once this conversion is complete.
    
    CGSize imageSize = CGSizeMake(CGImageGetWidth(imageRef), CGImageGetHeight(imageRef));
    int imageWidth = imageSize.width;
    int imageHeight = imageSize.height;
    
    //assert(imageWidth > 0);
    //assert(imageHeight > 0);
    
    // If this is the first frame, set the movie size based on the size of the first frame
    
    if (frameIndex == 0) {
        if (mvidWriter) {
            mvidWriter.movieSize = imageSize;
        }
        _movieDimensions = imageSize;
    } else if (CGSizeEqualToSize(imageSize, _movieDimensions) == FALSE) {
        // Size of next frame must exactly match the size of the previous one
        
        fprintf(stderr, "error: frame file \"%s\" size %d x %d does not match initial frame size %d x %d\n",
                [filenameStr UTF8String],
                (int)imageSize.width, (int)imageSize.height,
                (int)_movieDimensions.width, (int)_movieDimensions.height);
        exit(2);
    }
    
    // Render input image into a CGFrameBuffer at a specific BPP. If the input buffer actually contains
    // 16bpp pixels expanded to 24bpp, then this render logic will resample down to 16bpp.
    
    int bppNum = mvidFileMetaData.bpp;
    int checkAlphaChannel = mvidFileMetaData.checkAlphaChannel;
    int recordFramePixelValues = mvidFileMetaData.recordFramePixelValues;
    
    if (bppNum == 24 && checkAlphaChannel) {
        bppNum = 32;
    }
    
    int isSizeOkay = maxvid_v3_frame_check_max_size(imageWidth, imageHeight, bppNum);
    if (isSizeOkay != 0) {
        fprintf(stderr, "error: frame size is so large that it cannot be stored in MVID file : %d x %d at %d BPP\n",
                (int)imageWidth, (int)imageHeight, bppNum);
        exit(2);
    }
    
    CGFrameBuffer *cgBuffer = [CGFrameBuffer cGFrameBufferWithBppDimensions:bppNum width:imageWidth height:imageHeight];
    
    // Query the colorspace used in the input image. Note that if no ICC tag was used then we assume sRGB.
    
    CGColorSpaceRef inputColorspace;
    inputColorspace = CGImageGetColorSpace(imageRef);
    // Should default to RGB if nothing is specified
    //assert(inputColorspace);
    
    BOOL inputIsRGBColorspace = FALSE;
    BOOL inputIsSRGBColorspace = FALSE;
    
    {
        CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceRGB();
        
        NSString *colorspaceDescription = (NSString*) CFBridgingRelease(CGColorSpaceCopyName(colorspace));
        NSString *inputColorspaceDescription = (NSString*) CFBridgingRelease(CGColorSpaceCopyName(inputColorspace));
        
        if ([colorspaceDescription isEqualToString:inputColorspaceDescription]) {
            inputIsRGBColorspace = TRUE;
        }
        
        CGColorSpaceRelease(colorspace);
        //[colorspaceDescription release];
        //[inputColorspaceDescription release];
    }
    
    {
        CGColorSpaceRef colorspace = CGColorSpaceCreateWithName(kCGColorSpaceSRGB);
        
        NSString *colorspaceDescription = (NSString*) CFBridgingRelease(CGColorSpaceCopyName(colorspace));
        NSString *inputColorspaceDescription = (NSString*) CFBridgingRelease(CGColorSpaceCopyName(inputColorspace));
        
        if ([colorspaceDescription isEqualToString:inputColorspaceDescription]) {
            inputIsSRGBColorspace = TRUE;
        }
        
        CGColorSpaceRelease(colorspace);
        //[colorspaceDescription release];
        //[inputColorspaceDescription release];
    }
    
    if (inputIsRGBColorspace) {
        //assert(inputIsSRGBColorspace == FALSE);
    }
    if (inputIsSRGBColorspace) {
        //assert(inputIsRGBColorspace == FALSE);
    }
    
    // Output is always going to be "sRGB", so we have a couple of cases.
    //
    // 1. Input is already in sRGB and output is in sRGB, easy
    // 2. Input is in "GenericRGB" colorspace, so assign this same colorspace to the output
    //    buffer so that no colorspace conversion is done in the render step.
    // 3. If we do not detect sRGB or GenericRGB, then some other ICC profile is defined
    //    and we can convert from that colorspace to sRGB.
    
    BOOL outputSRGBColorspace = FALSE;
    BOOL outputRGBColorspace = FALSE;
    
    if (inputIsSRGBColorspace) {
        outputSRGBColorspace = TRUE;
    } else if (inputIsRGBColorspace) {
        outputRGBColorspace = TRUE;
    } else {
        // input is not sRGB and it is not GenericRGB, so convert from this colorspace
        // to the sRGB colorspace during the render operation.
        outputSRGBColorspace = TRUE;
    }
    
    // Use sRGB colorspace when reading input pixels into format that will be written to
    // the .mvid file. This is needed when using a custom color space to avoid problems
    // related to storing the exact original input pixels.
    
    if (outputSRGBColorspace) {
        CGColorSpaceRef colorspace = CGColorSpaceCreateWithName(kCGColorSpaceSRGB);
        cgBuffer.colorspace = colorspace;
        CGColorSpaceRelease(colorspace);
    } else if (outputRGBColorspace) {
        // Weird case where input RGB image was automatically assigned the GenericRGB colorspace,
        // use the same colorspace when rendering so that no colorspace conversion is done.
        cgBuffer.colorspace = inputColorspace;
        
        if (frameIndex == 0 && filenameStr != nil) {
            fprintf(stdout, "treating input pixels as sRGB since image does not define an ICC color profile\n");
        }
    } else {
        //assert(0);
    }
    
    BOOL worked = [cgBuffer renderCGImage:imageRef];
    //assert(worked);
    
    CGImageRelease(imageRef);
    
    if (outputRGBColorspace) {
        // Assign the sRGB colorspace to the framebuffer so that if we write an image
        // file or use the framebuffer in the next loop, we know it is really sRGB.
        
        CGColorSpaceRef colorspace = CGColorSpaceCreateWithName(kCGColorSpaceSRGB);
        cgBuffer.colorspace = colorspace;
        CGColorSpaceRelease(colorspace);
    }
    
    if (bppNum == 24 && (checkAlphaChannel == FALSE)) {
        // In the case where we know that opaque 24 BPP pixels are going to be emitted,
        // rewrite the pixels in the output buffer once the image has been rendered.
        // CoreGraphics will write 0xFF as the alpha value even though we know the
        // alpha value will be ignored due to the bitmap flags.
        
        [cgBuffer rewriteOpaquePixels];
    }
    
    // Debug dump contents of framebuffer to a file
    
    if (FALSE) {
        NSString *dumpFilename = [NSString stringWithFormat:@"WriteDumpFrame%0.4d.png", frameIndex+1];
        
        NSData *pngData = [cgBuffer formatAsPNG];
        
        [pngData writeToFile:dumpFilename atomically:NO];
        
        NSLog(@"wrote %@", dumpFilename);
    }
    
    // Scan the alpha values in the framebuffer to determine if any of the pixels have a non-0xFF alpha channel
    // value. If any pixels are non-opaque then the data needs to be treated as 32BPP.
    
    if ((checkAlphaChannel || recordFramePixelValues) && (prevFrameBuffer.bitsPerPixel != 16)) {
        uint32_t *currentPixels = (uint32_t*)cgBuffer.pixels;
        int width = cgBuffer.width;
        int height = cgBuffer.height;
        int numPixels = (width * height);
        
        BOOL allOpaque = TRUE;
        
        for (int i=0; i < numPixels; i++) {
            uint32_t currentPixel = currentPixels[i];
            
            // ABGR non-opaque pixel detection
            uint8_t alpha = (currentPixel >> 24) & 0xFF;
            if (alpha != 0xFF) {
                allOpaque = FALSE;
                
                if (!recordFramePixelValues) {
                    break;
                }
            }
            
            // Store pixel value in the next available slot
            // in a global hashtable of pixel values mapped
            // to a usage 32 bit integer.
            
            if (recordFramePixelValues) {
                if (prevFrameBuffer.bitsPerPixel == 16) {
                    //assert(0);
                } else {
                    [mvidFileMetaData foundPixel32:currentPixel];
                }
            }
        }
        
        if (allOpaque == FALSE && checkAlphaChannel) {
            mvidFileMetaData.bpp = 32;
            mvidFileMetaData.checkAlphaChannel = FALSE;
        }
    } else if (recordFramePixelValues && (prevFrameBuffer.bitsPerPixel == 16)) {
        uint16_t *currentPixels = (uint16_t*)cgBuffer.pixels;
        int width = cgBuffer.width;
        int height = cgBuffer.height;
        int numPixels = (width * height);
        
        for (int i=0; i < numPixels; i++) {
            uint16_t currentPixel = currentPixels[i];
            [mvidFileMetaData foundPixel16:currentPixel];
        }
    }
    
    // Emit either regular or delta data depending on mode
    
    if (mvidWriter) {
#if MV_ENABLE_DELTAS
        if (optionsPtr &&
            optionsPtr->deltas == 1)
        {
            CGFrameBuffer *emptyInitialFrameBuffer = nil;
            if (frameIndex == 0) {
                emptyInitialFrameBuffer = [CGFrameBuffer cGFrameBufferWithBppDimensions:bppNum width:imageWidth height:imageHeight];
            }
            process_frame_file_write_deltas(isKeyframe, cgBuffer, emptyInitialFrameBuffer, mvidWriter);
        } else
#endif // MV_ENABLE_DELTAS
        {
            process_frame_file_write_nodeltas(isKeyframe, cgBuffer, mvidWriter);
        }
    } // if (mvidWriter)
    
    // cleanup
    
    if (TRUE) {
        if (prevFrameBuffer) {
            //[prevFrameBuffer release];
        }
        prevFrameBuffer = cgBuffer;
        //[prevFrameBuffer retain];
    }
    
    
    // free up resources
    
    //[pool drain];
    
    return 0;
}

// This method implements the "writing" portion of the frame emit logic for the normal case
// where either a keyframe or a delta frame is generated. If pixel deltas are going to be
// calculated then the other write method is invoked.

void process_frame_file_write_nodeltas(BOOL isKeyframe,
                                       CGFrameBuffer *cgBuffer,
                                       AVMvidFileWriter *mvidWriter)
{
    BOOL worked;
    BOOL emitKeyframe = isKeyframe;
    
    uint32_t encodeFlags = 0;
    
    // In the case where we know the frame is a keyframe, then don't bother to run delta calculation
    // logic. In the case of the first frame, there is nothing to compare to anyway. The tricky case
    // is when the delta compare logic finds that all of the pixels have changed or the vast majority
    // of pixels have changed, in this case it is actually less optimal to emit a delta frame as compared
    // to a keyframe.
    
    NSData *encodedDeltaData = nil;
    
    if (isKeyframe == FALSE) {
        // Calculate delta pixels by comparing the previous frame to the current frame.
        // Once we know specific delta pixels, then only those pixels that actually changed
        // can be stored in a delta frame.
        
        //assert(prevFrameBuffer);
        
        //assert(prevFrameBuffer.width == cgBuffer.width);
        //assert(prevFrameBuffer.height == cgBuffer.height);
        //assert(prevFrameBuffer.bitsPerPixel == cgBuffer.bitsPerPixel);
        
        void *prevPixels = (void*)prevFrameBuffer.pixels;
        void *currentPixels = (void*)cgBuffer.pixels;
        int numWords;
        int width = cgBuffer.width;
        int height = cgBuffer.height;
        
        BOOL emitKeyframeAnyway = FALSE;
        
        if (prevFrameBuffer.bitsPerPixel == 16) {
            numWords = cgBuffer.numBytes / sizeof(uint16_t);
            encodedDeltaData = maxvid_encode_generic_delta_pixels16(prevPixels,
                                                                    currentPixels,
                                                                    numWords,
                                                                    width,
                                                                    height,
                                                                    &emitKeyframeAnyway,
                                                                    encodeFlags);
            
        } else {
            numWords = cgBuffer.numBytes / sizeof(uint32_t);
            encodedDeltaData = maxvid_encode_generic_delta_pixels32(prevPixels,
                                                                    currentPixels,
                                                                    numWords,
                                                                    width,
                                                                    height,
                                                                    &emitKeyframeAnyway,
                                                                    encodeFlags);
        }
        
        if (emitKeyframeAnyway) {
            // The delta calculation indicates that all the pixels in the frame changed or
            // so many changed that it would be better to emit a whole keyframe as opposed
            // to a delta frame.
            
            emitKeyframe = TRUE;
        }
    }
    
    
    if (emitKeyframe) {
        // Emit Keyframe
        
        char *buffer = cgBuffer.pixels;
        int numBytesInBuffer = cgBuffer.numBytes;
        
        worked = [mvidWriter writeKeyframe:buffer bufferSize:numBytesInBuffer];
        
        if (worked == FALSE) {
            fprintf(stderr, "cannot write keyframe data to mvid file \"%s\"\n", [mvidWriter.mvidPath UTF8String]);
            exit(1);
        }
    } else {
        // Emit the delta frame
        
        if (encodedDeltaData == nil) {
            // The two frames are pixel identical, this is a no-op delta frame
            
            [mvidWriter writeNopFrame];
            worked = TRUE;
        } else {
            // Convert generic maxvid codes to c4 codes and emit as a data buffer
            
            void *pixelsPtr = (void*)cgBuffer.pixels;
            int inputBufferNumBytes = cgBuffer.numBytes;
            NSUInteger frameBufferNumPixels = cgBuffer.width * cgBuffer.height;
            
            worked = maxvid_write_delta_pixels(mvidWriter,
                                               encodedDeltaData,
                                               pixelsPtr,
                                               inputBufferNumBytes,
                                               frameBufferNumPixels,
                                               encodeFlags);
        }
        
        if (worked == FALSE) {
            fprintf(stderr, "cannot write deltaframe data to mvid file \"%s\"\n", [mvidWriter.mvidPath UTF8String]);
            exit(1);
        }
    }
}

#if MV_ENABLE_DELTAS

// This method implements the "writing" portion of the frame emit logic for case where
// pixel deltas will be generated. Pixel deltas imply that a diff of every frame is needed
// since the delta logic is tied up with the delta logic.

void process_frame_file_write_deltas(BOOL isKeyframe,
                                     CGFrameBuffer *cgBuffer,
                                     CGFrameBuffer *emptyInitialFrameBuffer,
                                     AVMvidFileWriter *mvidWriter)
{
    BOOL worked;
    
    // In the case of the first frame, we need to create a fake "empty" previous frame so that
    // delta logic can generate a diff from all black to the current frame.
    
    if (emptyInitialFrameBuffer) {
        //[emptyInitialFrameBuffer retain];
        prevFrameBuffer = emptyInitialFrameBuffer;
    }
    
    if (mvidWriter.isAllKeyframes) {
        // This type of file contains all deltas, so we know it
        // is not "all feyframes"
        
        mvidWriter.isAllKeyframes = FALSE;
    }
    
#if MV_ENABLE_DELTAS
    // Mark the mvid file as containing all frame deltas and pixel deltas
    mvidWriter.isDeltas = TRUE;
#endif // MV_ENABLE_DELTAS
    
    // Run delta calculation in all cases, a keyframe in the initial frame is basically just the
    // same as a plain delta. Note that all frames are deltas when emitting pixel deltas, no
    // specific support for keyframes exists in this mode since max space savings is the goal.
    // The decoder will implicitly create an all black prev frame also.
    
    NSData *encodedDeltaData = nil;
    
    //assert(prevFrameBuffer);
    
    //assert(prevFrameBuffer.width == cgBuffer.width);
    //assert(prevFrameBuffer.height == cgBuffer.height);
    //assert(prevFrameBuffer.bitsPerPixel == cgBuffer.bitsPerPixel);
    
    void *prevPixels = (void*)prevFrameBuffer.pixels;
    void *currentPixels = (void*)cgBuffer.pixels;
    int numWords;
    int width = cgBuffer.width;
    int height = cgBuffer.height;
    
    // In the case of deltas, set this special flag to indicate that DUP codes
    // should not be generated. Instead, only COPY codes will be emitted. This
    // leads to less code overhead since only SKIP and COPY codes should be
    // emitted.
    
    //uint32_t encodeFlags = 0;
    uint32_t encodeFlags = MaxvidEncodeFlags_NO_DUP;
    
    // Note that we pass NULL as the emitKeyframeAnyway argument to explicitly
    // ignore the case where all the pixels change. We want to emit a delta
    // in the case, not a keyframe.
    
    if (prevFrameBuffer.bitsPerPixel == 16) {
        numWords = cgBuffer.numBytes / sizeof(uint16_t);
        encodedDeltaData = maxvid_encode_generic_delta_pixels16(prevPixels,
                                                                currentPixels,
                                                                numWords,
                                                                width,
                                                                height,
                                                                NULL,
                                                                encodeFlags);
        
    } else {
        numWords = cgBuffer.numBytes / sizeof(uint32_t);
        encodedDeltaData = maxvid_encode_generic_delta_pixels32(prevPixels,
                                                                currentPixels,
                                                                numWords,
                                                                width,
                                                                height,
                                                                NULL,
                                                                encodeFlags);
    }
    
    // Emit the delta frame
    
    if (encodedDeltaData == nil) {
        // The two frames are pixel identical, this is a no-op delta frame
        
        if (emptyInitialFrameBuffer) {
            // Special case handler for first frame that is a nop frame, this basically
            // means that an all black prev frame should be used.
            [mvidWriter writeInitialNopFrame];
        } else {
            [mvidWriter writeNopFrame];
        }
        
        worked = TRUE;
    } else {
        // There is a bunch of tricky logic involved in converting the raw deltas pixels
        // into a set of generic codes that capture all the pixels in the delta. Use
        // the output of the generic delta pixels logic as input to another method that
        // will examine the COPY (and possibly the DUP codes) and transform these
        // COPY codes to COPYD codes which indicate application of a pixel delta.
        
        void *pixelsPtr = (void*)cgBuffer.pixels;
        int inputBufferNumBytes = cgBuffer.numBytes;
        NSUInteger frameBufferNumPixels = cgBuffer.width * cgBuffer.height;
        
        NSMutableData *recodedDeltaData = [NSMutableData data];
        
        uint32_t processAsBPP;
        if (cgBuffer.bitsPerPixel == 16) {
            processAsBPP = 16;
        } else {
            processAsBPP = 32;
        }
        
        // Rewrite pixel values using previous pixel values as opposed to
        // absolute pixel values. This logic will not change the generic
        // codes, it will only modify the pixel values of the COPY and
        // DUP values.
        
        worked = maxvid_deltas_compress(encodedDeltaData,
                                        recodedDeltaData,
                                        pixelsPtr,
                                        inputBufferNumBytes,
                                        frameBufferNumPixels,
                                        processAsBPP);
        
        if (worked == FALSE) {
            fprintf(stderr, "cannot recode delta data to pixel delta\n");
            exit(1);
        }
        
        // Convert generic maxvid codes to c4 codes and emit as a data buffer
        
        worked = maxvid_write_delta_pixels(mvidWriter,
                                           recodedDeltaData,
                                           pixelsPtr,
                                           inputBufferNumBytes,
                                           frameBufferNumPixels,
                                           encodeFlags);
        
        // FIXME: if additional modification is needed then translate the code values
        // of the c4 codes after writing. For example, if there will be more COPY
        // codes than SKIP, then make SKIP 0x0 and make DUP 0x1 so that there will
        // be the maximul number of zero bits in a row. Another possible optimization
        // would be to store the SKIP and number values so that the 1 values are together
        // for the most common small values. This might result in additional compression
        // even though the actual values would be the same
    }
    
    if (worked == FALSE) {
        fprintf(stderr, "cannot write deltaframe data to mvid file \"%s\"\n", [mvidWriter.mvidPath UTF8String]);
        exit(1);
    }
}

#endif // MV_ENABLE_DELTAS

// Extract all the frames of movie data from an archive file into
// files indicated by a path prefix.

typedef enum
{
    EXTRACT_FRAMES_TYPE_PNG = 0,
    EXTRACT_FRAMES_TYPE_PIXELS,
    EXTRACT_FRAMES_TYPE_CODEC
} ExtractFramesType;

void extractFramesFromMvidMain(char *mvidFilename,
                               char *extractFramesPrefix,
                               ExtractFramesType type) {
    BOOL worked;
    
    AVMvidFrameDecoder *frameDecoder = [AVMvidFrameDecoder aVMvidFrameDecoder];
    
    NSString *mvidPath = [NSString stringWithUTF8String:mvidFilename];
    
    worked = [frameDecoder openForReading:mvidPath];
    
    if (worked == FALSE) {
        fprintf(stderr, "error: cannot open mvid filename \"%s\"\n", mvidFilename);
        exit(1);
    }
    
    worked = [frameDecoder allocateDecodeResources];
    //assert(worked);
    
    NSUInteger numFrames = [frameDecoder numFrames];
    //assert(numFrames > 0);
    
    int isV3 = (maxvid_file_version([frameDecoder header]) == MV_FILE_VERSION_THREE);
    
    for (NSUInteger frameIndex = 0; frameIndex < numFrames; frameIndex++) {
        // NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        
        AVCustomFrame *frame = [frameDecoder advanceToFrame:frameIndex];
        //assert(frame);
        
        // Release the NSImage ref inside the frame since we will operate on the CG image directly.
        frame.image = nil;
        
        CGFrameBuffer *cgFrameBuffer = frame.cgFrameBuffer;
        //assert(cgFrameBuffer);
        
        // The frame decoder should have created the frame buffers using the sRGB colorspace.
        
        CGColorSpaceRef sRGBColorspace = CGColorSpaceCreateWithName(kCGColorSpaceSRGB);
        //assert(sRGBColorspace == cgFrameBuffer.colorspace);
        CGColorSpaceRelease(sRGBColorspace);
        
        NSString *outFilename;
        
        if (type == EXTRACT_FRAMES_TYPE_PNG) {
            NSData *pngData = [cgFrameBuffer formatAsPNG];
            //assert(pngData);
            
            outFilename = [NSString stringWithFormat:@"%s%0.4d%s", extractFramesPrefix, frameIndex+1, ".png"];
            
            [pngData writeToFile:outFilename atomically:NO];
        } else if (type == EXTRACT_FRAMES_TYPE_PIXELS) {
            // Write data as "*.pixels" with format {WIDTH HEIGHT PIXEL0 PIXEL1 ...}
            
            outFilename = [NSString stringWithFormat:@"%s%0.4d%s", extractFramesPrefix, frameIndex+1, ".pixels"];
            
            FILE *outfd = fopen((char*)[outFilename UTF8String], "wb");
            //assert(outfd);
            
            uint32_t width = (uint32_t)cgFrameBuffer.width;
            uint32_t height = (uint32_t)cgFrameBuffer.height;
            
            int result;
            
            result = (int)fwrite(&width, sizeof(uint32_t), 1, outfd);
            //assert(result == 1);
            result = (int)fwrite(&height, sizeof(uint32_t), 1, outfd);
            //assert(result == 1);
            
            uint32_t size = sizeof(uint32_t);
            if (cgFrameBuffer.bitsPerPixel == 16) {
                size = sizeof(uint16_t);
            }
            
            result = (int)fwrite(cgFrameBuffer.pixels, size * width * height, 1, outfd);
            //assert(result == 1);
            
            fclose(outfd);
        } else if (type == EXTRACT_FRAMES_TYPE_CODEC && !isV3) {
            // Read the frame data encoded with codec specific word values.
            // Format: {WIDTH HEIGHT IS_DELTA WORD0 WORD1 ...}
            
            MVFrame *frame = maxvid_file_frame(frameDecoder.mvFrames, frameIndex);
            //assert(frame);
            
            outFilename = [NSString stringWithFormat:@"%s%0.4d%s", extractFramesPrefix, frameIndex+1, ".codec"];
            
            FILE *outfd = fopen((char*)[outFilename UTF8String], "wb");
            //assert(outfd);
            
            uint32_t width = (uint32_t)cgFrameBuffer.width;
            uint32_t height = (uint32_t)cgFrameBuffer.height;
            
            if (maxvid_frame_isnopframe(frame)) {
                // A nop frame is the same as the previous one, write a zero length file.
            } else {
                // Write: WIDTH HEIGHT
                
                int result;
                
                result = (int)fwrite(&width, sizeof(uint32_t), 1, outfd);
                //assert(result == 1);
                result = (int)fwrite(&height, sizeof(uint32_t), 1, outfd);
                //assert(result == 1);
                
                // Write: IS_DELTA
                
                uint32_t is_delta = 1;
                if (maxvid_frame_iskeyframe(frame)) {
                    is_delta = 0;
                }
                
                result = (int)fwrite(&is_delta, sizeof(uint32_t), 1, outfd);
                //assert(result == 1);
                
                // Write: WORDS
                
                // The memory is already mapped, so just get the pointer to
                // the front of the frame data and the length.
                
                uint32_t offset = maxvid_frame_offset(frame);
                uint32_t length = maxvid_frame_length(frame);
                
                uint32_t *frameDataPtr = (uint32_t*) (frameDecoder.mappedData.bytes + offset);
                
                result = (int)fwrite(frameDataPtr, length, 1, outfd);
                //assert(result == 1);
            }
            
            fclose(outfd);
        } else if (type == EXTRACT_FRAMES_TYPE_CODEC && isV3) {
            // Read the frame data encoded with codec specific word values.
            // Format: {WIDTH HEIGHT IS_DELTA WORD0 WORD1 ...}
            
            MVV3Frame *frame = maxvid_v3_file_frame(frameDecoder.mvFrames, frameIndex);
            //assert(frame);
            
            outFilename = [NSString stringWithFormat:@"%s%0.4d%s", extractFramesPrefix, frameIndex+1, ".codec"];
            
            FILE *outfd = fopen((char*)[outFilename UTF8String], "wb");
            //assert(outfd);
            
            uint32_t width = (uint32_t)cgFrameBuffer.width;
            uint32_t height = (uint32_t)cgFrameBuffer.height;
            
            if (maxvid_v3_frame_isnopframe(frame)) {
                // A nop frame is the same as the previous one, write a zero length file.
            } else {
                // Write: WIDTH HEIGHT
                
                int result;
                
                result = (int)fwrite(&width, sizeof(uint32_t), 1, outfd);
                //assert(result == 1);
                result = (int)fwrite(&height, sizeof(uint32_t), 1, outfd);
                //assert(result == 1);
                
                // Write: IS_DELTA
                
                uint32_t is_delta = 1;
                if (maxvid_v3_frame_iskeyframe(frame)) {
                    is_delta = 0;
                }
                
                result = (int)fwrite(&is_delta, sizeof(uint32_t), 1, outfd);
                //assert(result == 1);
                
                // Write: WORDS
                
                // The memory is already mapped, so just get the pointer to
                // the front of the frame data and the length.
                
                uint64_t offset = maxvid_v3_frame_offset(frame);
                uint32_t length = maxvid_v3_frame_length(frame);
                
                uint32_t *frameDataPtr = (uint32_t*) (frameDecoder.mappedData.bytes + offset);
                
                result = (int)fwrite(frameDataPtr, length, 1, outfd);
                //assert(result == 1);
            }
            
            fclose(outfd);
        } else {
            //assert(0);
        }
        
        NSString *dupString = @"";
        if (frame.isDuplicate) {
            dupString = @" (duplicate)";
        }
        
        fprintf(stdout, "wrote %s%s\n", [outFilename UTF8String], [dupString UTF8String]);
        
        //[pool drain];
    }
    
    [frameDecoder close];
    
    return;
}

// Return TRUE if file exists, FALSE otherwise

BOOL fileExists(NSString *filePath) {
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        return TRUE;
    } else {
        return FALSE;
    }
}

// Entry point for logic that encodes a .mvid from a series of frames.

void encodeMvidFromFramesMain(char *mvidFilenameCstr,
                              char *firstFilenameCstr,
                              MovieOptions *optionsPtr)
{
    NSString *mvidFilename = [NSString stringWithUTF8String:mvidFilenameCstr];
    
    BOOL isMvid = [mvidFilename hasSuffix:@".mvid"];
    
    if (isMvid == FALSE) {
        fprintf(stderr, "%s", USAGE);
        exit(1);
    }
    
    // Given the first frame image filename, build and array of filenames
    // by checking to see if files exist up until we find one that does not.
    // This makes it possible to pass the 25th frame ofa 50 frame animation
    // and generate an animation 25 frames in duration.
    
    NSString *firstFilename = [NSString stringWithUTF8String:firstFilenameCstr];
    
    if (fileExists(firstFilename) == FALSE) {
        fprintf(stderr, "error: first filename \"%s\" does not exist\n", firstFilenameCstr);
        exit(1);
    }
    
    NSString *firstFilenameExt = [firstFilename pathExtension];
    
    // Find first numerical character in the [0-9] range starting at the end of the filename string.
    // A frame filename like "Frame0001.png" would be an example input. Note that the last frame
    // number must be the last character before the extension.
    
    NSArray *upToLastPathComponent = [firstFilename pathComponents];
    NSRange upToLastPathComponentRange;
    upToLastPathComponentRange.location = 0;
    upToLastPathComponentRange.length = [upToLastPathComponent count] - 1;
    upToLastPathComponent = [upToLastPathComponent subarrayWithRange:upToLastPathComponentRange];
    NSString *upToLastPathComponentPath = [NSString pathWithComponents:upToLastPathComponent];
    
    NSString *firstFilenameTail = [firstFilename lastPathComponent];
    NSString *firstFilenameTailNoExtension = [firstFilenameTail stringByDeletingPathExtension];
    
    int numericStartIndex = -1;
    BOOL foundNonAlpha = FALSE;
    
    for (int i = [firstFilenameTailNoExtension length] - 1; i > 0; i--) {
        unichar c = [firstFilenameTailNoExtension characterAtIndex:i];
        if ((c >= '0') && (c <= '9') && (foundNonAlpha == FALSE)) {
            numericStartIndex = i;
        } else {
            foundNonAlpha = TRUE;
        }
    }
    if (numericStartIndex == -1 || numericStartIndex == 0) {
        fprintf(stderr, "error: could not find frame number in first filename \"%s\"\n", firstFilenameCstr);
        exit(1);
    }
    
    // Extract the numeric portion of the first frame filename
    
    NSString *namePortion = [firstFilenameTailNoExtension substringToIndex:numericStartIndex];
    NSString *numberPortion = [firstFilenameTailNoExtension substringFromIndex:numericStartIndex];
    
    if ([namePortion length] < 1 || [numberPortion length] == 0) {
        fprintf(stderr, "error: could not find frame number in first filename \"%s\"\n", firstFilenameCstr);
        exit(1);
    }
    
    // Convert number with leading zeros to a simple integer
    
    NSMutableArray *inFramePaths = [NSMutableArray arrayWithCapacity:1024];
    
    int formatWidth = [numberPortion length];
    int startingFrameNumber = [numberPortion intValue];
    int endingFrameNumber = -1;
    
#define CRAZY_MAX_FRAMES 9999999
#define CRAZY_MAX_DIGITS 7
    
    // Note that we include the first frame in this loop just so that it gets added to inFramePaths.
    
    for (int i = startingFrameNumber; i < CRAZY_MAX_FRAMES; i++) {
        //NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        
        NSMutableString *frameNumberWithLeadingZeros = [NSMutableString string];
        [frameNumberWithLeadingZeros appendFormat:@"%07d", i];
        if ([frameNumberWithLeadingZeros length] > formatWidth) {
            int numToDelete = [frameNumberWithLeadingZeros length] - formatWidth;
            NSRange delRange;
            delRange.location = 0;
            delRange.length = numToDelete;
            [frameNumberWithLeadingZeros deleteCharactersInRange:delRange];
            //assert([frameNumberWithLeadingZeros length] == formatWidth);
        }
        [frameNumberWithLeadingZeros appendString:@"."];
        [frameNumberWithLeadingZeros appendString:firstFilenameExt];
        [frameNumberWithLeadingZeros insertString:namePortion atIndex:0];
        NSString *framePathWithNumber = [upToLastPathComponentPath stringByAppendingPathComponent:frameNumberWithLeadingZeros];
        
        if (fileExists(framePathWithNumber)) {
            // Found frame at indicated path, add it to array of known frame filenames
            
            [inFramePaths addObject:framePathWithNumber];
            endingFrameNumber = i;
        } else {
            // Frame filename with indicated frame number not found, done scanning for frame files
            //[pool drain];
            break;
        }
        
        //[pool drain];
    }
    
    if ([inFramePaths count] <= 1) {
        fprintf(stderr, "error: at least 2 input frames are required\n");
        exit(1);
    }
    
    if ((startingFrameNumber == endingFrameNumber) || (endingFrameNumber == CRAZY_MAX_FRAMES-1)) {
        fprintf(stderr, "error: could not find last frame number\n");
        exit(1);
    }
    
    // FRAMERATE is a floating point number that indicates the delay between frames.
    // This framerate value is a constant that does not change over the course of the
    // movie, though it is possible that a certain frame could repeat a number of times.
    
    float framerateNum = optionsPtr->framerate;
    
    if (framerateNum <= 0.0f) {
        fprintf(stderr, "error: -framerate or -fps is required\n");
        exit(1);
    }
    
    // KEYFRAME : integer that indicates a keyframe should be emitted every N frames
    
    int keyframeNum = optionsPtr->keyframe;
    if (keyframeNum == 0 || keyframeNum == 1) {
        // All frames as stored as keyframes. This takes up more space but the frames can
        // be blitted into graphics memory directly from mapped memory at runtime.
        keyframeNum = 0;
    } else if (keyframeNum < 0) {
        // Just revert to the default
        keyframeNum = 10000;
    }
    
    // BITSPERPIXEL : 16, 24, or 32 BPP.
    //
    // Determine the BPP that the output movie will be written as, when reading from image
    // files 16BPP input data would automatically be converted to 24BPP before the data
    // could be read, so this logic only needs to determine the setting for the check alpha
    // logic.
    
    BOOL checkAlphaChannel;
    int renderAtBpp;
    
    if (optionsPtr->bpp == -1) {
        // No -bpp option given on the command line, detect either 24BPP or 32BPP depending
        // on the pixel data read from the image frames.
        
        renderAtBpp = 24;
        checkAlphaChannel = TRUE;
    } else {
        // When -bpp is explicitly set on the command line, checkAlphaChannel is always FALSE
        checkAlphaChannel = FALSE;
        
        if (optionsPtr->bpp == 16) {
            renderAtBpp = 16;
        } else if (optionsPtr->bpp == 24) {
            renderAtBpp = 24;
        } else {
            renderAtBpp = 32;
        }
    }
    
    // Stage 1: scan all the pixels in all the frames to figure out key info like the BPP
    // of output pixels. We cannot know certain key info about the input data until it
    // has all been scanned.
    
    MvidFileMetaData *mvidFileMetaData = [MvidFileMetaData mvidFileMetaData];
    mvidFileMetaData.bpp = renderAtBpp;
    mvidFileMetaData.checkAlphaChannel = checkAlphaChannel;
    //mvidFileMetaData.recordFramePixelValues = TRUE;
    
    int frameIndex;
    
    frameIndex = 0;
    for (NSString *framePath in inFramePaths) {
        //fprintf(stdout, "saved %s as frame %d\n", [framePath UTF8String], frameIndex+1);
        //fflush(stdout);
        
        BOOL isKeyframe = FALSE;
        if (frameIndex == 0) {
            isKeyframe = TRUE;
        }
        if (keyframeNum == 0) {
            // All frames are key frames
            isKeyframe = TRUE;
        } else if ((keyframeNum > 0) && ((frameIndex % keyframeNum) == 0)) {
            // Keyframe every N frames
            isKeyframe = TRUE;
        }
        
        process_frame_file(NULL, framePath, NULL, frameIndex, mvidFileMetaData, isKeyframe, optionsPtr);
        frameIndex++;
    }
    
    // Stage 2: once scanning all the input pixels is completed, we can loop over all the frames
    // again but this time we actually write the output at the correct BPP. The scan step takes
    // extra time, but it means that we do not need to write twice in the common case where
    // input is all 24 BPP pixels, so this logic is a win.
    
    if (mvidFileMetaData.recordFramePixelValues) {
        [mvidFileMetaData doneRecordingFramePixelValues];
    }
    
    renderAtBpp = mvidFileMetaData.bpp;
    mvidFileMetaData.checkAlphaChannel = FALSE;
    
    AVMvidFileWriter *mvidWriter;
    mvidWriter = makeMVidWriter(mvidFilename, renderAtBpp, framerateNum, [inFramePaths count]);
    
    fprintf(stdout, "writing %d frames to %s\n", [inFramePaths count], [[mvidFilename lastPathComponent] UTF8String]);
    fflush(stdout);
    
    // We now know the start and end integer values of the frame filename range.
    
    frameIndex = 0;
    for (NSString *framePath in inFramePaths) {
        //fprintf(stdout, "saved %s as frame %d\n", [framePath UTF8String], frameIndex+1);
        //fflush(stdout);
        
        BOOL isKeyframe = FALSE;
        if (frameIndex == 0) {
            isKeyframe = TRUE;
        }
        if (keyframeNum == 0) {
            // All frames are key frames
            isKeyframe = TRUE;
        } else if ((keyframeNum > 0) && ((frameIndex % keyframeNum) == 0)) {
            // Keyframe every N frames
            isKeyframe = TRUE;
        }
        
        process_frame_file(mvidWriter, framePath, NULL, frameIndex, mvidFileMetaData, isKeyframe, optionsPtr);
        frameIndex++;
    }
    
    // Done writing .mvid file
    
    [mvidWriter rewriteHeader];
    
    [mvidWriter close];
    
    fprintf(stdout, "done writing %d frames to %s\n", frameIndex, mvidFilenameCstr);
    fflush(stdout);
    
    // cleanup
    /*
     if (prevFrameBuffer) {
     [prevFrameBuffer release];
     }*/
}

void fprintStdoutFixedWidth(char *label)
{
    fprintf(stdout, "%-20s", label);
}

// Entry point for movie info printing logic. This will print the headers of the file
// and some encoding info.

void printMovieHeaderInfo(char *mvidFilenameCstr) {
    NSString *mvidFilename = [NSString stringWithUTF8String:mvidFilenameCstr];
    
    AVMvidFrameDecoder *frameDecoder = [AVMvidFrameDecoder aVMvidFrameDecoder];
    
    BOOL worked = [frameDecoder openForReading:mvidFilename];
    
    if (worked == FALSE) {
        fprintf(stderr, "error: cannot open mvid filename \"%s\"\n", mvidFilenameCstr);
        exit(1);
    }
    
    //worked = [frameDecoder allocateDecodeResources];
    ////assert(worked);
    
    NSUInteger numFrames = [frameDecoder numFrames];
    //assert(numFrames > 0);
    
    float frameDuration = [frameDecoder frameDuration];
    float movieDuration = frameDuration * numFrames;
    
    int bpp = [frameDecoder header]->bpp;
    
    // Format left side in fixed 20 space width
    
    fprintStdoutFixedWidth("MVID:");
    fprintf(stdout, "%s\n", [[mvidFilename lastPathComponent] UTF8String]);
    
    fprintStdoutFixedWidth("Version:");
    int version = maxvid_file_version([frameDecoder header]);
    fprintf(stdout, "%d\n", version);
    
    fprintStdoutFixedWidth("Width:");
    fprintf(stdout, "%d\n", [frameDecoder width]);
    
    fprintStdoutFixedWidth("Height:");
    fprintf(stdout, "%d\n", [frameDecoder height]);
    
    fprintStdoutFixedWidth("BitsPerPixel:");
    fprintf(stdout, "%d\n", bpp);
    
    // Note that pixels stored in .mvid file are always in the sRGB colorspace.
    // If any conversions are needed to convert from some other colorspace, they
    // would need to have been executed when writing the .mvid file.
    
    fprintStdoutFixedWidth("ColorSpace:");
    if (TRUE) {
        fprintf(stdout, "%s\n", "sRGB");
    } else {
        fprintf(stdout, "%s\n", "RGB");
    }
    
    fprintStdoutFixedWidth("Duration:");
    fprintf(stdout, "%.4fs\n", movieDuration);
    
    fprintStdoutFixedWidth("FrameDuration:");
    fprintf(stdout, "%.4fs\n", frameDuration);
    
    fprintStdoutFixedWidth("FPS:");
    fprintf(stdout, "%.4f\n", (1.0f / frameDuration));
    
    fprintStdoutFixedWidth("Frames:");
    fprintf(stdout, "%d\n", numFrames);
    
    // If the "all keyframes" bit is set then print TRUE for this element
    
    fprintStdoutFixedWidth("AllKeyFrames:");
    fprintf(stdout, "%s\n", [frameDecoder isAllKeyframes] ? "TRUE" : "FALSE");
    
#if MV_ENABLE_DELTAS
    
    // If the "deltas" bit is set, then print TRUE to indicate that all
    // pixel values are deltas and all frames are deltas.
    
    fprintStdoutFixedWidth("Deltas:");
    fprintf(stdout, "%s\n", [frameDecoder isDeltas] ? "TRUE" : "FALSE");
    
#endif // MV_ENABLE_DELTAS
    
    [frameDecoder close];
}

// testmode() runs a series of basic test logic having to do with rendering
// and then checking the results of a graphics render operation.

#if defined(TESTMODE)

static inline
NSString* bgra_to_string(uint32_t pixel) {
    uint8_t alpha = (pixel >> 24) & 0xFF;
    uint8_t red = (pixel >> 16) & 0xFF;
    uint8_t green = (pixel >> 8) & 0xFF;
    uint8_t blue = (pixel >> 0) & 0xFF;
    return [NSString stringWithFormat:@"(%d, %d, %d, %d)", red, green, blue, alpha];
}

void testmode()
{
    // Create a framebuffer that contains a 75% gray color in 16bpp and device RGB
    
    @autoreleasepool
    {
        int bppNum = 16;
        int width = 2;
        int height = 2;
        
        CGFrameBuffer *cgBuffer = [CGFrameBuffer cGFrameBufferWithBppDimensions:bppNum width:width height:height];
        
        uint16_t *pixels = (uint16_t *)cgBuffer.pixels;
        int numPixels = width * height;
        
        uint32_t grayLevel = (int) (0x1F * 0.75);
        uint16_t grayPixel = (grayLevel << 10) | (grayLevel << 5) | grayLevel;
        
        for (int i=0; i < numPixels; i++) {
            pixels[i] = grayPixel;
        }
        
        // Create image from test data
        
        CGImageRef imageRef = [cgBuffer createCGImageRef];
        
        // Render test image into a new CGFrameBuffer and then verify that the pixel value is the same
        
        CGFrameBuffer *renderBuffer = [CGFrameBuffer cGFrameBufferWithBppDimensions:bppNum width:width height:height];
        
        [renderBuffer renderCGImage:imageRef];
        
        uint16_t *renderPixels = (uint16_t *)renderBuffer.pixels;
        
        for (int i=0; i < numPixels; i++) {
            uint16_t pixel = renderPixels[i];
            //assert(pixel == grayPixel);
        }
    }
    
    // Create a framebuffer that contains a 75% gray color in 24bpp and device RGB
    
    @autoreleasepool
    {
        int bppNum = 24;
        int width = 2;
        int height = 2;
        
        CGFrameBuffer *cgBuffer = [CGFrameBuffer cGFrameBufferWithBppDimensions:bppNum width:width height:height];
        
        uint32_t *pixels = (uint32_t *)cgBuffer.pixels;
        //int numBytes = cgBuffer.numBytes;
        int numPixels = width * height;
        int numBytes = numPixels * sizeof(uint32_t);
        
        uint32_t grayLevel = (int) (255 * 0.75);
        uint32_t grayPixel = rgba_to_bgra(grayLevel, grayLevel, grayLevel, 0xFF);
        
        for (int i=0; i < numPixels; i++) {
            pixels[i] = grayPixel;
        }
        
        // calculate alder
        
        uint32_t adler1 = maxvid_adler32(0L, (unsigned char *)pixels, numBytes);
        //assert(adler1 != 0);
        
        // Create image from test data
        
        CGImageRef imageRef = [cgBuffer createCGImageRef];
        
        // Render test image into a new CGFrameBuffer and then verify that the pixel value is the same
        
        CGFrameBuffer *renderBuffer = [CGFrameBuffer cGFrameBufferWithBppDimensions:bppNum width:width height:height];
        
        [renderBuffer renderCGImage:imageRef];
        
        uint32_t *renderPixels = (uint32_t *)renderBuffer.pixels;
        
        for (int i=0; i < numPixels; i++) {
            uint32_t pixel = renderPixels[i];
            //assert(pixel == grayPixel);
        }
        
        uint32_t adler2 = maxvid_adler32(0L, (unsigned char *)renderPixels, numBytes);
        //assert(adler2 != 0);
        
        //assert(adler1 == adler2);
    }
    
    // Create a framebuffer that contains a 75% gray color with alpha 0xFF in 32bpp and device RGB
    
    @autoreleasepool
    {
        int bppNum = 32;
        int width = 2;
        int height = 2;
        
        CGFrameBuffer *cgBuffer = [CGFrameBuffer cGFrameBufferWithBppDimensions:bppNum width:width height:height];
        
        uint32_t *pixels = (uint32_t *)cgBuffer.pixels;
        //int numBytes = cgBuffer.numBytes;
        int numPixels = width * height;
        //int numBytes = numPixels * sizeof(uint32_t);
        
        uint32_t grayLevel = (int) (255 * 0.75);
        uint32_t grayPixel = rgba_to_bgra(grayLevel, grayLevel, grayLevel, 0xFF);
        
        for (int i=0; i < numPixels; i++) {
            pixels[i] = grayPixel;
        }
        
        // Create image from test data
        
        CGImageRef imageRef = [cgBuffer createCGImageRef];
        
        // Render test image into a new CGFrameBuffer and then verify that the pixel value is the same
        
        CGFrameBuffer *renderBuffer = [CGFrameBuffer cGFrameBufferWithBppDimensions:bppNum width:width height:height];
        
        [renderBuffer renderCGImage:imageRef];
        
        uint32_t *renderPixels = (uint32_t *)renderBuffer.pixels;
        
        for (int i=0; i < numPixels; i++) {
            uint32_t pixel = renderPixels[i];
            //assert(pixel == grayPixel);
        }
    }
    
    // Create a framebuffer that contains a 75% gray color with alpha 0.5 in 32bpp and device RGB
    
    @autoreleasepool
    {
        int bppNum = 32;
        int width = 2;
        int height = 2;
        
        CGFrameBuffer *cgBuffer = [CGFrameBuffer cGFrameBufferWithBppDimensions:bppNum width:width height:height];
        
        uint32_t *pixels = (uint32_t *)cgBuffer.pixels;
        //int numBytes = cgBuffer.numBytes;
        int numPixels = width * height;
        //int numBytes = numPixels * sizeof(uint32_t);
        
        uint32_t grayLevel = (int) (255 * 0.75);
        uint32_t grayPixel = rgba_to_bgra(grayLevel, grayLevel, grayLevel, 0xFF/2);
        
        for (int i=0; i < numPixels; i++) {
            pixels[i] = grayPixel;
        }
        
        // Create image from test data
        
        CGImageRef imageRef = [cgBuffer createCGImageRef];
        
        // Render test image into a new CGFrameBuffer and then verify that the pixel value is the same
        
        CGFrameBuffer *renderBuffer = [CGFrameBuffer cGFrameBufferWithBppDimensions:bppNum width:width height:height];
        
        [renderBuffer renderCGImage:imageRef];
        
        uint32_t *renderPixels = (uint32_t *)renderBuffer.pixels;
        
        for (int i=0; i < numPixels; i++) {
            uint32_t pixel = renderPixels[i];
            //assert(pixel == grayPixel);
        }
    }
    
    // Create a framebuffer that contains all device RGB pixel values at 24 bpp
    
    @autoreleasepool
    {
        int bppNum = 24;
        int width = 256;
        int height = 3;
        
        CGFrameBuffer *cgBuffer = [CGFrameBuffer cGFrameBufferWithBppDimensions:bppNum width:width height:height];
        
        uint32_t *pixels = (uint32_t *)cgBuffer.pixels;
        //int numPixels = width * height;
        
        int offset = 0;
        
        for (int step=0; step < 256; step++) {
            uint32_t redPixel = rgba_to_bgra(step, 0, 0, 0xFF);
            pixels[offset++] = redPixel;
        }
        
        for (int step=0; step < 256; step++) {
            uint32_t greenPixel = rgba_to_bgra(0, step, 0, 0xFF);
            pixels[offset++] = greenPixel;
        }
        
        for (int step=0; step < 256; step++) {
            uint32_t bluePixel = rgba_to_bgra(0, 0, step, 0xFF);
            pixels[offset++] = bluePixel;
        }
        
        //assert(offset == (256 * 3));
        
        // Create image from test data
        
        CGImageRef imageRef = [cgBuffer createCGImageRef];
        
        // Render test image into a new CGFrameBuffer and then verify that the pixel value is the same
        
        CGFrameBuffer *renderBuffer = [CGFrameBuffer cGFrameBufferWithBppDimensions:bppNum width:width height:height];
        
        [renderBuffer renderCGImage:imageRef];
        
        uint32_t *renderPixels = (uint32_t *)renderBuffer.pixels;
        
        offset = 0;
        
        for (int step=0; step < 256; step++) {
            uint32_t redPixel = rgba_to_bgra(step, 0, 0, 0xFF);
            uint32_t pixel = renderPixels[offset++];
            //assert(pixel == redPixel);
        }
        
        for (int step=0; step < 256; step++) {
            uint32_t greenPixel = rgba_to_bgra(0, step, 0, 0xFF);
            uint32_t pixel = renderPixels[offset++];
            //assert(pixel == greenPixel);
        }
        
        for (int step=0; step < 256; step++) {
            uint32_t bluePixel = rgba_to_bgra(0, 0, step, 0xFF);
            uint32_t pixel = renderPixels[offset++];
            //assert(pixel == bluePixel);
        }
        
        //assert(offset == (256 * 3));
    }
    
    // Create a framebuffer that contains all sRGB pixel values at 24 bpp
    
    @autoreleasepool
    {
        int bppNum = 24;
        int width = 256;
        int height = 3;
        
        CGFrameBuffer *cgBuffer = [CGFrameBuffer cGFrameBufferWithBppDimensions:bppNum width:width height:height];
        
        CGColorSpaceRef colorSpace;
        colorSpace = CGColorSpaceCreateWithName(kCGColorSpaceSRGB);
        //assert(colorSpace);
        
        cgBuffer.colorspace = colorSpace;
        
        uint32_t *pixels = (uint32_t *)cgBuffer.pixels;
        //int numPixels = width * height;
        
        int offset = 0;
        
        for (int step=0; step < 256; step++) {
            uint32_t redPixel = rgba_to_bgra(step, 0, 0, 0xFF);
            pixels[offset++] = redPixel;
        }
        
        for (int step=0; step < 256; step++) {
            uint32_t greenPixel = rgba_to_bgra(0, step, 0, 0xFF);
            pixels[offset++] = greenPixel;
        }
        
        for (int step=0; step < 256; step++) {
            uint32_t bluePixel = rgba_to_bgra(0, 0, step, 0xFF);
            pixels[offset++] = bluePixel;
        }
        
        //assert(offset == (256 * 3));
        
        // Create image from test data
        
        CGImageRef imageRef = [cgBuffer createCGImageRef];
        
        // Render test image into a new CGFrameBuffer and then verify that the pixel value is the same
        
        CGFrameBuffer *renderBuffer = [CGFrameBuffer cGFrameBufferWithBppDimensions:bppNum width:width height:height];
        
        renderBuffer.colorspace = colorSpace;
        CGColorSpaceRelease(colorSpace);
        
        [renderBuffer renderCGImage:imageRef];
        
        uint32_t *renderPixels = (uint32_t *)renderBuffer.pixels;
        
        offset = 0;
        
        for (int step=0; step < 256; step++) {
            uint32_t redPixel = rgba_to_bgra(step, 0, 0, 0xFF);
            uint32_t pixel = renderPixels[offset++];
            //assert(pixel == redPixel);
        }
        
        for (int step=0; step < 256; step++) {
            uint32_t greenPixel = rgba_to_bgra(0, step, 0, 0xFF);
            uint32_t pixel = renderPixels[offset++];
            //assert(pixel == greenPixel);
        }
        
        for (int step=0; step < 256; step++) {
            uint32_t bluePixel = rgba_to_bgra(0, 0, step, 0xFF);
            uint32_t pixel = renderPixels[offset++];
            //assert(pixel == bluePixel);
        }
        
        //assert(offset == (256 * 3));
    }
    
    // Create a framebuffer that contains device RGB pixel values with an alpha step at 32bpp
    
    @autoreleasepool
    {
        int bppNum = 32;
        int width = 256;
        int height = 3;
        
        CGFrameBuffer *cgBuffer = [CGFrameBuffer cGFrameBufferWithBppDimensions:bppNum width:width height:height];
        
        uint32_t *pixels = (uint32_t *)cgBuffer.pixels;
        
        int offset = 0;
        
        for (int step=0; step < 256; step++) {
            uint32_t redPixel = rgba_to_bgra(0xFF, 0, 0, step);
            pixels[offset++] = redPixel;
        }
        
        for (int step=0; step < 256; step++) {
            uint32_t greenPixel = rgba_to_bgra(0, 0xFF, 0, step);
            pixels[offset++] = greenPixel;
        }
        
        for (int step=0; step < 256; step++) {
            uint32_t bluePixel = rgba_to_bgra(0, 0, 0xFF, step);
            pixels[offset++] = bluePixel;
        }
        
        //assert(offset == (256 * 3));
        
        // Create image from test data
        
        CGImageRef imageRef = [cgBuffer createCGImageRef];
        
        // Render test image into a new CGFrameBuffer and then verify that the pixel value is the same
        
        CGFrameBuffer *renderBuffer = [CGFrameBuffer cGFrameBufferWithBppDimensions:bppNum width:width height:height];
        
        [renderBuffer renderCGImage:imageRef];
        
        uint32_t *renderPixels = (uint32_t *)renderBuffer.pixels;
        
        offset = 0;
        
        for (int step=0; step < 256; step++) {
            uint32_t redPixel = rgba_to_bgra(0xFF, 0, 0, step);
            uint32_t pixel = renderPixels[offset++];
            //assert(pixel == redPixel);
        }
        
        for (int step=0; step < 256; step++) {
            uint32_t greenPixel = rgba_to_bgra(0, 0xFF, 0, step);
            uint32_t pixel = renderPixels[offset++];
            //assert(pixel == greenPixel);
        }
        
        for (int step=0; step < 256; step++) {
            uint32_t bluePixel = rgba_to_bgra(0, 0, 0xFF, step);
            uint32_t pixel = renderPixels[offset++];
            //assert(pixel == bluePixel);
        }
        
        //assert(offset == (256 * 3));
    }
    
    // Create a framebuffer that contains sRGB pixel values with an alpha step at 32bpp
    
    @autoreleasepool
    {
        int bppNum = 32;
        int width = 256;
        int height = 3;
        
        CGFrameBuffer *cgBuffer = [CGFrameBuffer cGFrameBufferWithBppDimensions:bppNum width:width height:height];
        
        CGColorSpaceRef colorSpace;
        colorSpace = CGColorSpaceCreateWithName(kCGColorSpaceSRGB);
        //assert(colorSpace);
        
        cgBuffer.colorspace = colorSpace;
        
        uint32_t *pixels = (uint32_t *)cgBuffer.pixels;
        
        int offset = 0;
        
        for (int step=0; step < 256; step++) {
            uint32_t redPixel = rgba_to_bgra(0xFF, 0, 0, step);
            pixels[offset++] = redPixel;
        }
        
        for (int step=0; step < 256; step++) {
            uint32_t greenPixel = rgba_to_bgra(0, 0xFF, 0, step);
            pixels[offset++] = greenPixel;
        }
        
        for (int step=0; step < 256; step++) {
            uint32_t bluePixel = rgba_to_bgra(0, 0, 0xFF, step);
            pixels[offset++] = bluePixel;
        }
        
        //assert(offset == (256 * 3));
        
        // Create image from test data
        
        CGImageRef imageRef = [cgBuffer createCGImageRef];
        
        // Render test image into a new CGFrameBuffer and then verify that the pixel value is the same
        
        CGFrameBuffer *renderBuffer = [CGFrameBuffer cGFrameBufferWithBppDimensions:bppNum width:width height:height];
        
        renderBuffer.colorspace = colorSpace;
        CGColorSpaceRelease(colorSpace);
        
        [renderBuffer renderCGImage:imageRef];
        
        uint32_t *renderPixels = (uint32_t *)renderBuffer.pixels;
        
        offset = 0;
        
        for (int step=0; step < 256; step++) {
            uint32_t redPixel = rgba_to_bgra(0xFF, 0, 0, step);
            uint32_t pixel = renderPixels[offset++];
            //assert(pixel == redPixel);
        }
        
        for (int step=0; step < 256; step++) {
            uint32_t greenPixel = rgba_to_bgra(0, 0xFF, 0, step);
            uint32_t pixel = renderPixels[offset++];
        }
        
        for (int step=0; step < 256; step++) {
            uint32_t bluePixel = rgba_to_bgra(0, 0, 0xFF, step);
            uint32_t pixel = renderPixels[offset++];
        }
    }
    
    return;
}
#endif // TESTMODE

#if defined(SPLITALPHA)

void
splitalpha(char *mvidFilenameCstr)
{
    NSString *mvidPath = [NSString stringWithUTF8String:mvidFilenameCstr];
    
    BOOL isMvid = [mvidPath hasSuffix:@".mvid"];
    
    if (isMvid == FALSE) {
        fprintf(stderr, "%s", USAGE);
        exit(1);
    }
    
    // Create "xyz_rgb.mvid" and "xyz_alpha.mvid" output filenames
    
    NSString *mvidFilename = [mvidPath lastPathComponent];
    NSString *mvidFilenameNoExtension = [mvidFilename stringByDeletingPathExtension];
    
    NSString *rgbFilename = [NSString stringWithFormat:@"%@_rgb.mvid", mvidFilenameNoExtension];
    NSString *alphaFilename = [NSString stringWithFormat:@"%@_alpha.mvid", mvidFilenameNoExtension];
    
    // Reconstruct the fully qualified path for the RGB and ALPHA filenames
    
    NSArray *mvidPathComponents = [mvidPath pathComponents];
    //assert(mvidPathComponents);
    
    NSArray *pathPrefixComponents = [NSArray array];
    if ([mvidPathComponents count] > 1) {
        NSRange range;
        range.location = 0;
        range.length = [mvidPathComponents count] - 1;
        pathPrefixComponents = [mvidPathComponents subarrayWithRange:range];
    }
    NSString *pathPrefix = nil;
    if ([pathPrefixComponents count] > 0) {
        pathPrefix = [NSString pathWithComponents:pathPrefixComponents];
    }
    
    NSString *rgbPath = rgbFilename;
    if (pathPrefix != nil) {
        rgbPath = [pathPrefix stringByAppendingPathComponent:rgbFilename];
    }
    
    NSString *alphaPath = alphaFilename;
    if (pathPrefix != nil) {
        alphaPath = [pathPrefix stringByAppendingPathComponent:alphaFilename];
    }
    
    // Read in frames from input file, then split the RGB and ALPHA components such that
    // the premultiplied color values are writted to one file and the ALPHA (grayscale)
    // values are written to the other.
    
    AVMvidFrameDecoder *frameDecoder = [AVMvidFrameDecoder aVMvidFrameDecoder];
    
    BOOL worked = [frameDecoder openForReading:mvidPath];
    
    if (worked == FALSE) {
        fprintf(stderr, "error: cannot open mvid filename \"%s\"\n", mvidFilenameCstr);
        exit(1);
    }
    
    worked = [frameDecoder allocateDecodeResources];
    //assert(worked);
    
    NSUInteger numFrames = [frameDecoder numFrames];
    //assert(numFrames > 0);
    
    float frameDuration = [frameDecoder frameDuration];
    
    int bpp = [frameDecoder header]->bpp;
    
    int width = [frameDecoder width];
    int height = [frameDecoder height];
    
    if (bpp != 32) {
        fprintf(stderr, "%s\n", "-splitalpha can only be used on a 32BPP MVID movie");
        exit(1);
    }
    
    // Verify that the input color data has been mapped to the sRGB colorspace.
    
    if (maxvid_file_version([frameDecoder header]) == MV_FILE_VERSION_ZERO) {
        fprintf(stderr, "%s\n", "-splitalpha on MVID is not supported for an old MVID file version 0.");
        exit(1);
    }
    
    fprintf(stdout, "Split %s RGB+A as %s and %s\n", [mvidFilename UTF8String], [rgbFilename UTF8String], [alphaFilename UTF8String]);
    
    // Writer that will write the RGB values
    
    MvidFileMetaData *mvidFileMetaDataRGB = [MvidFileMetaData mvidFileMetaData];
    mvidFileMetaDataRGB.bpp = 24;
    mvidFileMetaDataRGB.checkAlphaChannel = FALSE;
    
    AVMvidFileWriter *fileWriter;
    fileWriter = makeMVidWriter(rgbPath, 24, frameDuration, numFrames);
    
    {
        CGFrameBuffer *rgbFrameBuffer = [CGFrameBuffer cGFrameBufferWithBppDimensions:24 width:width height:height];
        
        // Loop over all the frame data and emit RGB values without the alpha channel
        
        for (NSUInteger frameIndex = 0; frameIndex < numFrames; frameIndex++) {
            //NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
            
            AVCustomFrame *frame = [frameDecoder advanceToFrame:frameIndex];
            //assert(frame);
            
            // Release the NSImage ref inside the frame since we will operate on the CG image directly.
            frame.image = nil;
            
            CGFrameBuffer *cgFrameBuffer = frame.cgFrameBuffer;
            //assert(cgFrameBuffer);
            
            if (frameIndex == 0) {
                rgbFrameBuffer.colorspace = cgFrameBuffer.colorspace;
            }
            
            NSUInteger numPixels = cgFrameBuffer.width * cgFrameBuffer.height;
            uint32_t *pixels = (uint32_t*)cgFrameBuffer.pixels;
            uint32_t *rgbPixels = (uint32_t*)rgbFrameBuffer.pixels;
            
            for (NSUInteger pixeli = 0; pixeli < numPixels; pixeli++) {
                uint32_t pixel = pixels[pixeli];
                
                // First reverse the premultiply logic so that the color of the pixel is disconnected from
                // the specific alpha value it will be displayed with.
                
                uint32_t rgbPixel = unpremultiply_bgra(pixel);
                
                // Now toss out the alpha value entirely and emit the pixel by itself in 24BPP mode
                
                rgbPixel = rgbPixel & 0xFFFFFF;
                
                rgbPixels[pixeli] = rgbPixel;
            }
            
            // Copy RGB data into a CGImage and apply frame delta compression to output
            
            CGImageRef frameImage = [rgbFrameBuffer createCGImageRef];
            
            BOOL isKeyframe = FALSE;
            if (frameIndex == 0) {
                isKeyframe = TRUE;
            }
            
            process_frame_file(fileWriter, NULL, frameImage, frameIndex, mvidFileMetaDataRGB, isKeyframe, NULL);
            
            if (frameImage) {
                CGImageRelease(frameImage);
            }
            
            //[pool release];
        }
        
        [fileWriter rewriteHeader];
        [fileWriter close];
    }
    
    // Now process each of the alpha channel pixels and save to another file.
    
    [frameDecoder rewind];
    
    fileWriter = makeMVidWriter(alphaPath, 24, frameDuration, numFrames);
    
    // If alphaAsGrayscale is TRUE, then emit grayscale RGB values where all the componenets are equal.
    // If alphaAsGrayscale is FASLE, then emit componenet RGB values that are able to make use of
    // threshold RGB values to further correct Alpha values when decoding.
    
    const BOOL alphaAsGrayscale = TRUE;
    
    MvidFileMetaData *mvidFileMetaDataAlpha = [MvidFileMetaData mvidFileMetaData];
    mvidFileMetaDataAlpha.bpp = 24;
    mvidFileMetaDataAlpha.checkAlphaChannel = FALSE;
    
    {
        CGFrameBuffer *alphaFrameBuffer = [CGFrameBuffer cGFrameBufferWithBppDimensions:24 width:width height:height];
        
        // Loop over all the frame data and emit RGB values without the alpha channel
        
        for (NSUInteger frameIndex = 0; frameIndex < numFrames; frameIndex++) {
            //NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
            
            AVCustomFrame *frame = [frameDecoder advanceToFrame:frameIndex];
            //assert(frame);
            
            // Release the NSImage ref inside the frame since we will operate on the CG image directly.
            frame.image = nil;
            
            CGFrameBuffer *cgFrameBuffer = frame.cgFrameBuffer;
            //assert(cgFrameBuffer);
            
            if (frameIndex == 0) {
                alphaFrameBuffer.colorspace = cgFrameBuffer.colorspace;
            }
            
            NSUInteger numPixels = cgFrameBuffer.width * cgFrameBuffer.height;
            uint32_t *pixels = (uint32_t*)cgFrameBuffer.pixels;
            uint32_t *alphaPixels = (uint32_t*)alphaFrameBuffer.pixels;
            
            for (NSUInteger pixeli = 0; pixeli < numPixels; pixeli++) {
                uint32_t pixel = pixels[pixeli];
                uint32_t alpha = (pixel >> 24) & 0xFF;
                uint32_t alphaPixel;
                if (alphaAsGrayscale) {
                    alphaPixel = (alpha << 16) | (alpha << 8) | alpha;
                } else {
                    // R = transparent, G = partial transparency, B = opaque.
                    // This logic uses the green channel to map partial transparency
                    // values since the human visual system is able to descern more
                    // precision in the green values and so H264 encoders are more
                    // likely to store green with more precision.
                    
                    uint8_t red = 0x0, green = 0x0, blue = 0x0;
                    if (alpha == 0xFF) {
                        // Fully opaque pixel
                        blue = 0xFF;
                    } else if (alpha == 0x0) {
                        // Fully transparent pixel
                        red = 0xFF;
                    } else {
                        // Partial transparency
                        green = alpha;
                    }
                    alphaPixel = rgba_to_bgra(red, green, blue, 0xFF);
                }
                alphaPixels[pixeli] = alphaPixel;
            }
            
            // Copy RGB data into a CGImage and apply frame delta compression to output
            
            CGImageRef frameImage = [alphaFrameBuffer createCGImageRef];
            
            BOOL isKeyframe = FALSE;
            if (frameIndex == 0) {
                isKeyframe = TRUE;
            }
            
            process_frame_file(fileWriter, NULL, frameImage, frameIndex, mvidFileMetaDataAlpha, isKeyframe, NULL);
            
            if (frameImage) {
                CGImageRelease(frameImage);
            }
            
            //[pool release];
        }
        
        [fileWriter rewriteHeader];
        [fileWriter close];
    }
    
    fprintf(stdout, "Wrote %s\n", [rgbPath UTF8String]);
    fprintf(stdout, "Wrote %s\n", [alphaPath UTF8String]);
    
    return;
}

void
joinalpha(char *mvidFilenameCstr)
{
    NSString *mvidPath = [NSString stringWithUTF8String:mvidFilenameCstr];
    
    BOOL isMvid = [mvidPath hasSuffix:@".mvid"];
    
    if (isMvid == FALSE) {
        fprintf(stderr, "%s", USAGE);
        exit(1);
    }
    
    premultiply_init();
    
    // The join alpha logic needs to be able to find FILE_rgb.mvid and FILE_alpha.mvid
    // in the same directory as FILE.mvid
    
    NSString *mvidFilename = [mvidPath lastPathComponent];
    NSString *mvidFilenameNoExtension = [mvidFilename stringByDeletingPathExtension];
    
    NSString *rgbFilename = [NSString stringWithFormat:@"%@_rgb.mvid", mvidFilenameNoExtension];
    NSString *alphaFilename = [NSString stringWithFormat:@"%@_alpha.mvid", mvidFilenameNoExtension];
    
    // Reconstruct the fully qualified path for the RGB and ALPHA filenames
    
    NSArray *mvidPathComponents = [mvidPath pathComponents];
    //assert(mvidPathComponents);
    
    NSArray *pathPrefixComponents = [NSArray array];
    if ([mvidPathComponents count] > 1) {
        NSRange range;
        range.location = 0;
        range.length = [mvidPathComponents count] - 1;
        pathPrefixComponents = [mvidPathComponents subarrayWithRange:range];
    }
    NSString *pathPrefix = nil;
    if ([pathPrefixComponents count] > 0) {
        pathPrefix = [NSString pathWithComponents:pathPrefixComponents];
    }
    
    NSString *rgbPath = rgbFilename;
    if (pathPrefix != nil) {
        rgbPath = [pathPrefix stringByAppendingPathComponent:rgbFilename];
    }
    
    NSString *alphaPath = alphaFilename;
    if (pathPrefix != nil) {
        alphaPath = [pathPrefix stringByAppendingPathComponent:alphaFilename];
    }
    
    if (fileExists(rgbPath) == FALSE) {
        fprintf(stderr, "Cannot find input RGB file %s\n", [rgbPath UTF8String]);
        exit(1);
    }
    
    if (fileExists(alphaPath) == FALSE) {
        fprintf(stderr, "Cannot find input ALPHA file %s\n", [alphaPath UTF8String]);
        exit(1);
    }
    
    // Remove output file if it exists
    
    if (fileExists(mvidPath) == TRUE) {
        [[NSFileManager defaultManager] removeItemAtPath:mvidPath error:nil];
    }
    
    fprintf(stdout, "Combining %s and %s as %s\n", [rgbFilename UTF8String], [alphaFilename UTF8String], [mvidFilename UTF8String]);
    
    // Open both the rgb and alpha mvid files for reading
    
    AVMvidFrameDecoder *frameDecoderRGB = [AVMvidFrameDecoder aVMvidFrameDecoder];
    AVMvidFrameDecoder *frameDecoderAlpha = [AVMvidFrameDecoder aVMvidFrameDecoder];
    
    BOOL worked;
    worked = [frameDecoderRGB openForReading:rgbPath];
    
    if (worked == FALSE) {
        fprintf(stderr, "error: cannot open RGB mvid filename \"%s\"\n", [rgbPath UTF8String]);
        exit(1);
    }
    
    worked = [frameDecoderAlpha openForReading:alphaPath];
    
    if (worked == FALSE) {
        fprintf(stderr, "error: cannot open ALPHA mvid filename \"%s\"\n", [alphaPath UTF8String]);
        exit(1);
    }
    
    [frameDecoderRGB allocateDecodeResources];
    [frameDecoderAlpha allocateDecodeResources];
    
    int foundBPP;
    
    foundBPP = [frameDecoderRGB header]->bpp;
    if (foundBPP != 24) {
        fprintf(stderr, "error: RGB mvid file must be 24BPP, found %dBPP\n", foundBPP);
        exit(1);
    }
    
    foundBPP = [frameDecoderAlpha header]->bpp;
    if (foundBPP != 24) {
        fprintf(stderr, "error: ALPHA mvid file must be 24BPP, found %dBPP\n", foundBPP);
        exit(1);
    }
    
    NSTimeInterval frameRate = frameDecoderRGB.frameDuration;
    NSTimeInterval frameRateAlpha = frameDecoderAlpha.frameDuration;
    if (frameRate != frameRateAlpha) {
        fprintf(stderr, "RGB movie fps %.4f does not match alpha movie fps %.4f\n",
                1.0f/(float)frameRate, 1.0f/(float)frameRateAlpha);
        exit(1);
    }
    
    NSUInteger numFrames = [frameDecoderRGB numFrames];
    NSUInteger numFramesAlpha = [frameDecoderAlpha numFrames];
    if (numFrames != numFramesAlpha) {
        fprintf(stderr, "RGB movie numFrames %d does not match alpha movie numFrames %d\n",
                numFrames, numFramesAlpha);
        exit(1);
    }
    
    int width = [frameDecoderRGB width];
    int height = [frameDecoderRGB height];
    CGSize size = CGSizeMake(width, height);
    
    // Size of Alpha movie must match size of RGB movie
    
    CGSize alphaMovieSize;
    
    alphaMovieSize = CGSizeMake(frameDecoderAlpha.width, frameDecoderAlpha.height);
    if (CGSizeEqualToSize(size, alphaMovieSize) == FALSE) {
        fprintf(stderr, "RGB movie size (%d, %d) does not match alpha movie size (%d, %d)\n",
                (int)width, (int)height,
                (int)alphaMovieSize.width, (int)alphaMovieSize.height);
        exit(1);
    }
    
    // If alphaAsGrayscale is TRUE, then emit grayscale RGB values where all the componenets are equal.
    // If alphaAsGrayscale is FASLE, then emit componenet RGB values that are able to make use of
    // threshold RGB values to further correct Alpha values when decoding.
    
    const BOOL alphaAsGrayscale = TRUE;
    
    MvidFileMetaData *mvidFileMetaData = [MvidFileMetaData mvidFileMetaData];
    mvidFileMetaData.bpp = 32;
    mvidFileMetaData.checkAlphaChannel = FALSE;
    
    // Create output file writer object
    
    AVMvidFileWriter *fileWriter = makeMVidWriter(mvidPath, 32, frameRate, numFrames);
    
    fileWriter.movieSize = size;
    
    CGFrameBuffer *combinedFrameBuffer = [CGFrameBuffer cGFrameBufferWithBppDimensions:32 width:width height:height];
    
    for (NSUInteger frameIndex = 0; frameIndex < numFrames; frameIndex++) {
        //NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        
        AVCustomFrame *frameRGB = [frameDecoderRGB advanceToFrame:frameIndex];
        //assert(frameRGB);
        
        AVCustomFrame *frameAlpha = [frameDecoderAlpha advanceToFrame:frameIndex];
        //assert(frameAlpha);
        
        // Release the NSImage ref inside the frame since we will operate on the image data directly.
        frameRGB.image = nil;
        frameAlpha.image = nil;
        
        CGFrameBuffer *cgFrameBufferRGB = frameRGB.cgFrameBuffer;
        //assert(cgFrameBufferRGB);
        
        CGFrameBuffer *cgFrameBufferAlpha = frameAlpha.cgFrameBuffer;
        //assert(cgFrameBufferAlpha);
        
        // sRGB
        
        if (frameIndex == 0) {
            combinedFrameBuffer.colorspace = cgFrameBufferRGB.colorspace;
        }
        
        // Join RGB and ALPHA
        
        NSUInteger numPixels = width * height;
        uint32_t *combinedPixels = (uint32_t*)combinedFrameBuffer.pixels;
        uint32_t *rgbPixels = (uint32_t*)cgFrameBufferRGB.pixels;
        uint32_t *alphaPixels = (uint32_t*)cgFrameBufferAlpha.pixels;
        
        for (NSUInteger pixeli = 0; pixeli < numPixels; pixeli++) {
            uint32_t pixelAlpha = alphaPixels[pixeli];
            
            if (alphaAsGrayscale) {
                // All 3 components of the ALPHA pixel need to be the same in grayscale mode.
                
                uint32_t pixelAlphaRed = (pixelAlpha >> 16) & 0xFF;
                uint32_t pixelAlphaGreen = (pixelAlpha >> 8) & 0xFF;
                uint32_t pixelAlphaBlue = (pixelAlpha >> 0) & 0xFF;
                
                if (pixelAlphaRed != pixelAlphaGreen || pixelAlphaRed != pixelAlphaBlue) {
                    fprintf(stderr, "Input Alpha MVID input movie R G B components do not match at pixel %d in frame %d\n", pixeli, frameIndex);
                    exit(1);
                }
                
                pixelAlpha = pixelAlphaRed;
            } else {
                // R = transparent, G = partial transparency, B = opaque.
                
                uint32_t pixelAlphaRed = (pixelAlpha >> 16) & 0xFF;
                uint32_t pixelAlphaGreen = (pixelAlpha >> 8) & 0xFF;
                uint32_t pixelAlphaBlue = (pixelAlpha >> 0) & 0xFF;
                
                const float thresholdPercent = 0.90;
                const int thresholdValue = (int) (0xFF * thresholdPercent);
                
                // FIXME: threshold should be in terms of 0, X, 255
                
                if (pixelAlphaRed >= thresholdValue) {
                    // Fully transparent pixel
                    pixelAlpha = 0x0;
                } else if (pixelAlphaBlue >= thresholdValue) {
                    // Fully opaque pixel
                    pixelAlpha = 0xFF;
                } else {
                    // Partial transparency
                    pixelAlpha = pixelAlphaGreen;
                    //assert(pixelAlpha != 0x0);
                    //assert(pixelAlpha != 0xFF);
                }
            }
            
            // RGB componenets are 24 BPP non pre multiplied values
            
            uint32_t pixelRGB = rgbPixels[pixeli];
            uint32_t pixelRed = (pixelRGB >> 16) & 0xFF;
            uint32_t pixelGreen = (pixelRGB >> 8) & 0xFF;
            uint32_t pixelBlue = (pixelRGB >> 0) & 0xFF;
            
            // Create BGRA pixel that is not premultiplied
            
            uint32_t combinedPixel = premultiply_bgra_inline(pixelRed, pixelGreen, pixelBlue, pixelAlpha);
            
            combinedPixels[pixeli] = combinedPixel;
        }
        
        // Write combined RGBA pixles
        
        // Copy RGB data into a CGImage and apply frame delta compression to output
        
        CGImageRef frameImage = [combinedFrameBuffer createCGImageRef];
        
        BOOL isKeyframe = FALSE;
        if (frameIndex == 0) {
            isKeyframe = TRUE;
        }
        
        process_frame_file(fileWriter, NULL, frameImage, frameIndex, mvidFileMetaData, isKeyframe, NULL);
        
        if (frameImage) {
            CGImageRelease(frameImage);
        }
        
        //[pool drain];
    }
    
    [fileWriter rewriteHeader];
    [fileWriter close];
    
    fprintf(stdout, "Wrote %s\n", [fileWriter.mvidPath UTF8String]);
    return;
}

// Mix alpha means to split the RGB and Alpha channels into frames and then
// display one RGB frame and then one Alpha frame one after another.

void
mixalpha(char *mvidFilenameCstr)
{
    NSString *mvidPath = [NSString stringWithUTF8String:mvidFilenameCstr];
    
    BOOL isMvid = [mvidPath hasSuffix:@".mvid"];
    
    if (isMvid == FALSE) {
        fprintf(stderr, "%s", USAGE);
        exit(1);
    }
    
    // Create "xyz_mix.mvid" as output filenames
    
    NSString *mvidFilename = [mvidPath lastPathComponent];
    NSString *mvidFilenameNoExtension = [mvidFilename stringByDeletingPathExtension];
    
    NSString *mixFilename = [NSString stringWithFormat:@"%@_mix.mvid", mvidFilenameNoExtension];
    
    // Reconstruct the fully qualified path for the RGB and ALPHA filenames
    
    NSArray *mvidPathComponents = [mvidPath pathComponents];
    //assert(mvidPathComponents);
    
    NSArray *pathPrefixComponents = [NSArray array];
    if ([mvidPathComponents count] > 1) {
        NSRange range;
        range.location = 0;
        range.length = [mvidPathComponents count] - 1;
        pathPrefixComponents = [mvidPathComponents subarrayWithRange:range];
    }
    NSString *pathPrefix = nil;
    if ([pathPrefixComponents count] > 0) {
        pathPrefix = [NSString pathWithComponents:pathPrefixComponents];
    }
    
    NSString *mixPath = mixFilename;
    if (pathPrefix != nil) {
        mixPath = [pathPrefix stringByAppendingPathComponent:mixFilename];
    }
    
    // Read in frames from input file, then split the RGB and ALPHA components such that
    // the premultiplied color values are writted to one file and the ALPHA (grayscale)
    // values are written to the other.
    
    AVMvidFrameDecoder *frameDecoder = [AVMvidFrameDecoder aVMvidFrameDecoder];
    
    BOOL worked = [frameDecoder openForReading:mvidPath];
    
    if (worked == FALSE) {
        fprintf(stderr, "error: cannot open mvid filename \"%s\"\n", mvidFilenameCstr);
        exit(1);
    }
    
    worked = [frameDecoder allocateDecodeResources];
    //assert(worked);
    
    NSUInteger numFrames = [frameDecoder numFrames];
    //assert(numFrames > 0);
    
    float frameDuration = [frameDecoder frameDuration];
    
    int bpp = [frameDecoder header]->bpp;
    
    int width = [frameDecoder width];
    int height = [frameDecoder height];
    
    if (bpp != 32) {
        fprintf(stderr, "%s\n", "-mixalpha can only be used on a 32BPP MVID movie");
        exit(1);
    }
    
    // Verify that the input color data has been mapped to the sRGB colorspace.
    
    if (maxvid_file_version([frameDecoder header]) == MV_FILE_VERSION_ZERO) {
        fprintf(stderr, "%s\n", "-mixalpha on MVID is not supported for an old MVID file version 0.");
        exit(1);
    }
    
    fprintf(stdout, "Mix %s RGB+A as %s\n", [mvidFilename UTF8String], [mixFilename UTF8String]);
    
    // Writer that will write the RGB values to an output file that is 2 times longer than the input
    
    MvidFileMetaData *mvidFileMetaData = [MvidFileMetaData mvidFileMetaData];
    mvidFileMetaData.bpp = 24;
    mvidFileMetaData.checkAlphaChannel = FALSE;
    
    AVMvidFileWriter *fileWriter;
    fileWriter = makeMVidWriter(mixPath, 24, frameDuration, numFrames*2);
    
    // If alphaAsGrayscale is TRUE, then emit grayscale RGB values where all the componenets are equal.
    // If alphaAsGrayscale is FASLE, then emit componenet RGB values that are able to make use of
    // threshold RGB values to further correct Alpha values when decoding.
    
    const BOOL alphaAsGrayscale = TRUE;
    
    {
        CGFrameBuffer *rgbFrameBuffer = [CGFrameBuffer cGFrameBufferWithBppDimensions:24 width:width height:height];
        
        // Loop over all the frame data and emit RGB values without the alpha channel
        
        NSUInteger outFrameIndex = 0;
        
        for (NSUInteger frameIndex = 0; frameIndex < numFrames; frameIndex++) {
            //NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
            
            AVCustomFrame *frame = [frameDecoder advanceToFrame:frameIndex];
            //assert(frame);
            
            // Release the NSImage ref inside the frame since we will operate on the CG image directly.
            frame.image = nil;
            
            CGFrameBuffer *cgFrameBuffer = frame.cgFrameBuffer;
            //assert(cgFrameBuffer);
            
            if (frameIndex == 0) {
                rgbFrameBuffer.colorspace = cgFrameBuffer.colorspace;
            }
            
            NSUInteger numPixels = cgFrameBuffer.width * cgFrameBuffer.height;
            uint32_t *pixels = (uint32_t*)cgFrameBuffer.pixels;
            uint32_t *rgbPixels = (uint32_t*)rgbFrameBuffer.pixels;
            
            for (NSUInteger pixeli = 0; pixeli < numPixels; pixeli++) {
                uint32_t pixel = pixels[pixeli];
                
                // First reverse the premultiply logic so that the color of the pixel is disconnected from
                // the specific alpha value it will be displayed with.
                
                uint32_t rgbPixel = unpremultiply_bgra(pixel);
                
                // Now toss out the alpha value entirely and emit the pixel by itself in 24BPP mode
                
                rgbPixel = rgbPixel & 0xFFFFFF;
                
                rgbPixels[pixeli] = rgbPixel;
            }
            
            // Copy RGB data into a CGImage and apply frame delta compression to output
            
            CGImageRef frameImage = [rgbFrameBuffer createCGImageRef];
            
            BOOL isKeyframe = TRUE;
            
            process_frame_file(fileWriter, NULL, frameImage, outFrameIndex, mvidFileMetaData, isKeyframe, NULL);
            outFrameIndex++;
            
            if (frameImage) {
                CGImageRelease(frameImage);
            }
            
            // Emit Alpha frame
            
            for (NSUInteger pixeli = 0; pixeli < numPixels; pixeli++) {
                uint32_t pixel = pixels[pixeli];
                uint32_t alpha = (pixel >> 24) & 0xFF;
                uint32_t alphaPixel;
                if (alphaAsGrayscale) {
                    alphaPixel = (alpha << 16) | (alpha << 8) | alpha;
                } else {
                    // R = transparent, G = partial transparency, B = opaque.
                    // This logic uses the green channel to map partial transparency
                    // values since the human visual system is able to descern more
                    // precision in the green values and so H264 encoders are more
                    // likely to store green with more precision.
                    
                    uint8_t red = 0x0, green = 0x0, blue = 0x0;
                    if (alpha == 0xFF) {
                        // Fully opaque pixel
                        blue = 0xFF;
                    } else if (alpha == 0x0) {
                        // Fully transparent pixel
                        red = 0xFF;
                    } else {
                        // Partial transparency
                        green = alpha;
                    }
                    alphaPixel = rgba_to_bgra(red, green, blue, 0xFF);
                }
                rgbPixels[pixeli] = alphaPixel;
            }
            
            frameImage = [rgbFrameBuffer createCGImageRef];
            
            process_frame_file(fileWriter, NULL, frameImage, outFrameIndex, mvidFileMetaData, isKeyframe, NULL);
            outFrameIndex++;
            
            if (frameImage) {
                CGImageRelease(frameImage);
            }
            
            //[pool release];
        }
        
        [fileWriter rewriteHeader];
        [fileWriter close];
    }
    
    fprintf(stdout, "Wrote %s\n", [mixPath UTF8String]);
}

// Undo a mix where RGB and Alpha where split into different H.264 frames

void
unmixalpha(char *mvidFilenameCstr)
{
    NSString *mvidPath = [NSString stringWithUTF8String:mvidFilenameCstr];
    
    BOOL isMvid = [mvidPath hasSuffix:@".mvid"];
    
    if (isMvid == FALSE) {
        fprintf(stderr, "%s", USAGE);
        exit(1);
    }
    
    premultiply_init();
    
    // The join logic accepts a .mvid filename like "low_car.mvid" and looks
    // for an input file "low_car_mix.mvid"
    
    NSString *mvidFilename = [mvidPath lastPathComponent];
    NSString *mvidFilenameNoExtension = [mvidFilename stringByDeletingPathExtension];
    
    NSString *mixFilename = [NSString stringWithFormat:@"%@_mix.mvid", mvidFilenameNoExtension];
    
    // Reconstruct the fully qualified path for the RGB and ALPHA filenames
    
    NSArray *mvidPathComponents = [mvidPath pathComponents];
    //assert(mvidPathComponents);
    
    NSArray *pathPrefixComponents = [NSArray array];
    if ([mvidPathComponents count] > 1) {
        NSRange range;
        range.location = 0;
        range.length = [mvidPathComponents count] - 1;
        pathPrefixComponents = [mvidPathComponents subarrayWithRange:range];
    }
    NSString *pathPrefix = nil;
    if ([pathPrefixComponents count] > 0) {
        pathPrefix = [NSString pathWithComponents:pathPrefixComponents];
    }
    
    NSString *mixPath = mixFilename;
    if (pathPrefix != nil) {
        mixPath = [pathPrefix stringByAppendingPathComponent:mixPath];
    }
    
    if (fileExists(mixPath) == FALSE) {
        fprintf(stderr, "Cannot find input RGB file %s\n", [mixPath UTF8String]);
        exit(1);
    }
    
    // Remove output file if it exists
    
    if (fileExists(mvidPath) == TRUE) {
        [[NSFileManager defaultManager] removeItemAtPath:mvidPath error:nil];
    }
    
    fprintf(stdout, "Combine mix %s as %s\n", [mixFilename UTF8String], [mvidFilename UTF8String]);
    
    // Open both the rgb and alpha mvid files for reading
    
    AVMvidFrameDecoder *frameDecoderRGB = [AVMvidFrameDecoder aVMvidFrameDecoder];
    
    BOOL worked;
    worked = [frameDecoderRGB openForReading:mixPath];
    
    if (worked == FALSE) {
        fprintf(stderr, "error: cannot open RGB mvid filename \"%s\"\n", [mixPath UTF8String]);
        exit(1);
    }
    
    [frameDecoderRGB allocateDecodeResources];
    
    int foundBPP;
    
    foundBPP = [frameDecoderRGB header]->bpp;
    if (foundBPP != 24) {
        fprintf(stderr, "error: RGB mvid file must be 24BPP, found %dBPP\n", foundBPP);
        exit(1);
    }
    
    NSTimeInterval frameRate = frameDecoderRGB.frameDuration;
    
    NSUInteger numFrames = [frameDecoderRGB numFrames];
    
    int width = [frameDecoderRGB width];
    int height = [frameDecoderRGB height];
    CGSize size = CGSizeMake(width, height);
    
    // If alphaAsGrayscale is TRUE, then emit grayscale RGB values where all the componenets are equal.
    // If alphaAsGrayscale is FALSE, then emit componenet RGB values that are able to make use of
    // threshold RGB values to further correct Alpha values when decoding.
    
    const BOOL alphaAsGrayscale = TRUE;
    
    MvidFileMetaData *mvidFileMetaData = [MvidFileMetaData mvidFileMetaData];
    mvidFileMetaData.bpp = 32;
    mvidFileMetaData.checkAlphaChannel = FALSE;
    
    // Create output file writer object
    
    int numOutputFrames = numFrames / 2;
    
    AVMvidFileWriter *fileWriter = makeMVidWriter(mvidPath, 32, frameRate, numOutputFrames);
    
    fileWriter.movieSize = size;
    
    CGFrameBuffer *combinedFrameBuffer = [CGFrameBuffer cGFrameBufferWithBppDimensions:32 width:width height:height];
    
    for (NSUInteger frameIndex = 0; frameIndex < numFrames; frameIndex += 2) {
        // NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        
        AVCustomFrame *frameRGB = [frameDecoderRGB advanceToFrame:frameIndex];
        //assert(frameRGB);
        
        AVCustomFrame *frameAlpha = [frameDecoderRGB advanceToFrame:frameIndex+1];
        //assert(frameAlpha);
        
        // Release the NSImage ref inside the frame since we will operate on the image data directly.
        frameRGB.image = nil;
        frameAlpha.image = nil;
        
        CGFrameBuffer *cgFrameBufferRGB = frameRGB.cgFrameBuffer;
        //assert(cgFrameBufferRGB);
        
        CGFrameBuffer *cgFrameBufferAlpha = frameAlpha.cgFrameBuffer;
        //assert(cgFrameBufferAlpha);
        
        // sRGB
        
        if (frameIndex == 0) {
            combinedFrameBuffer.colorspace = cgFrameBufferRGB.colorspace;
        }
        
        // Join RGB and ALPHA
        
        NSUInteger numPixels = width * height;
        uint32_t *combinedPixels = (uint32_t*)combinedFrameBuffer.pixels;
        uint32_t *rgbPixels = (uint32_t*)cgFrameBufferRGB.pixels;
        uint32_t *alphaPixels = (uint32_t*)cgFrameBufferAlpha.pixels;
        
        for (NSUInteger pixeli = 0; pixeli < numPixels; pixeli++) {
            uint32_t pixelAlpha = alphaPixels[pixeli];
            
            if (alphaAsGrayscale) {
                // All 3 components of the ALPHA pixel need to be the same in grayscale mode.
                
                uint32_t pixelAlphaRed = (pixelAlpha >> 16) & 0xFF;
                uint32_t pixelAlphaGreen = (pixelAlpha >> 8) & 0xFF;
                uint32_t pixelAlphaBlue = (pixelAlpha >> 0) & 0xFF;
                
                if (pixelAlphaRed != pixelAlphaGreen || pixelAlphaRed != pixelAlphaBlue) {
                    fprintf(stderr, "Input Alpha MVID input movie R G B components do not match at pixel %d in frame %d\n", pixeli, frameIndex);
                    exit(1);
                }
                
                pixelAlpha = pixelAlphaRed;
            } else {
                // R = transparent, G = partial transparency, B = opaque.
                
                uint32_t pixelAlphaRed = (pixelAlpha >> 16) & 0xFF;
                uint32_t pixelAlphaGreen = (pixelAlpha >> 8) & 0xFF;
                uint32_t pixelAlphaBlue = (pixelAlpha >> 0) & 0xFF;
                
                const float thresholdPercent = 0.90;
                const int thresholdValue = (int) (0xFF * thresholdPercent);
                
                if (pixelAlphaRed >= thresholdValue) {
                    // Fully transparent pixel
                    pixelAlpha = 0x0;
                } else if (pixelAlphaBlue >= thresholdValue) {
                    // Fully opaque pixel
                    pixelAlpha = 0xFF;
                } else {
                    // Partial transparency
                    pixelAlpha = pixelAlphaGreen;
                    //assert(pixelAlpha != 0x0);
                    //assert(pixelAlpha != 0xFF);
                }
            }
            
            // RGB componenets are 24 BPP non pre multiplied values
            
            uint32_t pixelRGB = rgbPixels[pixeli];
            uint32_t pixelRed = (pixelRGB >> 16) & 0xFF;
            uint32_t pixelGreen = (pixelRGB >> 8) & 0xFF;
            uint32_t pixelBlue = (pixelRGB >> 0) & 0xFF;
            
            // Create BGRA pixel that is not premultiplied
            
            uint32_t combinedPixel = premultiply_bgra_inline(pixelRed, pixelGreen, pixelBlue, pixelAlpha);
            
            combinedPixels[pixeli] = combinedPixel;
        }
        
        // Write combined RGBA pixles
        
        // Copy RGB data into a CGImage and apply frame delta compression to output
        
        CGImageRef frameImage = [combinedFrameBuffer createCGImageRef];
        
        BOOL isKeyframe = FALSE;
        if (frameIndex == 0) {
            isKeyframe = TRUE;
        }
        
        process_frame_file(fileWriter, NULL, frameImage, frameIndex/2, mvidFileMetaData, isKeyframe, NULL);
        
        if (frameImage) {
            CGImageRelease(frameImage);
        }
        
        //[pool drain];
    }
    
    [fileWriter rewriteHeader];
    [fileWriter close];
    
    fprintf(stdout, "Wrote %s\n", [fileWriter.mvidPath UTF8String]);
    return;
}

// Combine an existing RGB and ALPHA video into an singe interleaved video.
// Typically a mixture would combine RGB and Alpha channel data, but it is
// also possible to combine any type of data as long as the data is each
// channel is represented as pixels. For example, other uses include encoding
// a 24BPP blend amount represented as grayscale pixels. One might also split
// two very large RGB frames into 1/2 frames for display at a very large size.

void
mixstraight(char *rgbMvidFilenameCstr, char *alphaMvidFilenameCstr, char *mixedMvidFilenameCstr)
{
    NSString *rgbMvidPath = [NSString stringWithUTF8String:rgbMvidFilenameCstr];
    NSString *alphaMvidPath = [NSString stringWithUTF8String:alphaMvidFilenameCstr];
    NSString *mixedMvidPath = [NSString stringWithUTF8String:mixedMvidFilenameCstr];
    
    for ( NSString *mvidPath in @[ rgbMvidPath, alphaMvidPath, mixedMvidPath ] ) {
        BOOL isMvid = [mvidPath hasSuffix:@".mvid"];
        
        if (isMvid == FALSE) {
            fprintf(stderr, "not .mvid file \"%s\"\n", [mvidPath UTF8String]);
            fprintf(stderr, "%s", USAGE);
            exit(1);
        }
    }
    
    // Remove output file if it exists
    
    if (fileExists(mixedMvidPath) == TRUE) {
        [[NSFileManager defaultManager] removeItemAtPath:mixedMvidPath error:nil];
    }
    
    // Open 2 input files
    
    if (fileExists(rgbMvidPath) == FALSE) {
        fprintf(stderr, "Cannot find input RGB file %s\n", [rgbMvidPath UTF8String]);
        exit(1);
    }
    
    if (fileExists(alphaMvidPath) == FALSE) {
        fprintf(stderr, "Cannot find input RGB file %s\n", [alphaMvidPath UTF8String]);
        exit(1);
    }
    
    // Open both the rgb and alpha mvid files for reading
    
    AVMvidFrameDecoder *frameDecoderRGB = [AVMvidFrameDecoder aVMvidFrameDecoder];
    
    BOOL worked;
    worked = [frameDecoderRGB openForReading:rgbMvidPath];
    
    if (worked == FALSE) {
        fprintf(stderr, "error: cannot open RGB mvid filename \"%s\"\n", [rgbMvidPath UTF8String]);
        exit(1);
    }
    
    [frameDecoderRGB allocateDecodeResources];
    
    int foundBPP;
    
    foundBPP = [frameDecoderRGB header]->bpp;
    if (foundBPP != 24) {
        fprintf(stderr, "error: input mvid file must be 24BPP, found %dBPP\n", foundBPP);
        exit(1);
    }
    
    AVMvidFrameDecoder *frameDecoderAlpha = [AVMvidFrameDecoder aVMvidFrameDecoder];
    
    worked = [frameDecoderAlpha openForReading:alphaMvidPath];
    
    if (worked == FALSE) {
        fprintf(stderr, "error: cannot open ALPHA mvid filename \"%s\"\n", [alphaMvidPath UTF8String]);
        exit(1);
    }
    
    [frameDecoderAlpha allocateDecodeResources];
    
    foundBPP = [frameDecoderAlpha header]->bpp;
    if (foundBPP != 24) {
        fprintf(stderr, "error: input mvid file must be 24BPP, found %dBPP\n", foundBPP);
        exit(1);
    }
    
    NSTimeInterval frameRate = frameDecoderRGB.frameDuration;
    
    NSUInteger numFrames = [frameDecoderRGB numFrames];
    NSUInteger numFrames2 = [frameDecoderAlpha numFrames];
    
    if (numFrames != numFrames2) {
        fprintf(stderr, "error:num frames mismatch %d != %d\n", numFrames, numFrames2);
        exit(1);
    }
    
    int width = [frameDecoderRGB width];
    int height = [frameDecoderRGB height];
    CGSize size = CGSizeMake(width, height);
    
    // If alphaAsGrayscale is TRUE, then emit grayscale RGB values where all the componenets are equal.
    // If alphaAsGrayscale is FALSE, then emit componenet RGB values that are able to make use of
    // threshold RGB values to further correct Alpha values when decoding.
    
    //  const BOOL alphaAsGrayscale = TRUE;
    
    MvidFileMetaData *mvidFileMetaData = [MvidFileMetaData mvidFileMetaData];
    mvidFileMetaData.bpp = 24;
    mvidFileMetaData.checkAlphaChannel = FALSE;
    
    // Create output file writer object
    
    int numOutputFrames = numFrames * 2;
    
    AVMvidFileWriter *fileWriter = makeMVidWriter(mixedMvidPath, 24, frameRate, numOutputFrames);
    
    fileWriter.movieSize = size;
    
    CGFrameBuffer *rgbOutputFrameBuffer = [CGFrameBuffer cGFrameBufferWithBppDimensions:24 width:width height:height];
    
    int outFrameIndex = 0;
    
    for (NSUInteger frameIndex = 0; frameIndex < numFrames; frameIndex++) @autoreleasepool {
        AVCustomFrame *frameRGB = [frameDecoderRGB advanceToFrame:frameIndex];
        //assert(frameRGB);
        
        AVCustomFrame *frameAlpha = [frameDecoderAlpha advanceToFrame:frameIndex];
        //assert(frameAlpha);
        
        // Release the NSImage ref inside the frame since we will operate on the CG image directly.
        frameRGB.image = nil;
        frameAlpha.image = nil;
        
        //assert(frameRGB.cgFrameBuffer);
        //assert(frameAlpha.cgFrameBuffer);
        
        if (frameIndex == 0) {
            rgbOutputFrameBuffer.colorspace = frameRGB.cgFrameBuffer.colorspace;
        }
        
        // Straight memcpy into rgbOutputFrameBuffer
        
        [rgbOutputFrameBuffer copyPixels:frameRGB.cgFrameBuffer];
        
        // Copy RGB data into a CGImage and apply frame delta compression to output
        
        CGImageRef frameImage = [rgbOutputFrameBuffer createCGImageRef];
        //assert(frameImage);
        
        BOOL isKeyframe = TRUE;
        
        process_frame_file(fileWriter, NULL, frameImage, outFrameIndex, mvidFileMetaData, isKeyframe, NULL);
        outFrameIndex++;
        
        if (frameImage) {
            CGImageRelease(frameImage);
        }
        
        // Straight memcpy into rgbOutputFrameBuffer
        
        [rgbOutputFrameBuffer copyPixels:frameAlpha.cgFrameBuffer];
        
        frameImage = [rgbOutputFrameBuffer createCGImageRef];
        //assert(frameImage);
        
        process_frame_file(fileWriter, NULL, frameImage, outFrameIndex, mvidFileMetaData, isKeyframe, NULL);
        outFrameIndex++;
        
        if (frameImage) {
            CGImageRelease(frameImage);
        }
    }
    
    //assert(numOutputFrames == outFrameIndex);
    
    [fileWriter rewriteHeader];
    [fileWriter close];
    
    fprintf(stdout, "Wrote %s\n", [fileWriter.mvidPath UTF8String]);
    return;
}

#endif // SPLITALPHA

// This method provides a command line interface that makes it possible to crop
// each frame of a movie and emit a new file containing the cropped portion
// of each frame. This is a very simple operation, but it can be very difficult
// to do using Quicktime or other command line tools. A high end video editor
// would do this easily, this implementation makes it easy to do on the command line.

void
cropMvidMovie(char *cropSpecCstr, char *inMvidFilenameCstr, char *outMvidFilenameCstr)
{
    NSString *inMvidPath = [NSString stringWithUTF8String:inMvidFilenameCstr];
    NSString *outMvidPath = [NSString stringWithUTF8String:outMvidFilenameCstr];
    
    BOOL isMvid;
    
    isMvid = [inMvidPath hasSuffix:@".mvid"];
    
    if (isMvid == FALSE) {
        fprintf(stderr, "%s", USAGE);
        exit(1);
    }
    
    isMvid = [outMvidPath hasSuffix:@".mvid"];
    
    if (isMvid == FALSE) {
        fprintf(stderr, "%s", USAGE);
        exit(1);
    }
    
    // Check the CROP spec, it should be 4 integer values that indicate the X Y W H
    // for the output movie.
    
    NSString *cropSpec = [NSString stringWithUTF8String:cropSpecCstr];
    NSArray *elements  = [cropSpec componentsSeparatedByString:@" "];
    
    if ([elements count] != 4) {
        fprintf(stderr, "CROP specification must be X Y WIDTH HEIGHT : not %s\n", cropSpecCstr);
        exit(1);
    }
    
    NSInteger cropX = [((NSString*)[elements objectAtIndex:0]) intValue];
    NSInteger cropY = [((NSString*)[elements objectAtIndex:1]) intValue];
    NSInteger cropW = [((NSString*)[elements objectAtIndex:2]) intValue];
    NSInteger cropH = [((NSString*)[elements objectAtIndex:3]) intValue];
    
    // Read in existing file into from the input file and create an output file
    // that has exactly the same options.
    
    AVMvidFrameDecoder *frameDecoder = [AVMvidFrameDecoder aVMvidFrameDecoder];
    
    BOOL worked = [frameDecoder openForReading:inMvidPath];
    
    if (worked == FALSE) {
        fprintf(stderr, "error: cannot open input mvid filename \"%s\"\n", [inMvidPath UTF8String]);
        exit(1);
    }
    
    worked = [frameDecoder allocateDecodeResources];
    //assert(worked);
    
    NSUInteger numFrames = [frameDecoder numFrames];
    //assert(numFrames > 0);
    
    float frameDuration = [frameDecoder frameDuration];
    
    int bpp = [frameDecoder header]->bpp;
    
    int width = [frameDecoder width];
    int height = [frameDecoder height];
    
    // Verify the crop spec info once info from input file is available
    
    BOOL cropXYInvalid = FALSE;
    BOOL cropWHInvalid = FALSE;
    
    if (cropX < 0 || cropY < 0) {
        cropXYInvalid = TRUE;
    }
    
    if (cropW <= 0 || cropW <= 0) {
        cropWHInvalid = TRUE;
    }
    
    // Output size has to be the same or smaller than the input size
    // X,Y must be greater than 0 and smaller than W,H of the input movie
    // W,H must be greater than 0 and smaller than W,H of the input movie
    
    if (cropW > width) {
        cropWHInvalid = TRUE;
    }
    
    if (cropH > height) {
        cropWHInvalid = TRUE;
    }
    
    int outputX2 = cropX + cropW;
    if (outputX2 > width) {
        cropWHInvalid = TRUE;
    }
    
    int outputY2 = cropY + cropH;
    if (outputY2 > height) {
        cropWHInvalid = TRUE;
    }
    
    if (cropXYInvalid || cropWHInvalid) {
        NSString *movieDimensionsStr = [NSString stringWithFormat:@"%d x %d", width, height];
        fprintf(stderr, "error: invalid -crop specification \"%s\" for movie with dimensions \"%s\"\n", cropSpecCstr, [movieDimensionsStr UTF8String]);
        exit(1);
    }
    
    // Writer that will write the RGB values. Note that invoking process_frame_file()
    // will define the output width/height based on the size of the image passed in.
    
    MvidFileMetaData *mvidFileMetaData = [MvidFileMetaData mvidFileMetaData];
    mvidFileMetaData.bpp = bpp;
    mvidFileMetaData.checkAlphaChannel = FALSE;
    
    AVMvidFileWriter *fileWriter = makeMVidWriter(outMvidPath, bpp, frameDuration, numFrames);
    
    CGFrameBuffer *croppedFrameBuffer = [CGFrameBuffer cGFrameBufferWithBppDimensions:bpp width:cropW height:cropH];
    
    for (NSUInteger frameIndex = 0; frameIndex < numFrames; frameIndex++) {
        // NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        
        AVCustomFrame *frame = [frameDecoder advanceToFrame:frameIndex];
        //assert(frame);
        
        // Release the NSImage ref inside the frame since we will operate on the CG image directly.
        frame.image = nil;
        
        CGFrameBuffer *cgFrameBuffer = frame.cgFrameBuffer;
        //assert(cgFrameBuffer);
        
        // sRGB support
        
        if (frameIndex == 0) {
            croppedFrameBuffer.colorspace = cgFrameBuffer.colorspace;
        }
        
        // Copy cropped area into the croppedFrameBuffer
        
        BOOL worked;
        CGImageRef frameImage = nil;
        
        // Crop pixels from cgFrameBuffer while doing a copy into croppedFrameBuffer. Note that this
        // API currently assumes that input and output are the same BPP.
        
        [croppedFrameBuffer cropCopyPixels:cgFrameBuffer cropX:cropX cropY:cropY];
        
        frameImage = [croppedFrameBuffer createCGImageRef];
        worked = (frameImage != nil);
        //assert(worked);
        
        BOOL isKeyframe = FALSE;
        if (frameIndex == 0) {
            isKeyframe = TRUE;
        }
        
        process_frame_file(fileWriter, NULL, frameImage, frameIndex, mvidFileMetaData, isKeyframe, NULL);
        
        if (frameImage) {
            CGImageRelease(frameImage);
        }
        
        //[pool drain];
    }
    
    [fileWriter rewriteHeader];
    [fileWriter close];
    
    fprintf(stdout, "Wrote: %s\n", [fileWriter.mvidPath UTF8String]);
    return;
}

// This -resize option provides a very handy command line operation that is able to resize
// a movie and write the result to a new file. Any width and height could be set as the
// output dimensions.

void
resizeMvidMovie(char *resizeSpecCstr, char *inMvidFilenameCstr, char *outMvidFilenameCstr)
{
    NSString *inMvidPath = [NSString stringWithUTF8String:inMvidFilenameCstr];
    NSString *outMvidPath = [NSString stringWithUTF8String:outMvidFilenameCstr];
    
    BOOL isMvid;
    
    isMvid = [inMvidPath hasSuffix:@".mvid"];
    
    if (isMvid == FALSE) {
        fprintf(stderr, "%s", USAGE);
        exit(1);
    }
    
    isMvid = [outMvidPath hasSuffix:@".mvid"];
    
    if (isMvid == FALSE) {
        fprintf(stderr, "%s", USAGE);
        exit(1);
    }
    
    // Check the RESIZE spec, it should be 2 integer values that indicate the W H
    // for the output movie. This parameter could also be DOUBLE or HALF to indicate
    // a "double size" operation or a "half size" operation. Note that there is a
    // special case when using "DOUBLE" in that it writes pixels directly to the double
    // size, while indicating the size explicitly will use the core graphics scale op.
    
    NSString *resizeSpec = [NSString stringWithUTF8String:resizeSpecCstr];
    
    NSInteger resizeW = -1;
    NSInteger resizeH = -1;
    
    BOOL doubleSizeFlag = FALSE;
    BOOL halfSizeFlag = FALSE;
    
    if ([resizeSpec isEqualToString:@"DOUBLE"]) {
        // Enable 1 -> 4 pixel logic for DOUBLE resize, the CG render will resample and produce some very strange
        // results that do not produce the identical pixel values when resized back to half the size.
        
        doubleSizeFlag = TRUE;
    } else if ([resizeSpec isEqualToString:@"HALF"]) {
        // Shortcut so that half size operation need not pass the exact sizes, they can be calculated from input movie
        
        halfSizeFlag = TRUE;
    }
    
    if ((doubleSizeFlag == FALSE) && (halfSizeFlag == FALSE)) {
        NSArray *elements  = [resizeSpec componentsSeparatedByString:@" "];
        
        if ([elements count] != 2) {
            fprintf(stderr, "RESIZE specification must be WIDTH HEIGHT : not %s\n", resizeSpecCstr);
            exit(1);
        }
        
        resizeW = [((NSString*)[elements objectAtIndex:0]) intValue];
        resizeH = [((NSString*)[elements objectAtIndex:1]) intValue];
        
        if (resizeW <= 0 || resizeH <= 0) {
            fprintf(stderr, "RESIZE specification must be WIDTH HEIGHT : not %s\n", resizeSpecCstr);
            exit(1);
        }
    }
    
    // Read in existing file into from the input file and create an output file
    // that has exactly the same options.
    
    AVMvidFrameDecoder *frameDecoder = [AVMvidFrameDecoder aVMvidFrameDecoder];
    
    BOOL worked = [frameDecoder openForReading:inMvidPath];
    
    if (worked == FALSE) {
        fprintf(stderr, "error: cannot open input mvid filename \"%s\"\n", [inMvidPath UTF8String]);
        exit(1);
    }
    
    worked = [frameDecoder allocateDecodeResources];
    //assert(worked);
    
    NSUInteger numFrames = [frameDecoder numFrames];
    //assert(numFrames > 0);
    
    float frameDuration = [frameDecoder frameDuration];
    
    int bpp = [frameDecoder header]->bpp;
    
    int width = [frameDecoder width];
    int height = [frameDecoder height];
    //assert(width > 0);
    //assert(height > 0);
    
    if (doubleSizeFlag) {
        resizeW = width * 2;
        resizeH = height * 2;
    }
    
    if (halfSizeFlag) {
        resizeW = width / 2;
        resizeH = height / 2;
    }
    
    //assert(resizeW != -1);
    //assert(resizeH != -1);
    
    // Writer that will write the RGB values. Note that invoking process_frame_file()
    // will define the output width/height based on the size of the image passed in.
    
    MvidFileMetaData *mvidFileMetaData = [MvidFileMetaData mvidFileMetaData];
    mvidFileMetaData.bpp = bpp;
    mvidFileMetaData.checkAlphaChannel = FALSE;
    
    AVMvidFileWriter *fileWriter = makeMVidWriter(outMvidPath, bpp, frameDuration, numFrames);
    
    CGFrameBuffer *resizedFrameBuffer = [CGFrameBuffer cGFrameBufferWithBppDimensions:bpp width:resizeW height:resizeH];
    
    // Resize input image to some other size. Ignore the case where the input is exactly
    // the same size as the output. If the HALF size resize is indicated, use the default
    // interpolation which results in exact half size pixel rendering. Otherwise, use
    // the high quality interpolation.
    
    if (halfSizeFlag == FALSE) {
        resizedFrameBuffer.useHighQualityInterpolation = TRUE;
    }
    
    for (NSUInteger frameIndex = 0; frameIndex < numFrames; frameIndex++) {
        // NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        
        AVCustomFrame *frame = [frameDecoder advanceToFrame:frameIndex];
        //assert(frame);
        
        // Release the NSImage ref inside the frame since we will operate on the CG image directly.
        frame.image = nil;
        
        CGFrameBuffer *cgFrameBuffer = frame.cgFrameBuffer;
        //assert(cgFrameBuffer);
        
        // sRGB support
        
        if (frameIndex == 0) {
            resizedFrameBuffer.colorspace = cgFrameBuffer.colorspace;
        }
        
        // Copy/Scale input image into resizedFrameBuffer
        
        BOOL worked;
        CGImageRef frameImage = nil;
        
        if (doubleSizeFlag == TRUE) {
            // Use special case "DOUBLE" logic that will simply duplicate the exact RGB value from the indicated
            // pixel into the 2x sized output buffer.
            
            //assert(cgFrameBuffer.bitsPerPixel == resizedFrameBuffer.bitsPerPixel);
            //assert(cgFrameBuffer.bitsPerPixel > 16); // FIXME later, add 16 BPP support
            
            int numOutputPixels = resizedFrameBuffer.width * resizedFrameBuffer.height;
            
            uint32_t *inPixels32 = (uint32_t*)cgFrameBuffer.pixels;
            uint32_t *outPixels32 = (uint32_t*)resizedFrameBuffer.pixels;
            
            int outRow = 0;
            int outColumn = 0;
            
            for (int i=0; i < numOutputPixels; i++) {
                if ((i > 0) && ((i % resizedFrameBuffer.width) == 0)) {
                    outRow += 1;
                    outColumn = 0;
                }
                
                // Divide by 2 to get the column/row in the input framebuffer
                int inColumn = outColumn / 2;
                int inRow = outRow / 2;
                
                // Get the pixel for the row and column this output pixel corresponds to
                int inOffset = (inRow * cgFrameBuffer.width) + inColumn;
                uint32_t pixel = inPixels32[inOffset];
                
                outPixels32[i] = pixel;
                
                //fprintf(stdout, "Wrote 0x%.10X for 2x row/col %d %d (%d), read from row/col %d %d (%d)\n", pixel, outRow, outColumn, i, inRow, inColumn, inOffset);
                
                outColumn += 1;
            }
        } else {
            // USe CG layer to double size and scale the pixels in the original image
            
            frameImage = [cgFrameBuffer createCGImageRef];
            worked = (frameImage != nil);
            //assert(worked);
            
            [resizedFrameBuffer clear];
            [resizedFrameBuffer renderCGImage:frameImage];
            
            if (frameImage) {
                CGImageRelease(frameImage);
                //assert(cgFrameBuffer.isLockedByDataProvider == FALSE);
            }
        }
        
        frameImage = [resizedFrameBuffer createCGImageRef];
        worked = (frameImage != nil);
        //assert(worked);
        
        BOOL isKeyframe = FALSE;
        if (frameIndex == 0) {
            isKeyframe = TRUE;
        }
        
        process_frame_file(fileWriter, NULL, frameImage, frameIndex, mvidFileMetaData, isKeyframe, NULL);
        
        if (frameImage) {
            CGImageRelease(frameImage);
        }
        
        //[pool drain];
    }
    
    [fileWriter rewriteHeader];
    [fileWriter close];
    
    fprintf(stdout, "Wrote: %s\n", [fileWriter.mvidPath UTF8String]);
    return;
}

// The "-4up IN.mvid" command writes "IN_q1.mvid IN_q2.mvid IN_q3.mvid IN_q4.mvid"
// after splitting each frame up into its own movie.

void
fourupMvidMovie(char *inMvidFilenameCstr)
{
    NSString *inMvidPath = [NSString stringWithUTF8String:inMvidFilenameCstr];
    NSString *prefix;
    
    // Generate prefix without .mvid
    {
        NSArray *elements = [inMvidPath componentsSeparatedByString:@".mvid"];
        prefix = [NSString stringWithFormat:@"%@", elements[0]];
    }
    
    NSString *outQ1MvidPath = [NSString stringWithFormat:@"%@_q1.mvid", prefix];
    NSString *outQ2MvidPath = [NSString stringWithFormat:@"%@_q2.mvid", prefix];
    NSString *outQ3MvidPath = [NSString stringWithFormat:@"%@_q3.mvid", prefix];
    NSString *outQ4MvidPath = [NSString stringWithFormat:@"%@_q4.mvid", prefix];
    
    BOOL isMvid;
    isMvid = [inMvidPath hasSuffix:@".mvid"];
    
    if (isMvid == FALSE) {
        fprintf(stderr, "%s", USAGE);
        exit(1);
    }
    
    NSArray *outMvidPaths = @[outQ1MvidPath, outQ2MvidPath, outQ3MvidPath, outQ4MvidPath];
    
    // Read in existing file into from the input file and create an output file
    // that has exactly the same options.
    
    AVMvidFrameDecoder *frameDecoder = [AVMvidFrameDecoder aVMvidFrameDecoder];
    
    BOOL worked = [frameDecoder openForReading:inMvidPath];
    
    if (worked == FALSE) {
        fprintf(stderr, "error: cannot open input mvid filename \"%s\"\n", [inMvidPath UTF8String]);
        exit(1);
    }
    
    worked = [frameDecoder allocateDecodeResources];
    //assert(worked);
    
    NSUInteger numFrames = [frameDecoder numFrames];
    //assert(numFrames > 0);
    
    float frameDuration = [frameDecoder frameDuration];
    
    int bpp = [frameDecoder header]->bpp;
    
    int width = [frameDecoder width];
    int height = [frameDecoder height];
    //assert(width > 0);
    //assert(height > 0);
    
    // Make sure the input frame can be split in half both ways
    
    if ((width % 2) != 0) {
        fprintf(stderr, "input width %d must be even number of pxiels", width);
        exit(1);
    }
    if ((height % 2) != 0) {
        fprintf(stderr, "input height %d must be even number of pxiels", height);
        exit(1);
    }
    
    // Writer that will write the RGB values. Note that invoking process_frame_file()
    // will define the output width/height based on the size of the image passed in.
    
    NSMutableArray *metadataArr = [NSMutableArray array];
    NSMutableArray *writerArr = [NSMutableArray array];
    
    for (int i = 0; i < 4; i++) {
        MvidFileMetaData *mvidFileMetaData = [MvidFileMetaData mvidFileMetaData];
        mvidFileMetaData.bpp = bpp;
        mvidFileMetaData.checkAlphaChannel = FALSE;
        [metadataArr addObject:mvidFileMetaData];
        
        AVMvidFileWriter *fileWriter = makeMVidWriter(outMvidPaths[i], bpp, frameDuration, numFrames);
        [writerArr addObject:fileWriter];
    }
    
    int qWidth = width / 2;
    int qHeight = height / 2;
    //assert(width > 0);
    //assert(height > 0);
    
    CGFrameBuffer *qFrameBuffer = [CGFrameBuffer cGFrameBufferWithBppDimensions:bpp width:qWidth height:qHeight];
    
    for (NSUInteger frameIndex = 0; frameIndex < numFrames; frameIndex++) {
        //NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        
        AVCustomFrame *frame = [frameDecoder advanceToFrame:frameIndex];
        //assert(frame);
        
        // Release the NSImage ref inside the frame since we will operate on the CG image directly.
        frame.image = nil;
        
        CGFrameBuffer *cgFrameBuffer = frame.cgFrameBuffer;
        //assert(cgFrameBuffer);
        
        // sRGB support
        
        if (frameIndex == 0) {
            qFrameBuffer.colorspace = cgFrameBuffer.colorspace;
        }
        
        // Copy/Scale input image into resizedFrameBuffer
        
        BOOL worked;
        
        for (int i = 0; i < 4; i++) {
            AVMvidFileWriter *fileWriter = writerArr[i];
            MvidFileMetaData *mvidFileMetaData = metadataArr[i];
            
            int cx;
            int cy;
            
            if (i == 0) {
                cx = 0;
                cy = 0;
            } else if (i == 1) {
                cx = qWidth;
                cy = 0;
            } else if (i == 2) {
                cx = 0;
                cy = qHeight;
            } else if (i == 3) {
                cx = qWidth;
                cy = qHeight;
            } else {
                //assert(0);
            }
            
            [qFrameBuffer cropCopyPixels:cgFrameBuffer cropX:cx cropY:cy];
            
            // Render quarter image
            
            CGImageRef qFrameImage = [qFrameBuffer createCGImageRef];
            worked = (qFrameImage != nil);
            //assert(worked);
            
            // Force all keyframes
            
            BOOL isKeyframe = TRUE;
            
            process_frame_file(fileWriter, NULL, qFrameImage, frameIndex, mvidFileMetaData, isKeyframe, NULL);
            
            if (qFrameImage) {
                CGImageRelease(qFrameImage);
            }
        }
        
        //[pool drain];
    }
    
    for (int i = 0; i < 4; i++) {
        AVMvidFileWriter *fileWriter = writerArr[i];
        
        [fileWriter rewriteHeader];
        [fileWriter close];
        
        fprintf(stdout, "Wrote: %s\n", [fileWriter.mvidPath UTF8String]);
    }
    
    return;
}

// This method provides an easy command line operation that will upgrade from
// v1 to v2. This change is a nasty one because the file format changed in
// a way that makes it impossible to support loading the old format. The
// code that needed to change was duplicated so that only the upgrade
// operation would need to deal with this horror show. The
// new file will be written with the most recent version number. If specific
// file format changes are needed, then will be implemented when the new file
// is written. This method writes to a tmp file and then the existing mvid
// file is replace by the tmp file once the operation is complete.

void
upgradeMvidMovie(char *inMvidFilenameCstr, char *optionalMvidFilenameCstr)
{
    NSString *inMvidPath = [NSString stringWithUTF8String:inMvidFilenameCstr];
    NSString *outMvidPath;
    
    BOOL isMvid;
    
    isMvid = [inMvidPath hasSuffix:@".mvid"];
    
    if (isMvid == FALSE) {
        fprintf(stderr, "%s", USAGE);
        exit(1);
    }
    
    BOOL writingToOptionalFile = FALSE;
    
    if (optionalMvidFilenameCstr != NULL) {
        outMvidPath = [NSString stringWithUTF8String:optionalMvidFilenameCstr];
        
        isMvid = [outMvidPath hasSuffix:@".mvid"];
        
        writingToOptionalFile = TRUE;
    } else {
        outMvidPath = @"tmp.mvid";
    }
    
    if (isMvid == FALSE) {
        fprintf(stderr, "%s", USAGE);
        exit(1);
    }
    
    // Read in existing file into from the input file and create an output file
    // that has exactly the same options.
    
    AVMvidFrameDecoder *frameDecoder = [AVMvidFrameDecoder aVMvidFrameDecoder];
    
    frameDecoder.upgradeFromV1 = TRUE;
    
    BOOL worked = [frameDecoder openForReading:inMvidPath];
    
    if (worked == FALSE) {
        fprintf(stderr, "error: cannot open input mvid filename \"%s\"\n", [inMvidPath UTF8String]);
        exit(1);
    }
    
    // Check for upgrade from version 1 or 0 to version 2.
    
    MVFileHeader *header = [frameDecoder header];
    int version = maxvid_file_version(header);
    if (version == MV_FILE_VERSION_ZERO || version == MV_FILE_VERSION_ONE) {
        // Success
    } else {
        fprintf(stderr, "error: cannot upgrade mvid file version %d to version 2\n", version);
        exit(1);
    }
    
    worked = [frameDecoder allocateDecodeResources];
    //assert(worked);
    
    NSUInteger numFrames = [frameDecoder numFrames];
    //assert(numFrames > 0);
    
    float frameDuration = [frameDecoder frameDuration];
    
    int bpp = [frameDecoder header]->bpp;
    
    //int width = [frameDecoder width];
    //int height = [frameDecoder height];
    
    // Writer that will write the RGB values. Note that invoking process_frame_file()
    // will define the width/height on the output.
    
    MvidFileMetaData *mvidFileMetaData = [MvidFileMetaData mvidFileMetaData];
    mvidFileMetaData.bpp = bpp;
    mvidFileMetaData.checkAlphaChannel = FALSE;
    
    AVMvidFileWriter *fileWriter = makeMVidWriter(outMvidPath, bpp, frameDuration, numFrames);
    
    for (NSUInteger frameIndex = 0; frameIndex < numFrames; frameIndex++) {
        //NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        
        AVCustomFrame *frame = [frameDecoder advanceToFrame:frameIndex];
        //assert(frame);
        
        // Release the NSImage ref inside the frame since we will operate on the CG image directly.
        frame.image = nil;
        
        CGFrameBuffer *cgFrameBuffer = frame.cgFrameBuffer;
        //assert(cgFrameBuffer);
        
        BOOL worked;
        CGImageRef frameImage = nil;
        
        frameImage = [cgFrameBuffer createCGImageRef];
        worked = (frameImage != nil);
        //assert(worked);
        
        BOOL isKeyframe = FALSE;
        if (frameIndex == 0) {
            isKeyframe = TRUE;
        }
        
        process_frame_file(fileWriter, NULL, frameImage, frameIndex, mvidFileMetaData, isKeyframe, NULL);
        
        if (frameImage) {
            CGImageRelease(frameImage);
        }
        
        //[pool drain];
    }
    
    [fileWriter rewriteHeader];
    [fileWriter close];
    
    // tmp file is written now, remove the original (old) .mvid and replace it with the upgraded file.
    
    if (writingToOptionalFile == FALSE) {
        worked = [[NSFileManager defaultManager] removeItemAtPath:inMvidPath error:nil];
        //assert(worked);
        
        worked = [[NSFileManager defaultManager] moveItemAtPath:outMvidPath toPath:inMvidPath error:nil];
        //assert(worked);
        
        fprintf(stdout, "Wrote %s\n", [inMvidPath UTF8String]);
    } else {
        fprintf(stdout, "Wrote %s\n", [outMvidPath UTF8String]);
    }
    
    return;
}

// Print the best FPS specification given the floating point framerate.
// For example, 24 FPS is about 0.0417 seconds, this is displayed
// as "24/1" in the output of this method.

void printMvidFPS(NSString *mvidFilename)
{
    BOOL worked;
    
    AVMvidFrameDecoder *frameDecoder = [AVMvidFrameDecoder aVMvidFrameDecoder];
    
    worked = [frameDecoder openForReading:mvidFilename];
    
    if (worked == FALSE) {
        fprintf(stderr, "error: cannot open mvid filename \"%s\"\n", [mvidFilename UTF8String]);
        exit(1);
    }
    
    worked = [frameDecoder allocateDecodeResources];
    //assert(worked);
    
    NSUInteger numFrames = [frameDecoder numFrames];
    //assert(numFrames > 0);
    
    NSTimeInterval framerate = frameDecoder.frameDuration;
    
    // Check for very common framerates
    
    float epsilon = 0.0001f;
    
    char buffer[256];
    
    if (fabs(1.0 - framerate) <= epsilon) {
        // 1 FPS
        snprintf(buffer, sizeof(buffer), "1/1");
    } else if (fabs(1.0f/2.0f - framerate) <= epsilon) {
        // 2 FPS
        snprintf(buffer, sizeof(buffer), "2/1");
    } else if (fabs(1.0f/10.0f - framerate) <= epsilon) {
        // 10 FPS
        snprintf(buffer, sizeof(buffer), "10/1");
    } else if (fabs(1.0f/12.0f - framerate) <= epsilon) {
        // 12 FPS
        snprintf(buffer, sizeof(buffer), "12/1");
    } else if (fabs(1.0f/15.0f - framerate) <= epsilon) {
        // 15 FPS
        snprintf(buffer, sizeof(buffer), "15/1");
    } else if (fabs(1.0f/(1000.0f/1001.0f) - framerate) <= epsilon) {
        // 23.98 FPS = 1000/1001 (NTSC film)
        snprintf(buffer, sizeof(buffer), "1000/1001");
    } else if (fabs(1.0f/24.0f - framerate) <= epsilon) {
        // 24 FPS
        snprintf(buffer, sizeof(buffer), "24/1");
    } else if (fabs(1.0f/(30000.0f/1001.0f) - framerate) <= epsilon) {
        // 29.97 FPS = 30000/1001
        snprintf(buffer, sizeof(buffer), "30000/1001");
    } else if (fabs(1.0f/30.0f - framerate) <= epsilon) {
        // 30 FPS
        snprintf(buffer, sizeof(buffer), "30/1");
    } else if (fabs(1.0f/50.0f - framerate) <= epsilon) {
        // 50 FPS
        snprintf(buffer, sizeof(buffer), "50/1");
    } else if (fabs(1.0f/(60000.0f/1001.0f) - framerate) <= epsilon) {
        // 59.94 FPS = 60000/1001
        snprintf(buffer, sizeof(buffer), "60000/1001");
    } else if (fabs(1.0f/60.0f - framerate) <= epsilon) {
        // 60 FPS
        snprintf(buffer, sizeof(buffer), "60/1");
    } else {
        // Get as close as possible in terms of 1000 units
        float oneThousandth = 1.0f / 1000.0f;
        int i = 0;
        for ( ; (oneThousandth * i) < framerate; i++) {
            //fprintf(stdout, "%0.8f ?< %0.8f\n", (oneThousandth * i), framerate);
        }
        //fprintf(stdout, "%0.8f ?< %0.8f\n", (oneThousandth * i), framerate);
        snprintf(buffer, sizeof(buffer), "%d/1000", i);
    }
    
    fprintf(stdout, "%s\n", buffer);
    
    [frameDecoder close];
    
    return;
}

// Adler for each frame of video

void printMvidFrameAdler(NSString *mvidFilename)
{
    BOOL worked;
    
    AVMvidFrameDecoder *frameDecoder = [AVMvidFrameDecoder aVMvidFrameDecoder];
    
    worked = [frameDecoder openForReading:mvidFilename];
    
    if (worked == FALSE) {
        fprintf(stderr, "error: cannot open mvid filename \"%s\"\n", [mvidFilename UTF8String]);
        exit(1);
    }
    
    worked = [frameDecoder allocateDecodeResources];
    //assert(worked);
    
    NSUInteger numFrames = [frameDecoder numFrames];
    //assert(numFrames > 0);
    
    int isV3 = (maxvid_file_version([frameDecoder header]) == MV_FILE_VERSION_THREE);
    
    //fprintf(stdout, "%s\n", [[mvidFilename lastPathComponent] UTF8String]);
    
    uint32_t lastAdler = 0x0;
    
    if (isV3) {
        for (NSUInteger frameIndex = 0; frameIndex < numFrames; frameIndex++) {
            // NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
            
            MVV3Frame *frame = maxvid_v3_file_frame(frameDecoder.mvFrames, frameIndex);
            //assert(frame);
            
            uint32_t currentAdler = frame->adler;
            
#if MV_ENABLE_DELTAS
            if (frameIndex == 0 && [frameDecoder isDeltas]) {
                // A nop delta frame is a special case in that it contains an adler
                // that corresponds to all black pixels.
                
                lastAdler = currentAdler;
            } else // note that the else/if here is only enabled in deltas mode
#endif // MV_ENABLE_DELTAS
                if (maxvid_v3_frame_isnopframe(frame)) {
                    currentAdler = lastAdler;
                } else {
                    lastAdler = currentAdler;
                }
            
            fprintf(stdout, "0x%X\n", currentAdler);
            
            //[pool drain];
        }
    } else {
        for (NSUInteger frameIndex = 0; frameIndex < numFrames; frameIndex++) {
            //NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
            
            MVFrame *frame = maxvid_file_frame(frameDecoder.mvFrames, frameIndex);
            //assert(frame);
            
            uint32_t currentAdler = frame->adler;
            
#if MV_ENABLE_DELTAS
            if (frameIndex == 0 && [frameDecoder isDeltas]) {
                // A nop delta frame is a special case in that it contains an adler
                // that corresponds to all black pixels.
                
                lastAdler = currentAdler;
            } else // note that the else/if here is only enabled in deltas mode
#endif // MV_ENABLE_DELTAS
                if (maxvid_frame_isnopframe(frame)) {
                    currentAdler = lastAdler;
                } else {
                    lastAdler = currentAdler;
                }
            
            fprintf(stdout, "0x%X\n", currentAdler);
            
            //[pool drain];
        }
    }
    
    [frameDecoder close];
    
    return;
}

// This method will iterate over each frame, then each row and print the
// pixel values as hex and decoded RGB values. This is useful when debugging
// RGB conversion logic.

void printMvidPixels(NSString *mvidPath)
{
    BOOL worked;
    
    AVMvidFrameDecoder *frameDecoder = [AVMvidFrameDecoder aVMvidFrameDecoder];
    
    worked = [frameDecoder openForReading:mvidPath];
    
    if (worked == FALSE) {
        fprintf(stderr, "error: cannot open mvid filename \"%s\"\n", [mvidPath UTF8String]);
        exit(1);
    }
    
    worked = [frameDecoder allocateDecodeResources];
    //assert(worked);
    
    NSUInteger numFrames = [frameDecoder numFrames];
    //assert(numFrames > 0);
    
    for (NSUInteger frameIndex = 0; frameIndex < numFrames; frameIndex++) {
        // NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        
        AVCustomFrame *frame = [frameDecoder advanceToFrame:frameIndex];
        //assert(frame);
        
        // Release the NSImage ref inside the frame since we will operate on the CG image directly.
        frame.image = nil;
        
        CGFrameBuffer *cgFrameBuffer = frame.cgFrameBuffer;
        //assert(cgFrameBuffer);
        
        if (frameIndex == 0) {
            fprintf(stdout, "File %s, %dBPP, %d FRAMES\n", [[mvidPath lastPathComponent] UTF8String], (int)cgFrameBuffer.bitsPerPixel, (int)numFrames);
        }
        
        if (frame.isDuplicate) {
            fprintf(stdout, "FRAME %d (duplicate)\n", frameIndex+1);
        } else {
            fprintf(stdout, "FRAME %d\n", frameIndex+1);
            
            // Iterate over the pixel contents of the framebuffer
            
            int numPixels = cgFrameBuffer.width * cgFrameBuffer.height;
            
            uint16_t *pixel16Ptr = (uint16_t*)cgFrameBuffer.pixels;
            uint32_t *pixel32Ptr = (uint32_t*)cgFrameBuffer.pixels;
            
            int row = 0;
            int column = 0;
            for (int pixeli = 0; pixeli < numPixels; pixeli++) {
                
                if ((pixeli % cgFrameBuffer.width) == 0) {
                    // At the first pixel in a new row
                    column = 0;
                    
                    fprintf(stdout, "ROW %d\n", row);
                    row += 1;
                }
                
                fprintf(stdout, "COLUMN %d: ", column);
                column += 1;
                
                if (cgFrameBuffer.bitsPerPixel == 16) {
                    uint16_t pixel = *pixel16Ptr++;
                    
#define CG_MAX_5_BITS 0x1F
                    
                    uint8_t red = (pixel >> 10) & CG_MAX_5_BITS;
                    uint8_t green = (pixel >> 5) & CG_MAX_5_BITS;
                    uint8_t blue = pixel & CG_MAX_5_BITS;
                    
                    fprintf(stdout, "HEX 0x%0.4X, RGB = (%d, %d, %d)\n", pixel, red, green, blue);
                } else if (cgFrameBuffer.bitsPerPixel == 24) {
                    uint32_t pixel = *pixel32Ptr++;
                    
                    uint8_t red = (pixel >> 16) & 0xFF;
                    uint8_t green = (pixel >> 8) & 0xFF;
                    uint8_t blue = pixel & 0xFF;
                    
                    fprintf(stdout, "HEX 0x%0.6X, RGB = (%d, %d, %d)\n", pixel, red, green, blue);
                } else {
                    uint32_t pixel = *pixel32Ptr++;
                    
                    uint8_t alpha = (pixel >> 24) & 0xFF;
                    uint8_t red = (pixel >> 16) & 0xFF;
                    uint8_t green = (pixel >> 8) & 0xFF;
                    uint8_t blue = pixel & 0xFF;
                    
                    fprintf(stdout, "HEX 0x%0.8X, RGBA = (%d, %d, %d, %d)\n", pixel, red, green, blue, alpha);
                }
            }
        }
        
        fflush(stdout);
        
        //[pool drain];
    }
    
    [frameDecoder close];
}

// This method will "map" certain alpha values to a new value based on the input
// specification. This operation is not so easy to implement with 3rd party
// software though it is conceptually simple. This method would typically be used
// to "clamp" alpha values near the opaque value to the actual opaque value.
// For example, if a green screen video was processed in a non-optimal way, pixels
// that really should have an alpha value of 255 (opaque) might have the values
// 254, 253, or even 252. This method makes it easy to map these values below
// the opaque value to the opaque value by passing "252,253,254=255" as
// the map spec.

void alphaMapMvid(NSString *inMvidPath,
                  NSString *outMvidPath,
                  NSString *mapSpecStr)
{
    BOOL isMvid;
    
    isMvid = [inMvidPath hasSuffix:@".mvid"];
    
    if (isMvid == FALSE) {
        fprintf(stderr, "%s", USAGE);
        exit(1);
    }
    
    isMvid = [outMvidPath hasSuffix:@".mvid"];
    
    if (isMvid == FALSE) {
        fprintf(stderr, "%s", USAGE);
        exit(1);
    }
    
    // Check the "MAPSPEC". The format is like so:
    //
    // 252=255
    //
    // NUM=VALUE
    //
    // 1 to N
    //
    // Could include multiple mappings
    //
    // 1=0,2=0,253=255,254=255
    
    NSMutableDictionary *mappings = [NSMutableDictionary dictionary];
    
    NSArray *elements = [mapSpecStr componentsSeparatedByString:@","];
    
    for (NSString *element in elements) {
        NSArray *singleSpecElements = [element componentsSeparatedByString:@"="];
        int count = [singleSpecElements count];
        if (count != 2) {
            fprintf(stderr, "MAPSPEC must contain 1 to N integer elements of the form IN=OUT, got \"%s\"\n", [element UTF8String]);
            exit(1);
        }
        // Store the input mapping number and the output number it maps to
        NSString *inNumStr = [singleSpecElements objectAtIndex:0];
        NSString *outNumStr = [singleSpecElements objectAtIndex:1];
        
        NSInteger inInt;
        NSInteger outInt;
        
        if ([inNumStr isEqualToString:@"0"]) {
            inInt = 0;
        } else {
            inInt = [inNumStr integerValue];
            if (inInt == 0) {
                inInt = -1;
            }
        }
        
        if ([outNumStr isEqualToString:@"0"]) {
            outInt = 0;
        } else {
            outInt = [outNumStr integerValue];
            if (outInt == 0) {
                outInt = -1;
            }
        }
        
        if (outInt < 0 || inInt < 0) {
            fprintf(stderr, "MAPSPEC must contain 1 to N integer elements of the form IN=OUT, got \"%s\"\n", [element UTF8String]);
            exit(1);
        }
        
        if (outInt > 255 || inInt > 255) {
            fprintf(stderr, "MAPSPEC IN=OUT values must be in range 0->255, got \"%s\"\n", [element UTF8String]);
            exit(1);
        }
        
        NSNumber *inNum = [NSNumber numberWithInteger:inInt];
        NSNumber *outNum = [NSNumber numberWithInteger:outInt];
        
        [mappings setObject:outNum forKey:inNum];
    }
    
    if ([mappings count] == 0) {
        fprintf(stderr, "No MAPSPEC elements parsed\n");
        exit(1);
    }
    
    fprintf(stdout, "processing input file, will apply %d alpha channel mapping(s)\n", (int)[mappings count]);
    
    // Read in existing file into from the input file and create an output file
    // that has exactly the same options.
    
    AVMvidFrameDecoder *frameDecoder = [AVMvidFrameDecoder aVMvidFrameDecoder];
    
    BOOL worked = [frameDecoder openForReading:inMvidPath];
    
    if (worked == FALSE) {
        fprintf(stderr, "error: cannot open input mvid filename \"%s\"\n", [inMvidPath UTF8String]);
        exit(1);
    }
    
    worked = [frameDecoder allocateDecodeResources];
    //assert(worked);
    
    NSUInteger numFrames = [frameDecoder numFrames];
    //assert(numFrames > 0);
    
    float frameDuration = [frameDecoder frameDuration];
    
    int bpp = [frameDecoder header]->bpp;
    
    if (bpp != 32) {
        fprintf(stderr, "-alphamap can only be used on a 32BPP mvid file since an alpha channel is required\n");
        exit(1);
    }
    
    int width = [frameDecoder width];
    int height = [frameDecoder height];
    
    // Writer that will write the RGB values. Note that invoking process_frame_file()
    // will define the output width/height based on the size of the image passed in.
    
    MvidFileMetaData *mvidFileMetaData = [MvidFileMetaData mvidFileMetaData];
    mvidFileMetaData.bpp = bpp;
    mvidFileMetaData.checkAlphaChannel = FALSE;
    
    AVMvidFileWriter *fileWriter = makeMVidWriter(outMvidPath, bpp, frameDuration, numFrames);
    
    CGFrameBuffer *mappedFrameBuffer = [CGFrameBuffer cGFrameBufferWithBppDimensions:bpp width:width height:height];
    
    uint32_t numPixelsModified = 0;
    
    for (NSUInteger frameIndex = 0; frameIndex < numFrames; frameIndex++) {
        //NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        
        AVCustomFrame *frame = [frameDecoder advanceToFrame:frameIndex];
        //assert(frame);
        
        // Release the NSImage ref inside the frame since we will operate on the CG image directly.
        frame.image = nil;
        
        CGFrameBuffer *cgFrameBuffer = frame.cgFrameBuffer;
        //assert(cgFrameBuffer);
        
        // sRGB support
        
        if (frameIndex == 0) {
            mappedFrameBuffer.colorspace = cgFrameBuffer.colorspace;
        }
        
        // Copy image area into mappedFrameBuffer
        
        BOOL worked;
        CGImageRef frameImage = nil;
        
        frameImage = [cgFrameBuffer createCGImageRef];
        worked = (frameImage != nil);
        //assert(worked);
        
        [mappedFrameBuffer clear];
        worked = [mappedFrameBuffer renderCGImage:frameImage];
        //assert(worked);
        
        if (frameImage) {
            CGImageRelease(frameImage);
        }
        
        // Do mapping logic by iterating over all the pixels in mappedFrameBuffer
        // and then editing the pixels in place if needed.
        
        int numPixels = mappedFrameBuffer.width * mappedFrameBuffer.height;
        
        uint32_t *pixel32Ptr = (uint32_t*)mappedFrameBuffer.pixels;
        
        for (int pixeli = 0; pixeli < numPixels; pixeli++) {
            uint32_t pixel = pixel32Ptr[pixeli];
            
            uint32_t alpha = (pixel >> 24) & 0xFF;
            uint32_t red = (pixel >> 16) & 0xFF;
            uint32_t green = (pixel >> 8) & 0xFF;
            uint32_t blue = pixel & 0xFF;
            
            // Check to see if the alpha value appears in the map
            
            NSNumber *keyNum = [NSNumber numberWithInteger:(NSInteger)alpha];
            NSNumber *valueNum = [mappings objectForKey:keyNum];
            
            if (valueNum != nil) {
                // This value appears in the mapping, get the new alpha value, combine
                // it with the existing RGB values and write the pixel back into the framebuffer.
                
                NSInteger mappedAlpha = [valueNum integerValue];
                uint32_t mappedUnsigned = (uint32_t)mappedAlpha;
                
                pixel = (mappedUnsigned << 24) | (red << 16) | (green << 8) | blue;
                
                pixel32Ptr[pixeli] = pixel;
                numPixelsModified += 1;
            }
        }
        
        // Now create a UIImage so that the result of this operation can be encoded into the output mvid
        
        frameImage = [mappedFrameBuffer createCGImageRef];
        worked = (frameImage != nil);
        //assert(worked);
        
        BOOL isKeyframe = FALSE;
        if (frameIndex == 0) {
            isKeyframe = TRUE;
        }
        
        process_frame_file(fileWriter, NULL, frameImage, frameIndex, mvidFileMetaData, isKeyframe, NULL);
        
        if (frameImage) {
            CGImageRelease(frameImage);
        }
        
        //[pool drain];
    }
    
    [fileWriter rewriteHeader];
    [fileWriter close];
    
    fprintf(stdout, "Mapped %d pixels to new values\n", numPixelsModified);
    fprintf(stdout, "Wrote %s\n", [fileWriter.mvidPath UTF8String]);
    return;
}

// Execute rdelta, this is basically a diff of an original (uncompressed) as compared
// to a compressed representation. The compressed implementation uses much less space
// than the original, but how much compression is too much? This logic attempts to
// visually show which pixels have been changed by the compression. The pixels written
// to the output mvid are the same ones in the inModifiedMvidPath argument, except that
// diffs as compared to inOriginalMvidPath will be displayed with a 50% red overlay.

void rdeltaMvidMovie(char *inOriginalMvidPathCstr,
                     char *inModifiedMvidPathCstr,
                     char *outMvidPathCstr)
{
    BOOL isMvid;
    
    NSString *inOriginalMvidPath = [NSString stringWithUTF8String:inOriginalMvidPathCstr];
    NSString *inModifiedMvidPath = [NSString stringWithUTF8String:inModifiedMvidPathCstr];
    NSString *outMvidPath = [NSString stringWithUTF8String:outMvidPathCstr];
    
    isMvid = [inOriginalMvidPath hasSuffix:@".mvid"];
    
    if (isMvid == FALSE) {
        fprintf(stderr, "%s", USAGE);
        exit(1);
    }
    
    isMvid = [inModifiedMvidPath hasSuffix:@".mvid"];
    
    if (isMvid == FALSE) {
        fprintf(stderr, "%s", USAGE);
        exit(1);
    }
    
    isMvid = [outMvidPath hasSuffix:@".mvid"];
    
    if (isMvid == FALSE) {
        fprintf(stderr, "%s", USAGE);
        exit(1);
    }
    
    // Read in existing original and compressed files
    
    AVMvidFrameDecoder *frameDecoderOriginal = [AVMvidFrameDecoder aVMvidFrameDecoder];
    AVMvidFrameDecoder *frameDecoderCompressed = [AVMvidFrameDecoder aVMvidFrameDecoder];
    
    BOOL worked;
    worked = [frameDecoderOriginal openForReading:inOriginalMvidPath];
    
    if (worked == FALSE) {
        fprintf(stderr, "error: cannot open input mvid filename \"%s\"\n", inOriginalMvidPathCstr);
        exit(1);
    }
    
    worked = [frameDecoderCompressed openForReading:inModifiedMvidPath];
    
    if (worked == FALSE) {
        fprintf(stderr, "error: cannot open input mvid filename \"%s\"\n", inModifiedMvidPathCstr);
        exit(1);
    }
    
    worked = [frameDecoderOriginal allocateDecodeResources];
    //assert(worked);
    
    worked = [frameDecoderCompressed allocateDecodeResources];
    //assert(worked);
    
    NSUInteger numFrames = [frameDecoderOriginal numFrames];
    //assert(numFrames > 0);
    
    NSUInteger compressedNumFrames = [frameDecoderCompressed numFrames];
    if (numFrames != compressedNumFrames) {
        fprintf(stderr, "rdelta failed: original mvid contains %d frames while compressed mvid contains %d frames\n", numFrames, compressedNumFrames);
        exit(1);
    }
    
    float frameDuration = [frameDecoderOriginal frameDuration];
    float compressedFrameDuration = [frameDecoderCompressed frameDuration];
    
    if (frameDuration != compressedFrameDuration) {
        fprintf(stderr, "rdelta failed: original mvid framerate %.4f while compressed framerate is %.4f\n", frameDuration, compressedFrameDuration);
        exit(1);
    }
    
    int bpp = [frameDecoderOriginal header]->bpp;
    int compressedBpp = [frameDecoderCompressed header]->bpp;
    
    if (bpp != compressedBpp) {
        fprintf(stderr, "rdelta failed: original mvid bpp %d while compressed bpp is %d\n", bpp, compressedBpp);
        exit(1);
    }
    
    int width = [frameDecoderOriginal width];
    int height = [frameDecoderOriginal height];
    
    int compressedWidth = [frameDecoderCompressed width];
    int compressedHeight = [frameDecoderCompressed height];
    
    if ((compressedWidth != width) || (compressedHeight != height)) {
        fprintf(stderr, "rdelta failed: original mvid width x height %d x %d while compressed mvid width x height %d x %d\n", width, height, compressedWidth, compressedHeight);
        exit(1);
    }
    
    // Writer that will write the RGB values. Note that invoking process_frame_file()
    // will define the output width/height based on the size of the image passed in.
    
    MvidFileMetaData *mvidFileMetaData = [MvidFileMetaData mvidFileMetaData];
    mvidFileMetaData.bpp = bpp;
    mvidFileMetaData.checkAlphaChannel = FALSE;
    
    AVMvidFileWriter *fileWriter = makeMVidWriter(outMvidPath, bpp, frameDuration, numFrames);
    
    CGFrameBuffer *outFrameBuffer = [CGFrameBuffer cGFrameBufferWithBppDimensions:bpp width:width height:height];
    CGFrameBuffer *redFrameBuffer = [CGFrameBuffer cGFrameBufferWithBppDimensions:32 width:width height:height];
    
    uint32_t numPixelsModified = 0;
    
    for (NSUInteger frameIndex = 0; frameIndex < numFrames; frameIndex++) {
        //NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        
        AVCustomFrame *originalFrame = [frameDecoderOriginal advanceToFrame:frameIndex];
        //assert(originalFrame);
        
        AVCustomFrame *compressedFrame = [frameDecoderCompressed advanceToFrame:frameIndex];
        //assert(compressedFrame);
        
        // Release the NSImage ref inside the frame since we will operate on the CG image directly.
        originalFrame.image = nil;
        compressedFrame.image = nil;
        
        CGFrameBuffer *originalCgFrameBuffer = originalFrame.cgFrameBuffer;
        //assert(originalCgFrameBuffer);
        
        CGFrameBuffer *compressedCgFrameBuffer = compressedFrame.cgFrameBuffer;
        //assert(originalCgFrameBuffer);
        
        // sRGB support
        
        if (frameIndex == 0) {
            outFrameBuffer.colorspace = compressedCgFrameBuffer.colorspace;
            redFrameBuffer.colorspace = compressedCgFrameBuffer.colorspace;
        }
        
        // Copy compressed image data into the output framebuffer
        
        BOOL worked;
        CGImageRef frameImage = nil;
        
        frameImage = [compressedCgFrameBuffer createCGImageRef];
        worked = (frameImage != nil);
        //assert(worked);
        
        [outFrameBuffer clear];
        worked = [outFrameBuffer renderCGImage:frameImage];
        //assert(worked);
        
        if (frameImage) {
            CGImageRelease(frameImage);
        }
        
        // Now iterate over the original and diff pixels and write any diffs to the redFrameBuffer
        
        [redFrameBuffer clear];
        
        int numPixels = width * height;
        
        // FIXME: impl for 16 bpp
        //assert(originalCgFrameBuffer.bitsPerPixel != 16);
        
        uint32_t *originalCgFrameBuffer32Ptr = (uint32_t*)originalCgFrameBuffer.pixels;
        uint32_t *compressedCgFrameBuffer32Ptr = (uint32_t*)compressedCgFrameBuffer.pixels;
        uint32_t *redCgFrameBuffer32Ptr = (uint32_t*)redFrameBuffer.pixels;
        
        for (int pixeli = 0; pixeli < numPixels; pixeli++) {
            uint32_t originalPixel = originalCgFrameBuffer32Ptr[pixeli];
            uint32_t compressedPixel = compressedCgFrameBuffer32Ptr[pixeli];
            
            /*
             uint32_t original_alpha = (originalPixel >> 24) & 0xFF;
             uint32_t original_red = (originalPixel >> 16) & 0xFF;
             uint32_t original_green = (originalPixel >> 8) & 0xFF;
             uint32_t original_blue = originalPixel & 0xFF;
             
             uint32_t compressed_alpha = (compressedPixel >> 24) & 0xFF;
             uint32_t compressed_red = (compressedPixel >> 16) & 0xFF;
             uint32_t compressed_green = (compressedPixel >> 8) & 0xFF;
             uint32_t compressed_blue = compressedPixel & 0xFF;
             */
            
            if (originalPixel != compressedPixel) {
                uint32_t redPixel = rgba_to_bgra(0xFF/2, 0, 0, 0xFF/2);
                redCgFrameBuffer32Ptr[pixeli] = redPixel;
                numPixelsModified++;
            }
        }
        
        // Render red pixels over compressed pixels in outFrameBuffer (matte)
        
        frameImage = [redFrameBuffer createCGImageRef];
        worked = (frameImage != nil);
        //assert(worked);
        
        worked = [outFrameBuffer renderCGImage:frameImage];
        //assert(worked);
        
        if (frameImage) {
            CGImageRelease(frameImage);
        }
        
        // Now create a UIImage so that the result of this operation can be encoded into the output mvid
        
        frameImage = [outFrameBuffer createCGImageRef];
        worked = (frameImage != nil);
        //assert(worked);
        
        BOOL isKeyframe = FALSE;
        if (frameIndex == 0) {
            isKeyframe = TRUE;
        }
        
        process_frame_file(fileWriter, NULL, frameImage, frameIndex, mvidFileMetaData, isKeyframe, NULL);
        
        if (frameImage) {
            CGImageRelease(frameImage);
        }
        
        //[pool drain];
    }
    
    [fileWriter rewriteHeader];
    [fileWriter close];
    
    fprintf(stdout, "Found %d modified pixels\n", numPixelsModified);
    fprintf(stdout, "Wrote %s\n", [fileWriter.mvidPath UTF8String]);
    return;
}

// Flatten will read all of the frames from a movie and write all the frames
// into a single PNG image. The output image will be a multiple of the original
// image height based on the number of frames in the movie.

void
flattenMvidMovie(char *inOriginalMvidFilename, char *outFlatPNGFilename)
{
    NSString *mvidPath = [NSString stringWithUTF8String:inOriginalMvidFilename];
    
    BOOL isMvid = [mvidPath hasSuffix:@".mvid"];
    
    if (isMvid == FALSE) {
        fprintf(stderr, "%s", USAGE);
        exit(1);
    }
    
    AVMvidFrameDecoder *frameDecoder = [AVMvidFrameDecoder aVMvidFrameDecoder];
    
    BOOL worked = [frameDecoder openForReading:mvidPath];
    
    if (worked == FALSE) {
        fprintf(stderr, "error: cannot open mvid filename \"%s\"\n", inOriginalMvidFilename);
        exit(1);
    }
    
    worked = [frameDecoder allocateDecodeResources];
    //assert(worked);
    
    NSUInteger numFrames = [frameDecoder numFrames];
    //assert(numFrames > 0);
    
    //float frameDuration = [frameDecoder frameDuration];
    
    int bpp = [frameDecoder header]->bpp;
    
    int width = [frameDecoder width];
    int height = [frameDecoder height];
    
    // Verify that the input color data has been mapped to the sRGB colorspace.
    
    if (maxvid_file_version([frameDecoder header]) == MV_FILE_VERSION_ZERO) {
        fprintf(stderr, "%s\n", "-mixalpha on MVID is not supported for an old MVID file version 0.");
        exit(1);
    }
    
    // Allocate framebuffer large enought to hold all the output frames in a single image
    
    int outHeight = height * numFrames;
    
    CGFrameBuffer *outFrameBuffer = [CGFrameBuffer cGFrameBufferWithBppDimensions:bpp width:width height:outHeight];
    uint32_t *outPixelsPtr = (uint32_t*)outFrameBuffer.pixels;
    
    for (NSUInteger frameIndex = 0; frameIndex < numFrames; frameIndex++) {
        //NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        
        AVCustomFrame *frame = [frameDecoder advanceToFrame:frameIndex];
        //assert(frame);
        
        // Release the NSImage ref inside the frame since we will operate on the CG image directly.
        frame.image = nil;
        
        CGFrameBuffer *cgFrameBuffer = frame.cgFrameBuffer;
        //assert(cgFrameBuffer);
        
        if (frameIndex == 0) {
            outFrameBuffer.colorspace = cgFrameBuffer.colorspace;
        }
        
        NSUInteger numPixels = cgFrameBuffer.width * cgFrameBuffer.height;
        uint32_t *pixels = (uint32_t*)cgFrameBuffer.pixels;
        
        // Append pixels to outFrameBuffer
        
        int numBytes = numPixels * sizeof(uint32_t);
        memcpy(outPixelsPtr, pixels, numBytes);
        outPixelsPtr += numPixels;
        
        //[pool release];
    }
    
    NSString *pngPath = [NSString stringWithFormat:@"%s", outFlatPNGFilename];
    
    NSData *pngData = [outFrameBuffer formatAsPNG];
    
    [pngData writeToFile:pngPath atomically:NO];
    
    fprintf(stdout, "Wrote %s with size %d x %d\n", outFlatPNGFilename, (int)outFrameBuffer.width, (int)outFrameBuffer.height);
    
    return;
}

// Reverse a flatten operation by reading the framerate and BPP info from a MVID
// reading the new image data from a flat PNG, and then writing the pixels from
// the PNG to and output MVID.

void
unflattenMvidMovie(char *inOriginalMvidFilename, char *inFlatPNGFilename, char *outMvidFilename)
{
    NSString *mvidPath = [NSString stringWithUTF8String:inOriginalMvidFilename];
    
    BOOL isMvid = [mvidPath hasSuffix:@".mvid"];
    
    if (isMvid == FALSE) {
        fprintf(stderr, "%s", USAGE);
        exit(1);
    }
    
    // Open original MVID for reading of header data
    
    AVMvidFrameDecoder *frameDecoder = [AVMvidFrameDecoder aVMvidFrameDecoder];
    
    BOOL worked = [frameDecoder openForReading:mvidPath];
    
    if (worked == FALSE) {
        fprintf(stderr, "error: cannot open mvid filename \"%s\"\n", inOriginalMvidFilename);
        exit(1);
    }
    
    worked = [frameDecoder allocateDecodeResources];
    //assert(worked);
    
    NSUInteger numFrames = [frameDecoder numFrames];
    //assert(numFrames > 0);
    
    float frameDuration = [frameDecoder frameDuration];
    
    int bpp = [frameDecoder header]->bpp;
    
    int width = [frameDecoder width];
    int height = [frameDecoder height];
    
    // Verify that the input color data has been mapped to the sRGB colorspace.
    
    if (maxvid_file_version([frameDecoder header]) == MV_FILE_VERSION_ZERO) {
        fprintf(stderr, "%s\n", "-unflatten on MVID is not supported for an old MVID file version 0.");
        exit(1);
    }
    
    // Read input PNG and verify that the size of the input matches the expected size in pixels
    
    CGImageRef imageRef = NULL;
    
    NSString *inFlatPNGFilenameStr = [NSString stringWithFormat:@"%s", inFlatPNGFilename];
    imageRef = createImageFromFile(inFlatPNGFilenameStr);
    
    if (imageRef == NULL) {
        fprintf(stderr, "error: cannot open flat PNG filename \"%s\"\n", inFlatPNGFilename);
        exit(1);
    }
    
    //assert(imageRef);
    
    // Copy all pixels in input to a framebuffer
    
    int inHeight = height * numFrames;
    
    // Verify height of PNG
    
    if (CGImageGetHeight(imageRef) != inHeight) {
        fprintf(stderr, "error: input flat PNG filename \"%s\" must contain image of height %d not %d\n", inFlatPNGFilename, inHeight, (int)CGImageGetHeight(imageRef));
        exit(1);
    }
    
    if (CGImageGetWidth(imageRef) != width) {
        fprintf(stderr, "error: input flat PNG filename \"%s\" must contain image of width %d not %d\n", inFlatPNGFilename, width, (int)CGImageGetWidth(imageRef));
        exit(1);
    }
    
    CGFrameBuffer *inFrameBuffer = [CGFrameBuffer cGFrameBufferWithBppDimensions:bpp width:width height:inHeight];
    
    // Explicitly use sRGB
    {
        CGColorSpaceRef colorSpace = NULL;
        colorSpace = CGColorSpaceCreateWithName(kCGColorSpaceSRGB);
        //assert(colorSpace);
        inFrameBuffer.colorspace = colorSpace;
        CGColorSpaceRelease(colorSpace);
    }
    
    [inFrameBuffer renderCGImage:imageRef];
    CGImageRelease(imageRef);
    
    uint32_t *inPixelsPtr = (uint32_t*)inFrameBuffer.pixels;
    
    // Open output MVID and duplicate the header settings from the original MVID
    
    MvidFileMetaData *mvidFileMetaData = [MvidFileMetaData mvidFileMetaData];
    mvidFileMetaData.bpp = bpp;
    mvidFileMetaData.checkAlphaChannel = FALSE;
    
    NSString *outMvidPath = [NSString stringWithFormat:@"%s", outMvidFilename];
    
    AVMvidFileWriter *fileWriter = makeMVidWriter(outMvidPath, bpp, frameDuration, numFrames);
    
    fileWriter.movieSize = CGSizeMake(width, height);
    
    // Allocate framebuffer for one frame from the input PNG
    
    CGFrameBuffer *currentFrameBuffer = [CGFrameBuffer cGFrameBufferWithBppDimensions:bpp width:width height:height];
    //assert(currentFrameBuffer);
    
    // Explicitly use sRGB
    {
        CGColorSpaceRef colorSpace = NULL;
        colorSpace = CGColorSpaceCreateWithName(kCGColorSpaceSRGB);
        //assert(colorSpace);
        currentFrameBuffer.colorspace = colorSpace;
        CGColorSpaceRelease(colorSpace);
    }
    
    uint32_t *currentPixelsPtr = (uint32_t*)currentFrameBuffer.pixels;
    
    for (NSUInteger frameIndex = 0; frameIndex < numFrames; frameIndex++) {
        //NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        
        int numBytes = width * height * sizeof(uint32_t);
        memcpy(currentPixelsPtr, inPixelsPtr, numBytes);
        
        inPixelsPtr += (width * height);
        
        CGImageRef frameImage = [currentFrameBuffer createCGImageRef];
        
        BOOL isKeyframe = FALSE;
        if (frameIndex == 0) {
            isKeyframe = TRUE;
        }
        
        // When original video is marked as "all keyframes" then retain this property in the output MVID
        
        if (frameDecoder.isAllKeyframes) {
            isKeyframe = TRUE;
        }
        
        process_frame_file(fileWriter, NULL, frameImage, frameIndex, mvidFileMetaData, isKeyframe, NULL);
        
        if (frameImage) {
            CGImageRelease(frameImage);
        }
        
        //[pool drain];
    }
    
    [fileWriter rewriteHeader];
    [fileWriter close];
    
    fprintf(stdout, "Wrote %s\n", [fileWriter.mvidPath UTF8String]);
    return;
}

/*
int invoke(NSString* firstFilenameStr, NSString* secondFilenameStr)
{
    // Either:
    //
    // mvidmoviemaker FIRSTFRAME.png OUTFILE.mvid ?OPTIONS?
    
    // If the arguments are INFILE.mvid OUTFILE.mvid, then convert video data
    // back to Quicktime format and write to a new movie file.
    
    // The second argument has to be "*.mvid"
    NSString *mvidFilename = secondFilenameStr;
    
    BOOL isMvid = [mvidFilename hasSuffix:@".mvid"];
    
    if (isMvid == FALSE) {
        fprintf(stderr, "%s", USAGE);
        exit(1);
    }
    
    // If the first argument is a .mov file, then this must be
    // a .mov -> .mvid conversion.
    //NSString *movFilename = [NSString stringWithUTF8String:firstFilenameCstr];
    
    BOOL isMov = false;
    
    // Both forms support 1 to N arguments like "-fps 15"
    
    MovieOptions options;
    options.framerate = 0.0417f;
    options.bpp = -1;
    options.keyframe = 10000;
    
    // Otherwise, generate a .mvid from a series of images

    // FIRSTFRAME.png : name of first frame file of input PNG files. All
    //   video frames must exist in the same directory
    // FILE.mvid : name of output file that will contain all the video frames

    // Either -framerate FLOAT or -fps FLOAT is required when build from frames.
    // -fps 15, -fps 29.97, -fps 30 are common values.

    // -bpp is optional, the default is 24 but 32 bpp will be detected if used.
    // If -bpp 16 is indicated then the result pixels will be downsamples from
    // 24 bpp to 16 bpp if the input source is in 24 bpp.

    encodeMvidFromFramesMain(mvidFilenameStr,
                             firstFilenameCstr,
                             &options);
    
    return 0;
}*/

/////////////////END MVIDMAKER CODE////////////////////
@import QuartzCore;

@interface MainCanvasViewController ()<AAPLMovieViewControllerDelegate,AAPLMovieTimelineUpdateDelgate, NSMenuDelegate, NSWindowDelegate, MouseDownTextFieldDelegate, ColorPanelViewControllerDelegate, AddArtistsDelegate, AddProductsDelegate, NSComboBoxDelegate, NSComboBoxDataSource>

@property (strong) InviteUserModalController *inviteWindowController;
@property (strong) SearchUserWindowController *searchUserWindowController;
@property (nonatomic,strong) NSPopover *colorPanelPopover;

@property AAPLMovieMutator *movieMutator;

@property (weak) IBOutlet AAPLMovieTimeline *movieTimeline;
@property CMTimeRange selectedTimeRange;
@property CMTime selectedPointInTime;

@property NSMutableArray* images;
@property NSMutableArray* timeFrames;
@property NSMutableArray* actualTimes;

//@property NSString* currentProjectName;
@property int selectedLibraryItemIndex;
@property int currentProjectIndex;
@property int currentSelectedProjectIndex;
@property Project* currentSelectedProject;

@property float projectsTableHeight;

@property NSURL* currentAssetFileUrl;
@property NSImage* selectedThumbnail;

@property FMDatabase *database;

@property NSMutableArray *userProjects;
@property NSMutableArray *assetsOfSelectedType;
@property NSMutableArray *selectedAssetTypes;

@property NSMutableArray *binFiles;
@property NSMutableArray *conformVideoFiles;
@property NSMutableArray *conformEDLFiles;
@property NSMutableArray *embedImageAssets;
@property NSMutableArray *embedPeopleAssets;
@property NSMutableArray *ADTileLibrary;
@property NSArray<NSValue *> * edlFramesArray;

@property NSMutableArray *EDLs;
@property NSMutableArray *savedEDLs;
@property Asset* selectedAssetToAssemble;
@property Asset* selectedAssetForADTile;

@property (strong) ExportViewController *exportViewController;
@property (strong) CreateArtistController *createArtistController;
@property (strong) CreateBrandController *createBrandController;
@property (strong) CreateLocationController *createLocationController;
@property (strong) CreateProductController *createProductController;
@property (strong) SearchArtistsController *searchArtistsController;
@property (strong) SearchProductsController *searchProductsController;
@property (strong) CreateSeriesViewController *createSeriesController;

@property NSMutableArray *spinnerImages;

@property NSMutableArray *currentSceneAnimations;

@property NSMutableArray *exportedProjects;

@end

@implementation MainCanvasViewController

AWSS3TransferManager* transitionAPNGUploadManager;
AWSS3TransferManager* transitionUploadManager;
AWSS3TransferManager* transitionSoundUploadManager;
AVAudioPlayer* _audioPlayer;
NSColor* selectedTilePlateColor;
NSColor *selectedTileTextColor;
BOOL isTileTextBold;
BOOL isTileTextItalic;
BOOL isTileTextUnderline;
BOOL userSelection;
NSString* tileTextAlignment;

NSColor *selectedTileDescColor;
BOOL isTileDescBold;
BOOL isTileDescItalic;
BOOL isTileDescUnderline;
NSString* tileDescAlignment;


BOOL transitionUploadInProgress;
BOOL transitionSoundUploadInProgress;

BOOL isCurrentEditInLoop;

NSString* tileTransition;
NSString* tileAudioTransition;

id mTimeObserver;

float currentFPS;
float nominalFPS;

int conformVideoIndex;
int conformEDLIndex;
BOOL checkSavedDataCalled;

static NSString* kStatusKey = @"stravplay";

BOOL isTileInEditMode;
ADTile* currentEditingTile;
int currentEditingTileIndex;

NSString* lastEditedField;

//mouse drag variables
//NSPoint location;
NSColor *itemColor;
NSColor *backgroundColor;
NSView* draggableItem;

NSMutableArray* currentVideoFrames;
int currentFrameNumber;
NSString* curreneTimeCodeString;
int currentTimeSeconds;
int currentTimeCodeFrame;
double currentTimeInSeconds;
// private variables that track state
BOOL dragging;
NSPoint lastDragLocation;

BOOL IsSceneDetectInProgress;
BOOL ReplaceEDLsFromDisk;
BOOL turnOnLoop;

NSMutableArray* currentProjecMVIDPaths;

BOOL isTileInEditCTA;
ADTile* currentSelectedADTile;
NSString * selectedTileTransDirection;

- (void)viewDidLoad {
    [super viewDidLoad];
    draggableItem = nil;
    userSelection = false;
    _currentProjectIndex = 0;
    conformVideoIndex = -1;
    conformEDLIndex = -1;
    checkSavedDataCalled = false;
    ReplaceEDLsFromDisk = false;
    transitionUploadInProgress = false;
    transitionSoundUploadInProgress = false;
    _ctaDialog.hidden = true;
    isTileInEditCTA = false;
    //_btnTransitionImage.state = 1;
    // Do view setup here.
    [_mainView setWantsLayer:YES];
    [_mainView.layer setBackgroundColor:[[NSColor colorFromHexadecimalValue:@"#181818"] CGColor]];
    
    currentProjecMVIDPaths = [NSMutableArray array];
    
    [self toggleButtonState:@"browse"];
    _lblUsername.stringValue = _username;
    _dialogView.hidden = true;
    
    [self setButtonTitle:_btnCreateProject toString:@"CREATE PROJECT" withColor:[NSColor whiteColor] withSize:18];
    [self setButtonTitle:_btnUpload toString:@"UPLOAD" withColor:[NSColor whiteColor] withSize:18];
    [self setButtonTitle:_btnImportVideoAsset toString:@"IMPORT" withColor:[NSColor whiteColor] withSize:18];
    
    [self setButtonTitle:_btnCreateCategoryTile toString:@"CREATE\nCATEGORY TILE" withColor:[NSColor whiteColor] withSize:12];
    [self setButtonTitle:_btnCreateCTATile toString:@"CREATE\nCTA TILE" withColor:[NSColor whiteColor] withSize:12];
    
    [self setButtonTitle:_btnSceneDetect toString:@"Detect Scenes \n & Assemble" withColor:[NSColor whiteColor] withSize:16];
   
    //[self setButtonTitle:_ADTileURLBtn toString:@"Visit Website" withColor:[NSColor whiteColor] withSize:12];

    [self setButtonTitle:_btnConformSelected toString:@"CONFORM" withColor:[NSColor whiteColor] withSize:18];
    [self setButtonTitle:_btnEmbedSelected toString:@"EMBED" withColor:[NSColor whiteColor] withSize:18];
    [self setButtonTitle:_btnAssemble toString:@"ASSEMBLE" withColor:[NSColor whiteColor] withSize:18];
    [self setButtonTitle:_btnAddFiles toString:@"ADD FILES..." withColor:[NSColor whiteColor] withSize:18];
    
    [self setButtonTitle:_btnAddMorePeople toString:@"ADD FROM BON2..." withColor:[NSColor whiteColor] withSize:18];
    
    [self setButtonTitle:_btnSaveTile toString:@"SAVE" withColor:[NSColor whiteColor] withSize:18];
    [self setButtonTitle:_btnEditTile toString:@"Edit" withColor:[NSColor whiteColor] withSize:18];
    [self setButtonTitle:_btnApplyTile toString:@"Apply" withColor:[NSColor whiteColor] withSize:18];
    [self setButtonTitle:_btnDeleteTile toString:@"Delete" withColor:[NSColor whiteColor] withSize:18];
    
    [self setPlaceholderTitle:_txtProjectName toString:@"Project Name" withColor:[NSColor lightGrayColor] withSize:14];
    
    [self setButtonTitle:_btnPlateColor toString:@"Plate" withColor:[NSColor orangeColor] withSize:18];
    [self setButtonTitle:_btnTileTransition toString:@"Transition" withColor:[NSColor orangeColor] withSize:18];
    [self setButtonTitle:_btnTileText toString:@"Text" withColor:[NSColor orangeColor] withSize:18];
    [self setButtonTitle:_btnTileLink toString:@"Links" withColor:[NSColor orangeColor] withSize:18];
    
    
    //[self setButtonTitle:_btnTransitionImage toString:@"IMAGES" withColor:[NSColor orangeColor] withSize:18];
    //[self setButtonTitle:_btnTransitionAudio toString:@"Sounds" withColor:[NSColor grayColor] withSize:18];
    
    //highlight embed products on load
    [self setButtonTitle:_btnEmbedPeople toString:@"People" withColor:[NSColor orangeColor] withSize:18];
    [self setButtonTitle:_btnEmbedProducts toString:@"PRODUCTS" withColor:[NSColor orangeColor] withSize:18];
    _btnEmbedProductsBorder.hidden = NO;
    _btnEmbedPeopleBorder.hidden = YES;
    
    _btnAddMorePeople.hidden = NO;
    
    self.delegate = self;
    
    self.toolBtn.layer.backgroundColor = [[NSColor blackColor] CGColor];
    
    _embedPeopleAssets = [NSMutableArray array];
    _embedImageAssets = [NSMutableArray array];
    
    _timelineCollection.delegate = self;
    
    _transitionComboBox.delegate = self;
    _transitionComboBox.dataSource = self;
    
    _soundsComboBox.delegate = self;
    _soundsComboBox.dataSource = self;
    
    _embedImagesCollectionView.delegate = self;
    _embedImagesCollectionView.dataSource = self;
    
    _libraryCollectionView.delegate = self;
    _libraryCollectionView.dataSource = self;
    
    //self.timelineCollection.itemPrototype = [self.storyboard instantiateControllerWithIdentifier:@"TimelineCollectionViewItem"];
    
    //[_timelineCollection registerClass:@"TimelineCollectionViewItem" forItemWithIdentifier:@"TimelineCollectionViewItem"];
    
    //TimelineCollectionViewItem* timeline= [[TimelineCollectionViewItem alloc] init];
    
    NSNib *nib = [[NSNib alloc] initWithNibNamed:@"timelineItem" bundle:nil];
    [_timelineCollection registerNib:nib forItemWithIdentifier:@"timelineItem"];
    
    // Add an observer for the MovieMutator to know if data has been pasted into it or cut out of it, and then update accordingly.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(underlyingMovieWasMutated) name:movieWasMutated object:self.movieMutator];
    
    _images = [[NSMutableArray alloc] init];
    _timeFrames = [[NSMutableArray alloc] init];
    _actualTimes = [[NSMutableArray alloc] init];
    _userProjects = [[NSMutableArray alloc] init];
    _binFiles = [[NSMutableArray alloc] init];
    _conformVideoFiles = [[NSMutableArray alloc] init];
    _conformEDLFiles = [[NSMutableArray alloc] init];
    _selectedAssetTypes = [[NSMutableArray alloc]init];
    [_selectedAssetTypes addObject:@"video"];
    [_selectedAssetTypes addObject:@"edl"];
    [_selectedAssetTypes addObject:@"picture"];
    [_selectedAssetTypes addObject:@"csv"];
    
    _movieTimeline.hidden = true;
    _btnExport.enabled = false;
    _tileCategoryComboBox.enabled = false;
    
    //Create (OR) Load Database to store and retrieve project data
    [self validateUserDatabase];
    
    _tblProjectsList.delegate = self;
    _tblProjectsList.dataSource = self;
    [_tblProjectsList setSelectionHighlightStyle:NSTableViewSelectionHighlightStyleNone];
    
    _tblImportAssets.delegate = self;
    _tblImportAssets.dataSource = self;
    [_tblImportAssets setSelectionHighlightStyle:NSTableViewSelectionHighlightStyleNone];

    _tblBinFiles.dataSource = self;
    _tblBinFiles.delegate = self;
    [_tblBinFiles setSelectionHighlightStyle:NSTableViewSelectionHighlightStyleNone];
    
    _tblConformVideos.dataSource = self;
    _tblConformVideos.delegate = self;
    [_tblConformVideos setSelectionHighlightStyle:NSTableViewSelectionHighlightStyleNone];
    
    _tblConformEDLs.dataSource = self;
    _tblConformEDLs.delegate = self;
    [_tblConformEDLs setSelectionHighlightStyle:NSTableViewSelectionHighlightStyleNone];
    
    _tblEDLs.dataSource = self;
    _tblEDLs.delegate = self;
    //[_tblEDLs setSelectionHighlightStyle:NSTableViewSelectionHighlightStyleSourceList];
    
    NSView *contentView = [_timelineScrollView contentView];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(boundDidChange:) name:NSViewBoundsDidChangeNotification object:contentView];
    
    
    if(selectedTileTextColor == nil)
        selectedTileTextColor = [NSColor whiteColor];
    
    if(selectedTileDescColor == nil)
        selectedTileDescColor = [NSColor whiteColor];
    
    isTileTextUnderline = false;
    isTileTextItalic = false;
    isTileTextBold = false;
    tileTextAlignment = @"left";
    
    isTileDescUnderline = false;
    isTileDescItalic = false;
    isTileDescBold = false;
    tileDescAlignment = @"left";
    
    lastEditedField = @"";
    
    [self UnderlineTileTextColorButton];
    
    [self IntializeRichTextButtons];
    
    _txtTileHeading.delegate = self;
    _txtTileDescription.delegate = self;
    
    _txtTileDescription.allowsEditingTextAttributes = YES;
    _txtTileHeading.allowsEditingTextAttributes = YES;
    
    _ADTileLibrary = [NSMutableArray array];
    
    _btnRemoveTileFromEdit.hidden = true;
    
    isCurrentEditInLoop = false;
    turnOnLoop = false;
    _tileDetailsView.hidden = true;
    
    //Tile Image View Border
    [_ADTileImage setWantsLayer:YES];
    _ADTileImage.layer.borderWidth = 3.0;
    _ADTileImage.layer.cornerRadius = 8.0;
    _ADTileImage.layer.masksToBounds = YES;
    CGColorRef color = CGColorRetain([NSColor orangeColor].CGColor);
    [_ADTileImage.layer setBorderColor:color];
    
    //Set selected tile image border
    [_selectedTileImage setWantsLayer:YES];
    _selectedTileImage.layer.borderWidth = 2.0;
    _selectedTileImage.layer.cornerRadius = 8.0;
    _selectedTileImage.layer.masksToBounds = YES;
    
    [_selectedTileImage.layer setBorderColor:color];
    
    CGColorRef neonColor = CGColorRetain([NSColor colorWithCalibratedRed:31/255.0f green:152/255.0f blue:255/255.0f alpha:1.0f].CGColor);
    [_btnSelectedTileText setWantsLayer:YES];
    _btnSelectedTileText.layer.borderWidth = 2.0;
    _btnSelectedTileText.layer.cornerRadius = 4;
    [_btnSelectedTileText.layer setBorderColor:neonColor];
    [self setButtonTitle:_btnSelectedTileText toString:@"TEXT" withColor:[NSColor whiteColor] withSize:13];

    [_btnSelectedTileLinks setWantsLayer:YES];
    _btnSelectedTileLinks.layer.borderWidth = 2.0;
    _btnSelectedTileLinks.layer.cornerRadius = 4;
    [_btnSelectedTileLinks.layer setBorderColor:neonColor];
    [self setButtonTitle:_btnSelectedTileLinks toString:@"LINKS" withColor:[NSColor whiteColor] withSize:13];
    
    [_btnShowTileIcon setWantsLayer:YES];
    _btnShowTileIcon.layer.borderWidth = 2.0;
    _btnShowTileIcon.layer.cornerRadius = 4;
    [_btnShowTileIcon.layer setBorderColor:neonColor];
    [self setButtonTitle:_btnShowTileIcon toString:@" SHOW " withColor:[NSColor whiteColor] withSize:13];

    [_btnHideTileIcon setWantsLayer:YES];
    _btnHideTileIcon.layer.borderWidth = 2.0;
    _btnHideTileIcon.layer.cornerRadius = 4;
    [_btnHideTileIcon.layer setBorderColor:neonColor];
    [self setButtonTitle:_btnHideTileIcon toString:@" HIDE " withColor:[NSColor whiteColor] withSize:13];
    
    [_btnSelectedTilePlate setWantsLayer:YES];
    _btnSelectedTilePlate.layer.borderWidth = 2.0;
    _btnSelectedTilePlate.layer.cornerRadius = 4;
    [_btnSelectedTilePlate.layer setBorderColor:neonColor];
    [self setButtonTitle:_btnSelectedTilePlate toString:@"PLATE" withColor:[NSColor whiteColor] withSize:13];

    
    [_btnSelectedTileTransition setWantsLayer:YES];
    _btnSelectedTileTransition.layer.borderWidth = 2.0;
    _btnSelectedTileTransition.layer.cornerRadius = 4;
    [_btnSelectedTileTransition.layer setBorderColor:neonColor];
    [self setButtonTitle:_btnSelectedTileTransition toString:@"TRANSITION" withColor:[NSColor whiteColor] withSize:13];

    //[self loadTempTransitionImages];
    self.currentSceneAnimations = [NSMutableArray array];
    
    _btnPlayAudioTransition.hidden = false;
    _imgAudioGif.imageScaling = NSImageScaleNone;
    _imgAudioGif.canDrawSubviewsIntoLayer = YES;
    _imgAudioGif.hidden = false;
    _imgAudioGif.animates = false;

    //add subviews
    [_activityBoxView addSubview:_browseView];
    [_activityBoxView addSubview:_conformView];
    [_activityBoxView addSubview:_embedView];

    [self.quickPlaceView setHidden:true];

    [_quickPlaceBtn1 setWantsLayer:YES];
    _quickPlaceBtn1.layer.borderWidth = 2.0;
    _quickPlaceBtn1.layer.cornerRadius = 12.5;
    [_quickPlaceBtn1.layer setBorderColor:neonColor];

    [_quickPlaceBtn2 setWantsLayer:YES];
    _quickPlaceBtn2.layer.borderWidth = 2.0;
    _quickPlaceBtn2.layer.cornerRadius = 12.5;
    [_quickPlaceBtn2.layer setBorderColor:neonColor];

    [_quickPlaceBtn3 setWantsLayer:YES];
    _quickPlaceBtn3.layer.borderWidth = 2.0;
    _quickPlaceBtn3.layer.cornerRadius = 12.5;
    [_quickPlaceBtn3.layer setBorderColor:neonColor];

    [_quickPlaceBtn4 setWantsLayer:YES];
    _quickPlaceBtn4.layer.borderWidth = 2.0;
    _quickPlaceBtn4.layer.cornerRadius = 12.5;
    [_quickPlaceBtn4.layer setBorderColor:neonColor];

    [_quickPlaceBtn5 setWantsLayer:YES];
    _quickPlaceBtn5.layer.borderWidth = 2.0;
    _quickPlaceBtn5.layer.cornerRadius = 12.5;
    [_quickPlaceBtn5.layer setBorderColor:neonColor];

    [_quickPlaceBtn6 setWantsLayer:YES];
    _quickPlaceBtn6.layer.borderWidth = 2.0;
    _quickPlaceBtn6.layer.cornerRadius = 12.5;
    [_quickPlaceBtn6.layer setBorderColor:neonColor];

    [_quickPlaceBtn7 setWantsLayer:YES];
    _quickPlaceBtn7.layer.borderWidth = 2.0;
    _quickPlaceBtn7.layer.cornerRadius = 12.5;
    [_quickPlaceBtn7.layer setBorderColor:neonColor];

    [_quickPlaceBtn8 setWantsLayer:YES];
    _quickPlaceBtn8.layer.borderWidth = 2.0;
    _quickPlaceBtn8.layer.cornerRadius = 12.5;
    [_quickPlaceBtn8.layer setBorderColor:neonColor];

    [_quickPlaceBtn9 setWantsLayer:YES];
    _quickPlaceBtn9.layer.borderWidth = 2.0;
    _quickPlaceBtn9.layer.cornerRadius = 12.5;
    [_quickPlaceBtn9.layer setBorderColor:neonColor];

    [_quickPlaceBtn10 setWantsLayer:YES];
    _quickPlaceBtn10.layer.borderWidth = 2.0;
    _quickPlaceBtn10.layer.cornerRadius = 12.5;
    [_quickPlaceBtn10.layer setBorderColor:neonColor];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(popOverShowed) name:NSPopoverDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(popOverClosed) name:NSPopoverDidCloseNotification object:nil];

    [_tblProjectsList setDoubleAction:@selector(doubleClick:)];
    [_btnRemoveProject setHidden:true];
}

- (void)doubleClick:(id) sender {
    int _r = [_tblProjectsList clickedRow];
    _currentSelectedProject = [_userProjects objectAtIndex:_r];
    NSLog(@"Selected Project:%@",_currentSelectedProject.projectName);
    _currentProjectIndex = _r;

    [self highlightActiveProjectInList:_r];
    [self setActiveProjectTitle:_currentSelectedProject.projectName collapse:true];

    [self getExportedProjectDetails];

    _btnAddFiles.hidden = NO;
    _boxBinView.hidden = YES;

    _embedImageAssets = [NSMutableArray array];
    _embedPeopleAssets = [NSMutableArray array];

    [self reloadAssets];

    [_tblConformVideos reloadData];
    [_tblConformEDLs reloadData];

    [_transitionComboBox reloadData];
    [_soundsComboBox reloadData];

    [self.playerView.player pause];
    self.playerView.player = nil;

    _EDLs = [NSMutableArray array];
    [_tblEDLs reloadData];

    _timeFrames = [[NSMutableArray alloc] init];
    _images = [[NSMutableArray alloc] init];

    [_timelineCollection reloadData];

    _btnExport.enabled = false;

    [self clearAllTileOnEditFrame];

    //LastSavedProject
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:_currentSelectedProject.projectId] forKey:[NSString stringWithFormat:@"LastSavedProject-%@", _username]];
    [[NSUserDefaults standardUserDefaults] synchronize];

    [_quickPlaceView setHidden:true];
    _quickPlaceSetTiles = [NSMutableArray array];

    [self checkSavedData];
}

-(void)viewDidAppear{
    [super viewDidAppear];

    self.exportViewController = [self.storyboard instantiateControllerWithIdentifier:@"ExportViewController"];
    self.createArtistController = [self.storyboard instantiateControllerWithIdentifier:@"CreateArtistController"];
    self.createBrandController = [self.storyboard instantiateControllerWithIdentifier:@"CreateBrandController"];
    self.createLocationController = [self.storyboard instantiateControllerWithIdentifier:@"CreateLocationController"];
    self.createProductController = [self.storyboard instantiateControllerWithIdentifier:@"CreateProductController"];
    self.searchArtistsController = [self.storyboard instantiateControllerWithIdentifier:@"SearchArtistsController"];
    self.searchProductsController = [self.storyboard instantiateControllerWithIdentifier:@"SearchProductsController"];
    self.createSeriesController = [self.storyboard instantiateControllerWithIdentifier:@"CreateSeriesViewController"];

    self.searchArtistsController.delegate = self;
    self.searchProductsController.delegate = self;

//    _browseView.frame = NSRectFromCGRect(CGRectMake(0, 21, _activityBoxView.frame.size.width, _activityBoxView.frame.size.height - 21));
//    NSLog(@"************* %@", NSStringFromRect(_browseView.frame));
//    _conformView.frame = NSRectFromCGRect(CGRectMake(0, 21, _activityBoxView.frame.size.width, _activityBoxView.frame.size.height - 21));
//    _embedView.frame = NSRectFromCGRect(CGRectMake(0, 21, _activityBoxView.frame.size.width, _activityBoxView.frame.size.height - 21));
}

- (NSInteger)numberOfItemsInComboBox:(NSComboBox *)aComboBox
{
    if(_currentSelectedProject != nil)
    {
        if([aComboBox.identifier isEqualToString:@"transitionComboBox"])
            return _currentSelectedProject.transitions.count;
        else
            return _currentSelectedProject.sounds.count;
    }
    else
        return 0;
}

-(id)comboBox:(NSComboBox *)comboBox objectValueForItemAtIndex:(NSInteger)index
{
     if([comboBox.identifier isEqualToString:@"transitionComboBox"])
         return [_currentSelectedProject.transitions objectAtIndex:index];
     else
         return [_currentSelectedProject.sounds objectAtIndex:index];
}

- (NSImage *)getImage:(NSString *)path {
    NSArray *imageReps = [NSBitmapImageRep imageRepsWithContentsOfFile:path];
    NSInteger width = 0;
    NSInteger height = 0;
    for (NSImageRep * imageRep in imageReps) {
        if ([imageRep pixelsWide] > width) width = [imageRep pixelsWide];
        if ([imageRep pixelsHigh] > height) height = [imageRep pixelsHigh];
    }
    NSImage *imageNSImage = [[NSImage alloc] initWithSize:NSMakeSize((CGFloat)width, (CGFloat)height)];
    [imageNSImage addRepresentations:imageReps];
    return imageNSImage;
}

-(void) playAudio:(NSString*)url {
        //NSString *path = [NSString stringWithFormat:@"%@/metronome.mp3", [[NSBundle mainBundle] resourcePath]];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        NSURL *metronomeSound = [NSURL fileURLWithPath:url];
        _audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:metronomeSound error:nil];
        [_audioPlayer prepareToPlay];
        [_audioPlayer play];
    });
}

-(void) pauseAudio
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        [_audioPlayer pause];
    });
}

-(void)loadTransitionImages:(NSArray*)urls{
   // self.tilePreviewImageView.wantsLayer = YES;
    
    CALayer *layer = [CALayer layer];
    self.spinnerImages = [NSMutableArray arrayWithCapacity:urls.count];
    for (int i = 0; i < urls.count; ++i)
    {
        NSURL *imageName = nil;
        if([urls[i] isKindOfClass:[NSURL class]]){
            imageName = urls[i];
            [imageName startAccessingSecurityScopedResource];
        }
        else
            imageName = [NSURL URLWithString:urls[i]];
        
        
        
        NSLog(@"%@",imageName);
        
        NSError* err = nil;
        NSData* img_data = [NSData dataWithContentsOfURL:imageName options:NSDataReadingMappedIfSafe error:&err];
        if(err == nil)
        {
            NSImage* img = [[NSImage alloc] initWithData:img_data];//[self getImage:imageName];  //
            if(img != nil)
                [self.spinnerImages addObject:img];
            else
                [self showAlert:@"Error" message:@"Trying to insert empty image"];
        }
        else
            NSLog(@"Error: %@",err);
        
    }
    //self.spinnerImages = [spinnerImages copy];
     dispatch_async(dispatch_get_main_queue(), ^{
        layer.frame = self.transitionPreviewView.frame;
        layer.bounds = self.transitionPreviewView.bounds;
        //[self.tilePreviewImageView setLayer:layer];
        [self.transitionPreviewView setWantsLayer:YES];
        [self.transitionPreviewView.layer setBackgroundColor:[[NSColor lightGrayColor] CGColor]];
        [self.transitionPreviewView.layer addSublayer:layer];
        
        CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:@"contents"];
        [animation setCalculationMode:kCAAnimationLinear];
        [animation setDuration:4.0f];
        [animation setRepeatCount:CGFLOAT_MAX];
        [animation setValues:self.spinnerImages];
        
        [self.transitionPreviewView.layer addAnimation:animation forKey:@"contents"];
     });
    
    //[self playTransition];
}

-(void)playAudioTransition:(NSString*)transitionName
{
    [_database open];
    //.. Preview current transition
    FMResultSet* assetResults = [self.database executeQuery:[NSString stringWithFormat:@"SELECT * FROM transition_sounds WHERE TRANSITION_PRJ_ID=%d AND TRANSITION_NAME='%@' COLLATE NOCASE", _currentSelectedProject.projectId, [self replaceSpacesInName:transitionName]]];
    
    int transition_id = -1;
    NSString* local_file_path = nil;
    NSData* local_bookmark = nil;
    while ([assetResults next]) {
        transition_id = [assetResults intForColumn:@"TRANSITION_ID"];
        local_file_path = [assetResults stringForColumn:@"LOCAL_PATH"];
        local_bookmark = [assetResults dataForColumn:@"LOCAL_BOOKMARK"];
    }
    [assetResults close];
    
    if(local_bookmark != nil)
    {
        NSURL* sound_url = [self getURLfromBookmarkData:local_bookmark];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            [self playAudio:sound_url.path];
        });
    }
    else if(local_file_path != nil){
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            [self playAudio:local_file_path];
        });
    }
}

-(void)playTransition:(NSString*)transitionName direction:(NSString*)direction
{
    NSRect _srcFr = _playerbox.frame;
    
    _srcFr.size.height = _srcFr.size.height;
    _srcFr.size.width = _srcFr.size.width/2;
    
    _srcFr.origin.y = _srcFr.origin.y;
    
    
    
    if([direction isEqualToString:@"left"])
    {
        _srcFr.origin.x = _srcFr.origin.x;
        
        if([transitionName localizedCaseInsensitiveContainsString:@".right."])
            transitionName = [[transitionName stringByReplacingOccurrencesOfString:@".right." withString:@".left." options:NSCaseInsensitiveSearch range:NSMakeRange(0, [transitionName length])] mutableCopy];
    }
    if([direction isEqualToString:@"right"])
    {
        _srcFr.origin.x = _srcFr.origin.x + _playerbox.frame.size.width/2;
        
        if([transitionName localizedCaseInsensitiveContainsString:@".left."])
            transitionName = [[transitionName stringByReplacingOccurrencesOfString:@".left." withString:@".right." options:NSCaseInsensitiveSearch range:NSMakeRange(0, [transitionName length])] mutableCopy];
    }
    
    [_database open];
    //.. Preview current transition
    FMResultSet* assetResults = [self.database executeQuery:[NSString stringWithFormat:@"SELECT * FROM TRANSITIONS WHERE TRANSITION_PRJ_ID=%d AND TRANSITION_NAME='%@' COLLATE NOCASE", _currentSelectedProject.projectId, [self replaceSpacesInName:transitionName]]];
    
    int transition_id = -1;
    while ([assetResults next]) {
        transition_id = [assetResults intForColumn:@"TRANSITION_ID"];
    }
    [assetResults close];
    
    FMResultSet* transitionFileResults = [self.database executeQuery:[NSString stringWithFormat:@"SELECT * FROM TRANSITIONFILES WHERE FILE_TRANSITION_ID=%d COLLATE NOCASE",transition_id]];
    
    NSMutableArray* transitionUrls = [NSMutableArray array];
    while ([transitionFileResults next]) {
        //NSString* local_file_path = [transitionFileResults stringForColumn:@"LOCAL_PATH"];
        NSData* local_bookmark = [transitionFileResults dataForColumn:@"LOCAL_BOOKMARK"];
        
        NSURL* _url = [self getURLfromBookmarkData:local_bookmark];
        //NSString* local_file_path = @"";
        
        [transitionUrls addObject:_url];
    }
    [transitionFileResults close];
    
    [_database close];
    CALayer *layer = [CALayer layer];
    
    NSMutableArray* transitionImages = [NSMutableArray array];//arrayWithCapacity:transitionUrls.count];
    for (int i = 0; i < transitionUrls.count; ++i)
    {
        NSURL *imageName = transitionUrls[i];
        
        BOOL available = [imageName startAccessingSecurityScopedResource];
        
        NSImage* img2 = [[NSImage alloc] initWithContentsOfURL:imageName];
        [transitionImages addObject:img2];
        //NSImage* img1 = [[NSImage alloc] initWithContentsOfFile:imageName.path];
        
        //[transitionImages addObject:[[NSImage alloc] initWithContentsOfFile:[NSURL URLWithString:imageName].absoluteString]];
    }
    
    ///To do: Add dispatch_after
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        layer.frame = _srcFr;//self.playerView.frame;
        //layer.bounds = self.playerView.bounds;
        //[self.tilePreviewImageView setLayer:layer];
        self.transitionPlayView.frame = _srcFr;
        
        [self.transitionPlayView setWantsLayer:YES];
        
        [self.transitionPlayView.layer addSublayer:layer];
        
        CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:@"contents"];
        [animation setCalculationMode:kCAAnimationLinear];
        [animation setDuration:4.0f];
        [animation setRepeatCount:0];
        [animation setValues:transitionImages];
        animation.removedOnCompletion = false;
        self.transitionPlayView.hidden = false;
        [self.transitionPlayView.layer addAnimation:animation forKey:@"contents"];
    });
}

- (void)stopAnimating
{
    //Not implemented
}

- (void)startAnimating
{
    //Not implemented
}

-(void) getExportedProjectDetails
{
    _exportedProjects = [NSMutableArray array];
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    
    NSMutableDictionary *postUserData = [[NSMutableDictionary alloc] init];
    
    NSString* userId = [[NSUserDefaults standardUserDefaults] valueForKey:@"userId"];
    NSString* accessToken = [[NSUserDefaults standardUserDefaults] valueForKey:@"accessToken"];
    
    [postUserData setValue:userId forKey:@"userId"];
    [postUserData setValue:accessToken forKey:@"accessToken"];
    [postUserData setValue:@"1" forKey:@"startRange"];
    [postUserData setValue:@"999" forKey:@"endRange"];
    [postUserData setValue:@"" forKey:@"searchString"];
    [postUserData setValue:userId forKey:@"targetUserId"];
    
    NSError *error = nil;
    NSData *json;
    NSString *jsonString;
    
    NSString *url = [NSString stringWithFormat:@"%@%@",BASE_URL, GET_USER_MEDIA];
    
    json = [NSJSONSerialization dataWithJSONObject:postUserData options:NSJSONWritingPrettyPrinted error:&error];
    
    // If no errors, let's view the JSON
    if (json != nil && error == nil)
    {
        jsonString = [[NSString alloc] initWithData:json encoding:NSUTF8StringEncoding];
        NSLog(@"JSON: %@", jsonString);
    }
    
    NSDictionary *params = @{@"data" : jsonString};
    
    [self showProgress];
    [manager POST:url parameters:params success:^(NSURLSessionDataTask * _Nonnull task, id  _Nonnull responseObject) {
        [self hideProgress];
        NSMutableDictionary* response = responseObject;
        NSString* status = [response valueForKey:@"responseStatus"];
        if([status isEqualToString:@"200"])
        {
            NSArray *response = [responseObject valueForKey:@"responseObj"];
            _exportedProjects = [NSMutableArray array];
            for (int i = 0; i < response.count; i++) {
                NSDictionary* media = [[response objectAtIndex:i] objectForKey:@"media"];
                [_exportedProjects addObject:[media mutableCopy]];
            }
            
            //_exportedProjects = [response mutableCopy];
        }
        
        else if([status isEqualToString:@"503"] || [status isEqualToString:@"504"])
        {
            //[self showAlert:@"Login Error" message:[response valueForKey:@"responseObj"]];
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [self hideProgress];
    }];
}

-(void)scrollItemToCenter{
    [self.timelineCollection scrollToItemsAtIndexPaths:[self.timelineCollection selectionIndexPaths] scrollPosition:NSCollectionViewScrollPositionCenteredHorizontally];
}

-(void)searchProductsController:(SearchProductsController *)viewController didSelectedProducts:(NSMutableArray *)products
{
    //create artist assets
    for (int i = 0; i < [products count]; i++) {
        [_database open];
        
        NSDictionary* artistData = [products objectAtIndex:i];
        if([self productNotExistsInList:[artistData valueForKey:@"productId"]]){
            
            //insert product to database
            NSString* name = [[artistData valueForKey:@"productName"] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            NSString* desc = [[artistData valueForKey:@"productDescription"] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            NSString* brandName = [[artistData valueForKey:@"brandName"] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            NSString* asset_identifier = [[artistData valueForKey:@"productId"] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            
            NSString* product_type = @"product";
            NSString* keywords = name;
            NSString* store_name = @"";
            
            if([artistData valueForKey:@"product_type"] != nil)
                product_type = [[artistData valueForKey:@"product_type"] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            
            if([artistData valueForKey:@"keywords"] != nil)
                keywords = [[artistData valueForKey:@"keywords"] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            
            if([artistData valueForKey:@"store_name"] != nil)
                store_name = [[artistData valueForKey:@"store_name"] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];

            NSString* generalCategory = [artistData valueForKey:@"generalCategory"];
            
            name = [name stringByReplacingOccurrencesOfString:@"'" withString:@"%27"];
            desc = [desc stringByReplacingOccurrencesOfString:@"'" withString:@"%27"];
            brandName = [brandName stringByReplacingOccurrencesOfString:@"'" withString:@"%27"];
            
            NSString *insertQuery = [NSString stringWithFormat:@"INSERT INTO products (ASSET_IDENTIFIER, ASSET_NAME, ASSET_IMAGE_PATH, ASSET_DESC, TILE_LINK1, TILE_LINK2, TILE_LINK3, TILE_LINK4, TILE_LINK5, BRAND_NAME, GENERAL_CATEGORY,PROJECT_ID, PRODUCT_TYPE, KEYWORDS) VALUES ('%@','%@','%@', '%@','%@' ,'%@', '%@','%@','%@','%@','%@','%d','%@','%@')",asset_identifier, name, [artistData valueForKey:@"picture"], desc, [artistData valueForKey:@"shopLink1"], [artistData valueForKey:@"shopLink2"], [artistData valueForKey:@"shopLink3"], [artistData valueForKey:@"shopLink4"], [artistData valueForKey:@"shopLink5"], brandName, generalCategory,_currentSelectedProject.projectId, product_type, keywords];
            
            BOOL status = [_database executeUpdate:insertQuery];
            
            //Get id from db
            //int project_id = (int)[_database lastInsertRowId];
            
            Asset* _a1 = [[Asset alloc] init];
            _a1.assetId = (int)[_database lastInsertRowId];
            _a1.assetIdentifier = [artistData valueForKey:@"productId"];
            _a1.assetName = [artistData valueForKey:@"productName"];
            
            _a1.assetImage = [[NSImage alloc] initWithContentsOfURL:[NSURL URLWithString:[artistData valueForKey:@"picture"]]];
            _a1.assetType = @"product";
            _a1.assetFilePath = [artistData valueForKey:@"picture"];
            _a1.assetDisplayName = [artistData valueForKey:@"productName"];
            _a1.assetProfileDescription = [artistData valueForKey:@"productDescription"];
            _a1.brandName = [artistData valueForKey:@"brandName"];
            
            _a1.link1 = [artistData valueForKey:@"shopLink1"];
            _a1.link2 = [artistData valueForKey:@"shopLink2"];
            _a1.link3 = [artistData valueForKey:@"shopLink3"];
            _a1.link4 = [artistData valueForKey:@"shopLink4"];
            _a1.link5 = [artistData valueForKey:@"shopLink5"];
            
            if(_a1.assetProfileDescription == nil)
                _a1.assetProfileDescription = @"";
            [_embedImageAssets addObject:_a1];
        }
        
        [_database close];
    }
    
    [_embedImagesCollectionView reloadData];
    
}

-(void)searchArtistsController:(SearchArtistsController *)viewController didSelectedArtists:(NSMutableArray *)artists
{
    //create artist assets
    for (int i = 0; i < [artists count]; i++) {
        
        [_database open];
        
        NSDictionary* artistData = [artists objectAtIndex:i];
        if([self artistNotExistsInList:[artistData valueForKey:@"artistId"]]){
            
            NSString* name = [NSString stringWithFormat:@"%@ %@", [artistData valueForKey:@"firstName"],[artistData valueForKey:@"lastName"] ];
            name = [name stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            NSString* desc = [[artistData valueForKey:@"artistDescription"] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            NSString* asset_identifier = [[artistData valueForKey:@"artistId"] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];

            NSString* firstname = [[artistData valueForKey:@"firstName"] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            NSString* lastname = [[artistData valueForKey:@"lastName"] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            
            NSString* nickname = [[artistData valueForKey:@"nickName"] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            
            nickname = [nickname stringByReplacingOccurrencesOfString:@"'" withString:@"%27"];
            
            name = [name stringByReplacingOccurrencesOfString:@"'" withString:@"%27"];
            desc = [desc stringByReplacingOccurrencesOfString:@"'" withString:@"%27"];
            
            firstname = [firstname stringByReplacingOccurrencesOfString:@"'" withString:@"%27"];
            lastname = [lastname stringByReplacingOccurrencesOfString:@"'" withString:@"%27"];
            
            
            //insert product to database
            NSString *insertQuery = [NSString stringWithFormat:@"INSERT INTO people (ASSET_IDENTIFIER, ASSET_NAME, NICK_NAME, FIRST_NAME, LAST_NAME, ASSET_IMAGE_PATH, ASSET_DESC, FACEBOOK_LINK, INSTAGRAM_LINK, PINTEREST_LINK, TWITTER_LINK, WEBSITE_LINK, PROJECT_ID) VALUES ('%@', '%@','%@','%@', '%@','%@' ,'%@', '%@','%@','%@','%@','%@','%d')",asset_identifier,name, nickname, firstname, lastname, [artistData valueForKey:@"profilePicture"], desc, [artistData valueForKey:@"fbUrl"], [artistData valueForKey:@"instagramUrl"], [artistData valueForKey:@"pintrestUrl"], [artistData valueForKey:@"youtubeUrl"], [artistData valueForKey:@"bon2Url"], _currentSelectedProject.projectId];
            
            BOOL status = [_database executeUpdate:insertQuery];
            
            NSError* err = [_database lastError];
            
            Asset* _a1 = [[Asset alloc] init];
            _a1.assetId = (int)[_database lastInsertRowId];
            _a1.assetIdentifier = [artistData valueForKey:@"artistId"];
            _a1.assetName = [NSString stringWithFormat:@"%@ %@", [artistData valueForKey:@"firstName"],[artistData valueForKey:@"lastName"] ];
            _a1.firstName = [artistData valueForKey:@"firstName"];
            _a1.lastName = [artistData valueForKey:@"lastName"];
            _a1.nickName = [artistData valueForKey:@"nickName"];
            _a1.assetImage = [[NSImage alloc] initWithContentsOfURL:[NSURL URLWithString:[artistData valueForKey:@"profilePicture"]]];
            _a1.assetType = @"people";
            _a1.assetFilePath = [artistData valueForKey:@"profilePicture"];
            _a1.assetDisplayName = [NSString stringWithFormat:@"%@ %@", [artistData valueForKey:@"firstName"],[artistData valueForKey:@"lastName"] ];
            _a1.assetProfileDescription = [artistData valueForKey:@"artistDescription"];
            
            _a1.assetFacebookLink = [artistData valueForKey:@"fbUrl"];
            _a1.assetTwitterLink = [artistData valueForKey:@"youtubeUrl"];
            _a1.assetInstagraamLink = [artistData valueForKey:@"instagramUrl"];
            _a1.assetPinterestLink = [artistData valueForKey:@"pintrestUrl"];
            _a1.assetWebsiteLink = [artistData valueForKey:@"bon2Url"];
            
            if(_a1.assetProfileDescription == nil)
                _a1.assetProfileDescription = @"";
            [_embedPeopleAssets addObject:_a1];

        }
        
        [_database close];
    }
    
    [_embedImagesCollectionView reloadData];
}

-(BOOL)artistNotExistsInList:(NSString*)artistId{
    BOOL exists = false;
    
    for (int i = 0; i < [_embedPeopleAssets count]; i++) {
        Asset* _a = (Asset*)[_embedPeopleAssets objectAtIndex:i];
        if([_a.assetIdentifier isEqualToString:artistId])
        {
            exists = true;
            break;
        }
    }
    
    return !exists;
}

-(BOOL)productNotExistsInList:(NSString*)productId{
    BOOL exists = false;
    
    for (int i = 0; i < [_embedImageAssets count]; i++) {
        Asset* _a = (Asset*)[_embedImageAssets objectAtIndex:i];
        if([_a.assetIdentifier isEqualToString:productId])
        {
            exists = true;
            break;
        }
    }
    
    return !exists;
}

//sync frames, edl selection during playback
int currentSceneIndex = 0;
int lastFrameIndex;

NSMutableArray* allSelectedEdits;

-(void)syncFrames:(CMTime)time
{
    if (/*isfinite(duration) && */_actualTimes.count > 0 && _EDLs.count > 0)
    {
        double minValue = ((NSNumber*)[_actualTimes objectAtIndex:0]).integerValue;
        double maxValue = ((NSNumber*)[_actualTimes objectAtIndex:_actualTimes.count-1]).floatValue;
        
        double currentFrameValue = 0;
        
        if(currentSceneIndex < _actualTimes.count)
            currentFrameValue = ((NSNumber*)[_actualTimes objectAtIndex:currentSceneIndex]).floatValue;

        
        double nextFrameIndex = currentSceneIndex + 1;
        double prevFrameIndex = currentSceneIndex - 1;

        
        int nextEditFrameNumber = currentFrameNumber;
        if(nextFrameIndex < _EDLs.count)
            nextEditFrameNumber = [((EDL*)[_EDLs objectAtIndex:nextFrameIndex]).reelName intValue];
        int prevEditFrameNumber = currentFrameNumber;
        if(prevFrameIndex >= 0 && prevFrameIndex < _EDLs.count)
            prevEditFrameNumber = [((EDL*)[_EDLs objectAtIndex:prevFrameIndex]).reelName intValue];
        
        int currentEditFrameNumber = 0;
        if(currentSceneIndex < _EDLs.count)
            currentEditFrameNumber = [((EDL*)[_EDLs objectAtIndex:currentSceneIndex]).reelName intValue];
        else
            currentEditFrameNumber = [((EDL*)[_EDLs objectAtIndex:_EDLs.count - 1]).reelName intValue];
        
        int lastEditFrameNumber = [((EDL*)[_EDLs objectAtIndex:_EDLs.count - 1]).reelName intValue];
        
        double timeSec = CMTimeGetSeconds(time);

        _lblCurrentFrameTime.stringValue = (NSString*)CFBridgingRelease(CMTimeCopyDescription(NULL, _playerView.player.currentTime));
        CFDictionaryRef timeAsDictionary = CMTimeCopyAsDictionary(_playerView.player.currentTime, kCFAllocatorDefault);
        NSDictionary *timeDict = (__bridge NSDictionary*)timeAsDictionary;

        
        lastFrameIndex = _actualTimes.count-1;
        
        if(timeSec > minValue)
        {
            if(currentFrameNumber > currentEditFrameNumber && currentFrameNumber >= nextEditFrameNumber)//if(timeSec > currentFrameValue && timeSec >= nextFrameValue)// && nextFrameValue != currentFrameValue)
            {
                if(isCurrentEditInLoop)
                {
                    //Repeat the current scene
                    userSelection = true;
                    [self.playerView.player pause];
                    [self seekToTimeAtVideo:((EDL*)(_EDLs[currentSceneIndex])).time frameIndex:currentSceneIndex];
                    [self.playerView.player play];

                    return;
                }
                else
                {
                    if(currentSceneIndex+1 < _EDLs.count)
                        currentSceneIndex++;

                }
            }
            else if(currentFrameNumber < currentEditFrameNumber && currentFrameNumber >= prevEditFrameNumber)//if(timeSec < currentFrameValue && timeSec >= previousFrameValue)
            {
                if(currentSceneIndex > 0)
                    currentSceneIndex--;

            }
            else if(currentFrameNumber >= currentEditFrameNumber) //if(timeSec > currentFrameValue)
            {
                //Do Nothing.. keep the current frame selected

            }
        }
        
        if(currentSceneIndex < _images.count)
            [self selectFrameAtIndex:currentSceneIndex];
        
        [self selectEDLinTableAtIndex:currentSceneIndex];
        
        //if video is playing - show CTA tiles
        if(_playerView.player.rate > 0 && _playerView.player.error == nil)
        {
            if(currentFrameNumber > currentEditFrameNumber + 20)
            {
                
            }
            else{
                [self showCTAforCurrentTile];
            }
        }
        
        [self resumeAnimations];
    }
}

//Method to select a frame at index
-(void)selectFrameAtIndex:(int)frameIndex{

    @try{
        NSIndexPath* _ip = [NSIndexPath indexPathForItem:frameIndex inSection:0];
    
        //NSLog(@"Frame Index:@%d", frameIndex);
        if(_ip != nil)
        {
            NSCollectionViewScrollPosition _nsPos = NSCollectionViewScrollPositionRight;
            
            NSSet *set = [NSSet setWithObjects:_ip, nil];
            
            NSArray<NSIndexPath*>* myset = [_timelineCollection selectionIndexPaths].allObjects;
            if(myset.count > 0)
            {
                if([myset containsObject:_ip])
                {
                    return;
                }
                
                if(myset[0].item >= frameIndex){
                    _nsPos = NSCollectionViewScrollPositionLeft;
                }
                
                NSArray<NSIndexPath*>* activeSet = [_timelineCollection indexPathsForVisibleItems].allObjects;
                
                //if(activeSet indexOfObject:myset[0])
                if([activeSet containsObject:_ip])
                {
                    _nsPos = NSCollectionViewScrollPositionNone;
                }
            }
            
            [_timelineCollection deselectAll:nil];
            [_timelineCollection selectItemsAtIndexPaths:set scrollPosition:_nsPos];
            [self scrollItemToCenter];
            [self clearAllTileOnEditFrame];
            
            [self showADTilesForCurrentFrame];
            
            [self updateEDLSlider];
            [_playerView becomeFirstResponder];
        }
    }
    @catch(NSException* ex)
    {
        NSLog(ex.description);
    }
}

-(void)updateEDLSlider{
    if(_EDLs != nil && [_EDLs count] > 0)
    {
        if(currentSceneIndex < [_EDLs count]){
            EDL* currentEDl = (EDL*)(_EDLs[currentSceneIndex]);
            CMTime _edlStart = currentEDl.time;
            CMTime _edlEnd = _playerView.player.currentItem.duration;
            
            if(currentSceneIndex+1 < _EDLs.count)
                _edlEnd = ((EDL*)(_EDLs[currentSceneIndex+1])).time;
            
            double beginSeconds = CMTimeGetSeconds(_edlStart);
            double endSeconds = CMTimeGetSeconds(_edlEnd);
            
            [_eldTimeSlider setMinValue:beginSeconds];
            [_eldTimeSlider setMaxValue:endSeconds];
            
            double currentSeconds = CMTimeGetSeconds(_playerView.player.currentTime);
            _eldTimeSlider.doubleValue = currentSeconds;
        }
    }
}

-(void)selectLibraryAssetAtIndex:(int)frameIndex{

    
    @try{
        NSIndexPath* _ip = [NSIndexPath indexPathForItem:frameIndex inSection:0];
       
        if(_ip != nil)
        {
            NSCollectionViewScrollPosition _nsPos = NSCollectionViewScrollPositionBottom;
            
            NSSet *set = [NSSet setWithObjects:_ip, nil];
            
            NSArray<NSIndexPath*>* myset = [_libraryCollectionView selectionIndexPaths].allObjects;
            if(myset.count > 0)
            {
                if([myset containsObject:_ip])
                {
                    return;
                }
                
                if(myset[0].item > frameIndex){
                    _nsPos = NSCollectionViewScrollPositionTop;
                }
                
                NSArray<NSIndexPath*>* activeSet = [_libraryCollectionView indexPathsForVisibleItems].allObjects;
                
                //if(activeSet indexOfObject:myset[0])
                if([activeSet containsObject:_ip])
                {
                    _nsPos = NSCollectionViewScrollPositionNone;
                }
            }
            
            [_libraryCollectionView deselectAll:nil];
            [_libraryCollectionView selectItemsAtIndexPaths:set scrollPosition:_nsPos];
        }
    }
    @catch(NSException* ex)
    {
        NSLog(ex.description);
    }
}

-(void)UpdateButtonStatesToMatchTextAttributes:(NSString*)fieldName
{
    if([fieldName isEqualToString:@"heading"])
    {
        if(isTileTextBold)
            _btnSetTextBold.state = 1;
        else
            _btnSetTextBold.state = 0;
        
        if(isTileTextUnderline)
            _btnSetTextUnderline.state = 1;
        else
            _btnSetTextUnderline.state = 0;
        
        if(isTileTextItalic)
            _btnSetTextItalic.state = 1;
        else
            _btnSetTextItalic.state = 0;
        
        _btnSetTextAlignLeft.state = 0;
        _btnSetTextAlignCenter.state = 0;
        _btnSetTextAlignRight.state = 0;
        
        if([tileTextAlignment isEqualToString:@"left"])
            _btnSetTextAlignLeft.state = 1;
        else if([tileTextAlignment isEqualToString:@"center"])
            _btnSetTextAlignCenter.state = 1;
        else if([tileTextAlignment isEqualToString:@"right"])
            _btnSetTextAlignRight.state = 1;
        
        _cgColorWell.color = selectedTileTextColor;
    
    }
    else if([fieldName isEqualToString:@"description"])
    {
        if(isTileDescBold)
            _btnSetTextBold.state = 1;
        else
            _btnSetTextBold.state = 0;
        
        if(isTileDescUnderline)
            _btnSetTextUnderline.state = 1;
        else
            _btnSetTextUnderline.state = 0;
        
        if(isTileDescItalic)
            _btnSetTextItalic.state = 1;
        else
            _btnSetTextItalic.state = 0;
        
        _btnSetTextAlignLeft.state = 0;
        _btnSetTextAlignCenter.state = 0;
        _btnSetTextAlignRight.state = 0;
        
        if([tileDescAlignment isEqualToString:@"left"])
            _btnSetTextAlignLeft.state = 1;
        else if([tileDescAlignment isEqualToString:@"center"])
            _btnSetTextAlignCenter.state = 1;
        else if([tileDescAlignment isEqualToString:@"right"])
            _btnSetTextAlignRight.state = 1;
        
        _cgColorWell.color = selectedTileDescColor;
    }
}

- (void)controlTextDidChange:(NSNotification *)notification {
    //Not implemented
}

- (void)controlTextDidBeginEditing:(NSNotification *)notification {
    //Not implemented
}

- (void)controlTextDidEndEditing:(NSNotification *)notification {
    //Not implemented
}

-(void)mouseDownTextFieldClicked:(MouseDownTextField *)textField
{
    lastEditedField = textField.identifier;
    [self UpdateButtonStatesToMatchTextAttributes:lastEditedField];
}

//lazy load the collection view for better performance

- (void)boundDidChange:(NSNotification *)notification
{
    NSRect collectionViewVisibleRect = _timelineCollection.visibleRect;
    //collectionViewVisibleRect.size.height += 300; //If you want some preloading for lower cells...

    for (int i = 0; i < _images.count; i++) {
        NSCollectionViewItem *item = [_timelineCollection itemAtIndex:i];
        if (NSPointInRect(NSMakePoint(item.view.frame.origin.x, item.view.frame.origin.y), collectionViewVisibleRect) == YES)
        {
            if (item.imageView.image == nil) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    TimelineCollectionViewItem* obj = [[TimelineCollectionViewItem alloc] init];
                    obj.thumbImageContent = [_images objectAtIndex:i];
                    obj.frameText = ((EDL*)_EDLs[i]).destIn;//[_timeFrames objectAtIndex:i];
                    
                    item.representedObject = obj;
                });
            }
        }
    }
}

-(void)validateUserDatabase{
    
    //Connect to the user database - creates if not exists
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *writableDBPath = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@",self.username]];
    self.database = [FMDatabase databaseWithPath:writableDBPath];

    [_database open];
    
    @try{
        //Create PROJECTS table in database if not exists
        [self deleteTransitions];
        [self deleteProductsAndPeople];
        
        [self.database executeUpdate:@"CREATE TABLE if not exists PROJECTS "
         "(PROJECT_ID INTEGER PRIMARY KEY AUTOINCREMENT, PROJECT_NAME TEXT)"];
        
        BOOL success;
        
        //Create ASSETS table in database if not exists
        [self.database executeUpdate:@"CREATE TABLE if not exists ASSETS "
         "(ASSET_ID INTEGER PRIMARY KEY AUTOINCREMENT, ASSET_NAME TEXT, ASSET_PATH TEXT, ASSET_TYPE TEXT, ASSET_PRJ_ID INTEGER NOT NULL, FOREIGN KEY (ASSET_PRJ_ID) REFERENCES PROJECTS (PROJECT_ID))"];
        
        if (![self.database columnExists:@"BOOKMARK_DATA" inTableWithName:@"ASSETS"])
        {
            success = [self.database executeUpdate:@"ALTER TABLE ASSETS ADD COLUMN BOOKMARK_DATA BLOB"];
            NSAssert(success, @"alter table failed: %@", [self.database lastErrorMessage]);
        }
        
        //Create SOUNDS table in database if not exists
        [self.database executeUpdate:@"CREATE TABLE if not exists TRANSITION_SOUNDS "
         "(TRANSITION_ID INTEGER PRIMARY KEY AUTOINCREMENT, TRANSITION_NAME TEXT, LOCAL_PATH TEXT, AWS_PATH TEXT, TRANSITION_PRJ_ID INTEGER NOT NULL, FOREIGN KEY (TRANSITION_PRJ_ID) REFERENCES PROJECTS (PROJECT_ID))"];
        
        if (![self.database columnExists:@"LOCAL_BOOKMARK" inTableWithName:@"TRANSITION_SOUNDS"])
        {
            success = [self.database executeUpdate:@"ALTER TABLE TRANSITION_SOUNDS ADD COLUMN LOCAL_BOOKMARK BLOB"];
            NSAssert(success, @"alter table failed: %@", [self.database lastErrorMessage]);
        }
        
        //Create TRANSITIONS table in database if not exists
        [self.database executeUpdate:@"CREATE TABLE if not exists TRANSITIONS "
         "(TRANSITION_ID INTEGER PRIMARY KEY AUTOINCREMENT, TRANSITION_NAME TEXT, TRANSITION_FRAME_COUNT TEXT, TRANSITION_PRJ_ID INTEGER NOT NULL, FOREIGN KEY (TRANSITION_PRJ_ID) REFERENCES PROJECTS (PROJECT_ID))"];
        
        if (![self.database columnExists:@"TRANSITION_FRAME_COUNT" inTableWithName:@"TRANSITIONS"])
        {
            success = [self.database executeUpdate:@"ALTER TABLE TRANSITIONS ADD COLUMN TRANSITION_FRAME_COUNT TEXT"];
            NSAssert(success, @"alter table failed: %@", [self.database lastErrorMessage]);
        }
        
        //Create TRANSITIONS table in database if not exists
        [self.database executeUpdate:@"CREATE TABLE if not exists TRANSITIONFILES "
         "(TRANSITION_FILE_ID INTEGER PRIMARY KEY AUTOINCREMENT, LOCAL_PATH TEXT, AWS_PATH TEXT, FILE_TRANSITION_ID INTEGER NOT NULL, FOREIGN KEY (FILE_TRANSITION_ID) REFERENCES TRANSITIONS (TRANSITION_ID))"];
        
        if (![self.database columnExists:@"LOCAL_BOOKMARK" inTableWithName:@"TRANSITIONFILES"])
        {
            success = [self.database executeUpdate:@"ALTER TABLE TRANSITIONFILES ADD COLUMN LOCAL_BOOKMARK BLOB"];
            NSAssert(success, @"alter table failed: %@", [self.database lastErrorMessage]);
        }
        //[self.database executeUpdate:@"DROP TABLE LIBRARY"];
        
        //Create LIBRARY table in database if not exists
        
        [self.database executeUpdate:@"CREATE TABLE if not exists LIBRARY "
         "(TILE_ID INTEGER PRIMARY KEY AUTOINCREMENT, TILE_ASSET_TYPE TEXT, TILE_ASSET_IMAGE_NAME TEXT, TILE_IMAGE_PATH TEXT, TILE_ICON TEXT, TILE_HEADING TEXT, TILE_DESC TEXT, TILE_PLATE_COLOR TEXT, TILE_TRANSITION TEXT, TILE_AUDIO_TRANSITION TEXT, TILE_LINK TEXT, INSTA_LINK TEXT, PINTEREST_LINK TEXT, TWITTER_LINK TEXT, TILE_HEADING_COLOR TEXT, TILE_DESC_COLOR TEXT, IS_HEADING_BOLD TEXT, IS_HEADING_ITALIC TEXT, IS_HEADING_UNDERLINE, TEXT, HEADING_ALIGNMENT TEXT, IS_DESC_BOLD TEXT, IS_DESC_ITALIC TEXT, IS_DESC_UNDERLINE TEXT, DESC_ALIGNMENT TEXT, ASSET_ID INTEGER NOT NULL, PROJECT_ID INTEGER NOT NULL, FOREIGN KEY (ASSET_ID) REFERENCES ASSETS (ASSET_ID), FOREIGN KEY (PROJECT_ID) REFERENCES PROJECTS (PROJECT_ID))"];
        
        if (![self.database columnExists:@"TRANSITION_FRAME_COUNT" inTableWithName:@"LIBRARY"])
        {
            success = [self.database executeUpdate:@"ALTER TABLE LIBRARY ADD COLUMN TRANSITION_FRAME_COUNT TEXT"];
            NSAssert(success, @"alter table failed: %@", [self.database lastErrorMessage]);
        }
        
        if (![self.database columnExists:@"SHOW_TILE_IN_SIDEBAR" inTableWithName:@"LIBRARY"])
        {
            success = [self.database executeUpdate:@"ALTER TABLE LIBRARY ADD COLUMN SHOW_TILE_IN_SIDEBAR TEXT"];
            NSAssert(success, @"alter table failed: %@", [self.database lastErrorMessage]);
        }
        
        if (![self.database columnExists:@"ARTIST_ID" inTableWithName:@"LIBRARY"])
        {
            success = [self.database executeUpdate:@"ALTER TABLE LIBRARY ADD COLUMN ARTIST_ID TEXT"];
            NSAssert(success, @"alter table failed: %@", [self.database lastErrorMessage]);
        }
        
        if (![self.database columnExists:@"PRODUCT_ID" inTableWithName:@"LIBRARY"])
        {
            success = [self.database executeUpdate:@"ALTER TABLE LIBRARY ADD COLUMN PRODUCT_ID TEXT"];
            NSAssert(success, @"alter table failed: %@", [self.database lastErrorMessage]);
        }
        
        if (![self.database columnExists:@"IS_TILE_DEFAULT" inTableWithName:@"LIBRARY"])
        {
            success = [self.database executeUpdate:@"ALTER TABLE LIBRARY ADD COLUMN IS_TILE_DEFAULT TEXT"];
            NSAssert(success, @"alter table failed: %@", [self.database lastErrorMessage]);
        }
        
        if (![self.database columnExists:@"USE_PROFILE_AS_ICON" inTableWithName:@"LIBRARY"])
        {
            success = [self.database executeUpdate:@"ALTER TABLE LIBRARY ADD COLUMN USE_PROFILE_AS_ICON TEXT"];
            NSAssert(success, @"alter table failed: %@", [self.database lastErrorMessage]);
        }
        
        if (![self.database columnExists:@"TILE_ASSET_TYPE" inTableWithName:@"LIBRARY"])
        {
            success = [self.database executeUpdate:@"ALTER TABLE LIBRARY ADD COLUMN TILE_ASSET_TYPE TEXT"];
            NSAssert(success, @"alter table failed: %@", [self.database lastErrorMessage]);
        }
        if (![self.database columnExists:@"TILE_ASSET_IMAGE_NAME" inTableWithName:@"LIBRARY"])
        {
            success = [self.database executeUpdate:@"ALTER TABLE LIBRARY ADD COLUMN TILE_ASSET_IMAGE_NAME TEXT"];
            NSAssert(success, @"alter table failed: %@", [self.database lastErrorMessage]);
        }
        
        if (![self.database columnExists:@"TILE_TRANSITION" inTableWithName:@"LIBRARY"])
        {
            success = [self.database executeUpdate:@"ALTER TABLE LIBRARY ADD COLUMN TILE_TRANSITION TEXT"];
            NSAssert(success, @"alter table failed: %@", [self.database lastErrorMessage]);
        }
        
        if (![self.database columnExists:@"TILE_AUDIO_TRANSITION" inTableWithName:@"LIBRARY"])
        {
            success = [self.database executeUpdate:@"ALTER TABLE LIBRARY ADD COLUMN TILE_AUDIO_TRANSITION TEXT"];
            NSAssert(success, @"alter table failed: %@", [self.database lastErrorMessage]);
        }
        
        if (![self.database columnExists:@"TILE_ICON" inTableWithName:@"LIBRARY"])
        {
            success = [self.database executeUpdate:@"ALTER TABLE LIBRARY ADD COLUMN TILE_ICON TEXT"];
            NSAssert(success, @"alter table failed: %@", [self.database lastErrorMessage]);
        }
        
        if (![self.database columnExists:@"INSTA_LINK" inTableWithName:@"LIBRARY"])
        {
            success = [self.database executeUpdate:@"ALTER TABLE LIBRARY ADD COLUMN INSTA_LINK TEXT"];
            NSAssert(success, @"alter table failed: %@", [self.database lastErrorMessage]);
        }
        if (![self.database columnExists:@"PINTEREST_LINK" inTableWithName:@"LIBRARY"])
        {
            success = [self.database executeUpdate:@"ALTER TABLE LIBRARY ADD COLUMN PINTEREST_LINK TEXT"];
            NSAssert(success, @"alter table failed: %@", [self.database lastErrorMessage]);
        }
        if (![self.database columnExists:@"TWITTER_LINK" inTableWithName:@"LIBRARY"])
        {
            success = [self.database executeUpdate:@"ALTER TABLE LIBRARY ADD COLUMN TWITTER_LINK TEXT"];
            NSAssert(success, @"alter table failed: %@", [self.database lastErrorMessage]);
        }
        if (![self.database columnExists:@"FB_LINK" inTableWithName:@"LIBRARY"])
        {
            success = [self.database executeUpdate:@"ALTER TABLE LIBRARY ADD COLUMN FB_LINK TEXT"];
            NSAssert(success, @"alter table failed: %@", [self.database lastErrorMessage]);
        }
        if (![self.database columnExists:@"TRANSPARENCY" inTableWithName:@"LIBRARY"])
        {
            success = [self.database executeUpdate:@"ALTER TABLE LIBRARY ADD COLUMN TRANSPARENCY TEXT"];
            NSAssert(success, @"alter table failed: %@", [self.database lastErrorMessage]);
        }
        if (![self.database columnExists:@"CATEGORY" inTableWithName:@"LIBRARY"])
        {
            success = [self.database executeUpdate:@"ALTER TABLE LIBRARY ADD COLUMN CATEGORY TEXT"];
            NSAssert(success, @"alter table failed: %@", [self.database lastErrorMessage]);
        }
        if (![self.database columnExists:@"NICK_NAME" inTableWithName:@"LIBRARY"])
        {
            success = [self.database executeUpdate:@"ALTER TABLE LIBRARY ADD COLUMN NICK_NAME TEXT"];
            NSAssert(success, @"alter table failed: %@", [self.database lastErrorMessage]);
        }
        
        if (![self.database columnExists:@"FIRST_NAME" inTableWithName:@"LIBRARY"])
        {
            success = [self.database executeUpdate:@"ALTER TABLE LIBRARY ADD COLUMN FIRST_NAME TEXT"];
            NSAssert(success, @"alter table failed: %@", [self.database lastErrorMessage]);
        }
        
        if (![self.database columnExists:@"LAST_NAME" inTableWithName:@"LIBRARY"])
        {
            success = [self.database executeUpdate:@"ALTER TABLE LIBRARY ADD COLUMN LAST_NAME TEXT"];
            NSAssert(success, @"alter table failed: %@", [self.database lastErrorMessage]);
        }
        
        //Create Products
        [self.database executeUpdate:@"CREATE TABLE if not exists PRODUCTS "
         "(ASSET_ID INTEGER PRIMARY KEY AUTOINCREMENT, ASSET_IDENTIFIER TEXT, ASSET_NAME TEXT, ASSET_IMAGE_PATH TEXT, ASSET_DESC TEXT, TILE_LINK1 TEXT, TILE_LINK2 TEXT, TILE_LINK3 TEXT, TILE_LINK4 TEXT, TILE_LINK5 TEXT, BRAND_NAME TEXT, PROJECT_ID INTEGER NOT NULL, FOREIGN KEY (PROJECT_ID) REFERENCES PROJECTS (PROJECT_ID))"];
        
        if (![self.database columnExists:@"GENERAL_CATEGORY" inTableWithName:@"PRODUCTS"])
        {
            success = [self.database executeUpdate:@"ALTER TABLE PRODUCTS ADD COLUMN GENERAL_CATEGORY TEXT"];
            NSAssert(success, @"alter table failed: %@", [self.database lastErrorMessage]);
        }
        
        if (![self.database columnExists:@"PRODUCT_TYPE" inTableWithName:@"PRODUCTS"])
        {
            success = [self.database executeUpdate:@"ALTER TABLE PRODUCTS ADD COLUMN PRODUCT_TYPE TEXT NOT NULL DEFAULT 'product'"];
            NSAssert(success, @"alter table failed: %@", [self.database lastErrorMessage]);
        }
        
        if (![self.database columnExists:@"KEYWORDS" inTableWithName:@"PRODUCTS"])
        {
            success = [self.database executeUpdate:@"ALTER TABLE PRODUCTS ADD COLUMN KEYWORDS TEXT"];
            NSAssert(success, @"alter table failed: %@", [self.database lastErrorMessage]);
        }
        
        if (![self.database columnExists:@"STORE_NAME" inTableWithName:@"PRODUCTS"])
        {
            success = [self.database executeUpdate:@"ALTER TABLE PRODUCTS ADD COLUMN STORE_NAME TEXT"];
            NSAssert(success, @"alter table failed: %@", [self.database lastErrorMessage]);
        }
        
        if (![self.database columnExists:@"PRODUCT_ID" inTableWithName:@"PRODUCTS"])
        {
            success = [self.database executeUpdate:@"ALTER TABLE PRODUCTS ADD COLUMN PRODUCT_ID TEXT"];
            NSAssert(success, @"alter table failed: %@", [self.database lastErrorMessage]);
        }
        
        //Create People
        [self.database executeUpdate:@"CREATE TABLE if not exists PEOPLE "
         "(ASSET_ID INTEGER PRIMARY KEY AUTOINCREMENT, ASSET_IDENTIFIER TEXT, ASSET_NAME TEXT, FIRST_NAME TEXT, LAST_NAME TEXT, ASSET_IMAGE_PATH TEXT, ASSET_DESC TEXT, FACEBOOK_LINK TEXT, INSTAGRAM_LINK TEXT, PINTEREST_LINK TEXT, TWITTER_LINK TEXT, WEBSITE_LINK TEXT, PROJECT_ID INTEGER NOT NULL, FOREIGN KEY (PROJECT_ID) REFERENCES PROJECTS (PROJECT_ID))"];
        
        if (![self.database columnExists:@"NICK_NAME" inTableWithName:@"PEOPLE"])
        {
            success = [self.database executeUpdate:@"ALTER TABLE PEOPLE ADD COLUMN NICK_NAME TEXT"];
            NSAssert(success, @"alter table failed: %@", [self.database lastErrorMessage]);
        }
        
        //Read existing projects and assets, if any
        FMResultSet* prjResults = [self.database executeQuery:@"SELECT * FROM PROJECTS"];
        while([prjResults next])
        {
            Project* prj = [[Project alloc]init];
            prj.projectId = [prjResults intForColumn:@"PROJECT_ID"];
            prj.projectName = [prjResults stringForColumn:@"PROJECT_NAME"];
            
            prj.assets = [[NSMutableArray alloc] init];
            
            FMResultSet* assetResults = [self.database executeQuery:[NSString stringWithFormat:@"SELECT * FROM ASSETS WHERE ASSET_PRJ_ID=%d", prj.projectId]];
            while ([assetResults next]) {
                Asset* asset = [[Asset alloc] init];
                asset.assetId = [assetResults intForColumn:@"ASSET_ID"];
                asset.assetName = [assetResults stringForColumn:@"ASSET_NAME"];
                asset.assetFilePath = [assetResults stringForColumn:@"ASSET_PATH"];
                asset.assetType = [assetResults stringForColumn:@"ASSET_TYPE"];
                asset.assetProjectId = [assetResults intForColumn:@"ASSET_PRJ_ID"];
                asset.assetBookmark = [assetResults dataForColumn:@"BOOKMARK_DATA"];

                //add assets to project
                [prj.assets addObject:asset];
            }
            [assetResults close];
            
            prj.transitions = [[NSMutableArray alloc] init];
            
            FMResultSet* transitionResults = [self.database executeQuery:[NSString stringWithFormat:@"SELECT * FROM TRANSITIONS WHERE TRANSITION_PRJ_ID=%d", prj.projectId]];
            while ([transitionResults next]) {
                NSString* transition = [transitionResults stringForColumn:@"TRANSITION_NAME"];
                
                //add assets to project
                [prj.transitions addObject:transition];
            }

            prj.sounds = [[NSMutableArray alloc] init];
            
            FMResultSet* transitionSoundResults = [self.database executeQuery:[NSString stringWithFormat:@"SELECT * FROM transition_sounds WHERE TRANSITION_PRJ_ID=%d", prj.projectId]];
            while ([transitionSoundResults next]) {
                NSString* transition = [transitionSoundResults stringForColumn:@"TRANSITION_NAME"];
                
                //add assets to project
                [prj.sounds addObject:transition];
            }

            //add project to araay
            [_userProjects addObject:prj];
        }
        [prjResults close];
        //close database connection
        [_database close];
    }
    @catch(NSException* exp){
        [_database close];
        NSLog(@"Error creating/reading database: %@",exp);
    }
    
    //update table
    [_tblProjectsList reloadData];
    
    if(_userProjects.count > 0)
    {
        int index = 0;
        //get last saved project id
        NSNumber* projectid = [[NSUserDefaults standardUserDefaults] valueForKey:[NSString stringWithFormat:@"LastSavedProject-%@", _username]];

        if(projectid != nil){
            for (int i = 0; i < _userProjects.count; i++) {
                if(((Project*)_userProjects[i]).projectId == projectid.intValue){
                    index = i;
                    break;
                }
            }
        }
        [self LoadProjectAtIndex:index];
    }
    else
    {
        _tblProjectsList.hidden = true;
    }
}

-(void)LoadProjectAtIndex:(int)index{
    _currentSelectedProject = [_userProjects objectAtIndex:index];
    _currentProjectIndex = index;
    _tblProjectsList.hidden = false;
    
    [self setActiveProjectTitle:_currentSelectedProject.projectName collapse:false];
    
    //[self performSelector:@selector(highlightActiveProjectInList:) withObject:@"0" afterDelay:1];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self highlightActiveProjectInList:index];
    });
    
    [self getExportedProjectDetails];
    
    [_embedImagesCollectionView reloadData];
    
    _btnAddFiles.hidden = NO;
    
    if(!checkSavedDataCalled)
    {
        checkSavedDataCalled = true;
        
        [self checkSavedData];
    }
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    if(tableView.tag == 10)
        return self.userProjects.count;
    else if(tableView.tag == 11)
    {
        _assetsOfSelectedType = [[NSMutableArray alloc] init];
        
        if(self.userProjects.count > _currentProjectIndex)
        {
            NSArray* assets = ((Project*)[self.userProjects objectAtIndex:_currentProjectIndex]).assets;
            for (int i = 0; i < assets.count; i++) {
                if([_selectedAssetTypes containsObject:((Asset*)assets[i]).assetType])
                    [_assetsOfSelectedType addObject:assets[i]];
            }
        }
        return _assetsOfSelectedType.count;
    }
    else if(tableView.tag == 12)
    {
        return _binFiles.count;
    }
    else if(tableView.tag == 20)//conform videos
    {
        return _conformVideoFiles.count;
    }
    else if(tableView.tag == 21)//conform EDLs
    {
        return _conformEDLFiles.count;
    }
    else if(tableView.tag == 30)//Selected EDL List
    {
        return _EDLs.count;
    }
    else
        return 0;
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    if(tableView.tag == 10)//projects
    {
        ProjectsCellView *cellView = [tableView makeViewWithIdentifier:@"ProjectsCellView" owner:self];
        cellView.backgroundStyle = NSBackgroundStyleDark;
        cellView.projectName.stringValue = ((Project*)[self.userProjects objectAtIndex:row]).projectName;
        
        return cellView;
    }
    else if(tableView.tag == 11)//assets
    {
        ItemSelectionCellView *cellView = [tableView makeViewWithIdentifier:@"ItemSelectionCellView" owner:self];
        cellView.backgroundStyle = NSBackgroundStyleDark;
        cellView.isSelected = true;
        
        Asset* _currAsset = [_assetsOfSelectedType objectAtIndex:row];
        cellView.AssetForItem = _currAsset;        
        cellView.ListItem.state = 1;
        cellView.ListItem.title = _currAsset.assetName;
        
        return cellView;
    }
    else if(tableView.tag == 12)//Bin
    {
        NSTableCellView *cellView = [tableView makeViewWithIdentifier:@"DefaultTableCellView" owner:self];
        cellView.backgroundStyle = NSBackgroundStyleDark;
        
        Asset* _currAsset = [_binFiles objectAtIndex:row];
        cellView.textField.stringValue = _currAsset.assetName;
        
        return cellView;
    }
    else if(tableView.tag == 20)//conform videos
    {
        ItemSelectionCellView *cellView = [tableView makeViewWithIdentifier:@"ItemSelectionCellView" owner:self];
        cellView.backgroundStyle = NSBackgroundStyleDark;
        cellView.isSelected = false;
        
        Asset* _currAsset = [_conformVideoFiles objectAtIndex:row];
        cellView.AssetForItem = _currAsset;
        cellView.ListItem.state = 0;
        cellView.ListItem.title = _currAsset.assetName;
        cellView.ListItem.tag = row;
        
        return cellView;
    }
    else if(tableView.tag == 21)//conform edls
    {
        ItemSelectionCellView *cellView = [tableView makeViewWithIdentifier:@"ItemSelectionCellView" owner:self];
        cellView.backgroundStyle = NSBackgroundStyleDark;
        cellView.isSelected = false;
        
        Asset* _currAsset = [_conformEDLFiles objectAtIndex:row];
        cellView.AssetForItem = _currAsset;
        cellView.ListItem.state = 0;
        cellView.ListItem.title = _currAsset.assetName;
        cellView.ListItem.tag = row;
        
        return cellView;
    }
    else if(tableView.tag == 30)//Selected EDL
    {
        NSTableCellView *cellView = [tableView makeViewWithIdentifier:@"DefaultTableCellView" owner:self];
        cellView.backgroundStyle = NSBackgroundStyleDark;
        
        EDL* _currEDL = [_EDLs objectAtIndex:row];
        
        NSMutableAttributedString* edlString = [[NSMutableAttributedString alloc] init];
        
       
        //ADD EDL INFORMATION
        NSDictionary *_blueColorAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                 [NSFont systemFontOfSize:9], NSFontAttributeName, [NSColor colorWithCalibratedRed:(CGFloat)31/255 green:(CGFloat)152/255 blue:255/255 alpha:1], NSForegroundColorAttributeName, nil];
        
        NSAttributedString* blueString = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@ %@ %@ %@",_currEDL.editNumber, _currEDL.reelName, _currEDL.channel, _currEDL.operation] attributes:_blueColorAttributes];
        
        [edlString appendAttributedString:blueString];
        
        //ADD SOURCE AND DEST TIMES
        NSDictionary *_orangeColorAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                              [NSFont systemFontOfSize:9], NSFontAttributeName, [NSColor colorWithCalibratedRed:(CGFloat)255/255 green:(CGFloat)123/255 blue:(CGFloat)19/255 alpha:1], NSForegroundColorAttributeName, nil];
        
        NSAttributedString* orangeString = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@" %@ %@ %@ %@",_currEDL.sourceIn, _currEDL.sourceOut, _currEDL.destIn, _currEDL.destOut] attributes:_orangeColorAttributes];
        
        [edlString appendAttributedString:orangeString];
        
        cellView.textField.attributedStringValue = edlString;
        
       // cellView.textField.lineBreakMode = NSLineBreakByTruncatingMiddle;
        
        return cellView;
    }
    else
        return nil;
}

-(void)projectsSelectionChanged:(id)sender
{
    int _r = [_tblProjectsList selectedRow];
    _currentSelectedProjectIndex = _r;

    if (_currentSelectedProjectIndex != _currentProjectIndex) {
        [_btnRemoveProject setHidden:false];
    }
    else {
        [_btnRemoveProject setHidden:true];
    }

    [self highlightSelectedProjectInList:_r];
}

-(void)highlightSelectedProjectInList:(int)index{

    if(index > _userProjects.count)
        index = 0;

    for (int i = 0; i < _userProjects.count; i++) {
        // Get row at specified index
        ProjectsCellView *selectedRow = [_tblProjectsList viewAtColumn:0 row:i makeIfNecessary:YES];

        // Get row's text field
        NSTextField *selectedRowTextField = [selectedRow projectName];

        if(i == index && i != _currentProjectIndex)
            selectedRowTextField.textColor = [NSColor redColor];
        else if(i == _currentProjectIndex)
            selectedRowTextField.textColor = [NSColor orangeColor];
        else
            selectedRowTextField.textColor = [NSColor blackColor];
    }
}

-(void)assetsSelectionChanged:(id)sender
{
    //int _r = [_tblImportAssets selectedRow];

    //NSLog(@"Selected Asset:%@",((Asset*)[_currentSelectedProject.assets objectAtIndex:_r]).assetName);
}

-(Asset*)getAssetForTile:(int)index{
    if(_currentSelectedProject != nil)
    {
        for (int i = 0; i < _currentSelectedProject.assets.count; i++) {
            Asset* _a = _currentSelectedProject.assets[i];
            if(_a.assetId == index)
                return _a;
        }
    }
    else
        return nil;
    
    return nil;
}

-(void)EDLSelectionChanged:(id)sender
{
    if(_actualTimes.count > 0 && !userSelection)
    {
        userSelection = true;
        int _r = [_tblEDLs selectedRow];
        
        //Navigate to the frame
        [self selectFrameAtIndex:_r];
        
        //Seek to frame time
        //CMTime _t = [[_edlFramesArray objectAtIndex:_r] CMTimeValue];
        
//        CMTime _t = [self parseTimecodeStringIntoCMTime:((EDL*)(_EDLs[_r])).destIn];
        CMTime _t = ((EDL*)(_EDLs[_r])).time;
        
        [self seekToTimeAtVideo:_t frameIndex:_r];
    }
}

-(NSInteger)numberOfSectionsInCollectionView:(NSCollectionView *)collectionView
{
    return 1;
}

-(NSInteger)collectionView:(NSCollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    if([collectionView.identifier isEqualToString:@"mainCollectionView"] || [collectionView.identifier isEqualToString:@"exportCollectionView"] )
    {
        return _images.count;
    }
    else if([collectionView.identifier isEqualToString:@"imageAssetsCollectionView"])
    {
        if(_btnEmbedPeopleBorder.isHidden)
            return _embedImageAssets.count;
        else
            return _embedPeopleAssets.count;
    }
    else if([collectionView.identifier isEqualToString:@"libraryCollectionView"])
    {
        return _ADTileLibrary.count;
    }
    else
    {
        return 0;
    }
}

-(void)seekToTimeAtVideo:(CMTime)frameTime frameIndex:(int)frameIndex
{
    if(currentSceneIndex != frameIndex) {
        currentSceneIndex = frameIndex;
        currentSelectedADTile = nil;
    }

    [self.quickPlaceView setHidden:false];
    [self updateQuickPlaceBtnState];

    [self.playerView.player seekToTime:frameTime toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
    if(self.playerView.player.rate != 0 && self.playerView.player.error == nil)
    {
        [self.playerView.player play];
    }

    [self clearAllTileOnEditFrame];
    [self showADTilesForCurrentFrame];
    [self updateEDLSlider];
    [self showCurrentFrameNumber:frameTime];
    userSelection = false;
    if(turnOnLoop)
    {
        turnOnLoop = false;
        isCurrentEditInLoop = true;
        [_btnLoop setState:NSControlStateValueOn];
    }
}

-(void)collectionView:(NSCollectionView *)collectionView didSelectItemsAtIndexPaths:(NSSet<NSIndexPath *> *)indexPaths
{

    //NSInteger index = collectionView.selectionIndexPaths.objectEnumerator[0];
    
    //NSInteger index = indexPaths(0).item;
    
    NSArray<NSIndexPath*>* myset = indexPaths.allObjects;
    
    NSArray<NSIndexPath*>* myset2 = _timelineCollection.selectionIndexPaths.allObjects;
    
    if(myset2.count > 0)
    {
        allSelectedEdits = [NSMutableArray array];
        
        for (int i =0; i < myset2.count; i++) {
            [allSelectedEdits addObject:[NSNumber numberWithInteger:myset2[i].item]];
        }
    }
    
    if([collectionView.identifier isEqualToString:@"mainCollectionView"] )
    {
        //NSNumber* secs = [_actualTimes objectAtIndex:myset[0].item];
        [self pauseAudio];
        
        BOOL is_paused = false;
        if(self.playerView.player.rate != 0){
           [self.playerView.player pause];
            is_paused = true;
        }
        else
            [self pauseAnimations]; //video is not playing so don't play animations
        userSelection = true;
        //CMTime _t = [self parseTimecodeStringIntoCMTime:((EDL*)(_EDLs[myset[0].item])).destIn];//[[_edlFramesArray objectAtIndex:myset[0].item] CMTimeValue];
        turnOnLoop = false;
        if(isCurrentEditInLoop){
            isCurrentEditInLoop = false;
            [_btnLoop setState:NSControlStateValueOff];
            turnOnLoop = true;
        }                
        
        [self seekToTimeAtVideo:((EDL*)(_EDLs[myset[0].item])).time frameIndex:myset[0].item];
        
        [self selectEDLinTableAtIndex:myset[0].item];
        
        //center selection
        [self scrollItemToCenter];
        if(is_paused){
            [self.playerView.player play];
            [self resumeAnimations];
        }
    }
    else if([collectionView.identifier isEqualToString:@"imageAssetsCollectionView"])
    {
        
        if(isTileInEditMode)
        {
            NSAlert *alert = [[NSAlert alloc] init];
            [alert addButtonWithTitle:@"Yes"];
            [alert addButtonWithTitle:@"No"];
            [alert addButtonWithTitle:@"Cancel"];
            [alert setMessageText:@"Save Changes?"];
            [alert setInformativeText:@"Do you want to save changes to the current Tile before loading a new one?"];
            [alert setAlertStyle:NSWarningAlertStyle];
            
            NSModalResponse response = [alert runModal];
            
            if (response == NSAlertFirstButtonReturn) {
                // Yes Clicked
                
                //1. Save Current Tile
                [self saveUpdateCurrentTile];
                //2. Load Image for New Tile
                [self loadAssetForADTile:myset[0].item];
            }
            else if (response == NSAlertSecondButtonReturn)
            {
                //No Clicked
                
                //1. Discard Changes and Load Image for New Tile
                [self loadAssetForADTile:myset[0].item];
            }
            else{
                return;//exit
            }
        }
        else
        {
            [self loadAssetForADTile:myset[0].item];
        }
    }
    /*else if([collectionView.identifier isEqualToString:@"exportCollectionView"])
    {
        NSNumber* secs = [_actualTimes objectAtIndex:myset[0].item];
        [self.playerExport.player seekToTime:CMTimeMakeWithSeconds(secs.doubleValue,1)];
        //[self.playerExport.player play];
        _selectedThumbnail = [_images objectAtIndex:myset[0].item];
    }*/
    else if([collectionView.identifier isEqualToString:@"libraryCollectionView"])
    {
        _selectedLibraryItemIndex = myset[0].item;
        
        _btnEditTile.enabled = true;
        
        if([((ADTile*)_ADTileLibrary[_selectedLibraryItemIndex]).assetType isEqualToString:@"cta"])
            _btnEditTile.enabled = false;
        
        _btnDeleteTile.enabled = true;
        _btnApplyTile.enabled = true;
    }
}

-(void)loadAssetForADTile:(int)assetIndex{
    isTileInEditCTA = false;
    [self resetTileEditorFromCTA];
    //selected an image to embed from the image assets library
    Asset* _a = [[Asset alloc] init];
    
    if(_btnEmbedPeopleBorder.isHidden)
        _a = (Asset*)[_embedImageAssets objectAtIndex:assetIndex];
    else
        _a = (Asset*)[_embedPeopleAssets objectAtIndex:assetIndex];
    
    if([_a.assetType isEqualToString:@"people"] || [_a.assetType isEqualToString:@"product"])
        [self resetADTileEditor:_a];
    else
        [self resetADTileEditor:nil];
    
    if([_a.assetType isEqualToString:@"people"] || [_a.assetType isEqualToString:@"product"])
        _imgSelectedAssetImage.image = _a.assetImage;
    else{
        //_imgSelectedAssetImage.image = [[NSImage alloc] initWithContentsOfFile:_a.assetFilePath];
        _imgSelectedAssetImage.image = [[NSImage alloc] initWithContentsOfURL:[self getURLfromBookmarkData:_a.assetBookmark]];
        
        //if(_imgSelectedAssetImage.image == nil)
         //   _imgSelectedAssetImage.image = [[NSImage alloc] initWithContentsOfURL:[NSURL URLWithString:_a.assetFilePath]];
        
        _imgSelectedAssetImage.hidden = false;
    }
    
    _selectedAssetForADTile = _a;
    
    [self setButtonTitle:_btnPlateColor toString:@"PLATE" withColor:[NSColor orangeColor] withSize:18];
    [self setButtonTitle:_btnTileTransition toString:@"Transition" withColor:[NSColor orangeColor] withSize:18];
    [self setButtonTitle:_btnTileText toString:@"Text" withColor:[NSColor orangeColor] withSize:18];
    [self setButtonTitle:_btnTileLink toString:@"Link" withColor:[NSColor orangeColor] withSize:18];
    
    _plateview.hidden = NO;
    _transitionView.hidden = YES;
    _tileTextView.hidden = YES;
    _tileLinkView.hidden = YES;
    
    _btnPlateColorBorder.hidden = NO;
    _btnTileTransitionBorder.hidden = YES;
    _btnTileTextBorder.hidden = YES;
    _btnTileLinkBorder.hidden = YES;
    
    
    isTileInEditMode = false;
    _toolBtn.enabled = true;
    _btnTileLink.enabled = true;
    _btnTileTransition.enabled = true;
}

-(void)resetADTileEditor:(Asset*)asset
{
    selectedImageTransitionIndex = -1;
    selectedAudioTransitionIndex = -1;
    
    _lblCTAduration.enabled = false;
    _ctaDurationSlider.enabled = false;
    
    if(asset == nil)
    {
        _txtTileHeading.stringValue = @"";
        _txtTileDescription.stringValue = @"";
        [_tileCategoryComboBox setObjectValue:@"No Category"];
        _tileCategoryComboBox.enabled = true;
        _txtTileLink.stringValue = @"";
        _txtInstaLink.stringValue = @"";
        _txtPinterestLink.stringValue = @"";
        _txtTwitterLink.stringValue = @"";
        _txtWebsiteLink.stringValue = @"";
        if(!isTileInEditCTA)
        {
            _imgSelectedAssetImage.image = nil;
            isTileInEditCTA = false;
        }
    }
    else
    {
        _btnTileTransition.enabled = true;
        _btnTileLink.enabled = true;
        _txtTileHeading.stringValue = @"";
        _txtTileDescription.stringValue = @"";
        
        _tileCategoryComboBox.enabled = false;
        [_tileCategoryComboBox setObjectValue:@"No Category"];
        
        _chkUseProfilePicAsIcon.enabled = true;
        
        _txtTileLink.stringValue = @"";
        _txtInstaLink.stringValue = @"";
        _txtPinterestLink.stringValue = @"";
        _txtTwitterLink.stringValue = @"";
        _txtWebsiteLink.stringValue = @"";
        
        _btnTileEditLinkFb.image = [NSImage imageNamed:@"fb-icon"];
        _btnTileEditLinkInsta.image = [NSImage imageNamed:@"instagram-icon"];
        _btnTileEditLinkPinterest.image = [NSImage imageNamed:@"pinterest-icon"];
        _btnTileEditLinkTwitter.image = [NSImage imageNamed:@"tw_icon"];
        
        
        if(asset.assetDisplayName != nil)
            _txtTileHeading.stringValue = asset.assetDisplayName;
        
        if(asset.assetProfileDescription != nil)
            _txtTileDescription.stringValue = asset.assetProfileDescription;
        
        if(asset.assetFacebookLink != nil)
            _txtTileLink.stringValue = asset.assetFacebookLink;
        if(asset.assetInstagraamLink != nil)
            _txtInstaLink.stringValue = asset.assetInstagraamLink;
        if(asset.assetPinterestLink!=nil)
            _txtPinterestLink.stringValue = asset.assetPinterestLink;
        if(asset.assetTwitterLink!=nil)
        _txtTwitterLink.stringValue = asset.assetTwitterLink;
        if(asset.assetWebsiteLink!=nil)
        _txtWebsiteLink.stringValue = asset.assetWebsiteLink;
        
        _chkIsTileDefault.state = 0;
        _chkShowTileInSidebox.state = 0;
        
        isTileInEditCTA = false;
        if([asset.assetType isEqualToString:@"cta"])
        {
            isTileInEditCTA = true;
            [self updateTileEditorForCTA];
        }
        
        if([asset.assetType isEqualToString:@"product"]){
            _btnTileEditLinkFb.image = [NSImage imageNamed:@"website"];
            _btnTileEditLinkInsta.image = [NSImage imageNamed:@"website"];
            _btnTileEditLinkPinterest.image = [NSImage imageNamed:@"website"];
            _btnTileEditLinkTwitter.image = [NSImage imageNamed:@"website"];
            
            if(asset.link1 != nil)
                _txtTileLink.stringValue = asset.link1;
            if(asset.link2 != nil)
                _txtInstaLink.stringValue = asset.link2;
            if(asset.link3!=nil)
                _txtPinterestLink.stringValue = asset.link3;
            if(asset.link4!=nil)
                _txtTwitterLink.stringValue = asset.link4;
            if(asset.link5!=nil)
                _txtWebsiteLink.stringValue = asset.link5;
        }
    }
    

    
    isTileTextUnderline = false;
    isTileTextItalic = false;
    isTileTextBold = false;
    selectedTileTextColor = [NSColor whiteColor];
    
    isTileDescBold = false;
    isTileDescItalic = false;
    isTileDescUnderline = false;
    selectedTileDescColor = [NSColor whiteColor];
    
    isTileInEditMode = false;
    currentEditingTileIndex = -1;
}


-(NSCollectionViewItem *)collectionView:(NSCollectionView *)collectionView itemForRepresentedObjectAtIndexPath:(NSIndexPath *)indexPath
{
    if([collectionView.identifier isEqualToString:@"mainCollectionView"] || [collectionView.identifier isEqualToString:@"exportCollectionView"])
    {
        if(_images.count > 0)
        {
            //TimelineCollectionViewItem* item = [self.storyboard instantiateControllerWithIdentifier:@"TimelineCollectionViewItem"];
            
            NSCollectionViewItem* item = [collectionView makeItemWithIdentifier:@"timelineItem" forIndexPath:indexPath];
            
            TimelineCollectionViewItem* obj = [[TimelineCollectionViewItem alloc] init];
            obj.thumbImageContent = [_images objectAtIndex:indexPath.item];
            
            //CMTime _t = [[_edlFramesArray objectAtIndex:indexPath.item] CMTimeValue];
            
            obj.frameText = ((EDL*)_EDLs[indexPath.item]).destIn;//[_timeFrames objectAtIndex:indexPath.item];
            
            item.representedObject = obj;
            
            //item.thumbImage.image = [_images objectAtIndex:indexPath.item];
            //[item.frameTime setStringValue:@"00:15"];
            
            return item;
        }
        else
            return nil;
    }
    else if([collectionView.identifier isEqualToString:@"imageAssetsCollectionView"])
    {
        if(_btnEmbedPeopleBorder.isHidden)
        {
            if(_embedImageAssets.count > 0)
            {
                NSCollectionViewItem* item = [collectionView makeItemWithIdentifier:@"ImageAssetItem" forIndexPath:indexPath];
                
                AssetItem* obj = [[AssetItem alloc] init];
                
                Asset* _a = (Asset*)[_embedImageAssets objectAtIndex:indexPath.item];
                
                if([_a.assetType isEqualToString:@"product"])
                    obj.thumbImageContent = _a.assetImage;
                else{
                    //obj.thumbImageContent = [[NSImage alloc]initWithContentsOfFile:_a.assetFilePath];
                    obj.thumbImageContent = [[NSImage alloc] initWithContentsOfURL:[self getURLfromBookmarkData:_a.assetBookmark]];
                }
                
                obj.assetForItem = _a;
                
                item.representedObject = obj;
                
                return item;
            }
            else
                return nil;
        }
        else
        {
            if(_embedPeopleAssets.count > 0)
            {
                NSCollectionViewItem* item = [collectionView makeItemWithIdentifier:@"ImageAssetItem" forIndexPath:indexPath];
                
                AssetItem* obj = [[AssetItem alloc] init];
                
                Asset* _a = (Asset*)[_embedPeopleAssets objectAtIndex:indexPath.item];
                
                obj.thumbImageContent = _a.assetImage;
                obj.assetForItem = _a;
                
                item.representedObject = obj;
                
                return item;
            }
            else
                return nil;
        }
    }
    else if([collectionView.identifier isEqualToString:@"libraryCollectionView"])
    {
        if(_ADTileLibrary.count > 0)
        {
            
            NSCollectionViewItem* item = [collectionView makeItemWithIdentifier:@"LibraryCollectionItem" forIndexPath:indexPath];
            
            LibraryItem* obj = [[LibraryItem alloc] init];
            
            ADTile* _a = (ADTile*)[_ADTileLibrary objectAtIndex:indexPath.item];
            
            if([_a.assetType isEqualToString:@"people"] || [_a.assetType isEqualToString:@"product"])
            {
                if([_a.assetType isEqualToString:@"product"] && _a.tileCategory != nil && _a.tileCategory.length > 0 &&[_a.tileCategory isNotEqualTo:@"No Category"])
                    obj.thumbImage = [NSImage imageNamed:[NSString stringWithFormat:@"%@.png",_a.tileCategory]];
                else
                    obj.thumbImage = [[NSImage alloc]initWithContentsOfURL:[NSURL URLWithString:_a.assetImagePath]];
            }
            else if([_a.assetType isEqualToString:@"cta"])
            {
                obj.thumbImage = [NSImage imageNamed:@"tap"];
            }
            else
                obj.thumbImage = [[NSImage alloc]initWithContentsOfFile:_a.assetImagePath];
            
            obj.heading = _a.tileHeadingText;
            obj.desc = _a.tileDescription;
            obj.plateColor = _a.tilePlateColor;
            
            item.representedObject = obj;
            
            return item;
        }
        else
            return nil;
    }
    else
    {
        return nil;
    }
}



-(void)updateVideoController
{
    if(mTimeObserver != nil)
        [_playerView.player removeTimeObserver:mTimeObserver];
    
    self.playerView.player = [AVPlayer playerWithPlayerItem:[self.movieMutator makePlayerItem]];
    self.playerView.layer.backgroundColor = [[NSColor lightGrayColor] CGColor];
    
    self.playerView.videoGravity = AVLayerVideoGravityResizeAspectFill;
    
    /*
    NSDictionary* attributes =
    @{
      (NSString*)kCVPixelBufferPixelFormatTypeKey: @(kCVPixelFormatType_32ARGB),
      //        (NSString*)kCVPixelBufferBytesPerRowAlignmentKey: @1,
      (NSString*)kCVPixelBufferOpenGLCompatibilityKey: @YES
      };
    
    self.output = [[AVPlayerItemVideoOutput alloc] initWithPixelBufferAttributes:attributes];
    
    [self.playerView.player.currentItem addObserver:self forKeyPath:kStatusKey options:NSKeyValueObservingOptionInitial context:&kStatusKey];
    [self.playerView.player addObserver:self forKeyPath:kStatusKey options:NSKeyValueObservingOptionInitial context:&kStatusKey];
    */
    
    [self.playerView.player seekToTime:kCMTimeZero];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(videoReachedToEnd) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    mTimeObserver = [_playerView.player addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(0.1, NSEC_PER_SEC)
                                                                     queue:NULL /* If you pass NULL, the main queue is used. */
                                                                usingBlock:^(CMTime time)
                     {
                         if(!userSelection && self.playerView.player.rate != 0){
                             [self showCurrentFrameNumber:time];
                             [self getFrameRateFromAVPlayer];
                             [self syncFrames:time];
                             [self updateEDLSlider];
                         }
                     }];
}

- (void) observeValueForKeyPath:(NSString*)inKeyPath ofObject:(id)inObject change:(NSDictionary*)inChange context:(void*)inContext
{
    
    if (inContext == &kStatusKey)
    {
       // __weak typeof(self) weakSelf = self;
        AVPlayer* player = _playerView.player;
        AVPlayerItem* playerItem = player.currentItem;
        
        if (player.status == AVPlayerStatusReadyToPlay && playerItem.status == AVPlayerItemStatusReadyToPlay)
        {
            [playerItem addOutput:self.output];
            
            
                 
                 CMTime itemTime = CMTimeMakeWithSeconds(16,1);
                 CMTime msItemTime = CMTimeMake(10,100);
                 
                 itemTime = CMTimeAdd(itemTime, msItemTime);
                 
                 if ([_output hasNewPixelBufferForItemTime:itemTime])
                 {
                    /* CVPixelBufferRef buffer = [_output copyPixelBufferForItemTime:itemTime itemTimeForDisplay:nil];
                     
                     if (buffer)
                     {
                         CIImage* frameImage = [CIImage imageWithCVPixelBuffer:buffer];
                         
                         NSCIImageRep *rep = [NSCIImageRep imageRepWithCIImage:frameImage];
                         NSImage *nsImage = [[NSImage alloc] initWithSize:rep.size];
                         [nsImage addRepresentation:rep];
                         
                         [self.previewThumbImageView setImage:nsImage];
                         self.previewThumbImageView.hidden = false;
                         CVPixelBufferRelease(buffer);
                     }
                     */
                     NSLog(@"lgo1 1");
                 }
            
        }
    }
    else
    {
        [super observeValueForKeyPath:inKeyPath ofObject:inObject change:inChange context:inContext];
    }
}

-(void)videoReachedToEnd{
    if(_btnLoop.state == 1)
    {
        [_playerView.player seekToTime:kCMTimeZero];
        [_playerView.player play];
        //_playerView.player.rate = 0.96;
    }
    else
    {
        [_btnPlayPause setImage:[NSImage imageNamed:@"play"]];
    }
}

-(void)uploadImageForTile:(ADTile*)tile
{
    /*
    AWSS3TransferManagerUploadRequest *thumbnailUploadRequest = [AWSS3TransferManagerUploadRequest new];
    thumbnailUploadRequest.bucket = @"com.bon2.mediadatastore";
    thumbnailUploadRequest.key = [NSString stringWithFormat:@"%@.png", filename];
    thumbnailUploadRequest.body = _selectedThumbnailUrl;
    thumbnailUploadRequest.ACL = AWSS3ObjectCannedACLPublicRead;
    thumbnailUploadRequest.contentType = @"image/png";
    //uploadRequest.contentLength = [NSNumber numberWithUnsignedLongLong:fileSize];
    
    [[[AWSS3TransferManager S3TransferManagerForKey:@"ncalifornia" ] upload:thumbnailUploadRequest] continueWithBlock:^id(AWSTask *task) {
        if(task.error)
        {
            
            [_uploadProgress stopAnimation:_uploadProgress];
            _uploadProgress.hidden = true;
            
            NSLog(@"%@", task.error);
            _btnExport.enabled = true;
            _btnExport.state = 0;
        }
        else
        {
            thumbnailUrl = [NSString stringWithFormat:@"https://s3-us-west-1.amazonaws.com/com.bon2.mediadatastore/%@/%@.png", _username, filename];
            if(videoUrl != nil && thumbnailUrl != nil)
            {
                [self makePostAPICall:videoUrl thumbnailUrl:thumbnailUrl];
                thumbnailUrl = nil;
            }
            
            NSLog(@"%@", @"Image Uploaded.");
        }
        
        return nil;
    }];*/
}




- (void)keyDown:(NSEvent *)theEvent {
    //if(![theEvent modifierFlags] & !NSControlKeyMask)
   // {
       // if([[theEvent characters] isEqualToString:@" "])
        //{
         //   NSLog(@"SPACE");
          //  [self playPause];
     //          }
    //}
    
}

-(void)generateThumbnailAtTimeCode:(CMTime) time index:(int)currentSceneIndex{
    /*AVAsset *asset = _playerView.player.currentItem.asset;
    AVAssetImageGenerator *imageGenerator = [[AVAssetImageGenerator alloc]initWithAsset:asset];
    
    [imageGenerator setAppliesPreferredTrackTransform:TRUE];
    imageGenerator.requestedTimeToleranceAfter = kCMTimeZero;
    imageGenerator.requestedTimeToleranceBefore = kCMTimeZero;
    
    [imageGenerator setRequestedTimeToleranceAfter:kCMTimeZero];
    [imageGenerator setRequestedTimeToleranceBefore:kCMTimeZero];
    
    imageGenerator.maximumSize = CGSizeMake(338, 154);
    
    imageGenerator.apertureMode = AVAssetImageGeneratorApertureModeProductionAperture;
    
    NSError* error = nil;
    CMTime actualTime;
    CGImageRef imageRef = [imageGenerator copyCGImageAtTime:time actualTime:&actualTime error:&error];
    NSImage *thumbnail;
    if(error == nil){
        thumbnail = [[NSImage alloc] initWithCGImage:imageRef size:NSMakeSize(CGImageGetWidth(imageRef), CGImageGetHeight(imageRef))];
    }
    else
        thumbnail = [NSImage imageNamed:@"bon2-scope"];
    CGImageRelease(imageRef);  // CGImageRef won't be released by ARC
    
    */
    
    NSUInteger dTotalSeconds = CMTimeGetSeconds(time);
    
    double _fl = CMTimeGetSeconds(time);
    
    /*float val = actualTime.value;
    float ts = actualTime.timescale;
    
    float _fl1 = val/ts;
    NSLog(@"actual time: %f", _fl1);
    
    float _fl = CMTimeGetSeconds(actualTime);*/
    
    NSUInteger dHours = floor(dTotalSeconds / 3600);
    NSUInteger dMinutes = floor(dTotalSeconds % 3600 / 60);
    NSUInteger dSeconds = floor(dTotalSeconds % 3600 % 60);
    
    NSString *timeForFrame = [NSString stringWithFormat:@"%lu:%02lu:%02lu",(unsigned long)dHours, (unsigned long)dMinutes, (unsigned long)dSeconds];
    
    //NSRect viewFrameInWindowCoords = [_mainView convertRect: [_playerView bounds] toView:_playerView];
    NSRect viewFrameToWindowCoords = [_mainView convertRect: [_playerView bounds] fromView:_playerView];
    //NSRect viewFrameFromWindowCoords = [_mainView convertRect: [_playerView bounds] fromView:_mainView];
    //NSRect viewBounds = _playerView.bounds;
    //NSRect viewFrame = _playerView.frame;
    
    //viewFrameToWindowCoords.origin.x = 200;
    //viewFrameToWindowCoords.origin.y = 300;
    
    viewFrameToWindowCoords.origin.y = self.mainView.bounds.size.height - viewFrameToWindowCoords.size.height - viewFrameToWindowCoords.origin.y;
    
    NSImage* thumbnail = [self NSImageFromScreenWithRect:viewFrameToWindowCoords];
    
    AVAssetImageGenerator *generate = [[AVAssetImageGenerator alloc] initWithAsset:_playerView.player.currentItem.asset];
    generate.requestedTimeToleranceAfter = kCMTimeZero;
    generate.requestedTimeToleranceBefore = kCMTimeZero;
    generate.appliesPreferredTrackTransform = true;
    NSError *err = NULL;
    
    CGImageRef imgRef = [generate copyCGImageAtTime:time actualTime:NULL error:&err];
    
    thumbnail = [[NSImage alloc] initWithCGImage:imgRef size:NSMakeSize(1920, 1080)];
    
    //NSImage * mainthumbnail =  [[NSImage alloc] initWithData:[self.mainView dataWithPDFInsideRect:[self.mainView bounds]]];

    //NSImage* thumbnail = [self layerScreenshot];
    /*[[NSImage alloc] initWithSize:self.playerViewParent.bounds.size];
    [thumbnail lockFocus];
    CGContextRef ctx = [NSGraphicsContext currentContext].graphicsPort;
    [self.playerViewParent.layer renderInContext:ctx];
    [thumbnail unlockFocus];*/

    
    NSMutableArray* _imgArr = [_images copy];
    _images = [[NSMutableArray alloc] init];
    for (int i = 0; i < [_imgArr count]; i++) {
        [_images addObject:[_imgArr objectAtIndex:i]];
    }
    if(currentSceneIndex < [_images count] )
        [_images insertObject:thumbnail atIndex:currentSceneIndex];
    else
        [_images addObject:thumbnail];
    
    NSMutableArray* timeFramesArr = [_timeFrames copy];
    _timeFrames = [[NSMutableArray alloc] init];
    for (int i = 0; i < [timeFramesArr count]; i++) {
        [_timeFrames addObject:[timeFramesArr objectAtIndex:i]];
    }
    if(currentSceneIndex < [_timeFrames count] )
        [_timeFrames insertObject:timeForFrame atIndex:currentSceneIndex];
    else
        [_timeFrames addObject:timeForFrame];
    
    
    NSMutableArray* _actualTimesArr = [_actualTimes copy];
    _actualTimes = [[NSMutableArray alloc] init];
    for (int i = 0; i < [_actualTimesArr count]; i++) {
        [_actualTimes addObject:[_actualTimesArr objectAtIndex:i] ];
    }
    if(currentSceneIndex < [_actualTimes count] )
        [_actualTimes insertObject: [NSNumber numberWithFloat:_fl] atIndex:currentSceneIndex];
    else
        [_actualTimes addObject:[NSNumber numberWithFloat:_fl]];
    
    [_timelineCollection reloadData];
    
    //select newly added frame
    dispatch_async(dispatch_get_main_queue(), ^{
        [self selectFrameAtIndex:currentSceneIndex];
    });
}

- (NSImage *)layerScreenshot
{
    
    // Retina test
    ////////////
    
    
    int pixelsHigh = (int)[[self.playerViewParent layer] bounds].size.height * self.playerViewParent.layer.contentsScale;
    int pixelsWide = (int)[[self.playerViewParent layer] bounds].size.width * self.playerViewParent.layer.contentsScale;
    
    NSBitmapImageRep *cachedImageRep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:NULL
                                                                               pixelsWide:pixelsWide
                                                                               pixelsHigh:pixelsHigh
                                                                            bitsPerSample:8
                                                                          samplesPerPixel:4
                                                                                 hasAlpha:YES
                                                                                 isPlanar:NO
                                                                           colorSpaceName:NSCalibratedRGBColorSpace
                                                                             bitmapFormat:0
                                                                              bytesPerRow:0
                                                                             bitsPerPixel:0];
    NSSize pointSize = [[self.playerViewParent layer] bounds].size;
    
    [cachedImageRep setSize:pointSize];
    NSGraphicsContext * cacheContext = [NSGraphicsContext graphicsContextWithBitmapImageRep:cachedImageRep];
    
    
    [NSGraphicsContext saveGraphicsState];
    [NSGraphicsContext setCurrentContext:cacheContext];
    
    [self.playerViewParent.layer renderInContext:cacheContext.graphicsPort];
    
    [NSGraphicsContext restoreGraphicsState];
    
    NSImage *cachedImage = [[NSImage alloc] initWithSize:pointSize];
    [cachedImage addRepresentation:cachedImageRep];
    
    //    CGFloat cachedImageScale = self.layer.contentsScale;
    
    return cachedImage;
    
}

- (NSImage *)screenshot {
    
    NSBitmapImageRep *imageRep = [_playerViewParent bitmapImageRepForCachingDisplayInRect:[_playerViewParent frame]];
    
    [_playerViewParent cacheDisplayInRect:_playerViewParent.bounds toBitmapImageRep:imageRep];
    
    NSImage *image = [[NSImage alloc] initWithSize:_playerViewParent.frame.size];
    [image addRepresentation:imageRep];
    
    return image;
}

-(CGImageRef) CGImageCreateWithNSImage:(NSImage *)image {
    NSSize imageSize = [image size];
    
    CGContextRef bitmapContext = CGBitmapContextCreate(NULL, imageSize.width, imageSize.height, 8, 0, [[NSColorSpace genericRGBColorSpace] CGColorSpace], kCGBitmapByteOrder32Host|kCGImageAlphaPremultipliedFirst);
    
    [NSGraphicsContext saveGraphicsState];
    [NSGraphicsContext setCurrentContext:[NSGraphicsContext graphicsContextWithGraphicsPort:bitmapContext flipped:NO]];
    [image drawInRect:NSMakeRect(0, 0, imageSize.width, imageSize.height) fromRect:NSZeroRect operation:NSCompositeCopy fraction:1.0];
    [NSGraphicsContext restoreGraphicsState];
    
    CGImageRef cgImage = CGBitmapContextCreateImage(bitmapContext);
    CGContextRelease(bitmapContext);
    return cgImage;
}

- (NSImage*) NSImageFromScreenWithRect:(CGRect) rect{
        NSInteger winNum = [[[NSApplication sharedApplication] keyWindow] windowNumber];
        //  copy screenshot to clipboard, works on OS X only..
        system([[NSString stringWithFormat:@"screencapture -c -S -o -l %ld -x", (long)winNum] UTF8String]);
    
        //  get NSImage from clipboard..
        //NSImage *imageFromClipboard = [[NSImage alloc] initWithData:[self.mainView dataWithPDFInsideRect:[self.mainView bounds]]];
        NSImage *imageFromClipboard = [[NSImage alloc]initWithPasteboard:[NSPasteboard generalPasteboard]];

        //  get CGImageRef from NSImage for further cutting..
        CGImageRef screenShotImage=[self CGImageCreateWithNSImage:imageFromClipboard];
        
        //  cut desired subimage from fullscreen screenshot..
        CGImageRef screenShotCenter= CGImageCreateWithImageInRect(screenShotImage,rect);
        
        //  create NSImage from CGImageRef..
        NSImage *resultImage=[[NSImage alloc]initWithCGImage:screenShotCenter size:rect.size];
        
        //  release CGImageRefs cause ARC has no effect on them..
        CGImageRelease(screenShotCenter);
        CGImageRelease(screenShotImage);
        return resultImage;
}

- (void)underlyingMovieWasMutated {
    self.playerView.player = [AVPlayer playerWithPlayerItem:[self.movieMutator makePlayerItem]];
    self.playerView.layer.backgroundColor = [[NSColor lightGrayColor] CGColor];
    
    
    self.playerView.videoGravity = AVLayerVideoGravityResizeAspectFill;
    
    [self updateMovieTimeline];
    self.view.needsDisplay = YES;
}

- (BOOL)readFromURL:(nonnull NSURL *)url showOnlyFirstThumb:(BOOL)showOnlyFirstThumb bIsShouldConfigFrame:(BOOL) bIsShouldConfigFrame {
    [self showProgress];
    if ([url.absoluteString hasPrefix: @"https://www.youtube.com"] || [url.absoluteString hasPrefix:@"https://youtube.com"]) {
        NSString * youtubeIdentifier = [[url.absoluteString componentsSeparatedByString: @"watch?v="] lastObject];
        [[XCDYouTubeClient defaultClient] getVideoWithIdentifier:youtubeIdentifier completionHandler:^(XCDYouTubeVideo *video, NSError *error) {
            if (video)
            {
                if (video.streamURLs != nil) {
                    NSURL *streamURL = video.streamURL;
//                    NSDictionary *streamURLs = video.streamURLs;
//                    NSURL *streamURL = streamURLs[XCDYouTubeVideoQualityHTTPLiveStreaming] ?: streamURLs[@(XCDYouTubeVideoQualityHD720)] ?: streamURLs[@(XCDYouTubeVideoQualityMedium360)] ?: streamURLs[@(XCDYouTubeVideoQualitySmall240)];

                    if (streamURL == nil) {
                        return;
                    }
                    NSString *fileType = [self UTIFromPathExtension:streamURL.pathExtension];

                    // If the UTI is not one of AVMovie.movieTypes() then this movie is not supported by AVMovie and should not be opened.
                    if (![[AVMovie movieTypes] containsObject:fileType])
                    {
                        return;
                    }

                    AVMovie *currentMovie = [AVMovie movieWithURL:streamURL options:nil];
                    self.movieMutator = [[AAPLMovieMutator alloc] initWithMovie:currentMovie];

                    [self updateVideoController];

                    if(!showOnlyFirstThumb)
                    {
                        self.previewThumbImageView.hidden = true;
                        [self reloadTimeline];
                    }

                    if (bIsShouldConfigFrame) {
                        [self findAllFrames];
                    }
                    else if (showOnlyFirstThumb){
                        [self hideProgress];
                    }
                }
            }
            else
            {
                [self hideProgress];
                NSLog(error.localizedDescription);
                // Handle error
            }
        }];
    }
    else {
        NSString *fileType = [self UTIFromPathExtension:url.pathExtension];

        // If the UTI is not one of AVMovie.movieTypes() then this movie is not supported by AVMovie and should not be opened.
        if (![[AVMovie movieTypes] containsObject:fileType]) {
            return false;
        }

        if(url == nil)
            return false;

        NSFileManager *fileManager = [NSFileManager defaultManager];
        if(![fileManager fileExistsAtPath:url.path]){
            return false;
        }

        AVMovie *currentMovie = [AVMovie movieWithURL:url options:nil];

        //[url stopAccessingSecurityScopedResource];

        self.movieMutator = [[AAPLMovieMutator alloc] initWithMovie:currentMovie];

        [self updateVideoController];

        if(!showOnlyFirstThumb)
        {
            self.previewThumbImageView.hidden = true;
            [self reloadTimeline];
        }
        else
        {
            /*
            AVURLAsset* asset = [AVURLAsset URLAssetWithURL:url options:nil];
            AVAssetImageGenerator* imageGenerator = [AVAssetImageGenerator assetImageGeneratorWithAsset:asset];
            [imageGenerator setAppliesPreferredTrackTransform:TRUE];

            CMTime midpoint = CMTimeMake(1, 1);

            CMTime actualTime;
            NSError *error;

            CGImageRef halfWayImage = [imageGenerator copyCGImageAtTime:midpoint actualTime:&actualTime error:&error];

            if (halfWayImage != NULL) {

                NSImage *nextImage = [[NSImage alloc] initWithCGImage:halfWayImage size:NSMakeSize(CGImageGetWidth(halfWayImage), CGImageGetHeight(halfWayImage))];

                [self.previewThumbImageView setImage:nextImage];
                self.previewThumbImageView.hidden = false;
            }*/
        }
        
        if (bIsShouldConfigFrame) {
            [self findAllFrames];
        }
        else if (showOnlyFirstThumb){
            [self hideProgress];
        }
    }

    return true;
}

- (BOOL)cutMovieTimeRange:(CMTimeRange)timeRange error:(NSError *)error {
    return [self.movieMutator cutTimeRange:timeRange error:error];
}

- (BOOL)copyMovieTimeRange:(CMTimeRange)timeRange error:(NSError *)error {
    return [self.movieMutator copyTimeRange:timeRange error:error];
}

- (BOOL)pasteMovieAtTime:(CMTime)time error:(NSError *)error {
    return [self.movieMutator pasteAtTime:time error:error];
}

- (void)movieViewController:(NSUInteger)numberOfImages edlArray:(NSArray<NSValue *> *)edlArray completionHandler:(ImageGenerationCompletionHandler)completionHandler {
    [self.movieMutator generateImages:numberOfImages edlArray:(NSArray<NSValue *> *)edlArray withCompletionHandler:completionHandler];
}

- (CMTime)timeAtPercentage:(float)percentage {
    return [self.movieMutator timePercentageThroughMovie:percentage];
}

#pragma mark - File -> Save

- (void)saveDocument:(nullable id)sender {
    NSSavePanel *savePanel = [NSSavePanel savePanel];
    
    // The only UTIs that AVMovie can write to are in AVMovie.movieTypes()
    savePanel.allowedFileTypes = [AVMovie movieTypes];
    [savePanel beginWithCompletionHandler:^(NSInteger result) {
        if (result == 1) {
            NSURL *url = savePanel.URL;
            NSString *fileType = [self UTIFromPathExtension:url.pathExtension];
            NSError *error = nil;
            BOOL didSucceed = [self.movieMutator writeMovieToURL:url fileType:fileType error:error];
            if (!didSucceed || error) {
                NSLog(@"There was a problem saving the movie.");
            }
        }
    }];
}

- (NSString *)UTIFromPathExtension:(NSString *)pathExtension {
    // Figure out the correct UTI from the path extension.
    NSString *fileType = AVFileTypeQuickTimeMovie;
    if ([pathExtension.lowercaseString isEqualToString:@"mp4"])
        fileType = AVFileTypeMPEG4;
    else if ([pathExtension.lowercaseString isEqualToString:@"m4v"])
        fileType = AVFileTypeAppleM4V;
    else if ([pathExtension.lowercaseString isEqualToString:@"m4a"])
        fileType = AVFileTypeAppleM4A;
    
    return fileType;
}

- (NSRect)window:(NSWindow *)window willPositionSheet:(NSWindow *)sheet
       usingRect:(NSRect)rect {
    rect.origin.y += 41;  // or as much as we need
    return rect;
}

-(NSArray<NSValue *> *)getImageFramesFromEDL{
    NSMutableArray <NSValue *> *times = [NSMutableArray array];
    // Generate an image at time zero.
    for (int i = 0; i < _EDLs.count; i++) {
        NSValue *nextValue = [NSValue valueWithCMTime:((EDL*)_EDLs[i]).time];
        [times addObject:nextValue];
    }
    
    return [times copy];
}

- (CMTime)convertSecondsMilliseconds:(NSUInteger)seconds toCMTime:(NSUInteger)milliseconds {
    CMTime secondsTime = CMTimeMake(seconds, 1);
    CMTime millisecondsTime;
    
    if (milliseconds == 0) {
        return secondsTime;
    } else {
        millisecondsTime = CMTimeMake(milliseconds, currentFPS);
        CMTime time = CMTimeAdd(secondsTime, millisecondsTime);
        return time;
    }
}

- (float)totalSecondsForHours:(NSUInteger)hours
                           minutes:(NSUInteger)minutes
                           seconds:(NSUInteger)seconds
                      milliseconds:(NSUInteger)milliseconds
{
    return (hours * 3600) + (minutes * 60) + seconds ;//+ (milliseconds/1000);
}

-(CMTime)getTimeForEDLAt:(NSString*)timecodeString frameNumber:(int*)frameNumber{
    //float frameRate = 0;
    CMTime time;
    //float totalNumSeconds;
    int returnIndex = 0;
    double closestTime = 0;
    BOOL found = false;
    int frameIndex = -1;
    
    NSArray *timeComponents = [timecodeString componentsSeparatedByString:@":"];
    //int hours = 0;//[(NSString *)timeComponents[0] intValue];
    int minutes = [(NSString *)timeComponents[1] intValue];
    int seconds = [(NSString *)timeComponents[2] intValue];
    
    double currentFrameNumber = [(NSString *)timeComponents[3] intValue];
    
    double totalSeconds = minutes*60 + seconds;
    
    double timeToCompare = 0;
    
    //find the frame at which current cut starts
    for (int i = 0; i < currentVideoFrames.count; i++) {
        NSDictionary* frameDict = [currentVideoFrames objectAtIndex:i];
        
        timeToCompare = timeToCompare + [(NSNumber*)[frameDict objectForKey:@"duration"] doubleValue];
        
        if(timeToCompare == totalSeconds){
            closestTime = timeToCompare;
            frameIndex = i;
            found = true;
            break;
        }
        else if(timeToCompare > totalSeconds)
        {
            if(i == 0 || i == currentVideoFrames.count - 1)
            {
                returnIndex = i;
                frameIndex = i;
                found = true;
                break;
            }
            
            returnIndex = i;
            frameIndex = i;
            //NSDictionary* prevFrameDict = [currentVideoFrames objectAtIndex:i-1];
            double prevTime = timeToCompare - [(NSNumber*)[frameDict objectForKey:@"duration"] doubleValue];//[(NSNumber*)[prevFrameDict objectForKey:@"time"] floatValue];
            
            CGFloat leftDifference = totalSeconds - prevTime;
            CGFloat rightDifference = timeToCompare - totalSeconds;
            
            if (leftDifference < rightDifference) {
                returnIndex = returnIndex - 1;
                frameIndex = returnIndex;
            }
            
            found = true;
            break;
        }
    }
    
    if(!found)
    {
        returnIndex = currentVideoFrames.count - 1;
        frameIndex = returnIndex;
    }
    
    int targetFrame = currentFrameNumber + frameIndex;
    
    //*frameNumber  = [[((NSDictionary*)[currentVideoFrames objectAtIndex:targetFrame]) objectForKey:@"frame"] intValue];//targetFrame;
    
    
    if(targetFrame < currentVideoFrames.count)
    {
        *frameNumber  = [[((NSDictionary*)[currentVideoFrames objectAtIndex:targetFrame]) objectForKey:@"frame"] intValue];
        //time = [((NSDictionary*)currentVideoFrames[targetFrame]) valueForKey:@"cmtime"];
        NSValue* frTimeValue = [(NSDictionary*)[currentVideoFrames objectAtIndex:targetFrame] objectForKey:@"cmtime"];
    
        /*
        if(targetFrame+2 < currentVideoFrames.count)
            frTimeValue = [(NSDictionary*)[currentVideoFrames objectAtIndex:targetFrame+2] objectForKey:@"cmtime"];
        */
        
        [frTimeValue getValue:&time];
    }
    else
    {
        //*frameNumber = currentVideoFrames.count - 1;
        *frameNumber  = [[((NSDictionary*)[currentVideoFrames lastObject]) objectForKey:@"frame"] intValue];
        NSValue* frTimeValue = [(NSDictionary*)[currentVideoFrames lastObject] objectForKey:@"cmtime"];
        [frTimeValue getValue:&time];
    }
    
    return time;
}

- (CMTime)parseTimecodeStringIntoCMTime:(NSString *)timecodeString{
    
    float frameRate = 0;
    
    float milliseconds;
    float totalNumSeconds;
    
    NSArray *timeComponents = [timecodeString componentsSeparatedByString:@":"];
    
    int hours = 0;//[(NSString *)timeComponents[0] intValue];
    int minutes = [(NSString *)timeComponents[1] intValue];
    int seconds = [(NSString *)timeComponents[2] intValue];
    
    if([timecodeString localizedCaseInsensitiveContainsString:@"."]){
        NSArray *msComponents = [timeComponents[2] componentsSeparatedByString:@"."];
        seconds = [(NSString *)msComponents[0] intValue];
        milliseconds = [(NSString *)msComponents[1] intValue];
        
        float framenumber = milliseconds*currentFPS;
        framenumber = framenumber/1000;
        milliseconds = framenumber;
        
        milliseconds = round(milliseconds);
    }
    else
    {
        milliseconds = [(NSString *)timeComponents[3] intValue];
        
        if(currentFPS > 0)
            frameRate = currentFPS;
        else
        {
            currentFPS = [self getFrameRateFromAVPlayer];
            frameRate = currentFPS;
        }

    }

    
    totalNumSeconds = [self totalSecondsForHours:hours minutes:minutes seconds:seconds milliseconds:milliseconds];

    //CMTime time = CMTimeMake(totalNumSeconds + (milliseconds/fps), 1);//self.playerView.player.currentItem.asset.duration.timescale);
    CMTime time = [self convertSecondsMilliseconds:totalNumSeconds toCMTime:milliseconds];
    
    //CMTime movieTime = CMTimeMake((totalNumSeconds*24)+milliseconds, self.playerView.player.currentItem.asset.duration.timescale);
    
    return time;
}

-(float)getFrameRateFromAVPlayer
{
    float fps=0.00;
    float fps2=0.00;
    if (self.playerView.player.currentItem.asset)
    {
        AVAssetTrack * videoATrack = [[self.playerView.player.currentItem.asset tracksWithMediaType:AVMediaTypeVideo] lastObject];
        if(videoATrack)
        {
            fps = videoATrack.nominalFrameRate;
        }
        
        AVPlayerItem *item = self.playerView.player.currentItem;
        for (AVPlayerItemTrack *track in item.tracks) {
            if ([track.assetTrack.mediaType isEqualToString:AVMediaTypeVideo]) {
                if(track.currentVideoFrameRate > 0)
                    fps2 = track.currentVideoFrameRate;
            }
        }
    }

    
    return fps;
}

- (NSString *)stringFromCMTime:(CMTime)theTime {
    // Need a string of format "hh:mm:ss". (No milliseconds.)
    NSTimeInterval seconds = (NSTimeInterval)CMTimeGetSeconds(theTime);
    NSDate *date1 = [NSDate new];
    NSDate *date2 = [NSDate dateWithTimeInterval:seconds sinceDate:date1];
    NSCalendarUnit unitFlags = NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond;
    NSDateComponents *converted = [[NSCalendar currentCalendar] components:unitFlags
                                                                  fromDate:date1
                                                                    toDate:date2
                                                                   options:0];
    
    NSString *str = [NSString stringWithFormat:@"%02d:%02d:%02d:%2d",
                     (int)[converted hour],
                     (int)[converted minute],
                     (int)[converted second]];
    return str;
}

-(float)GetSecondsFromString:(NSString*)time
{
    //NSString *timeString = @"2:3:31";
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"hh:mm:ss:SS";
    NSDate *timeDate = [formatter dateFromString:time];
    
    formatter.dateFormat = @"hh";
    int hours = [[formatter stringFromDate:timeDate] intValue];
    formatter.dateFormat = @"mm";
    int minutes = [[formatter stringFromDate:timeDate] intValue];
    formatter.dateFormat = @"ss";
    int seconds = [[formatter stringFromDate:timeDate] intValue];
    formatter.dateFormat = @"SS";
    int milliseconds = [[formatter stringFromDate:timeDate] intValue];
    
    float timeInSeconds = seconds + (minutes * 60) /*+ (hours * 3600)*/ + (CGFloat)milliseconds/1000;
    
    return timeInSeconds;
}

-(void)reloadTimeline{
    self.movieTimeline.delegate = self;
    [self updateMovieTimeline];
    /*
    [[NSNotificationCenter defaultCenter] addObserverForName:NSWindowDidEndLiveResizeNotification object:nil queue:nil usingBlock:^(NSNotification * __nonnull note) {
        [self updateMovieTimeline];
    }];*/
}

- (void)updateMovieTimeline {
    self.movieTimeline.needsLayout = YES;
    [self.movieTimeline removeAllPositionalSubviews];
    
    //[_images removeAllObjects];
    _images = nil;
    _images = [[NSMutableArray alloc] init];
    [_timelineCollection reloadData];
    //[_exportThumbsView reloadData];
    
    currentFPS = [self getFrameRateFromAVPlayer];
    
    _edlFramesArray = [self getImageFramesFromEDL];//[self.movieMutator countOfImagesRequiredToFillView];

    [self showProgress];
    [self.delegate movieViewController:_edlFramesArray.count edlArray:_edlFramesArray completionHandler:^(NSMutableArray * images, NSMutableArray *times, NSMutableArray *actualTimes) {
        
        // Add image view on the main thread.
        dispatch_async(dispatch_get_main_queue(), ^{
            //[self.movieTimeline addImageView:image];
            
            _images = [images mutableCopy];
            _timeFrames = [times mutableCopy];
            _actualTimes = [actualTimes mutableCopy];
            [_timelineCollection reloadData];
            
            [self selectFrameAtIndex:0];
            
            [self hideProgress];
            
            //NSNumber *val = [NSNumber numberWithInteger:actualTime];
            
            //[_actualTimes addObject:val];
            if(_images.count == _edlFramesArray.count)
            {
                //[_timelineCollection reloadData];
                //[_exportThumbsView reloadData];
                //[_timelineCollection setNeedsDisplay:true];
            }
        });
    }];
}
#pragma mark - Begin MovieTimeLine Delegate
- (void)movieTimeline:(AAPLMovieTimeline *)timeline didUpdateCursorToPoint:(NSPoint)toPoint {
    CGFloat percentage = toPoint.x / self.movieTimeline.frame.size.width;
    CMTime time = [self.delegate timeAtPercentage:percentage];
    
    // Update the time label for the new cursor point.
    float seconds = CMTimeGetSeconds(time) <= 0 ? 0 : CMTimeGetSeconds(time);
    NSString *timeDescription = [NSString stringWithFormat:@"%.2f", seconds];
    [self.movieTimeline updateTimeLabel:timeDescription];
}

- (void)didSelectTimelineRangeFromPoint:(NSPoint)fromPoint toPoint:(NSPoint)toPoint {
    CGFloat startPercentage = fromPoint.x / self.movieTimeline.frame.size.width;
    CGFloat endPercentage = toPoint.x / self.movieTimeline.frame.size.width;
    CMTime startTime = [self.delegate timeAtPercentage:startPercentage];
    CMTime endTime = [self.delegate timeAtPercentage:endPercentage];
    
    // Calculate the duration from the the time percentages.
    CMTime duration = CMTimeSubtract(endTime, startTime);
    self.selectedTimeRange = CMTimeRangeMake(startTime, duration);
}

- (void)didSelectTimelinePoint:(NSPoint)point {
    CGFloat pointPercentage = point.x / self.movieTimeline.frame.size.width;
    self.selectedPointInTime = [self.delegate timeAtPercentage:pointPercentage];
    self.selectedTimeRange = CMTimeRangeMake(kCMTimeZero, kCMTimeZero);
}

-(void)setPlaceholderTitle:(NSTextField*)txtField toString:(NSString*)title withColor:(NSColor*)color withSize:(int)size{
    NSFont *txtFont = [NSFont systemFontOfSize:size];
    
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc]init] ;
    [paragraphStyle setAlignment:NSTextAlignmentCenter];
    
    NSDictionary *txtDict = [NSDictionary dictionaryWithObjectsAndKeys:
                             txtFont, NSFontAttributeName, color, NSForegroundColorAttributeName, nil];
    NSMutableAttributedString *attrStr = [[NSMutableAttributedString alloc] initWithString:title attributes:txtDict];
    [attrStr addAttributes:[NSDictionary dictionaryWithObject:paragraphStyle forKey:NSParagraphStyleAttributeName] range:NSMakeRange(0,[attrStr length])];
    
    //[attrStr addAttribute: NSBaselineOffsetAttributeName value: [NSNumber numberWithFloat: -10.0] range: NSMakeRange(0, [attrStr length])];
    
    [txtField setPlaceholderAttributedString:attrStr];
}
#pragma mark - End MovieTimeLine Delegate

#pragma mark - Right click NSMEnu to message Cut, Copy, and Paste

- (void)rightMouseDown:(nonnull NSEvent *)theEvent {
    /*NSMenu *menu = [[NSMenu alloc] initWithTitle:@"Movie Style Editing"];
    
    // If we have not selected a time range then we can not copy or cut - only paste.
    if (CMTIME_COMPARE_INLINE(self.selectedTimeRange.start, ==, kCMTimeZero) && CMTIME_COMPARE_INLINE(self.selectedTimeRange.duration, ==, kCMTimeZero)) {
        [menu insertItemWithTitle:@"Paste" action:@selector(pasteMovie) keyEquivalent:@"" atIndex:0];
    } else {
        [menu insertItemWithTitle:@"Cut" action:@selector(cutMovie) keyEquivalent:@"" atIndex:0];
        [menu insertItemWithTitle:@"Copy" action:@selector(copyMovie) keyEquivalent:@"" atIndex:1];
    }
    
    menu.delegate = self;
    
    [NSMenu popUpContextMenu:menu withEvent:theEvent forView:self.view];*/
}

- (void)cutMovie {
    // Cut the movie and handle the error if necessary.
    NSError *error = nil;
    BOOL didSucceed = [self.delegate cutMovieTimeRange:self.selectedTimeRange error:error];
    if (!didSucceed || error) {
        NSLog(@"There was an error performing the cut operation");
    }
}

- (void)copyMovie {
    // Cut the movie and handle the error if necessary.
    NSError *error = nil;
    BOOL didSucceed = [self.delegate copyMovieTimeRange:self.selectedTimeRange error:error];
    if (!didSucceed || error) {
        NSLog(@"There was an error performing the copy operation.");
    }
}

- (void)pasteMovie {
    // Paste the movie and handle the error if necessary.
    NSError *error = nil;
    BOOL didSucceed = [self.delegate pasteMovieAtTime:self.selectedPointInTime error:error];
    if (!didSucceed || error) {
        NSLog(@"There was an error performing the paste operation.");
    }
}
#pragma mark - End Right click NSMEnu to message Cut, Copy, and Paste

#pragma mark - Edit Menu Cut, Copy, Paste methods

- (void)cut:(id)sender {
    [self cutMovie];
}

- (void)copy:(id)sender {
    [self copyMovie];
}

- (void)paste:(id)sender {
    [self pasteMovie];
}



-(void)setButtonTitle:(NSButton*)button toString:(NSString*)title withColor:(NSColor*)color withSize:(int)size{
    NSFont *txtFont = [NSFont systemFontOfSize:size];
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc]init] ;
    [paragraphStyle setAlignment:NSTextAlignmentCenter];
    NSDictionary *txtDict = [NSDictionary dictionaryWithObjectsAndKeys:
                             txtFont, NSFontAttributeName, color, NSForegroundColorAttributeName, nil];
    NSMutableAttributedString *attrStr = [[NSMutableAttributedString alloc] initWithString:title attributes:txtDict];
    [attrStr addAttributes:[NSDictionary dictionaryWithObject:paragraphStyle forKey:NSParagraphStyleAttributeName] range:NSMakeRange(0,[attrStr length])];
    [button setAttributedTitle:attrStr];
}


- (IBAction)btnBrowseClick:(id)sender {
    //if(_btnBrowse.state == 0)
        [self toggleButtonState:@"browse"];
}
- (IBAction)btnConformClick:(id)sender {
    //if(_btnConform.state == 0)
        [self toggleButtonState:@"conform"];
}
- (IBAction)btnEmbedClick:(id)sender {
    //if(_btnEmbed.state == 0)
        [self toggleButtonState:@"embed"];
}
- (IBAction)btnExportClick:(id)sender {
    
    //if(_btnExport.state == 0)
    //[self toggleButtonState:@"export"];
    _btnExport.state == 0;
    //_currentSelectedProject.transitions
    /*if(transitionLocalUrls.count > 0)
    {
        NSString* localUrl = transitionLocalUrls[0];
        NSString* localDirUrl = [localUrl stringByReplacingOccurrencesOfString:@"file://" withString:@""];
        localDirUrl = [localDirUrl stringByDeletingLastPathComponent];
        NSString* localmvidUrl = [localUrl stringByReplacingOccurrencesOfString:@"file://" withString:@""];//[localDirUrl stringByAppendingString:@"/*.mvid"];
        NSString* local7zUrl = [localDirUrl stringByAppendingString:@"/test.7z"];
        
        //To Do
        //[self create7z:local7zUrl files:localmvidUrl];
    }*/
    
    [self showExportDialog];
}

- (IBAction)btnMyProjectsClick:(id)sender {
    
    if(_projectsScrollView.hidden)
        _projectsScrollView.hidden = NO;
    else
        _projectsScrollView.hidden = YES;
}

- (IBAction)btnSceneDetectClick:(id)sender {
    if(!IsSceneDetectInProgress)
        [self detectScenes];
    else{
        [self showAlert:@"Scene Detect In Progress" message:@"Please wait until the current scene detection is completed."];
    }
}

- (IBAction)btnNewProjectClick:(id)sender {

    /* //ToDo: Review Export Dialog Changes
     _chkPublic.state = 1;
    _chkPrivate.state = 0;
    _chkFollowers.state = 0;
    
    NSPoint pt = NSMakePoint(0.0, [[_exportDialog documentView]
                                   bounds].size.height);
    [[_exportDialog documentView] scrollPoint:pt];
    */
    _btnNewProject.state = 1;
    NSMutableAttributedString *_string = [self getAttributedString:@"  New Project" color:[NSColor orangeColor]];
    [_btnNewProject setAttributedTitle: _string];
    [_btnNewProject setAttributedAlternateTitle:_string];
    
    _dialogView.hidden = false;
    _btnCloseDialog.hidden = false;
    
    _projectDialog.hidden = false;
    _ctaDialog.hidden = true;
    
    [self toggleAllButtons:false];
    
    CALayer *backgroundLayer = [CALayer layer];
    [_dialogView setLayer:backgroundLayer];
    [_dialogView setWantsLayer:YES];
    
    CIFilter *blurFilter = [CIFilter filterWithName:@"CIGaussianBlur"];
    [blurFilter setValue:@"3.0" forKey:@"inputRadius"];
    
    _dialogView.backgroundFilters = [NSArray arrayWithObject:blurFilter];
}

- (void)didEndSheet:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
    [sheet orderOut:self];
}

-(NSMutableDictionary*)getLastExportDetails:(NSString*)projectName
{
    NSMutableDictionary* prjDetails;
    for (int i = 0; i < _exportedProjects.count; i++) {
        NSDictionary* project = [_exportedProjects objectAtIndex:i];
        if([[project valueForKey:@"projectName"] isEqualToString:projectName])
        {
            prjDetails = [project mutableCopy];
            break;
        }
    }
    return prjDetails;
}

-(NSMutableArray*)getCurrentProjectTransitionMvids
{
    NSMutableArray* transitionMVids = [NSMutableArray array];
    for(int i = 0; i < _currentSelectedProject.transitions.count; i++){
        NSString *strValue = _currentSelectedProject.transitions[i];
        [transitionMVids addObject:[self getTransitionFilePath:strValue]];
    }
    return transitionMVids;
}

-(void)showExportDialog
{
     //WORK IN PROGRESS TO SHOW EXPORT DIALOG AS POPOVER
    if(self.exportViewController.IsUploadInProgress)
    {
        [self showAlert:@"Upload In Progress" message:@"Please wait until the current export operation is completed"];
    }

    self.exportViewController.images = [[NSMutableArray alloc] init];
    self.exportViewController.timeFrames = [[NSMutableArray alloc] init];
    self.exportViewController.actualTimes = [[NSMutableArray alloc] init];
    self.exportViewController.EDLs = [[NSMutableArray alloc]init];
    
    self.exportViewController.exportedProject = [self getLastExportDetails:_currentSelectedProject.projectName];
    
    self.exportViewController.playDuration = CMTimeGetSeconds(_playerView.player.currentItem.asset.duration);
    self.exportViewController.movieMutator = _movieMutator;
    self.exportViewController.images = [_images mutableCopy];
    self.exportViewController.currentAssetFileUrl = _currentAssetFileUrl;
    self.exportViewController.timeFrames = _timeFrames;
    self.exportViewController.actualTimes = _actualTimes;
    self.exportViewController.username = _username;
    self.exportViewController.playerWidth = _playerView.frame.size.width;
    self.exportViewController.playerHeight = _playerView.frame.size.height;
    self.exportViewController.projectName = _currentSelectedProject.projectName;
    self.exportViewController.EDLs = [_EDLs mutableCopy];
    self.exportViewController.mvidFiles = [self getCurrentProjectTransitionMvids];//[currentProjecMVIDPaths mutableCopy];
    
    AVAssetTrack * videoATrack = [[self.playerView.player.currentItem.asset tracksWithMediaType:AVMediaTypeVideo] lastObject];
    CGSize videoSize = videoATrack.naturalSize;
    self.exportViewController.originalVideoWidth = videoSize.width;
    self.exportViewController.originalVideoHeight = videoSize.height;

    NSRect mainRect = self.mainView.frame;
    mainRect.size.height -= 25;
    
    [self presentViewController:self.exportViewController asPopoverRelativeToRect:mainRect ofView:self.mainView preferredEdge:NSRectEdgeMaxY behavior:NSPopoverBehaviorApplicationDefined];
    
    self.isShowingExportView = true;

    return;
}

- (void)popOverShowed {
    self.isShowingExportView = true;
}

- (void)popOverClosed {
    self.isShowingExportView = false;
}

-(void) hideExportDialog
{
    /*
     //To Do: Review Export Changes
    _exportDialog.backgroundFilters = nil;
    _exportDialog.hidden = true;
    
    _txtExportTitle.stringValue = @"";
    _txtExportArtist.stringValue = @"";
    _txtDescription.stringValue = @"";
    _txtTags.stringValue = @"";
    */
}

-(void)hideProgress{
    dispatch_async(dispatch_get_main_queue(), ^{
        _progressView.hidden =  true;
        [_progressWheel stopAnimation:self];
    });
    
}

-(void)showProgress{
    dispatch_async(dispatch_get_main_queue(), ^{
        [_progressWheel startAnimation:self];
        _progressView.hidden = false;
    });
}

-(void)showProgressAsync:(NSString*)status{
    dispatch_async(dispatch_get_main_queue(), ^{
        [_uploadProgress startAnimation:self];
        _uploadProgress.hidden = false;
        _txtUploadStatus.hidden = false;
        _txtUploadStatus.stringValue = status;
    });
}

-(void)hideProgressAsync{
    dispatch_async(dispatch_get_main_queue(), ^{
        _uploadProgress.hidden =  true;
        [_uploadProgress stopAnimation:self];
        _txtUploadStatus.hidden = true;
    });
    
}

-(void)hideDialogView
{
    //_mainView.layer.filters = nil;
    //_mainView.contentFilters = nil;
    _dialogView.backgroundFilters = nil;
    _ctaDialog.hidden = true;
    _dialogView.hidden = true;
    _projectDialog.hidden = false;
    _projectCreatedDialog.hidden = true;
    _btnCloseDialog.hidden = false;
    _txtProjectName.stringValue = @"";
    [self toggleAllButtons:true];
    
    _btnNewProject.state = 0;
    NSMutableAttributedString *_string = [self getAttributedString:@"  New Project" color:[NSColor blackColor]];
    [_btnNewProject setAttributedTitle: _string];
    [_btnNewProject setAttributedAlternateTitle:_string];
    
    /*
    if(_currentProjectName.length > 0)
        _btnNewProject.enabled = false;
    else
        _btnNewProject.enabled = true;
     */
}

- (IBAction)btnUploadClick:(id)sender {
    [self openVideo];
    //[self hideDialogView];
}

-(void)toggleAllButtons:(BOOL)state
{
    _btnBrowse.enabled = state;
    _btnConform.enabled = state;
    _btnEmbed.enabled = state;
    _btnExport.enabled = state;
    _btnNewProject.enabled = state;
}

-(void)toggleButtonState:(NSString*)buttonName{
    
    _btnBrowse.state = 0;
    NSMutableAttributedString *_string = [self getAttributedString:@"    Browse" color:[NSColor whiteColor]];
    [_btnBrowse setAttributedTitle: _string];
    [_btnBrowse setAttributedAlternateTitle:_string];
    _imgBrowseIndicator.hidden = true;
    _boxBrowseMenuItems.hidden = true;
    
    _string = [self getAttributedString:@"    Conform" color:[NSColor whiteColor]];
    _btnConform.state = 0;
    [_btnConform setAttributedTitle:_string];
    [_btnConform setAttributedAlternateTitle:_string];
    _imgConformIndicator.hidden = true;
    
    
    _btnEmbed.state = 0;
    _string = [self getAttributedString:@"    Embed" color:[NSColor whiteColor]];
    [_btnEmbed setAttributedTitle:_string];
    [_btnEmbed setAttributedAlternateTitle:_string];
    _imgEmbedIndicator.hidden = true;

    _btnExport.state = 0;
    _string = [self getAttributedString:@"    Export" color:[NSColor whiteColor]];
    [_btnExport setAttributedTitle:_string];
    [_btnExport setAttributedAlternateTitle:_string];
    _imgExpertViewIndicator.hidden = true;
    
    _lblMessage.hidden = false;
    
    if([buttonName isEqualToString:@"browse"])
    {
        _btnBrowse.state = 1;
        _string = [self getAttributedString:@"    Browse" color:[NSColor orangeColor]];
        [_btnBrowse setAttributedTitle:_string];
        [_btnBrowse setAttributedAlternateTitle:_string];
        _imgBrowseIndicator.hidden = false;
        _boxBrowseMenuItems.hidden = false;
        
        _lblMessage.hidden = true;
        _embedView.hidden = true;
        _browseView.hidden = false;
        _conformView.hidden = true;
        
        if(_currentSelectedProject != nil && _currentSelectedProject.projectName.length > 0){
            _boxProjectAssets.hidden = false;
            _boxAssetFiles.hidden = false;
            _imgMyProjectsIndicator.hidden = false;
            _imgAssetsIndicator.hidden = false;
            _btnAddFiles.hidden = false;
        
        }
        else{
            _boxProjectAssets.hidden = true;
            _boxAssetFiles.hidden = true;
            _imgMyProjectsIndicator.hidden = true;
            _imgAssetsIndicator.hidden = true;
            _btnAddFiles.hidden = true;
        }
    }
    if([buttonName isEqualToString:@"conform"]){
        _btnConform.state = 1;
        _string = [self getAttributedString:@"    Conform" color:[NSColor orangeColor]];
        [_btnConform setAttributedTitle:_string];
        [_btnConform setAttributedAlternateTitle:_string];
        _imgConformIndicator.hidden = false;
        _imgMyProjectsIndicator.hidden = true;
        _imgAssetsIndicator.hidden = true;
        _boxProjectAssets.hidden = true;
        _boxAssetFiles.hidden = true;
        _btnAddFiles.hidden = true;
        _browseView.hidden = true;
        _conformView.hidden = false;
        _embedView.hidden = true;
        _lblMessage.hidden = true;
     
    }
    if([buttonName isEqualToString:@"embed"]){
        _btnEmbed.state = 1;
        _string = [self getAttributedString:@"    Embed" color:[NSColor orangeColor]];
        [_btnEmbed setAttributedTitle:_string];
        [_btnEmbed setAttributedAlternateTitle:_string];
        _imgEmbedIndicator.hidden = false;
        _imgMyProjectsIndicator.hidden = true;
        _imgAssetsIndicator.hidden = true;
        _boxProjectAssets.hidden = true;
        _boxAssetFiles.hidden = true;
        _lblMessage.hidden = true;
        _btnAddFiles.hidden = true;
        _browseView.hidden = true;
        _conformView.hidden = true;
        _embedView.hidden = false;

    }
    if([buttonName isEqualToString:@"export"]){
        _btnExport.state = 1;
        _string = [self getAttributedString:@"    Export" color:[NSColor orangeColor]];
        [_btnExport setAttributedTitle:_string];
        [_btnExport setAttributedAlternateTitle:_string];
        _imgExpertViewIndicator.hidden = false;
        _imgMyProjectsIndicator.hidden = true;
        _imgAssetsIndicator.hidden = true;
        _boxProjectAssets.hidden = true;
        _boxAssetFiles.hidden = true;
        _btnAddFiles.hidden = true;
        _lblMessage.hidden = true;
    }
}

-(NSMutableAttributedString*)getAttributedString:(NSString*)title color:(NSColor*)withColor
{
    NSFont *txtFont = [NSFont systemFontOfSize:18];
    
    NSDictionary *txtDict = [NSDictionary dictionaryWithObjectsAndKeys: txtFont, NSFontAttributeName,
                         withColor, NSForegroundColorAttributeName, nil];
    NSMutableAttributedString *attrStr = [[NSMutableAttributedString alloc] initWithString:title attributes:txtDict];
    return attrStr;
}

- (IBAction)btnCloseDialogClick:(id)sender {
    
    [self hideDialogView];
    
}

-(void)highlightActiveProjectInList:(int)index{
    
    if(index > _userProjects.count)
        index = 0;
    
    for (int i = 0; i < _userProjects.count; i++) {
        // Get row at specified index
        ProjectsCellView *selectedRow = [_tblProjectsList viewAtColumn:0 row:i makeIfNecessary:YES];
        
        // Get row's text field
        NSTextField *selectedRowTextField = [selectedRow projectName];
     
        if(i == index)
            selectedRowTextField.textColor = [NSColor orangeColor];
        else
            selectedRowTextField.textColor = [NSColor blackColor];
    }
    
    if(_userProjects.count > 0)
    {
        _boxProjectAssets.hidden = false;
    }
    
    [self reloadAssets];
}

-(void)setActiveProjectTitle:(NSString*)title collapse:(BOOL)collapse
{
    NSString* _newProjectName = [NSString stringWithFormat:@"\n   %@", title];
    
    NSFont *txtFont = [NSFont systemFontOfSize:18];
    
    NSDictionary *txtDict = [NSDictionary dictionaryWithObjectsAndKeys: txtFont, NSFontAttributeName,
                             [NSColor orangeColor], NSForegroundColorAttributeName, nil];
    
    NSMutableAttributedString *muAtrStr = [[NSMutableAttributedString alloc] initWithString:@"  My Projects" attributes:txtDict];
    
    //NSMutableAttributedString *muAtrStr = [[NSMutableAttributedString alloc]initWithString:@"  My Projects" attributes:@{NSFontAttributeName : [NSFont fontWithName:@"System" size:18]} ];
    
    
    NSFont *txtsubFont = [NSFont systemFontOfSize:12];
    
    NSDictionary *txtsubDict = [NSDictionary dictionaryWithObjectsAndKeys: txtsubFont, NSFontAttributeName,
                                [NSColor orangeColor], NSForegroundColorAttributeName, nil];
    
    NSAttributedString *atrStr = [[NSAttributedString alloc]initWithString:_newProjectName attributes:txtsubDict];
    [muAtrStr appendAttributedString:atrStr];
    
    _btnCloseDialog.hidden = true;
    _btnMyProjects.enabled = true;
    
    _btnNewProject.state = 0;
    //_btnNewProject.enabled = false;
    _imgMyProjectsIndicator.hidden = false;
    //_imgAssetsIndicator.hidden = false;
    _btnMyProjects.state = 1;
    _btnNewProject.enabled = true;
    [_btnMyProjects setAttributedTitle:muAtrStr];
    [_btnMyProjects setAttributedAlternateTitle:muAtrStr];
    
    //animate table height to collapse the table
    if(!_projectsScrollView.hidden && collapse)
    {
        _projectsScrollView.hidden = YES;
    }
    
    //set blue bar text
    _lblSelectProjectTitleBar.stringValue = title;

}

- (IBAction)createNewProjectClick:(id)sender {
    if(_txtProjectName.stringValue.length > 0)
    {
        Project* _prj = [[Project alloc] init];
        
        _prj.projectName = _txtProjectName.stringValue;
        
        //update selected project button text
        [self setActiveProjectTitle:_prj.projectName collapse:true];
        
        //insert in to database
        [_database open];
        NSString *insertQuery = [NSString stringWithFormat:@"INSERT INTO projects (PROJECT_NAME) VALUES ('%@')", _prj.projectName];
        [_database executeUpdate:insertQuery];
        
        //Get id from db
        int project_id = (int)[_database lastInsertRowId];
        
        [_database close];
        
        _prj.projectId = project_id;
        _prj.assets = [[NSMutableArray alloc] init];
        _prj.transitions = [NSMutableArray array];
        _prj.people = [NSMutableArray array];
        _prj.products = [NSMutableArray array];
        _prj.sounds = [NSMutableArray array];
        [_userProjects addObject:_prj];
        [_tblProjectsList reloadData];
        
        _currentProjectIndex = _userProjects.count - 1;
        [self highlightActiveProjectInList:_currentProjectIndex];
        _currentSelectedProject = _prj;

//        _projectCreatedDialog.hidden = false;
//        _projectDialog.hidden = true;
//        _btnCloseDialog.hidden = true;
//        _ctaDialog.hidden = true;
        [self hideDialogView]; //hide by passion
        
        [self reloadAssets];
        
        [self resetEDLPlayerAndFrames];
    }
    else
    {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert addButtonWithTitle:@"OK"];
        [alert setMessageText:@"Invalid Project Name!"];
        [alert setInformativeText:@"Project name cannot be empty."];
        [alert setAlertStyle:NSWarningAlertStyle];
        
        if ([alert runModal] == NSAlertFirstButtonReturn) {
            // OK clicked, delete the record
        }
    }
}


-(void)showAlert:(NSString*)title message:(NSString*)message{
    dispatch_async(dispatch_get_main_queue(), ^{
        NSAlert *alert = [[NSAlert alloc] init];
        [alert addButtonWithTitle:@"OK"];
        [alert setMessageText:title];
        [alert setInformativeText:message];
        [alert setAlertStyle:NSWarningAlertStyle];
        
        if ([alert runModal] == NSAlertFirstButtonReturn) {
            // OK clicked, delete the record
        }
    });

}
-(BOOL)checkVideoLength:(NSURL*)url{
    
    AVPlayerItem *playerItem = [AVPlayerItem playerItemWithURL:url];
    
    CMTime duration = playerItem.asset.duration;
    float seconds = CMTimeGetSeconds(duration);
    
    //NSString* email = [[NSUserDefaults standardUserDefaults] objectForKey:@"email"];
    NSString* userId = [[NSUserDefaults standardUserDefaults] valueForKey:@"userId"];
    NSString* email = [[NSUserDefaults standardUserDefaults] valueForKey:@"email"];
    if([userId isEqualToString:@"the.people"] || [userId isEqualToString:@"rajani"] || [userId.lowercaseString isEqualToString:@"bon2admin"])
    {
        return true;
    }
    else if(email != nil && email.length > 0 && ([email hasSuffix:@"bon2.tv"] || [email hasSuffix:@"bon2.com"] || [email hasSuffix:@"watchtele.tv"])){
        return true;
    }
    else{
        NSString* stationPartner = [[NSUserDefaults standardUserDefaults] valueForKey:@"isStationPartner"];
        if([stationPartner isEqualToString:@"Y"] || [stationPartner isEqualToString:@"y"])
        {
            if(seconds < 1500)
                return true;
            else
                return false;
        }
        else
        {
            if(seconds <= 330)
            {
                return true;
            }
            else
                return false;
        }
    }
    
    return false;
}

-(NSURL*)getURLfromBookmarkData:(NSData*)bookmark
{
    NSURL* url = nil;
    
    BOOL isStale = NO;
    NSError * error = nil;
    url = [NSURL URLByResolvingBookmarkData:bookmark options:NSURLBookmarkResolutionWithSecurityScope relativeToURL:nil bookmarkDataIsStale:&isStale error:&error];
    if ( url == nil )
    {

    }
    else if(isStale)
    {
        // the bookmark data needs to be updated: create & store a new bookmark// . . .
        
    }
    else
    {
        [url startAccessingSecurityScopedResource];
    }
    
    return url;
}

- (Asset*)CreateCTAAssetAndAddtoDB:(NSURL *)url bookmark:(NSData*)bookmark{
    Asset* currentAsset = [[Asset alloc] init];
    currentAsset.assetName = [[url path] lastPathComponent];;
    currentAsset.assetFilePath = [url path];
    currentAsset.assetBookmark = bookmark;
    
    
    currentAsset.assetType = @"cta";
    
    currentAsset.assetProjectId = _currentSelectedProject.projectId;
    
    //2. Insert in to assets table
    [_database open];
    
    BOOL result = [_database executeUpdate:@"INSERT INTO assets (ASSET_NAME, ASSET_PATH, ASSET_TYPE, ASSET_PRJ_ID, BOOKMARK_DATA) VALUES (?, ?, ?, ?, ?)", currentAsset.assetName, currentAsset.assetFilePath, currentAsset.assetType, [NSNumber numberWithInt:currentAsset.assetProjectId], bookmark];
    
    
    //3. Get last id and Update asset object
    currentAsset.assetId = (int)[_database lastInsertRowId];
    
    [_database close];
    
    //4. Add to current project's assets array
    [((Project*)[_userProjects objectAtIndex:_currentProjectIndex]).assets addObject:currentAsset];
    
    return currentAsset;
}

- (Asset*)CreateAssetAndAddtoDB:(NSURL *)url bookmark:(NSData*)bookmark{
    Asset* currentAsset = [[Asset alloc] init];
    currentAsset.assetName = [[url path] lastPathComponent];;
    currentAsset.assetFilePath = [url path];
    currentAsset.assetBookmark = bookmark;

    if([[url pathExtension] isEqualToString:@"mp4"] || [[url pathExtension] isEqualToString:@"m4v"] || [[url pathExtension] isEqualToString:@"mov"])
        currentAsset.assetType = @"video";
    else if([[url pathExtension] isEqualToString:@"edl"])
        currentAsset.assetType = @"edl";
    else if([[url pathExtension] isEqualToString:@"csv"])
        currentAsset.assetType = @"csv";
    else if([[url pathExtension] isEqualToString:@"mp3"])
        currentAsset.assetType = @"audio";
    else
        currentAsset.assetType = @"picture";

//    if([currentAsset.assetType isEqualToString:@"video"])
//    {
//        BOOL isAssetDurationValid = [self checkVideoLength:url];
//        if(!isAssetDurationValid)
//        {
//            NSString* stationPartner = [[NSUserDefaults standardUserDefaults] valueForKey:@"isStationPartner"];
//            if([stationPartner isEqualToString:@"Y"] || [stationPartner isEqualToString:@"y"])
//            {
//                [self showAlert:@"Invalid Video Duration" message:@"The maximum allow video length is 25 minutes."];
//            }
//            else
//            {
//                [self showAlert:@"Invalid Video Duration" message:@"The maximum allow video length is 5.5 minutes."];
//            }
//
//            return nil;
//        }
//    }

    currentAsset.assetProjectId = _currentSelectedProject.projectId;

    //2. Insert in to assets table
    [_database open];

    BOOL result = [_database executeUpdate:@"INSERT INTO assets (ASSET_NAME, ASSET_PATH, ASSET_TYPE, ASSET_PRJ_ID, BOOKMARK_DATA) VALUES (?, ?, ?, ?, ?)", currentAsset.assetName, currentAsset.assetFilePath, currentAsset.assetType, [NSNumber numberWithInt:currentAsset.assetProjectId], bookmark];

    //3. Get last id and Update asset object
    currentAsset.assetId = (int)[_database lastInsertRowId];

    [_database close];

    //4. Add to current project's assets array
    [((Project*)[_userProjects objectAtIndex:_currentProjectIndex]).assets addObject:currentAsset];

    return currentAsset;
}

-(void)openVideo{
    // Create the File Open Dialog class.
    NSOpenPanel* openDlg = [NSOpenPanel openPanel];
    
    // Enable the selection of files in the dialog.
    [openDlg setCanChooseFiles:YES];
    
    // Multiple files not allowed
    [openDlg setAllowsMultipleSelection:YES];
    
    // Can't select a directory
    [openDlg setCanChooseDirectories:NO];
    
    
    // Let the user select any images supported by
    // the NSImage class.
    [openDlg setAllowedFileTypes:[NSArray arrayWithObjects:@"mp4", @"m4v", @"mov", @"png", @"jpg", @"jpeg", @"edl", @"csv", @"mp3",nil]];

    
    // Display the dialog. If the OK button was pressed,
    // process the files.
    if ( [openDlg runModal] == NSModalResponseOK )
    {
        
        [self hideDialogView];
        
        // Get an array containing the full filenames of all
        // files and directories selected.
        NSArray* urls = [openDlg URLs];
        
        //[self readFromURL:[urls objectAtIndex:0] showOnlyFirstThumb:true];
        
        _currentAssetFileUrl = [urls objectAtIndex:0];
        
        _boxProjectAssets.hidden = false;
        _imgMyProjectsIndicator.hidden = false;
        _imgAssetsIndicator.hidden = false;
        _boxAssetFiles.hidden = false;
        _btnAddFiles.hidden = false;
        
        // Loop through all the files and process them.
        for(int i = 0; i < [urls count]; i++ )
        {
            NSURL* url = [urls objectAtIndex:i];
            NSLog(@"Url: %@", url);
            
            NSData *bookmark = nil;
            NSError *error = nil;
            bookmark = [url bookmarkDataWithOptions:NSURLBookmarkCreationWithSecurityScope
                     includingResourceValuesForKeys:nil
                                      relativeToURL:nil // Make it app-scoped
                                              error:&error];
            if (error) {
                NSLog(@"Error creating bookmark for URL (%@): %@", url, error);
                [self showAlert:@"Error" message:@"Error creating file bookmark."];
            }
            else{
                //1. Read file details and create asset object
                [self CreateAssetAndAddtoDB:url bookmark:bookmark];
            }
        }
        [_tblImportAssets reloadData];
    }
}
- (IBAction)btnImportVideoAssetClicked:(id)sender {
    
//    _btnExport.enabled = true;
//    [self readFromURL:_currentAssetFileUrl];
//    //_btnImportVideoAsset.enabled = false;
    if(_currentSelectedProject.assets.count > 0)
    {
        //_btnAddFiles.hidden = YES;
        _boxBinView.hidden = NO;
        [self addToBin];
    }
}

-(void)findAllFrames{
    /*NSMutableArray *thumbTimes=[NSMutableArray arrayWithCapacity:self.playerView.player.currentItem.asset.duration.value];
    for(int t=0;t < self.playerView.player.currentItem.asset.duration.value;t++) {
        CMTime thumbTime = CMTimeMake(t,self.playerView.player.currentItem.asset.duration.timescale);
        NSValue *v=[NSValue valueWithCMTime:thumbTime];
        [thumbTimes addObject:v];
    }
    AVAssetImageGenerator* generator = [[AVAssetImageGenerator alloc] initWithAsset:self.playerView.player.currentItem.asset];
    generator.appliesPreferredTrackTransform=TRUE;
    generator.requestedTimeToleranceAfter=kCMTimeZero;
    generator.requestedTimeToleranceBefore=kCMTimeZero;
    
    __block int frameNumber = 0;
    AVAssetImageGeneratorCompletionHandler handler = ^(CMTime requestedTime, CGImageRef im, CMTime actualTime, AVAssetImageGeneratorResult result, NSError *error){
        if (result != AVAssetImageGeneratorSucceeded) {
            NSLog(@"couldn't generate thumbnail, error:%@", error);
        }
        frameNumber = frameNumber + 1;
        float _fl = CMTimeGetSeconds(actualTime);
    };
    CGSize maxSize = CGSizeMake(320, 180);
    generator.maximumSize = maxSize;
    [generator generateCGImagesAsynchronouslyForTimes:thumbTimes completionHandler:handler];*/
    [self showProgress];
    AVAsset* asset = _playerView.player.currentItem.asset;
    //get video track
    NSArray *videoTracks = [asset tracksWithMediaType:AVMediaTypeVideo];
    AVAssetTrack *track = [videoTracks objectAtIndex:0];
    if(track == nil)
        return;
    AVAssetReaderTrackOutput* output = [[AVAssetReaderTrackOutput alloc] initWithTrack:track outputSettings:nil];
    NSError *error = nil;

    AVAssetReader *reader = [[AVAssetReader alloc] initWithAsset:asset error:&error];
    if (error != nil) {
        currentVideoFrames = [[NSMutableArray alloc] init];
        int frameNumber = -1;
        CMTime frTime = CMTimeMake(0, track.naturalTimeScale);
        double durationAsSecond = CMTimeGetSeconds(track.timeRange.duration);
        while (frameNumber < durationAsSecond * track.nominalFrameRate) {
            frameNumber ++;
            NSMutableDictionary* dict = [@{@"frame":[NSNumber numberWithInt:frameNumber], @"time":[NSNumber numberWithDouble:CMTimeGetSeconds(frTime)], @"duration":[NSNumber numberWithDouble: CMTimeGetSeconds(track.minFrameDuration)], @"cmtime":[NSValue valueWithBytes:&frTime objCType:@encode(CMTime)]} mutableCopy];

            [currentVideoFrames addObject:dict];

            frTime = CMTimeMakeWithSeconds(frameNumber / track.nominalFrameRate, track.naturalTimeScale);
        }
//        [self showAlert:@"error" message:error.localizedDescription];
        [self hideProgress];

        return;
    }
    [reader addOutput:output];

    currentVideoFrames = [[NSMutableArray alloc] init];

    [reader startReading];

    int frameNumer = -1;

    while ( [reader status] == AVAssetReaderStatusReading ) {
        CMSampleBufferRef sampleBuffer = [output copyNextSampleBuffer];
        if(sampleBuffer){
            CMTime frTime = CMSampleBufferGetOutputPresentationTimeStamp(sampleBuffer);
            //frTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
            //frTime = CMSampleBufferGetOutputDecodeTimeStamp(sampleBuffer);
            if(CMTIME_IS_VALID(frTime)){
                frameNumer++;
                //NSLog(@"Frame: %d, Time: %f",frameNumer, CMTimeGetSeconds(frTime));
                NSMutableDictionary* dict = [@{@"frame":[NSNumber numberWithInt:frameNumer], @"time":[NSNumber numberWithDouble:CMTimeGetSeconds(frTime)], @"duration":[NSNumber numberWithDouble:CMTimeGetSeconds(CMSampleBufferGetOutputDuration(sampleBuffer))], @"cmtime":[NSValue valueWithBytes:&frTime objCType:@encode(CMTime)]} mutableCopy];

                [currentVideoFrames addObject:dict];
            }
        }
    }
    //sort array
    //NSArray *array1 = [NSArray arrayWithArray:currentVideoFrames];
    NSSortDescriptor* sortOrder = [NSSortDescriptor sortDescriptorWithKey: @"time" ascending: YES];
    currentVideoFrames = [[currentVideoFrames sortedArrayUsingDescriptors: [NSArray arrayWithObject: sortOrder]] mutableCopy];

    /*
    NSArray *sortedArray = [currentVideoFrames sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        NSNumber* time1 = [obj1 objectForKey:@"time"];
        NSNumber* time2 = [obj2 objectForKey:@"time"];
        return [time1 compare:time2];
    }];

    currentVideoFrames = [sortedArray mutableCopy];*/

    /*
    int lowest_frameNumber = [[(NSDictionary*)[currentVideoFrames objectAtIndex:0] objectForKey:@"frame"] intValue];
    int lowest_time = [[(NSDictionary*)[currentVideoFrames objectAtIndex:0] objectForKey:@"time"] intValue];

    for (int i = 0; i < currentVideoFrames.count; i++) {
        int new_fr_number = [[(NSDictionary*)[currentVideoFrames objectAtIndex:i] objectForKey:@"frame"] intValue];
        if(new_fr_number < lowest_frameNumber)
            lowest_frameNumber = new_fr_number;
    }
    int setFrameNumber = lowest_frameNumber;*/
    for (int i = 0; i < currentVideoFrames.count; i++) {
        [((NSMutableDictionary*)[currentVideoFrames objectAtIndex:i]) setObject:[NSNumber numberWithInt:i] forKey:@"frame"];

        //NSLog(@"Frame: %d, Time: %f, duration:%f",i, [[((NSMutableDictionary*)[currentVideoFrames objectAtIndex:i]) objectForKey:@"time"] doubleValue], [[((NSMutableDictionary*)[currentVideoFrames objectAtIndex:i]) objectForKey:@"duration"] doubleValue]);
        //setFrameNumber++;
    }

    [self hideProgress];
}

-(NSImage *) imageFromSampleBuffer:(CMSampleBufferRef) sampleBuffer
{
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    
    CVPixelBufferLockBaseAddress(imageBuffer,0);
    
    uint8_t *baseAddress = (uint8_t *)CVPixelBufferGetBaseAddress(imageBuffer);
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef newContext = CGBitmapContextCreate(baseAddress, width, height, 8, bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    
    CGImageRef newImage = CGBitmapContextCreateImage(newContext);
    
    CGContextRelease(newContext);
    CGColorSpaceRelease(colorSpace);
    
    NSImage *newUIImage = [[NSImage alloc] initWithCGImage:newImage size:NSMakeSize(width, height)];
    
    CFRelease(newImage);
    
    return newUIImage;
}

-(void)createTimeCodeTrack{
    NSError* localError = nil;
    //NSString* webStringURL = [_selectedAssetToAssemble.assetFilePath stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    _currentAssetFileUrl = [self getURLfromBookmarkData:_selectedAssetToAssemble.assetBookmark];
    if (_currentAssetFileUrl == nil) {
        _currentAssetFileUrl = [[NSURL alloc] initWithString: _selectedAssetToAssemble.assetFilePath];
    }
    
    AVAsset *localAsset = _playerView.player.currentItem.asset;
    /*//COMMENTED TO READ FROM BOOKMARK
    if(![webStringURL hasPrefix:@"file://"])
        webStringURL = [NSString stringWithFormat:@"file://%@",webStringURL];
    
    _currentAssetFileUrl = [NSURL URLWithString:webStringURL];
    */
    
    AVAssetWriter *assetWriter = [[AVAssetWriter alloc] initWithURL:_currentAssetFileUrl
                                                           fileType:AVFileTypeMPEG4 error:&localError];
    
    if(assetWriter != nil){
        AVAssetTrack *audioTrack = nil, *videoTrack = nil;
        
        NSArray *videoTracks = [localAsset tracksWithMediaType:AVMediaTypeVideo];
        
        if ([videoTracks count] > 0)
            videoTrack = [videoTracks objectAtIndex:0];
        
        // Setup video track to write video samples into
        if(videoTrack){
            AVAssetWriterInput *videoInput = [AVAssetWriterInput assetWriterInputWithMediaType:
                                              [videoTrack mediaType] outputSettings:nil];
            
            [assetWriter addInput:videoInput];
            
            // Setup timecode track in order to write timecode samples
            AVAssetWriterInput *timecodeInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeTimecode outputSettings:nil];
            
            // The default size of a timecode track is 0x0. Uncomment the following line to make the timecode samples viewable in QT7-based apps that use the timecode media handler APIs for timecode display. Some older QT7-based apps may not recognize that 64-bit timecode tracks are eligible for timecode display.
            //[timecodeInput setNaturalSize:CGSizeMake(videoTrack.naturalSize.width, 16)];
            
            [videoInput addTrackAssociationWithTrackOfInput:timecodeInput type:AVTrackAssociationTypeTimecode];
            [assetWriter addInput:timecodeInput];
        }
    }
    
    
}

-(void)showCurrentFrameNumber:(CMTime)givenTime{
    if (currentVideoFrames.count == 0) {
        return;
    }

    CMTime currentTime = givenTime;
    if(CMTimeCompare(currentTime,kCMTimeZero) == 0)
        currentTime = _playerView.player.currentTime;
    currentTimeInSeconds = CMTimeGetSeconds(currentTime);
    double timeToAdd = 0;
    currentTimeSeconds = 0;
    currentTimeCodeFrame = -1;
    currentFrameNumber = 0;
    currentFrameNumber = [[(NSDictionary*)[currentVideoFrames objectAtIndex:0] objectForKey:@"frame"] intValue];
    int secondsCounter = 1;
    for (int i = 0; i < [currentVideoFrames count]; i++) {
        NSDictionary* frameDict = [currentVideoFrames objectAtIndex:i];
        NSNumber* currentFrameDuration = [frameDict valueForKey:@"time"];
        timeToAdd = /*timeToAdd +*/ [currentFrameDuration doubleValue];
        currentTimeCodeFrame++;
        
        if(timeToAdd > secondsCounter)
        {
            secondsCounter++;
            currentTimeSeconds++;
            currentTimeCodeFrame = 0;
        }
        
        if(timeToAdd >= currentTimeInSeconds){
            //currentFrameNumber = i;
            currentFrameNumber = [[frameDict objectForKey:@"frame"] intValue];
            [self updateFrameCountDisplay:false];
            break;
        }
    }
}

-(int)getFrameNumberForEditTime:(CMTime)givenTime{
    CMTime currentTime = givenTime;
    if(CMTimeCompare(currentTime,kCMTimeZero) == 0)
        currentTime = _playerView.player.currentTime;
    double currentTimeInSeconds = CMTimeGetSeconds(currentTime);
    float timeToAdd = 0;
    
    int currentFrameNumber = 0;
    currentFrameNumber = [[(NSDictionary*)[currentVideoFrames objectAtIndex:0] objectForKey:@"frame"] intValue];

    for (int i = 0; i < [currentVideoFrames count]; i++) {
        NSDictionary* frameDict = [currentVideoFrames objectAtIndex:i];
        NSNumber* currentFrameDuration = [frameDict valueForKey:@"time"];
        timeToAdd = [currentFrameDuration doubleValue];

        if(timeToAdd > currentTimeInSeconds){
            currentFrameNumber = [[frameDict objectForKey:@"frame"] intValue];
            break;
        }
    }
    return currentFrameNumber;
}

-(void)readTimeCodeTrack{
    AVTimecodeReader *timecodeReader = [[AVTimecodeReader alloc] initWithSourceAsset:_playerView.player.currentItem.asset];
    NSArray *outputTimecodes = [timecodeReader readTimecodeSamples];
    
    for (NSValue *timecodeValue in outputTimecodes) {
        CVSMPTETime timecode = {0};
        [timecodeValue getValue:&timecode];
        NSLog(@"%@",[NSString stringWithFormat:@"HH:MM:SS:FF => %02d:%02d:%02d:%02d", timecode.hours, timecode.minutes, timecode.seconds, timecode.frames]);
    }
}

-(void)addToBin{
    _binFiles = [[NSMutableArray alloc] init];
    
    for (int i = 0; i < _assetsOfSelectedType.count; i++) {
        // Get row at specified index
        ItemSelectionCellView *selectedRow = [_tblImportAssets viewAtColumn:0 row:i makeIfNecessary:YES];
        
        if(selectedRow.ListItem.state == 1)
        {
            [_binFiles addObject:selectedRow.AssetForItem];
        }
    }
    _boxBinView.hidden = false;
    _tblBinFiles.hidden = false;
    _btnConformSelected.hidden = false;
    _btnEmbedSelected.hidden = false;
    
    [_tblBinFiles reloadData];
}

-(void)loadEDLfromCSV:(NSString*)csvFilePath
{
    @try {
        if(ReplaceEDLsFromDisk)
        {
            ReplaceEDLsFromDisk = false;
            _EDLs = [_savedEDLs mutableCopy];
            [_tblEDLs reloadData];
            if(_EDLs.count > 0){
                [self selectEDLinTableAtIndex:0];
                [self assemble];
            }
            return;
        }
    } @catch (NSException *exception) {
        [self showAlert:@"Error loading csv from disk" message:exception.description];
    } @finally {
        //...
    }
    
    
    NSError* err  = nil;
    NSString *psEdlFile = [NSString stringWithContentsOfFile:csvFilePath encoding:NSASCIIStringEncoding error:&err];
    // Reads the file as one string. EDL's are simple ASCII text files of roughly 50KB.
    
    NSArray *psEdlLines = [psEdlFile componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    // Separates the data into lines.
    
    if([psEdlLines count] == 0)
    {
        NSLog(@"Error!");
    } //prints error if EDL file has no events.
    else
    {
        _EDLs = [[NSMutableArray alloc]init];

        NSValue* frTimeValue = [(NSDictionary*)[currentVideoFrames objectAtIndex:0] objectForKey:@"cmtime"];
        CMTime frTime;
        [frTimeValue getValue:&frTime];
        
        for (NSString *line in psEdlLines)
        {
            NSScanner *lineScanner = [NSScanner scannerWithString:line];
            
            int eventNum;
            
            if ([lineScanner scanInt:&eventNum])
            {
                // parse the event into fields
                
                // does not work if edl contains dissolve or wipe
                // need to automatically convert dissolves into cuts
                if(eventNum >= 1){
                    NSString *editNum;
                    NSString *reelName;
                    NSString *channels = @" - ";
                    NSString *operation = @" - ";
                    //NSString *opDuration;
                    NSString *sourceInTime;
                    NSString *sourceOutTime;
                    NSString *destInTime;
                    NSString *destOutTime;
                    
                    NSScanner *elementScanner = [NSScanner scannerWithString:line];
                    NSArray *editComponents = [line componentsSeparatedByString:@","];
                    
                    //NSString *token = [NSString string];
                    NSCharacterSet *divider = [NSCharacterSet characterSetWithCharactersInString:@","];
                    
                    [elementScanner scanUpToCharactersFromSet:divider intoString:&editNum];
                    [elementScanner scanUpToCharactersFromSet:divider intoString:&reelName];
                    [elementScanner scanUpToCharactersFromSet:divider intoString:&destInTime];
                    
                    editNum = (NSString *)editComponents[0];
                    double timeValue = editComponents.count < 5 ? [editComponents[2] doubleValue] : [editComponents[3] doubleValue];
                    CMTime getTime = CMTimeMakeWithSeconds(timeValue, frTime.timescale);
                    reelName = [NSString stringWithFormat:@"%d", [self getFrameNumberForEditTime:getTime]];

                    int closestTime = CMTimeGetSeconds(getTime);

                    int h = closestTime / 3600;
                    int m = (closestTime / 60) % 60;
                    int s = closestTime % 60;
                    NSString *edit = [NSString stringWithFormat:@"%02d:%02d:%02d:00", h, m, s];

                    if([_EDLs count] == 0 && ![edit isEqualToString:@"00:00:00:00"])
                    {
                        //Inject edit at 00:00:00:00
                        EDL* edl = [[EDL alloc]init];
                        edl.editNumber = @"0";
                        edl.reelName = @"0";
                        edl.channel = channels;
                        edl.operation = operation;
                        edl.sourceIn = @"00:00:00:00";
                        edl.sourceOut = @"00:00:00:00";
                        edl.destIn = @"00:00:00:00";
                        edl.destOut = @"00:00:00:00";
                        edl.time = kCMTimeZero;
                        [_EDLs addObject:edl];
                    }

                    sourceInTime = sourceOutTime = destOutTime = destInTime = edit;

                    EDL* edl = [[EDL alloc]init];
                    edl.editNumber = editNum;
                    edl.reelName = reelName;
                    edl.channel = channels;
                    edl.operation = operation;
                    edl.sourceIn = sourceInTime;
                    edl.sourceOut = sourceOutTime;
                    edl.destIn = destInTime;
                    edl.destOut = destOutTime;
                    edl.time = getTime;
                    
                    [_EDLs addObject:edl];
                    
                    NSLog(@"Event\tReelName\tChannels\tOperation\tSource In\tSource Out\tDest In\t\tDest Out");
                    NSLog(@"%@\t%@\t%@\t\t\t%@\t\t\t%@\t%@\t%@\t%@",
                          editNum, reelName, channels, operation, /*opDuration,*/ sourceInTime, sourceOutTime, destInTime,destOutTime);
                }
            }//end if
        }//end for
        //reload EDL table
        [_tblEDLs reloadData];
        
        //select first row
        [self selectEDLinTableAtIndex:0];
        
        //assemble frames
        [self assemble];
    }
}

-(NSString*)getFrameTimeFromMilliSecs:(NSString*)msTimeString time:(CMTime*)time{
    //NSArray *timeComponents = [msTimeString componentsSeparatedByString:@":"];
    //NSString* hrs = timeComponents[0];
    //NSString* mins = timeComponents[1];
    //NSString* milliSecs = timeComponents[2];//E.g., 18.601
    
    //float msTime = [milliSecs floatValue];
    
    //int index = [self getClosestIndexOfFrame:msTime];
    
    int index =[msTimeString intValue];
    index++;
    
    NSValue* frTimeValue = [(NSDictionary*)[currentVideoFrames objectAtIndex:index] objectForKey:@"cmtime"];
    CMTime frTime;
    [frTimeValue getValue:&frTime];
    *time = frTime;
    
    int closestTime = CMTimeGetSeconds(frTime);
    
    int h = closestTime / 3600;
    int m = (closestTime / 60) % 60;
    int s = closestTime % 60;
    
    int displayTimeCodeFrameIndex = [self getFrameNumberForEditTime:frTime];
    
    int displayTimeCodeFrame = abs(index - displayTimeCodeFrameIndex);
    if(displayTimeCodeFrame == -1)
        displayTimeCodeFrame = 0;
    
    return [NSString stringWithFormat:@"%02d:%02d:%02d:%02d", h, m, s, displayTimeCodeFrame];
    /*
    NSArray *timeComponents = [msTimeString componentsSeparatedByString:@"."];
    NSString* totalSecs = timeComponents[0];
    NSString* milliSecs = timeComponents[1]; //E.g., 450
    
    float milliSecsInt = [milliSecs floatValue];
    if(currentFPS == 0)
        currentFPS = [self getFrameRateFromAVPlayer];
    float milliseconds = milliSecsInt/1000;
    milliseconds = milliseconds*currentFPS;
    return [NSString stringWithFormat:@"%@:%02d",totalSecs,(int)round(milliseconds)];
     */
}

-(int)getClosestIndexOfFrame:(float)fromTime{
 
    int returnIndex = 0;
    float closestTime = fromTime;
    BOOL found = false;
    if(fromTime == 0)
        return 0;
    for (int i = 0; i < currentVideoFrames.count; i++) {
        NSDictionary* frameDict = [currentVideoFrames objectAtIndex:i];
        
        float timeToCompare = [(NSNumber*)[frameDict objectForKey:@"time"] floatValue];
        
        if(timeToCompare == fromTime){
            closestTime = timeToCompare;
            break;
        }
        else if(timeToCompare > fromTime)
        {
            if(i == 0 || i == currentVideoFrames.count - 1)
            {
                returnIndex = i;
                found = true;
                break;
            }
            returnIndex = i;
            NSDictionary* prevFrameDict = [currentVideoFrames objectAtIndex:i-1];
            float prevTime = [(NSNumber*)[prevFrameDict objectForKey:@"time"] floatValue];
            
            CGFloat leftDifference = fromTime - prevTime;
            CGFloat rightDifference = timeToCompare - fromTime;
            
            if (leftDifference < rightDifference) {
                returnIndex = returnIndex - 1;
            }
            
            found = true;
            break;
        }
    }
    
    if(!found)
    {
        returnIndex = currentVideoFrames.count - 1;
    }
    
    return returnIndex;
}

-(BOOL)notExistsInEDL:(EDL*)edl inEDLs:(NSMutableArray*)EDLs{
    BOOL notExists = true;
    
    for (int i = 0; i < EDLs.count; i++) {
        EDL* currentEdl = EDLs[i];
        if([currentEdl.destIn isEqualToString:edl.destIn] || [currentEdl.destOut isEqualToString:edl.destOut]){
            notExists = false;
            break;
        }
    }
    
    return notExists;
}

-(void)loadEDL:(Asset*)asset
{
    if(ReplaceEDLsFromDisk)
    {
        ReplaceEDLsFromDisk = false;
        _EDLs = [_savedEDLs mutableCopy];
        [_tblEDLs reloadData];
        [self selectEDLinTableAtIndex:0];
        return;
    }
    NSError* filereadError = nil;
    //NSString *psEdlFile = [NSString stringWithContentsOfFile:asset.assetFilePath encoding:NSASCIIStringEncoding error:&filereadError];
    NSURL* fileUrl = [self getURLfromBookmarkData:asset.assetBookmark];
    
    [fileUrl startAccessingSecurityScopedResource];
    
    NSString *psEdlFile = [NSString stringWithContentsOfFile:fileUrl.path encoding:NSASCIIStringEncoding error:&filereadError];
    
    [fileUrl stopAccessingSecurityScopedResource];
    
    // Reads the file as one string. EDL's are simple ASCII text files of roughly 50KB.
    
    NSArray *psEdlLines = [psEdlFile componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    // Separates the data into lines.
    
    if([psEdlLines count] == 0)
    {
        NSLog(@"Error!");
    } //prints error if EDL file has no events.
    else
    {
        _EDLs = [[NSMutableArray alloc]init];
        
        for (NSString *line in psEdlLines)
        {
            NSScanner *lineScanner = [NSScanner scannerWithString:line];
            
            int eventNum;
            
            if ([lineScanner scanInt:&eventNum])
            {
                // parse the event into fields
                
                // does not work if edl contains dissolve or wipe
                // need to automatically convert dissolves into cuts
                
                NSString *editNum;
                NSString *reelName;
                NSString *channels;
                NSString *operation;
                //NSString *opDuration;
                NSString *sourceInTime;
                NSString *sourceOutTime;
                NSString *destInTime;
                NSString *destOutTime;
                
                NSScanner *elementScanner = [NSScanner scannerWithString:line];
                
                //NSString *token = [NSString string];
                NSCharacterSet *divider = [NSCharacterSet whitespaceCharacterSet];
                
                NSArray *array = [line componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                array = [array filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"length > 0"]];
                
                editNum = [array objectAtIndex:0];
                reelName = [array objectAtIndex:1];
                channels = [array objectAtIndex:2];
                operation = [array objectAtIndex:3];
                
                int array_len = array.count;

                sourceInTime = [array objectAtIndex:array_len-4];
                sourceOutTime = [array objectAtIndex:array_len-3];
                destInTime = [array objectAtIndex:array_len-2];
                destOutTime = [array objectAtIndex:array_len-1];
                
                if(([reelName isEqualToString:@"AX"] || [reelName isEqualToString:@"UNKNOWN"]) && ([channels isEqualToString:@"V"] || [channels isEqualToString:@"AA/V" ]) && ![destInTime isEqualToString:destOutTime] && ([operation isEqualToString:@"C"] || [operation isEqualToString:@"K"]))
                {
                    //... Process
                }
                else
                    continue;
                
                if([_EDLs count] == 0 && ![destInTime isEqualToString:@"00:00:00:00"])
                {
                    //Inject edit at 00:00:00:00
                    EDL* edl = [[EDL alloc]init];
                    edl.editNumber = @"0";
                    edl.reelName = @"0";
                    edl.channel = channels;
                    edl.operation = operation;
                    edl.sourceIn = @"00:00:00:00";
                    edl.sourceOut = @"00:00:00:00";
                    edl.destIn = @"00:00:00:00";
                    edl.destOut = destInTime;
                    edl.time = kCMTimeZero;
                    [_EDLs addObject:edl];
                }
                
                EDL* edl = [[EDL alloc]init];
                edl.editNumber = editNum;
                
                edl.channel = channels;
                edl.operation = operation;
                edl.sourceIn = sourceInTime;
                edl.sourceOut = sourceOutTime;
                edl.destIn = destInTime;
                edl.destOut = destOutTime;
                int frameNumber = -1;
                edl.time = [self getTimeForEDLAt:destInTime frameNumber:&frameNumber];//[self parseTimecodeStringIntoCMTime:destInTime];
                //edl.reelName = [NSString stringWithFormat:@"%d", [self getFrameNumberForEditTime:edl.time]];
                edl.reelName = [NSString stringWithFormat:@"%d", frameNumber];
                
                if([self notExistsInEDL:edl inEDLs:_EDLs])
                    [_EDLs addObject:edl];
                
                NSLog(@"Event\tReelName\tChannels\tOperation\tSource In\tSource Out\tDest In\t\tDest Out");
                NSLog(@"%@\t%@\t%@\t\t\t%@\t\t\t%@\t%@\t%@\t%@", 
                      editNum, reelName, channels, operation, /*opDuration,*/ sourceInTime, sourceOutTime, destInTime,destOutTime);
            }//end if
        }//end for
        
        //
        NSMutableArray *tmpEdls = [NSMutableArray array];
        for (int i = 0; i < _EDLs.count; i++) {
            EDL* edl = [_EDLs objectAtIndex:i];
            
            if(tmpEdls.count > 1)
            {
                EDL* prevEdl = [tmpEdls lastObject];
                
                if([edl.destIn isEqualToString:prevEdl.destOut])
                {
                    //[tmpEdls addObject:edl];
                    if([self notExistsInEDL:edl inEDLs:tmpEdls])
                        [tmpEdls addObject:edl];
                }
                else
                {
                    //Create and add EDL to fill the gap between current EDL and previous EDL
                    EDL* edl_new = [[EDL alloc]init];
                    edl_new.editNumber = prevEdl.editNumber;
                    //edl_new.reelName = prevEdl.reelName;
                    edl_new.channel = prevEdl.channel;
                    edl_new.operation = prevEdl.operation;
                    edl_new.sourceIn = prevEdl.destOut;
                    edl_new.sourceOut = edl.destIn;
                    edl_new.destIn = prevEdl.destOut;
                    edl_new.destOut = edl.destIn;
                    int edlNewFrameNumber = -1;
                    edl_new.time = [self getTimeForEDLAt:prevEdl.destOut frameNumber:&edlNewFrameNumber];//[self parseTimecodeStringIntoCMTime:prevEdl.destOut];
                    //edl_new.reelName = [NSString stringWithFormat:@"%d", [self getFrameNumberForEditTime:edl_new.time]];
                    edl_new.reelName = [NSString stringWithFormat:@"%d", edlNewFrameNumber];
                    
                    if([self notExistsInEDL:edl_new inEDLs:tmpEdls])
                        [tmpEdls addObject:edl_new];
                    
                    //Then add the current EDL
                    //[tmpEdls addObject:edl];
                    if([self notExistsInEDL:edl inEDLs:tmpEdls])
                        [tmpEdls addObject:edl];
                }
            }
            else
            {
                //[tmpEdls addObject:edl];
                if([self notExistsInEDL:edl inEDLs:tmpEdls])
                    [tmpEdls addObject:edl];
            }
        }
        
        if(tmpEdls.count > 0)
        {
            _EDLs = [tmpEdls mutableCopy];
        }
        
        for (int i = 0; i < tmpEdls.count; i++) {
            ((EDL*)[tmpEdls objectAtIndex:i]).editNumber = [NSString stringWithFormat:@"%03d", i];
        }
        
        //reload EDL table
        [_tblEDLs reloadData];
        [self selectEDLinTableAtIndex:0];
        //select first row
    }//end else
}

-(void)selectEDLinTableAtIndex:(int)index{
    if(index < _EDLs.count)
    {
        NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:index];
        [_tblEDLs selectRowIndexes:indexSet byExtendingSelection:NO];
        [_tblEDLs scrollRowToVisible:index];
        
        //_lblFrameTime.stringValue = [NSString stringWithFormat:@"%@ %@", ((EDL*)_EDLs[index]).destIn, ((EDL*)_EDLs[index]).destIn];
    }
}

-(void)assemble
{
    if(_selectedAssetToAssemble != nil){
        if(_EDLs.count == 0)
        {
            CMTime currentFrameTime  = _playerView.player.currentTime;
            
            EDL* newEDL = [[EDL alloc] init];
            newEDL.destIn = [NSString stringWithFormat:@"%02d:%02d:%02d:%02d", 0, 0, 0, 0];
            newEDL.time = currentFrameTime;
            newEDL.reelName = [NSString stringWithFormat:@"%d", currentFrameNumber];
            newEDL.sourceOut = newEDL.sourceIn = newEDL.destOut = newEDL.destIn;
            newEDL.editNumber = @"-";
            newEDL.channel = @"C";
            newEDL.operation = @"";
            [_EDLs addObject:newEDL];
        }
        [self showProgress];
        
        
        _currentAssetFileUrl = [self getURLfromBookmarkData:_selectedAssetToAssemble.assetBookmark];

        if (_currentAssetFileUrl == nil) {
            _currentAssetFileUrl = [[NSURL alloc] initWithString: _selectedAssetToAssemble.assetFilePath];
        }

        BOOL status = [self readFromURL:_currentAssetFileUrl showOnlyFirstThumb:false bIsShouldConfigFrame:false];
        
        if(!status)
            [self hideProgress];
        
        _btnExport.enabled = true;
        
        _btnPrevious.enabled = true;
        _btnNext.enabled = true;
        _btnLoop.enabled = true;
        _btnPlayPause.enabled = true;
    }
    else
        [self showAlert:@"Incorrect EDL or Video" message:@"Select a valid video and EDL to assemble."];
}

-(void)detectScenes
{
    if(_selectedAssetToAssemble != nil)
    {
        _currentAssetFileUrl = [self getURLfromBookmarkData:_selectedAssetToAssemble.assetBookmark];
        if (_currentAssetFileUrl == nil) {
            _currentAssetFileUrl = [[NSURL alloc] initWithString: _selectedAssetToAssemble.assetFilePath];
        }

        if (_currentAssetFileUrl != nil) {
            [self openCSVSettingViewController];
            return;
        }
        [self csvFileExists:_currentAssetFileUrl.absoluteString];
    }
    else
    {
        [self showAlert:@"No file selected" message:@"Select a valid video to detect scenes."];
    }
}

-(void)openCSVSettingViewController {
    NSStoryboard * sb = [NSStoryboard storyboardWithName: @"Main" bundle:nil];
    CSVSettingViewController* csvSettingViewController = [sb instantiateControllerWithIdentifier: @"CSVSettingViewController"];
    csvSettingViewController.delegate = self;
    [self presentViewControllerAsModalWindow:csvSettingViewController];
}

- (NSData *)generatePostDataForData:(NSData *)uploadData params:(NSMutableDictionary*)params boundary:(NSString*)boundary fileName:(NSString*)fileName
{
    // Generate the mutable data variable:
    NSMutableData *postData = [NSMutableData data];//initWithLength:[postHeaderData length] ];
    
    //add param 1 boundary
    [postData appendData:[[NSString stringWithFormat:@"\r\n–%@\r\n",boundary] dataUsingEncoding:NSASCIIStringEncoding]];
    
    //Add param1
    [postData appendData:[NSString stringWithFormat:@""]];
    
    //add video opening boundary
    [postData appendData:[[NSString stringWithFormat:@"\r\n–%@\r\n",boundary] dataUsingEncoding:NSASCIIStringEncoding]];
    
    // Generate the post header:
    NSString *header = [NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"; filename=\".%@\"\r\n",[fileName stringByDeletingPathExtension],[fileName pathExtension]];
    //NSString *post = [NSString stringWithCString:"--AaB03x\r\nContent-Disposition: form-data; name=\"upload[file]\"; filename=\"somefile\"\r\nContent-Type: application/octet-stream\r\nContent-Transfer-Encoding: binary\r\n\r\n" encoding:NSASCIIStringEncoding];
    
    // Get the post header int ASCII format:
    NSData *postHeaderData = [header dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
    [postData setData:postHeaderData];
    
    
    
    
    // Add the video:
    [postData appendData: uploadData];
    
    // Add the closing boundry:
    //[postData appendData: [@"\r\n--AaB03x--" dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES]];
    [postData appendData:[[NSString stringWithFormat:@"\r\n–%@–\r\n",boundary] dataUsingEncoding:NSASCIIStringEncoding]];
    

    // Return the post data:
    return postData;
}

- (NSString *)mimeTypeForPath:(NSString *)path {
    return @"video/mp4";
}

- (NSData *)createBodyWithBoundary:(NSString *)boundary
                        parameters:(NSDictionary *)parameters
                             paths:(NSArray *)paths
                          filename:(NSString*)filename
                         fieldName:(NSString *)fieldName {
    NSMutableData *httpBody = [NSMutableData data];
    
    // add params (all params are strings)
    
    [parameters enumerateKeysAndObjectsUsingBlock:^(NSString *parameterKey, NSString *parameterValue, BOOL *stop) {
        [httpBody appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
        [httpBody appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n", parameterKey] dataUsingEncoding:NSUTF8StringEncoding]];
        [httpBody appendData:[[NSString stringWithFormat:@"%@\r\n", parameterValue] dataUsingEncoding:NSUTF8StringEncoding]];
    }];
    
    // add image data
    
    for (NSString *path in paths) {
        //NSString *filename  = [path lastPathComponent];
        NSData   *data      = [NSData dataWithContentsOfFile:path];
        NSString *mimetype  = [self mimeTypeForPath:path];
        
        [httpBody appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
        [httpBody appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"; filename=\"%@\"\r\n", fieldName, filename] dataUsingEncoding:NSUTF8StringEncoding]];
        [httpBody appendData:[[NSString stringWithFormat:@"Content-Type: %@\r\n\r\n", mimetype] dataUsingEncoding:NSUTF8StringEncoding]];
        [httpBody appendData:data];
        [httpBody appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    }
    
    [httpBody appendData:[[NSString stringWithFormat:@"--%@--\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    
    return httpBody;
}

-(void)csvFileExists:(NSString *)filePath{
    
    NSLog(@"POSTING");
    
    NSString *theFileName = [filePath lastPathComponent];

    [self showProgress];
    
    //NSData *httpBody = [self createBodyWithBoundary:boundary parameters:postUserData paths:@[filePath] filename:theFileName fieldName:@"file" ];
    // Build the request body
    NSString *boundary = @"SportuondoFormBoundary";
    NSMutableData *body = [NSMutableData data];
    // Body part for "filename" parameter. This is a string.
    [body appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n", @"file_name"] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"%@\r\n", theFileName] dataUsingEncoding:NSUTF8StringEncoding]];
    // Body part for "username" parameter. This is a string.
    [body appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n", @"user_name"] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"%@\r\n", _username] dataUsingEncoding:NSUTF8StringEncoding]];
    
    [body appendData:[[NSString stringWithFormat:@"--%@--\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    
    // Setup the session
    NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
    sessionConfiguration.HTTPAdditionalHeaders = @{
                                                   @"Content-Type"  : [NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundary]
                                                   };
    
    sessionConfiguration.timeoutIntervalForRequest = 600;
    sessionConfiguration.timeoutIntervalForResource = 600;
    // Create the session
    // We can use the delegate to track upload progress
    NSURLSession *session = [NSURLSession sessionWithConfiguration:sessionConfiguration delegate:self delegateQueue:nil];
    
    // Data uploading task. We could use NSURLSessionUploadTask instead of NSURLSessionDataTask if we needed to support uploads in the background
    NSURL *url = [NSURL URLWithString:@"http://www.bon2.tv/api/is-file-exist.php"/*@"http://34.237.47.16/api/is-file-exist.php"*/];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"POST";
    request.HTTPBody = body;
    
    NSURLSessionDataTask *uploadTask = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        
        // Process the response
        if (error) {
            NSLog(@"error = %@", error);
            [self hideProgress];
            [self uploadToSceneDetect:filePath];
        }
        
        NSError *e = nil;
        
        NSDictionary *resultJson = (NSDictionary*)[NSJSONSerialization JSONObjectWithData: data options: NSJSONReadingMutableContainers error: &e];
        
        if (!resultJson) {
            NSLog(@"Error parsing JSON: %@", e);
            [self hideProgress];
        } else {
            //download csv
            if([resultJson[@"api_status"] isEqualToString:@"1"]){
                NSString* csv_path = resultJson[@"file_csv_url"];
                if(csv_path == nil)
                    csv_path = resultJson[@"s3_file_csv_url"];
                
                NSURL *URL = [NSURL URLWithString:csv_path];
                NSURLRequest *request = [NSURLRequest requestWithURL:URL];
                
                NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
                AFURLSessionManager *manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:configuration];
                
                
                
                NSURLSessionDownloadTask *downloadTask = [manager downloadTaskWithRequest:request progress:nil destination:^NSURL *(NSURL *targetPath, NSURLResponse *response) {
                    NSURL *documentsDirectoryURL = [[NSFileManager defaultManager] URLForDirectory:NSDocumentDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:NO error:nil];
                    NSURL *fileURL = [documentsDirectoryURL URLByAppendingPathComponent:[response suggestedFilename]];
                    
                    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                    if ([httpResponse statusCode] == 200) {
                        // delete existing file (using file URL above)
                        NSFileManager *fileManager = [NSFileManager defaultManager];
                        NSError* error = nil;
                        if([fileManager fileExistsAtPath:fileURL.absoluteString]){
                            [fileManager removeItemAtPath:fileURL.absoluteString error:&error];
                            if(error)
                                [self showAlert:@"Error" message:@"Error overwriting file in Documents folder"];
                        }
                        /**/
                    }
                    return fileURL;
                } completionHandler:^(NSURLResponse *response, NSURL *filePath, NSError *error) {
                    NSLog(@"File downloaded to: %@", filePath);
                    [self hideProgress];
                    Asset* _a = nil;
                    //load edl with csv file
                    NSData *bookmark = nil;
                    NSError *bookmarkError = nil;
                    bookmark = [filePath bookmarkDataWithOptions:NSURLBookmarkCreationWithSecurityScope
                             includingResourceValuesForKeys:nil
                                              relativeToURL:nil // Make it app-scoped
                                                      error:&bookmarkError];
                    if (bookmarkError) {
                        NSLog(@"Error creating bookmark for URL (%@): %@", filePath, bookmarkError);
                        [self showAlert:@"Error" message:@"Error creating file bookmark."];
                    }
                    else{
                        //1. Read file details and create asset object
                        _a  = [self CreateAssetAndAddtoDB:filePath bookmark:bookmark];
                    }
                    
                    //Asset* _a = [self CreateAssetAndAddtoDB:filePath];
                    [_binFiles addObject:_a];
                    [_conformEDLFiles addObject:_a];
                    [_tblConformEDLs reloadData];
                    [_tblImportAssets reloadData];
                    
                    for (int i = 0; i < _conformEDLFiles.count; i++) {
                        // Get row at specified index
                        ItemSelectionCellView *selectedRow = [_tblConformEDLs viewAtColumn:0 row:i makeIfNecessary:YES];
                        selectedRow.ListItem.state = 0;
                        selectedRow.isSelected = NO;
                    }
                    // Select last item
                    int i = _conformEDLFiles.count - 1;
                    ItemSelectionCellView *selectedRow = [_tblConformEDLs viewAtColumn:0 row:i makeIfNecessary:YES];
                    selectedRow.ListItem.state = 1;
                    selectedRow.isSelected = YES;
                    
                    [self loadEDLfromCSV:filePath.path];
                }];
                [downloadTask resume];
            }//end if status == 1
            else
            {
                [self hideProgress];
                [self uploadToSceneDetect:filePath];
            }
        }
    }];
    [uploadTask resume];
}

-(void) checkSceneDetectProgressInBackground:(NSString*)filePath
{
    NSLog(@"POSTING");
    
    NSString *theFileName = [filePath lastPathComponent];
    
    //[self showProgress];
    
    //NSData *httpBody = [self createBodyWithBoundary:boundary parameters:postUserData paths:@[filePath] filename:theFileName fieldName:@"file" ];
    // Build the request body
    NSString *boundary = @"SportuondoFormBoundary";
    NSMutableData *body = [NSMutableData data];
    // Body part for "filename" parameter. This is a string.
    [body appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n", @"file_name"] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"%@\r\n", theFileName] dataUsingEncoding:NSUTF8StringEncoding]];
    // Body part for "username" parameter. This is a string.
    [body appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n", @"user_name"] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"%@\r\n", _username] dataUsingEncoding:NSUTF8StringEncoding]];
    
    [body appendData:[[NSString stringWithFormat:@"--%@--\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    
    // Setup the session
    NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
    sessionConfiguration.HTTPAdditionalHeaders = @{
                                                   @"Content-Type"  : [NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundary]
                                                   };
    
    sessionConfiguration.timeoutIntervalForRequest = 600;
    sessionConfiguration.timeoutIntervalForResource = 600;
    // Create the session
    // We can use the delegate to track upload progress
    NSURLSession *session = [NSURLSession sessionWithConfiguration:sessionConfiguration delegate:self delegateQueue:nil];
    
    // Data uploading task. We could use NSURLSessionUploadTask instead of NSURLSessionDataTask if we needed to support uploads in the background
    NSURL *url = [NSURL URLWithString:@"http://www.bon2.tv/api/is-file-exist.php"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"POST";
    request.HTTPBody = body;
    
    NSURLSessionDataTask *uploadTask = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        
        // Process the response
        if (error) {
            NSLog(@"error = %@", error);
            [self hideProgressAsync];
            IsSceneDetectInProgress = false;
            [self showAlert:@"Error" message:@"Scene Detection Failed"];
        }
        
        NSError *e = nil;
        
        NSDictionary *resultJson = (NSDictionary*)[NSJSONSerialization JSONObjectWithData: data options: NSJSONReadingMutableContainers error: &e];
        
        if (!resultJson) {
            NSLog(@"Error parsing JSON: %@", e);
            [self hideProgressAsync];
            IsSceneDetectInProgress = false;
            [self showAlert:@"Error" message:@"Scene Detection Failed"];
        } else {
            //download csv
            if([resultJson[@"api_status"] isEqualToString:@"1"]){
                NSString* csv_path = resultJson[@"file_csv_url"];
                if(csv_path == nil)
                    csv_path = resultJson[@"s3_file_csv_url"];
                
                NSURL *URL = [NSURL URLWithString:csv_path];
                NSURLRequest *request = [NSURLRequest requestWithURL:URL];
                
                NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
                AFURLSessionManager *manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:configuration];
                
                NSURLSessionDownloadTask *downloadTask = [manager downloadTaskWithRequest:request progress:nil destination:^NSURL *(NSURL *targetPath, NSURLResponse *response) {
                    NSURL *documentsDirectoryURL = [[NSFileManager defaultManager] URLForDirectory:NSDocumentDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:NO error:nil];
                    NSURL *fileURL = [documentsDirectoryURL URLByAppendingPathComponent:[response suggestedFilename]];
                    
                    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                    if ([httpResponse statusCode] == 200) {
                        // delete existing file (using file URL above)
                        NSFileManager *fileManager = [NSFileManager defaultManager];
                        NSError* error = nil;
                        if([fileManager fileExistsAtPath:fileURL.absoluteString]){
                            [fileManager removeItemAtPath:fileURL.absoluteString error:&error];
                            if(error)
                                [self showAlert:@"Error" message:@"Error overwriting file in Documents folder"];
                        }
                        /**/
                    }
                    return fileURL;
                } completionHandler:^(NSURLResponse *response, NSURL *filePath, NSError *error) {
                    NSLog(@"File downloaded to: %@", filePath);
                    [self hideProgressAsync];
                    IsSceneDetectInProgress = false;
                    //load edl with csv file
                    //[self loadEDLfromCSV:filePath];
                    Asset* _a = nil;
                    
                    NSData *bookmark = nil;
                    NSError *bookmarkError = nil;
                    bookmark = [filePath bookmarkDataWithOptions:NSURLBookmarkCreationWithSecurityScope
                                  includingResourceValuesForKeys:nil
                                                   relativeToURL:nil // Make it app-scoped
                                                           error:&bookmarkError];
                    if (bookmarkError) {
                        NSLog(@"Error creating bookmark for URL (%@): %@", filePath, bookmarkError);
                        [self showAlert:@"Error" message:@"Error creating file bookmark."];
                    }
                    else{
                        //1. Read file details and create asset object
                        _a  = [self CreateAssetAndAddtoDB:filePath bookmark:bookmark];
                    }
                    
                    //_a = [self CreateAssetAndAddtoDB:filePath];
                    [_binFiles addObject:_a];
                    [_conformEDLFiles addObject:_a];
                    [_tblConformEDLs reloadData];
                    [_tblImportAssets reloadData];
                    
                    [self showAlert:[filePath lastPathComponent] message:@"Scene Detect Completed"];
                }];
                [downloadTask resume];
            }//end if status == 1
            else
            {
                dispatch_queue_t myBackgroundQ = dispatch_queue_create("com.romanHouse.backgroundDelay", NULL);
                dispatch_time_t delay = dispatch_time(DISPATCH_TIME_NOW, 30 * NSEC_PER_SEC);
                dispatch_after(delay, myBackgroundQ, ^(void){
                    [self checkSceneDetectProgressInBackground:filePath];
                });
                //[self checkSceneDetectProgressInBackground:filePath];
            }
        }
    }];
    [uploadTask resume];
}


- (void)uploadToSceneDetect:(NSString *)filePath
{
    NSLog(@"POSTING");
    IsSceneDetectInProgress = true;
    [self showProgressAsync:[NSString stringWithFormat:@"Detecting Scenes in %@",[filePath lastPathComponent]]];
    
    //NSString *boundary = @"—————————14737809831466499882746641449";
    //NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@",boundary];
    
    NSMutableDictionary *postUserData = [[NSMutableDictionary alloc] init];
    
    NSString *theFileName = [[filePath lastPathComponent] stringByDeletingPathExtension];
    theFileName = [theFileName stringByReplacingOccurrencesOfString:@" " withString:@""];

    
    NSString* extension = [filePath pathExtension];
    
    [postUserData setValue:theFileName forKey:@"file_name"];
    [postUserData setValue:extension forKey:@"file_type"];
    [postUserData setValue:_username forKey:@"user_name"];

    
    //NSData *httpBody = [self createBodyWithBoundary:boundary parameters:postUserData paths:@[filePath] filename:theFileName fieldName:@"file" ];
    // Build the request body
    NSString *boundary = @"SportuondoFormBoundary";
    NSMutableData *body = [NSMutableData data];
    // Body part for "filename" parameter. This is a string.
    [body appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n", @"file_name"] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"%@\r\n", theFileName] dataUsingEncoding:NSUTF8StringEncoding]];
    // Body part for "filetype" parameter. This is a string.
    [body appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n", @"file_type"] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"%@\r\n", extension] dataUsingEncoding:NSUTF8StringEncoding]];
    // Body part for "username" parameter. This is a string.
    [body appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n", @"user_name"] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"%@\r\n", _username] dataUsingEncoding:NSUTF8StringEncoding]];
    // Body part for the attachament. This is an image.
    NSData   *data      = [NSData dataWithContentsOfFile:filePath];
    if (data) {
        [body appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"; filename=\"%@.%@\"\r\n", @"file", theFileName, extension] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[@"Content-Type: video/mp4\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:data];
        [body appendData:[[NSString stringWithFormat:@"\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
    }
    [body appendData:[[NSString stringWithFormat:@"--%@--\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    
    // Setup the session
    NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
    sessionConfiguration.HTTPAdditionalHeaders = @{
                                                   @"Content-Type"  : [NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundary]
                                                   };
    
    sessionConfiguration.timeoutIntervalForRequest = 600;
    sessionConfiguration.timeoutIntervalForResource = 600;
    // Create the session
    // We can use the delegate to track upload progress
    NSURLSession *session = [NSURLSession sessionWithConfiguration:sessionConfiguration delegate:self delegateQueue:nil];
    
    // Data uploading task. We could use NSURLSessionUploadTask instead of NSURLSessionDataTask if we needed to support uploads in the background
    NSURL *url = [NSURL URLWithString:@"http://www.bon2.tv/api/upload-object.php"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"POST";
    request.HTTPBody = body;
   
    NSURLSessionDataTask *uploadTask = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        
        // Process the response
        if (error) {
            NSLog(@"error = %@", error);
            [self hideProgress];
            return;
        }
        
        NSError *e = nil;
        
        NSDictionary *resultJson = (NSDictionary*)[NSJSONSerialization JSONObjectWithData: data options: NSJSONReadingMutableContainers error: &e];
        
        if (!resultJson) {
            NSLog(@"Error parsing JSON: %@", e);
            [self hideProgress];
        } else {
            //download csv
            NSString* csv_path = resultJson[@"file_csv_url"];
            if(csv_path == nil)
                csv_path = resultJson[@"s3_file_csv_url"];
            
            dispatch_queue_t myBackgroundQ = dispatch_queue_create("com.romanHouse.backgroundDelay", NULL);
            dispatch_time_t delay = dispatch_time(DISPATCH_TIME_NOW, 30 * NSEC_PER_SEC);
            dispatch_after(delay, myBackgroundQ, ^(void){
                [self checkSceneDetectProgressInBackground:filePath];
            });
            //[self checkSceneDetectProgressInBackground:filePath];
            
            /*
            NSURL *URL = [NSURL URLWithString:csv_path];
            NSURLRequest *request = [NSURLRequest requestWithURL:URL];
            
            NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
            AFURLSessionManager *manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:configuration];

            

            NSURLSessionDownloadTask *downloadTask = [manager downloadTaskWithRequest:request progress:nil destination:^NSURL *(NSURL *targetPath, NSURLResponse *response) {
                NSURL *documentsDirectoryURL = [[NSFileManager defaultManager] URLForDirectory:NSDocumentDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:NO error:nil];
                NSURL *fileURL = [documentsDirectoryURL URLByAppendingPathComponent:[response suggestedFilename]];

                NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                if ([httpResponse statusCode] == 200) {
                    // delete existing file (using file URL above)
                    NSFileManager *fileManager = [NSFileManager defaultManager];
                    NSError* error = nil;
                    if([fileManager fileExistsAtPath:fileURL.absoluteString]){
                        [fileManager removeItemAtPath:fileURL.absoluteString error:&error];
                        if(error)
                            [self showAlert:@"Error" message:@"Error overwriting file in Documents folder"];
                    }
             
                }
                return fileURL;
            } completionHandler:^(NSURLResponse *response, NSURL *filePath, NSError *error) {
                NSLog(@"File downloaded to: %@", filePath);
                
                
                [self hideProgressAsync];
                //load edl with csv file
                //[self loadEDLfromCSV:filePath];
                Asset* _a = [self CreateAssetAndAddtoDB:filePath];
                [_binFiles addObject:_a];
                [_tblConformEDLs reloadData];
                [_tblImportAssets reloadData];
                
                [self showAlert:[filePath lastPathComponent] message:@"Scene Detect Completed"];
            }];
            [downloadTask resume];
             */
        }
    }];
    [uploadTask resume];

    /*
    NSString *postLength = [NSString stringWithFormat:@"%lu", (unsigned long)[body length]];
    
    // Setup the request:
    NSMutableURLRequest *uploadRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:@"http://52.54.255.102/api/upload-object.php"] cachePolicy: NSURLRequestReloadIgnoringLocalCacheData timeoutInterval: 30 ] ;
    [uploadRequest setHTTPMethod:@"POST"];
    //[uploadRequest setValue:postLength forHTTPHeaderField:@"Content-Length"];
    [uploadRequest setValue:contentType forHTTPHeaderField:@"Content-Type"];
    [uploadRequest setHTTPBody:httpBody];
    
    // Setup the session
    NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
    sessionConfiguration.HTTPAdditionalHeaders = @{
                                                   @"Accept"        : @"application/json,text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng;q=0.8",
                                                   @"Content-Type"  : contentType
                                                   };

    
    NSURLSession *session = [NSURLSession sessionWithConfiguration:sessionConfiguration delegate:self delegateQueue:nil];
    
    NSURLSessionDataTask *task = [session dataTaskWithRequest:uploadRequest completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            NSLog(@"error = %@", error);
            return;
        }
        
        NSError *e = nil;

        NSArray *resultJson = [NSJSONSerialization JSONObjectWithData: data options: NSJSONReadingMutableContainers error: &e];

        if (!resultJson) {
            NSLog(@"Error parsing JSON: %@", e);
        } else {
            for(NSDictionary *item in resultJson) {
                NSLog(@"Item: %@", item);
            }
        }
    }];
    [task resume];
*/
}

-(void)uploadUsingAFNetworking{
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    AFURLSessionManager *manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:configuration];
    
    NSURL *URL = [NSURL URLWithString:@"http://52.54.255.102/api/upload-object.php"];
    NSURLRequest *request = [NSURLRequest requestWithURL:URL];
    
    NSURL *filePath = [NSURL fileURLWithPath:@"file://path/to/image.png"];
    NSURLSessionUploadTask *uploadTask = [manager uploadTaskWithRequest:request fromFile:filePath progress:nil completionHandler:^(NSURLResponse *response, id responseObject, NSError *error) {
        if (error) {
            NSLog(@"Error: %@", error);
        } else {
            NSLog(@"Success: %@ %@", response, responseObject);
        }
    }];
    [uploadTask resume];
}

- (IBAction)chkVideoClicked:(id)sender {
    if(_chkVideos.state == 1)
    {
        if(![_selectedAssetTypes containsObject:@"video"])
        {
            [_selectedAssetTypes addObject:@"video"];
        }
    }
    else
    {
        [_selectedAssetTypes removeObject:@"video"];
        _chkSelectAllAssets.state = 0;
    }
    [self reloadAssets];
}
- (IBAction)chkEDLClicked:(id)sender {
    if(_chkEDLs.state == 1)
    {
        if(![_selectedAssetTypes containsObject:@"edl"])
        {
            [_selectedAssetTypes addObject:@"edl"];
        }
        if(![_selectedAssetTypes containsObject:@"csv"])
        {
            [_selectedAssetTypes addObject:@"csv"];
        }
    }
    else
    {
        [_selectedAssetTypes removeObject:@"edl"];
        [_selectedAssetTypes removeObject:@"csv"];
        _chkSelectAllAssets.state = 0;
    }
    [self reloadAssets];
}
- (IBAction)chkPicturesClicked:(id)sender {
    if(_chkPictures.state == 1)
    {
        if(![_selectedAssetTypes containsObject:@"picture"])
        {
            [_selectedAssetTypes addObject:@"picture"];
        }
    }
    else
    {
        [_selectedAssetTypes removeObject:@"picture"];
        _chkSelectAllAssets.state = 0;
    }
    [self reloadAssets];
}
- (IBAction)chkAudioClicked:(id)sender {
    if(_chkAudio.state == 1)
    {
        if(![_selectedAssetTypes containsObject:@"audio"])
        {
            [_selectedAssetTypes addObject:@"audio"];
        }
    }
    else
    {
        [_selectedAssetTypes removeObject:@"audio"];
    }
    
    [self reloadAssets];
}
- (IBAction)chkSelectAllClicked:(id)sender {
    _chkVideos.state = _chkSelectAllAssets.state;
    _chkAudio.state = _chkSelectAllAssets.state;
    _chkPictures.state = _chkSelectAllAssets.state;
    _chkEDLs.state = _chkSelectAllAssets.state;
    
    if(_chkSelectAllAssets.state == 1)
    {
        if(![_selectedAssetTypes containsObject:@"video"])
        {
            [_selectedAssetTypes addObject:@"video"];
        }
        if(![_selectedAssetTypes containsObject:@"edl"])
        {
            [_selectedAssetTypes addObject:@"edl"];
        }
        if(![_selectedAssetTypes containsObject:@"csv"])
        {
            [_selectedAssetTypes addObject:@"csv"];
        }
        if(![_selectedAssetTypes containsObject:@"picture"])
        {
            [_selectedAssetTypes addObject:@"picture"];
        }
        if(![_selectedAssetTypes containsObject:@"audio"])
        {
            [_selectedAssetTypes addObject:@"audio"];
        }
        //[self selectAllAssets];
        [self reloadAssets];
    }
    else
    {
        [_selectedAssetTypes removeObject:@"video"];
        [_selectedAssetTypes removeObject:@"edl"];
        [_selectedAssetTypes removeObject:@"csv"];
        [_selectedAssetTypes removeObject:@"picture"];
        [_selectedAssetTypes removeObject:@"audio"];
        
        _boxAssetFiles.hidden = true;
        _boxBinView.hidden = true;
        _btnAddFiles.hidden = true;
    }
}

-(void)selectAllAssets
{
    
    for (int i = 0; i < _assetsOfSelectedType.count; i++) {
        // Get row at specified index
        ItemSelectionCellView *selectedRow = [_tblImportAssets viewAtColumn:0 row:i makeIfNecessary:YES];
        selectedRow.ListItem.state = 1;
        selectedRow.isSelected = YES;
    }
    
    //[_tblImportAssets selectAll:self];
}

-(void)reloadAssets{
    
    _tblBinFiles.hidden = true;
    _btnConformSelected.hidden = true;
    _btnEmbedSelected.hidden = true;
    
    currentProjecMVIDPaths = [NSMutableArray array];
    
    if(_selectedAssetTypes.count > 0)
    {
        _boxAssetFiles.hidden = false;
        _btnAddFiles.hidden = false;
    }
    else
    {
        _boxAssetFiles.hidden = true;
        _btnAddFiles.hidden = true;
    }
    
    if(_selectedAssetTypes.count == 5)
        _chkSelectAllAssets.state = 1;
    else
        _chkSelectAllAssets.state = 0;
    
    [_tblImportAssets reloadData];
    
    [self reloadTileLibrary];
    
    [self reloadPeopleAndProducts];
    
    _imgSelectedAssetImage.image = nil;
    [self resetADTileEditor:nil];
    _tileCategoryComboBox.enabled = false;
}

-(void)reloadPeopleAndProducts{
    //Read existing people and products, if any
    
    [self.database open];
    
    //Read People
    NSString* q = [NSString stringWithFormat:@"SELECT * FROM PEOPLE WHERE PROJECT_ID=%d", _currentSelectedProject.projectId];
    
    FMResultSet* prjResults = [self.database executeQuery:q];
    
    _embedPeopleAssets = [NSMutableArray array];
    
    while([prjResults next])
    {
        Asset* _a1 = [[Asset alloc] init];
        _a1.assetId = [prjResults intForColumn:@"ASSET_ID"];
        _a1.assetIdentifier = [prjResults stringForColumn:@"ASSET_IDENTIFIER"];
        _a1.assetName = [[prjResults stringForColumn:@"ASSET_NAME"] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        _a1.assetName = [_a1.assetName stringByReplacingOccurrencesOfString:@"%27" withString:@"'"];
        
        _a1.nickName = [[prjResults stringForColumn:@"NICK_NAME"] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        _a1.nickName = [_a1.nickName stringByReplacingOccurrencesOfString:@"%27" withString:@"'"];
        
        _a1.firstName = [[prjResults stringForColumn:@"FIRST_NAME"] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        _a1.firstName = [_a1.nickName stringByReplacingOccurrencesOfString:@"%27" withString:@"'"];
        
        _a1.lastName = [[prjResults stringForColumn:@"LAST_NAME"] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        _a1.lastName = [_a1.nickName stringByReplacingOccurrencesOfString:@"%27" withString:@"'"];

        _a1.assetType = @"people";
        _a1.assetFilePath = [prjResults stringForColumn:@"ASSET_IMAGE_PATH"];// stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        _a1.assetImage = [[NSImage alloc] initWithContentsOfURL:[NSURL URLWithString:_a1.assetFilePath]];
        _a1.assetDisplayName = _a1.assetName;

        _a1.assetProfileDescription = [[prjResults stringForColumn:@"ASSET_DESC"] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        _a1.assetProfileDescription = [_a1.assetProfileDescription stringByReplacingOccurrencesOfString:@"%27" withString:@"'"];

        _a1.assetFacebookLink = [prjResults stringForColumn:@"FACEBOOK_LINK"];
        _a1.assetTwitterLink = [prjResults stringForColumn:@"INSTAGRAM_LINK"];
        _a1.assetInstagraamLink = [prjResults stringForColumn:@"PINTEREST_LINK"];
        _a1.assetPinterestLink = [prjResults stringForColumn:@"TWITTER_LINK"];
        _a1.assetWebsiteLink = [prjResults stringForColumn:@"WEBSITE_LINK"];
        
        if(_a1.assetProfileDescription == nil || [_a1.assetProfileDescription isEqualToString:@"(null)"])
            _a1.assetProfileDescription = @"";
        [_embedPeopleAssets addObject:_a1];
    }
    
    
    //Read Products
    NSString* pq = [NSString stringWithFormat:@"SELECT * FROM PRODUCTS WHERE PROJECT_ID=%d", _currentSelectedProject.projectId];
    
    FMResultSet* prdResults = [self.database executeQuery:pq];
    
    _embedImageAssets = [NSMutableArray array];
    
    while([prdResults next])
    {
        Asset* _a1 = [[Asset alloc] init];
        _a1.assetId = [prdResults intForColumn:@"ASSET_ID"];
        _a1.assetIdentifier = [prdResults stringForColumn:@"ASSET_IDENTIFIER"];
        _a1.assetName = [[prdResults stringForColumn:@"ASSET_NAME"] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        _a1.assetName = [_a1.assetName stringByReplacingOccurrencesOfString:@"%27" withString:@"'"];
        
        _a1.assetType = @"product";

        _a1.assetFilePath = [prdResults stringForColumn:@"ASSET_IMAGE_PATH"];// stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];

        _a1.assetImage = [[NSImage alloc] initWithContentsOfURL:[NSURL URLWithString:_a1.assetFilePath]];
        _a1.assetDisplayName = _a1.assetName;

        _a1.assetProfileDescription = [[prdResults stringForColumn:@"ASSET_DESC"] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        _a1.assetProfileDescription = [_a1.assetProfileDescription stringByReplacingOccurrencesOfString:@"%27" withString:@"'"];
        
        _a1.link1 = [prdResults stringForColumn:@"TILE_LINK1"];
        _a1.link2 = [prdResults stringForColumn:@"TILE_LINK2"];
        _a1.link3 = [prdResults stringForColumn:@"TILE_LINK3"];
        _a1.link4 = [prdResults stringForColumn:@"TILE_LINK4"];
        _a1.link5 = [prdResults stringForColumn:@"TILE_LINK5"];

        _a1.brandName = [[prdResults stringForColumn:@"BRAND_NAME"] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        _a1.brandName = [_a1.brandName stringByReplacingOccurrencesOfString:@"%27" withString:@"'"];
        
        if([[prdResults stringForColumn:@"GENERAL_CATEGORY"] isEqualToString:@"Y"])
            _a1.general_category = YES;
        else
            _a1.general_category = NO;

        if(_a1.assetProfileDescription == nil || [_a1.assetProfileDescription isEqualToString:@"(null)"])
            _a1.assetProfileDescription = @"";
        [_embedImageAssets addObject:_a1];
    }
    [prjResults close];
    [prdResults close];
    
    
    //close database connection
    //[_database close];
    
    [_embedImagesCollectionView reloadData];
}

-(void)reloadTileLibrary{
    //Read existing projects and assets, if any
    
    NSString* q = [NSString stringWithFormat:@"SELECT * FROM LIBRARY WHERE PROJECT_ID=%d", _currentSelectedProject.projectId];
    
    [self.database open];
    
    FMResultSet* prjResults = [self.database executeQuery:q];
    
    _ADTileLibrary = [NSMutableArray array];
    
    while([prjResults next])
    {
        
        /*NSString *insertQuery = [NSString stringWithFormat:@"INSERT INTO library (TILE_IMAGE_PATH, TILE_HEADING, TILE_DESC, TILE_PLATE_COLOR, TILE_TRANSITION, TILE_LINK, TILE_HEADING_COLOR, TILE_DESC_COLOR, IS_HEADING_BOLD, IS_HEADING_ITALIC, IS_HEADING_UNDERLINE, HEADING_ALIGNMENT, IS_DESC_BOLD, IS_DESC_ITALIC, IS_DESC_UNDERLINE, DESC_ALIGNMENT, ASSET_ID, PROJECT_ID) VALUES ('%@', '%@', '%@', '%@', '%@', '%@', '%@', '%@', '%@', '%@', '%@', '%@', '%@', '%@', '%@', '%@', %d, %d)", currentTile.assetImagePath, currentTile.tileHeadingText, currentTile.tileDescription, [self hexadecimalValueOfAnNSColor:currentTile.tilePlateColor], currentTile.tileTransition, currentTile.tileLink, [self hexadecimalValueOfAnNSColor:currentTile.headingColor], [self hexadecimalValueOfAnNSColor:currentTile.descColor], currentTile.isHeadingBold ? @"YES" : @"NO", currentTile.isHeadingItalic ? @"YES" : @"NO", currentTile.isHeadingUnderline ? @"YES" : @"NO", currentTile.tileHeadingAlignment, currentTile.isDescBold ? @"YES" : @"NO", currentTile.isDescItalic ? @"YES" : @"NO", currentTile.isDescUnderline ? @"YES" : @"NO", currentTile.tileDescAlignment, currentTile.tileAssetId, currentTile.tileProjectId];*/
        
        ADTile* tile = [[ADTile alloc]init];
        tile.tileId = [prjResults intForColumn:@"TILE_ID"];
        tile.tileProjectId = [prjResults intForColumn:@"PROJECT_ID"];
        tile.tileAssetId = [prjResults intForColumn:@"ASSET_ID"];
        
        tile.artistId = [prjResults stringForColumn:@"ARTIST_ID"];
        tile.productId = [prjResults stringForColumn:@"PRODUCT_ID"];
        
        tile.nickName = [[prjResults stringForColumn:@"NICK_NAME"] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        tile.firstName = [[prjResults stringForColumn:@"FIRST_NAME"] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        tile.lastName = [[prjResults stringForColumn:@"LAST_NAME"] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        
        tile.tileHeadingText = [[prjResults stringForColumn:@"TILE_HEADING"] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        tile.tileDescription = [[prjResults stringForColumn:@"TILE_DESC"] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        
        tile.tileHeadingText = [tile.tileHeadingText stringByReplacingOccurrencesOfString:@"%27" withString:@"'"];
        tile.tileDescription = [tile.tileDescription stringByReplacingOccurrencesOfString:@"%27" withString:@"'"];
        
        tile.tileLink = [prjResults stringForColumn:@"TILE_LINK"];
        
        tile.fbLink = [prjResults stringForColumn:@"TILE_LINK"];
        tile.instaLink = [prjResults stringForColumn:@"INSTA_LINK"];
        tile.pinterestLink = [prjResults stringForColumn:@"PINTEREST_LINK"];
        tile.twLink = [prjResults stringForColumn:@"TWITTER_LINK"];
        
        tile.tileCategory = [[prjResults stringForColumn:@"CATEGORY"] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        
        tile.tileThumbnailName = [[prjResults stringForColumn:@"TILE_ICON"] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        tile.tileThumbnailImage = [NSImage imageNamed:tile.tileThumbnailName];
        
        tile.assetType = [prjResults stringForColumn:@"TILE_ASSET_TYPE"];
        tile.assetImageName = [prjResults stringForColumn:@"TILE_ASSET_IMAGE_NAME"];
        
        if(tile.assetType == nil)
            tile.assetType = @"product";
        
        tile.tilePlateColor = [NSColor colorFromHexadecimalValue:[prjResults stringForColumn:@"TILE_PLATE_COLOR"]];
        
        tile.tileTransition = [prjResults stringForColumn:@"TILE_TRANSITION"];
        
        tile.tileAudioTransition = [prjResults stringForColumn:@"TILE_AUDIO_TRANSITION"];
        
        tile.tileTransitionFrameCount = [prjResults stringForColumn:@"TRANSITION_FRAME_COUNT"];
        
        if(tile.tileTransition.length > 0 && tile.tileTransitionFrameCount == 0)
        {
            tile.tileTransitionFrameCount = [self getTileTransitionFrameCount:tile.tileProjectId name:tile.tileTransition];
        }
        
        NSString* transparency = [prjResults stringForColumn:@"TRANSPARENCY"];
        
        if(transparency != nil && transparency.length > 0)
            tile.transparency = [transparency floatValue];
        else
            tile.transparency = 0;
        
        tile.isHeadingBold = [[prjResults stringForColumn:@"IS_HEADING_BOLD"] boolValue];
        tile.isHeadingItalic = [[prjResults stringForColumn:@"IS_HEADING_ITALIC"] boolValue];
        tile.isHeadingUnderline = [[prjResults stringForColumn:@"IS_HEADING_UNDERLINE"] boolValue];
        tile.headingColor = [NSColor colorFromHexadecimalValue:[prjResults stringForColumn:@"TILE_HEADING_COLOR"]];
        tile.tileHeadingAlignment = [prjResults stringForColumn:@"HEADING_ALIGNMENT"];
        
        tile.isDescBold = [[prjResults stringForColumn:@"IS_DESC_BOLD"] boolValue];
        tile.isDescItalic = [[prjResults stringForColumn:@"IS_DESC_ITALIC"] boolValue];
        tile.isDescUnderline = [[prjResults stringForColumn:@"IS_DESC_UNDERLINE"] boolValue];
        tile.descColor = [NSColor colorFromHexadecimalValue:[prjResults stringForColumn:@"TILE_DESC_COLOR"]];
        tile.tileDescAlignment = [prjResults stringForColumn:@"DESC_ALIGNMENT"];
        
        tile.assetImagePath = [prjResults stringForColumn:@"TILE_IMAGE_PATH"];
        
        tile.isTileDefault = [[prjResults stringForColumn:@"IS_TILE_DEFAULT"] boolValue];
        
        tile.showTileInSidebox = [[prjResults stringForColumn:@"SHOW_TILE_IN_SIDEBAR"] boolValue];
        
        tile.useProfileAsIcon = [[prjResults stringForColumn:@"USE_PROFILE_AS_ICON"] boolValue];
        
        tile.x_pos = -1;
        tile.y_pos = -1;
        
        //Add tile to library
        [_ADTileLibrary addObject:tile];
        
        if (!_database.open) {
            [_database open];
        }
    }
    [prjResults close];
    //close database connection
    [_database close];
    
    [_libraryCollectionView reloadData];
}

-(NSString*)getTileTransitionFrameCount:(int)project_id name:(NSString*)name{
    
    int transitionFrameCount = 0;
    
    [_database open];
    //.. Preview current transition
    FMResultSet* assetResults = [self.database executeQuery:[NSString stringWithFormat:@"SELECT * FROM TRANSITIONS WHERE TRANSITION_PRJ_ID=%d AND TRANSITION_NAME='%@' COLLATE NOCASE", project_id, [self replaceSpacesInName:name]]];
    
    int transition_id = -1;
    while ([assetResults next]) {
        transition_id = [assetResults intForColumn:@"TRANSITION_ID"];
    }
    [assetResults close];
    if(transition_id != -1)
    {
        FMResultSet* transitionFiles = [self.database executeQuery:[NSString stringWithFormat:@"SELECT * FROM TRANSITIONFILES WHERE FILE_TRANSITION_ID=%d",transition_id]];
        
        while ([transitionFiles next]) {
            transitionFrameCount++;
        }
        
        [transitionFiles close];
    }
    
    //[_database close];
    
    return [NSString stringWithFormat:@"%d",transitionFrameCount];
}

- (IBAction)btnEmbedSelectedClick:(id)sender {
    //Show Embed View
    if(_binFiles.count > 0)
    {
        for (int i = 0; i < _binFiles.count; i++) {
            if([((Asset*)_binFiles[i]).assetType isEqualToString:@"picture"])
            {
                if(i==0)
                    _embedImageAssets = [NSMutableArray array];
                
                [_embedImageAssets addObject:_binFiles[i]];
            }
        }
        
        if(_embedImageAssets.count > 0)
        {
            _browseView.hidden = YES;
            _conformView.hidden = YES;
            _embedView.hidden = NO;
            [_embedImagesCollectionView reloadData];
            [self toggleButtonState:@"embed"];
            [self Save];
        }
        else
        {
            [self showAlert:@"No images found" message:@"Please add some images to the Bin to Embed."];
        }
    }
}

- (void)ConformAssetsAddedToBin {
    if(_binFiles.count > 0)
    {
        _browseView.hidden = YES;
        _conformView.hidden = NO;
        _embedView.hidden = YES;
        
        _conformVideoFiles = [[NSMutableArray alloc]init];
        _conformEDLFiles = [[NSMutableArray alloc]init];
        
        for (int i = 0; i < _binFiles.count; i++) {
            if([((Asset*)_binFiles[i]).assetType isEqualToString:@"video"])
            {
                [_conformVideoFiles addObject:_binFiles[i]];
            }
            else if([((Asset*)_binFiles[i]).assetType isEqualToString:@"edl"])
            {
                [_conformEDLFiles addObject:_binFiles[i]];
            }
            else if([((Asset*)_binFiles[i]).assetType isEqualToString:@"csv"])
            {
                [_conformEDLFiles addObject:_binFiles[i]];
            }
        }
        
        [_tblConformVideos reloadData];
        [_tblConformEDLs reloadData];
        
        [self.playerView.player pause];
        self.playerView.player = nil;
        
        _EDLs = [NSMutableArray array];
        [_tblEDLs reloadData];
        
        _timeFrames = [[NSMutableArray alloc] init];
        _images = [[NSMutableArray alloc] init];
        
        [_timelineCollection reloadData];
        //[_exportThumbsView reloadData];
        
        _btnExport.enabled = false;
        
        [self toggleButtonState:@"conform"];
        
        [self Save];
    }
}

- (IBAction)btnConformSelectedClick:(id)sender {
    [self ConformAssetsAddedToBin];
}

- (IBAction)btnAddFilesClick:(id)sender {
    NSStoryboard * sb = [NSStoryboard storyboardWithName: @"Main" bundle:nil];
    PopUpController* popController = [sb instantiateControllerWithIdentifier: @"PopUpController"];
    popController.importVideoDelegate = self;
    [self presentViewController:popController asPopoverRelativeToRect:[sender bounds] ofView:sender preferredEdge:NSRectEdgeMaxX behavior:NSPopoverBehaviorTransient];
}

- (IBAction)btnAssembleClicked:(id)sender {
    //[self readTimeCodeTrack];
    [self assemble];
}

- (void)LoadVideoAndFindFrames {
    NSString* webStringURL = [_selectedAssetToAssemble.assetFilePath stringByAddingPercentEncodingWithAllowedCharacters: NSCharacterSet.URLQueryAllowedCharacterSet];
//    NSString* webStringURL = [_selectedAssetToAssemble.assetFilePath stringbyadd:NSUTF8StringEncoding];

    if ([webStringURL hasPrefix:@"https://youtube.com"] || [webStringURL hasPrefix:@"https://www.youtube.com"]) {
        [self readFromURL:[NSURL URLWithString:webStringURL] showOnlyFirstThumb:true bIsShouldConfigFrame:true];
    }
    else {
        if(![webStringURL hasPrefix:@"file://"])
            webStringURL = [NSString stringWithFormat:@"file://%@",webStringURL];

        NSURL* _url = [self getURLfromBookmarkData:_selectedAssetToAssemble.assetBookmark];//[NSURL URLWithString: webStringURL];
        NSFileManager *fileManager = [NSFileManager defaultManager];

        NSString* pathString = [_selectedAssetToAssemble.assetFilePath copy];

        pathString = [pathString stringByReplacingOccurrencesOfString:@"file://" withString:@""];

        if ([fileManager fileExistsAtPath:_url.path]){
            [self readFromURL:_url showOnlyFirstThumb:true bIsShouldConfigFrame:true];
        }
        else
        {
            [self showAlert:@"File not found" message:[NSString stringWithFormat:@"Unable to locate the video %@", webStringURL]];
        }
    }
}

- (void)SelectVideoAtIndexAndConform:(int)index {
    @try {
        _selectedAssetToAssemble = _conformVideoFiles[index];
        
        NSLog(@"conform video:%@", _selectedAssetToAssemble.assetName);
        
        for (int i = 0; i < _conformVideoFiles.count; i++) {
            // Get row at specified index
            ItemSelectionCellView *selectedRow = [_tblConformVideos viewAtColumn:0 row:i makeIfNecessary:YES];
            if(i != index)
                [selectedRow ListItem].state = 0;
            else if([selectedRow ListItem].state == 0)
                [selectedRow ListItem].state = 1;
        }
        
        //Load Video
        //Generate 1st frame thumbnail
        [self LoadVideoAndFindFrames];
    } @catch (NSException *exception) {
        [self showAlert:@"Error loading video" message:exception.description];
    } @finally {
        //...
    }
}

- (IBAction)videoSelectedForConform:(id)sender {
    int index = ((NSButton*)sender).tag;
    conformVideoIndex = index;
    [self SelectVideoAtIndexAndConform:index];
}

- (void)ConformEDLAtIndex:(int)index {
    @try {
        if(_conformEDLFiles != nil && _conformEDLFiles.count > index){
            conformEDLIndex = index;
            NSLog(@"conform EDL:%@", ((Asset*)_conformEDLFiles[index]).assetName);
            for (int i = 0; i < _conformEDLFiles.count; i++) {
                // Get row at specified index
                ItemSelectionCellView *selectedRow = [_tblConformEDLs viewAtColumn:0 row:i makeIfNecessary:YES];
                if(i != index)
                    [selectedRow ListItem].state = 0;
                else if([selectedRow ListItem].state == 0)
                    [selectedRow ListItem].state = 1;
                
            }
            @try {
                //Load EDL
                if([((Asset*)_conformEDLFiles[index]).assetType isEqualToString:@"edl"])
                    [self loadEDL:_conformEDLFiles[index]];
                else
                    [self loadEDLfromCSV:((Asset*)_conformEDLFiles[index]).assetFilePath];
            } @catch (NSException *exception) {
                
                [self showAlert:@"Error loading CSV" message:exception.description];
                
            } @finally {
                //..
            }
        }
        else if(_savedEDLs.count > 0)
        {
            @try{
                _EDLs = [_savedEDLs mutableCopy];
                [_tblEDLs reloadData];
                
                //select first row
                [self selectEDLinTableAtIndex:0];
                
                //assemble frames
                [self assemble];
            } @catch (NSException *exception) {
                
                [self showAlert:@"Error assembling saved EDL" message:exception.description];
                
            } @finally {
                //..
            }
        }
    } @catch (NSException *exception) {
        
        [self showAlert:@"Error assembling EDL" message:exception.description];
        
    } @finally {
        //..
    }
    
    
}

- (IBAction)EDLSelectedForConform:(id)sender {
    int index = ((NSButton*)sender).tag;
    conformEDLIndex = index;
    [self ConformEDLAtIndex:index];
}

- (IBAction)btnAddPeopleClick:(id)sender {
    if(_btnEmbedPeopleBorder.isHidden)
        [self showProductSearch];
    else
        [self showArtistSearch];
}

-(void)searchBon2Profiles{
    
    self.searchUserWindowController = [[SearchUserWindowController alloc] initWithWindowNibName:@"SearchUserWindow"];
    
    self.searchUserWindowController.isForArtist = false;
    
    [[[NSApplication sharedApplication] mainWindow]beginSheet:self.searchUserWindowController.window  completionHandler:^(NSModalResponse returnCode) {
        NSLog(@"Sheet closed");
        
        switch (returnCode) {
            case NSModalResponseOK:
                NSLog(@"Done button tapped in Custom Sheet");
                break;
            case NSModalResponseCancel:
                NSLog(@"Cancel button tapped in Custom Sheet");
                break;
                
            default:
                break;
        }
        
        self.searchUserWindowController = nil;
    }];
}

- (IBAction)btnEmbedProductsClick:(id)sender {
    [self setButtonTitle:_btnEmbedPeople toString:@"People" withColor:[NSColor orangeColor] withSize:18];
    [self setButtonTitle:_btnEmbedProducts toString:@"PRODUCTS" withColor:[NSColor orangeColor] withSize:18];
    
    _btnEmbedProductsBorder.hidden = NO;
    _btnEmbedPeopleBorder.hidden = YES;
    _btnAddMorePeople.hidden = NO;
    [_embedImagesCollectionView reloadData];
}

- (IBAction)btnEmbedPeopleClick:(id)sender {
    [self setButtonTitle:_btnEmbedPeople toString:@"PEOPLE" withColor:[NSColor orangeColor] withSize:18];
    [self setButtonTitle:_btnEmbedProducts toString:@"Products" withColor:[NSColor orangeColor] withSize:18];
    _btnEmbedProductsBorder.hidden = YES;
    _btnEmbedPeopleBorder.hidden = NO;
    _btnAddMorePeople.hidden = NO;
    [_embedImagesCollectionView reloadData];
}

- (IBAction)btnPlateColorClick:(id)sender {
    [self setButtonTitle:_btnPlateColor toString:@"PLATE" withColor:[NSColor orangeColor] withSize:18];
    [self setButtonTitle:_btnTileTransition toString:@"Transition" withColor:[NSColor orangeColor] withSize:18];
    [self setButtonTitle:_btnTileText toString:@"Text" withColor:[NSColor orangeColor] withSize:18];
    [self setButtonTitle:_btnTileLink toString:@"Link" withColor:[NSColor orangeColor] withSize:18];
    
    _plateview.hidden = NO;
    _transitionView.hidden = YES;
    _tileTextView.hidden = YES;
    _tileLinkView.hidden = YES;
   
    _btnPlateColorBorder.hidden = NO;
    _btnTileTransitionBorder.hidden = YES;
    _btnTileTextBorder.hidden = YES;
    _btnTileLinkBorder.hidden = YES;
    
    //[self setButtonTitle:_btnSaveTile toString:@"SAVE" withColor:[NSColor whiteColor] withSize:18];

    [self stopAnimating];
}

- (IBAction)btnTileTransitionClick:(id)sender {
    [self setButtonTitle:_btnPlateColor toString:@"Plate" withColor:[NSColor orangeColor] withSize:18];
    [self setButtonTitle:_btnTileTransition toString:@"TRANSITION" withColor:[NSColor orangeColor] withSize:18];
    [self setButtonTitle:_btnTileText toString:@"Text" withColor:[NSColor orangeColor] withSize:18];
    [self setButtonTitle:_btnTileLink toString:@"Link" withColor:[NSColor orangeColor] withSize:18];
    
    _plateview.hidden = YES;
    _transitionView.hidden = NO;
    _tileTextView.hidden = YES;
    _tileLinkView.hidden = YES;
    
    _btnPlateColorBorder.hidden = YES;
    _btnTileTransitionBorder.hidden = NO;
    _btnTileTextBorder.hidden = YES;
    _btnTileLinkBorder.hidden = YES;
    
    //[self setButtonTitle:_btnSaveTile toString:@"ADD TRANSITION" withColor:[NSColor whiteColor] withSize:18];

    [self startAnimating];

}

- (IBAction)btnTileTextClick:(id)sender {
    [self setButtonTitle:_btnPlateColor toString:@"Plate" withColor:[NSColor orangeColor] withSize:18];
    [self setButtonTitle:_btnTileTransition toString:@"Transition" withColor:[NSColor orangeColor] withSize:18];
    [self setButtonTitle:_btnTileText toString:@"TEXT" withColor:[NSColor orangeColor] withSize:18];
    [self setButtonTitle:_btnTileLink toString:@"Link" withColor:[NSColor orangeColor] withSize:18];
    
    _plateview.hidden = YES;
    _transitionView.hidden = YES;
    _tileTextView.hidden = NO;
    _tileLinkView.hidden = YES;
    
    _btnPlateColorBorder.hidden = YES;
    _btnTileTransitionBorder.hidden = YES;
    _btnTileTextBorder.hidden = NO;
    _btnTileLinkBorder.hidden = YES;
    
    //[self setButtonTitle:_btnSaveTile toString:@"SAVE" withColor:[NSColor whiteColor] withSize:18];
    [self stopAnimating];

}

- (IBAction)btnTileLinkClick:(id)sender {
    [self setButtonTitle:_btnPlateColor toString:@"Plate" withColor:[NSColor orangeColor] withSize:18];
    [self setButtonTitle:_btnTileTransition toString:@"Transition" withColor:[NSColor orangeColor] withSize:18];
    [self setButtonTitle:_btnTileText toString:@"Text" withColor:[NSColor orangeColor] withSize:18];
    [self setButtonTitle:_btnTileLink toString:@"LINK" withColor:[NSColor orangeColor] withSize:18];
    
    _plateview.hidden = YES;
    _transitionView.hidden = YES;
    _tileTextView.hidden = YES;
    _tileLinkView.hidden = NO;
    
    _btnPlateColorBorder.hidden = YES;
    _btnTileTransitionBorder.hidden = YES;
    _btnTileTextBorder.hidden = YES;
    _btnTileLinkBorder.hidden = NO;
    
    //[self setButtonTitle:_btnSaveTile toString:@"SAVE" withColor:[NSColor whiteColor] withSize:18];

    [self stopAnimating];

}

- (IBAction)btnSaveTileClick:(id)sender {
    [self saveUpdateCurrentTile];
}

-(void)addNewImageTransition{
    
        //.. To do: Select Images and Create Transition
        if(!transitionUploadInProgress && !transitionSoundUploadInProgress)
            [self uploadNewTransition:@"png" allowMultiple:YES];
        else{
            NSAlert *alert = [[NSAlert alloc] init];
            [alert addButtonWithTitle:@"Wait"];
            [alert addButtonWithTitle:@"Cancel and Add New"];
            [alert setMessageText:@"Upload In Progress"];
            [alert setInformativeText:@"A transition upload is in progress. Wait until it completes or cancel and upload"];
            [alert setAlertStyle:NSWarningAlertStyle];
            
            NSModalResponse response = [alert runModal];
            
            if (response == NSAlertFirstButtonReturn) {
                // Continue clicked, wait
            }
            if(response == NSAlertSecondButtonReturn)
            {
                //Cancel and add new
                
                //Cancel all the requests
                [transitionUploadManager cancelAll];
                //Delete the transition from combobox
                [_currentSelectedProject.transitions removeLastObject];
                transitionUploadInProgress = false;
                
                [_transitionComboBox reloadData];
                if(_currentSelectedProject.transitions.count > 0){
                    [_transitionComboBox selectItemAtIndex:0];
                    
                        [_transitionComboBox setObjectValue:_currentSelectedProject.transitions[0]];
                        selectedImageTransitionIndex = 0;

                }
            }
            //[self showAlert:@"Busy" message:@"Please wait until the current transition is uploaded."];
        }
}

-(void)addNewSoundTransition{
    
    //.. To do: Select Images and Create Transition
    if(!transitionSoundUploadInProgress)
        [self uploadNewTransition:@"mp3" allowMultiple:NO];
    else{
        NSAlert *alert = [[NSAlert alloc] init];
        [alert addButtonWithTitle:@"Wait"];
        [alert addButtonWithTitle:@"Cancel and Add New"];
        [alert setMessageText:@"Upload In Progress"];
        [alert setInformativeText:@"A transition upload is in progress. Wait until it completes or cancel and upload"];
        [alert setAlertStyle:NSWarningAlertStyle];
        
        NSModalResponse response = [alert runModal];
        
        if (response == NSAlertFirstButtonReturn) {
            // Continue clicked, wait
        }
        if(response == NSAlertSecondButtonReturn)
        {
            //Cancel and add new
            
            //Cancel all the requests
            [transitionSoundUploadManager cancelAll];
            //Delete the transition from combobox
            [_currentSelectedProject.sounds removeLastObject];
            transitionSoundUploadInProgress = false;
            [_soundsComboBox reloadData];
            if(_currentSelectedProject.sounds.count > 0){
                [_soundsComboBox selectItemAtIndex:0];

                    [_soundsComboBox setObjectValue:_currentSelectedProject.sounds[0]];
                    selectedAudioTransitionIndex = 0;
            }
        }
        //[self showAlert:@"Busy" message:@"Please wait until the current transition is uploaded."];
    }
}

-(NSString*)getAWSURLForTransition:(NSString*)transition{
    //NSString *filename = [NSString stringWithFormat:@"%@",[[_currentAssetFileUrl path] lastPathComponent]];
    
    if(_username != nil && transition != nil && _username.length > 0 && transition.length > 0 && _currentSelectedProject != nil)
        return [NSString stringWithFormat:@"https://s3-us-west-1.amazonaws.com/com.bon2.userdatastore/%@/%@/%@/", [_username lowercaseString],_currentSelectedProject.projectName, transition];
    else
        return @"";
}

-(NSString*)getAWSURLForTransitionFile:(NSString*)transition transitionfile:(NSString*)transitionfile{
    //NSString *filename = [NSString stringWithFormat:@"%@",[[_currentAssetFileUrl path] lastPathComponent]];
    
    if(_username != nil && transition != nil && _username.length > 0 && transition.length > 0 && _currentSelectedProject != nil)
        return [NSString stringWithFormat:@"https://s3-us-west-1.amazonaws.com/com.bon2.userdatastore/%@/%@/%@/%@", [_username lowercaseString],_currentSelectedProject.projectName, transition, transitionfile];
    else
        return @"";
}

- (void)startConversion:(NSString*)startFramePath{
    
    NSString *inStr = startFramePath;//@"/Users/chaitanyavenneti/Downloads/badgirlpromo/Bad.Girl.Left.00000.png";
    
    NSString *outStr = [startFramePath stringByReplacingOccurrencesOfString:@"00000.png" withString:@"mvid"];
    
    
    NSString* fileName =[startFramePath lastPathComponent];
    fileName = [fileName stringByReplacingOccurrencesOfString:@"00000.png" withString:@"mvid"];
    
    NSString* tempDirPath = NSHomeDirectory();//NSTemporaryDirectory();
    
    tempDirPath = [tempDirPath stringByAppendingPathComponent:[NSString stringWithFormat:@"/%@/", _currentSelectedProject.projectName]];
    
    //Create directory for project in temp if not exists
    BOOL isDir = NO;
    [[NSFileManager defaultManager] fileExistsAtPath:tempDirPath isDirectory:&isDir];
    
    if(!isDir)
        [[NSFileManager defaultManager] createDirectoryAtPath:[NSHomeDirectory() stringByAppendingPathComponent:_currentSelectedProject.projectName]
                              withIntermediateDirectories:YES attributes:nil error:nil];
    
    if(tempDirPath != nil)
    {
        outStr = [tempDirPath stringByAppendingPathComponent:fileName];
    }
    
    
    [currentProjecMVIDPaths addObject:[outStr copy]];
    
    
    NSString *outAPNGStr = [[startFramePath lastPathComponent] stringByReplacingOccurrencesOfString:@"00000.png" withString:@"png"];
    
    //NSString *outAPNGStr = [startFramePath stringByReplacingOccurrencesOfString:@"00000.png" withString:@"png"];
    
    outAPNGStr = [tempDirPath stringByAppendingPathComponent:outAPNGStr];
    
    NSString *inAPNGStr = startFramePath;//[startFramePath stringByReplacingOccurrencesOfString:@"00000.png" withString:@"*.png"];//@"/Users/chaitanyavenneti/Downloads/badgirlpromo/Bad.Girl.Left.mvid";
    
    //inStr = [inStr stringByReplacingOccurrencesOfString:@"file:///" withString:@"/"];
    //outStr = [outStr stringByReplacingOccurrencesOfString:@"file:///" withString:@"/"];
    
    char *firstFilenameCstr =[inStr UTF8String];
    char *mvidFilenameCstr = [outStr cStringUsingEncoding:NSUTF8StringEncoding];;
    

    MovieOptions options;
    options.framerate = 0.0417f;
    //options.bpp = 32;
    options.keyframe = 1;
    options.deltas = 1;

    //Create MVID - Run in background
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        encodeMvidFromFramesMain(mvidFilenameCstr,
                                 firstFilenameCstr,
                                 &options);
        /*
        NSString *mvidPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"makemvid"];
        //Arguments
        NSArray *args = [NSArray arrayWithObjects:[NSString stringWithFormat:@"%@",inStr],[NSString stringWithFormat:@"%@",outStr], @"-fps", @"24", nil];
        
        NSTask* task  = [NSTask launchedTaskWithLaunchPath:mvidPath arguments:args];
        [task waitUntilExit];
        
        int status = [task terminationStatus];
        
        if (status == 0) {
            dispatch_async(dispatch_get_main_queue(),
                           ^{
                               //[self showAlert:@"Successs" message:@"APNG genearated"];
                               //[self uploadAPNG:outAPNGStr];
                           });
        } else {
            dispatch_async(dispatch_get_main_queue(),
                           ^{
                               [self showAlert:@"MVID Generation Failed" message:@"Failed to generate MVID"];
                           });
        }
         */
        
    });
    
    
    
    //Create APNG - Run in background
    NSString *execPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"apngasm_29"];
    //Arguments
    NSArray *args = [NSArray arrayWithObjects:[NSString stringWithFormat:@"%@",outAPNGStr],[NSString stringWithFormat:@"%@",inAPNGStr], @"-l1", nil];
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        NSTask* task  = [NSTask launchedTaskWithLaunchPath:execPath arguments:args];
        [task waitUntilExit];
        
        int status = [task terminationStatus];
        
        if (status == 0) {
            dispatch_async(dispatch_get_main_queue(),
                           ^{
                               //[self showAlert:@"Successs" message:@"APNG genearated"];
                               [self uploadAPNG:outAPNGStr];
                           });
        } else {
            dispatch_async(dispatch_get_main_queue(),
                           ^{
                               [self showAlert:@"APNG Failed" message:@"Failed to generate APNG"];
                           });
        }
    });
}

-(void)uploadAPNG:(NSString*)filePath{
    [self uploadTransitionAPNGImageToS3:[[NSURL alloc] initFileURLWithPath:filePath]];
}
/*
-(void)onLzmaSDKObjCWriter:(LzmaSDKObjCWriter *)writer writeProgress:(float)progress
{
    //...track progress
    if(progress >= 100)
    {
        [self showAlert:@"7Z" message:@"Completed"];
    }
}*/



-(void)create7z:(NSString*)path files:(NSString*)files{
    /*
    // Create writer
    LzmaSDKObjCWriter * writer = [[LzmaSDKObjCWriter alloc] initWithFileURL:[NSURL fileURLWithPath:path]];
    
    // Add file data's or paths
    //for (int i = 0; i < files.count; i++) {
    //  [writer addPath:files[i] forPath:files[i]]; // Add file at path
    //}
    //[writer addPath:@"/Path/somefile.txt" forPath:@"archiveDir/somefile.txt"]; // Add file at path
    //[writer addPath:@"/Path/SomeDirectory" forPath:@"SomeDirectory"]; // Recursively add directory with all contents
    
    [writer addPath:files forPath:files];
    
    // Setup writer
    writer.delegate = self; // Track progress
    //writer.passwordGetter = ^NSString*(void) { // Password getter
    //    return @"1234";
    //};
    
    // Optional settings
    writer.method = LzmaSDKObjCMethodLZMA2; // or LzmaSDKObjCMethodLZMA
    writer.solid = YES;
    writer.compressionLevel = 9;
    writer.encodeContent = YES;
    writer.encodeHeader = YES;
    writer.compressHeader = YES;
    writer.compressHeaderFull = YES;
    writer.writeModificationTime = NO;
    writer.writeCreationTime = NO;
    writer.writeAccessTime = NO;
    
    // Open archive file
    NSError * error = nil;
    [writer open:&error];
    
    // Write archive within current thread
    //[writer write];
    
    // or
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        [writer write];
    });
    */
}

- (void)ProcessTransitions:(NSString *)type urls:(NSArray *)urls skipConversion:(BOOL)skipConversion {
    if([type isEqualToString:@"png"])
    {
        transitionImageName = [((NSURL*)urls[0]) lastPathComponent];
        
        if(!skipConversion)
            [self startConversion:((NSURL*)urls[0]).path];
        
    }
    
    if([type isEqualToString:@"mp3"])
        transitionSoundName = [((NSURL*)urls[0]) lastPathComponent];
    
    NSString* transitionName = [((NSURL*)urls[0]) lastPathComponent];
    
    transitionName = [self replaceSpacesInName:transitionName];
    
    if(_currentSelectedProject != nil)
    {
        if([type isEqualToString:@"png"]){
            if(![_currentSelectedProject.transitions containsObject:transitionName])
            {
                //[self loadTransitionImages:urls];
                [self showTransitionPreview:urls];
            }
        }
        if([type isEqualToString:@"mp3"]){
            if(![_currentSelectedProject.sounds containsObject:transitionName])
            {
                //[self loadTransitionImages:urls];
                [self showTransitionSoundPreview:urls];
            }
        }
    }
    
    //REMOVE THIS - ADDED FOR TESTING
    //return;
    
    //check if the user's project has a folder by name fileName
    NSString* _tvideoUrl = [self getAWSURLForTransition:transitionName];
    
    NSMutableURLRequest *request;
    NSURLResponse *response = nil;
    NSError *error=nil;
    
    request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:_tvideoUrl]];
    [request setHTTPMethod:@"HEAD"];
    
    NSData *data=[[NSData alloc] initWithData:[NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error]];
    NSString* retVal = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    // you can use retVal , ignore if you don't need.
    NSInteger httpStatus = [((NSHTTPURLResponse *)response) statusCode];
    NSLog(@"responsecode:%d", httpStatus);
    // there will be various HTTP response code (status)
    // you might concern with 404
    
    if(httpStatus == 200)
    {
        //[self showAlert:@"Transition Exists" message:[NSString stringWithFormat:@"A transition named %@ already exists in this project.", transitionName]];
        
        //to do: Uncomment the checking and ask user if he wish to overwrite.
        if([type isEqualToString:@"png"])
            [self uploadTransitionImages:urls trName:transitionName]; //Remove this when the to do is implemented
        else
            [self uploadTransitionSounds:urls trName:transitionName];
    }
    else{
        //Upload transition images
        if([type isEqualToString:@"png"])
            [self uploadTransitionImages:urls trName:transitionName];
        else
            [self uploadTransitionSounds:urls trName:transitionName];
        
    }
}

-(void)uploadNewTransition:(NSString*)type allowMultiple:(BOOL)allowMultiple
{
    // Create the File Open Dialog class.
    NSOpenPanel* openDlg = [NSOpenPanel openPanel];
    
    // Enable the selection of files in the dialog.
    [openDlg setCanChooseFiles:YES];
    
    // Can't select a directory
    [openDlg setCanChooseDirectories:NO];
    
    
    // Let the user select any images supported by
    // the NSImage class.
    [openDlg setAllowsMultipleSelection:allowMultiple];
    [openDlg setAllowedFileTypes:[NSArray arrayWithObjects:type,nil]];
    
    
    // Display the dialog. If the OK button was pressed,
    // process the files.
    if ( [openDlg runModal] == NSModalResponseOK )
    {
        
        [self hideDialogView];
        
        // Get an array containing the full filenames of all
        // files and directories selected.
        NSArray* urls = [openDlg URLs];
        
        NSMutableArray* leftUrls = [NSMutableArray array];
        NSMutableArray* rightUrls = [NSMutableArray array];
        
        BOOL processMvid = true;
        //Get first file name
        if(urls.count > 0){
            NSString* urlString = [((NSURL*)urls[0]) absoluteString];
            
            if(urls.count == 1 && ![urlString localizedCaseInsensitiveContainsString:@".left."] && ![urlString localizedCaseInsensitiveContainsString:@".right."])
            {
                //...
                processMvid = false;
                [self ProcessTransitions:type urls:urls skipConversion:true];
            }
            else{
                for (int i = 0; i < urls.count; i++) {
                    NSString* urlString = [((NSURL*)urls[i]) absoluteString];
                    if([urlString localizedCaseInsensitiveContainsString:@".left."])
                       [leftUrls addObject:urls[i]];
                    else if([urlString localizedCaseInsensitiveContainsString:@".right."])
                        [rightUrls addObject:urls[i]];
                }
            }
        }
        if(processMvid){
            if(leftUrls.count == 0 && rightUrls.count == 0)
            {
                //transitionName = [((NSURL*)urls[0]) lastPathComponent];
                [self ProcessTransitions:type urls:urls skipConversion:false];
            }//end if left and write empty
            else{
                if(leftUrls.count > 0)
                {
                    [self ProcessTransitions:type urls:leftUrls skipConversion:false];
                }
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW,
                                             2* NSEC_PER_SEC),
                               dispatch_get_main_queue(),
                               ^{
                                    if(rightUrls.count > 0)
                                    {
                                        [self ProcessTransitions:type urls:rightUrls skipConversion:false];
                                    }
                               });
            }
        }
    }
}

NSString* transitionImageName;
NSMutableArray* transitionLocalUrls;
NSMutableArray* transitionLocalBookmarks;
NSMutableArray* transitionAWSUrls;

//NSData* transitionImageBookmark;

NSString* transitionSoundName;
NSString* transitionSoundLocalUrl;
NSString* transitionSoundAWSUrl;

NSData* transitionSoundBookmark;

-(void)uploadTransitionSounds:(NSArray*)urls trName:(NSString*)trName
{
    //transitionName = trName;
    transitionSoundLocalUrl = [urls[0] path];
    transitionSoundAWSUrl = [urls[0] path];
    
    
    transitionSoundBookmark = @"";//
    
    [self updateProjectAudioDetailsInDatabase];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW,
                                 1* NSEC_PER_SEC),
                   dispatch_get_main_queue(),
                   ^{
                       [self uploadTransitionSoundToS3:urls transitionName:trName];
                   });
}

-(void)uploadTransitionImages:(NSArray*)urls trName:(NSString*)trName
{
    //transitionName = trName;
    transitionLocalUrls = [urls mutableCopy];
    transitionAWSUrls = [urls mutableCopy];
    
    transitionLocalBookmarks = [NSMutableArray array];
    for (int i = 0; i < urls.count; i++) {
        NSError *error = nil;
        NSData* bookmark = [urls[i] bookmarkDataWithOptions:NSURLBookmarkCreationWithSecurityScope
                             includingResourceValuesForKeys:nil
                                              relativeToURL:nil // Make it app-scoped
                                                      error:&error];
        
        [transitionLocalBookmarks addObject:bookmark];
    }
    
    [self updateProjectDetailsInDatabase];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW,
                                 1* NSEC_PER_SEC),
                   dispatch_get_main_queue(),
                   ^{
                       [self uploadTransitionImagesToS3:urls transitionName:trName];
                   });
}

int totalTransitionImagesToUpload;

-(void)uploadTransitionImagesToS3:(NSArray*)urls transitionName:(NSString*)transitionName{
    //upload each image using operation block
    
    totalTransitionImagesToUpload = urls.count;
    
    if(totalTransitionImagesToUpload > 0)
    {
        [self showProgressAsync:@"Uploading Transition..."];
        transitionUploadInProgress = true;
        transitionAWSUrls = [NSMutableArray array];
        
        for (int i = 0; i < urls.count; i++) {
            [transitionAWSUrls addObject: [self getAWSURLForTransitionFile:transitionName transitionfile:[urls[i] lastPathComponent]]];
            
            [self uploadTransitionImageToS3:urls[i] transitionName:transitionName];
        }
    }
}

-(void)uploadTransitionSoundToS3:(NSArray*)urls transitionName:(NSString*)transitionName{
    //upload each image using operation block
    
    //totalTransitionImagesToUpload = urls.count;
    

        [self showProgressAsync:@"Uploading Transition..."];
        transitionSoundUploadInProgress = true;
        transitionSoundAWSUrl = @"";
        for (int i = 0; i < urls.count; i++) {
            transitionSoundAWSUrl = [self getAWSURLForTransitionFile:transitionName transitionfile:[urls[i] lastPathComponent]];
            
            NSData* bookmark = [urls[i] bookmarkDataWithOptions:NSURLBookmarkCreationWithSecurityScope
                                 includingResourceValuesForKeys:nil
                                                  relativeToURL:nil // Make it app-scoped
                                                          error:nil];
            
            [transitionLocalBookmarks addObject:bookmark];
            
            [self startTransitionSoundUpload:urls[i] transitionName:transitionName];
        }

}

-(void)startTransitionSoundUpload:(NSURL*)filePath transitionName:(NSString*)transitionName
{
    //ToDo: Show Progress
    
    [self registerAWSCredentialsForTransferManager];
    
    NSURL *_tileImgUrl = [[NSURL alloc] initFileURLWithPath:[filePath path]];
    
    //Create Upload Request Object
    AWSS3TransferManagerUploadRequest *thumbnailUploadRequest = [AWSS3TransferManagerUploadRequest new];
    thumbnailUploadRequest.bucket = @"com.bon2.userdatastore";
    thumbnailUploadRequest.key = [NSString stringWithFormat:@"%@/%@/%@", [_username lowercaseString], _currentSelectedProject.projectName, [filePath lastPathComponent]];
    thumbnailUploadRequest.body = _tileImgUrl;
    thumbnailUploadRequest.ACL = AWSS3ObjectCannedACLPublicRead;
    
    //Get Image Type (PNG/JPEG)
    NSString* extension = [_tileImgUrl pathExtension];
    if([extension isEqualToString:@"mp3"])
        thumbnailUploadRequest.contentType = @"audio/mpeg";
    
    
    transitionSoundUploadManager = [AWSS3TransferManager S3TransferManagerForKey:@"ncalifornia"];
    //Start Upload
    [[transitionSoundUploadManager upload:thumbnailUploadRequest] continueWithBlock:^id(AWSTask *task) {
        totalTransitionImagesToUpload--;
        if(task.error || task.cancelled)
        {
            NSLog(@"Upload Error: %@", _tileImgUrl);
        }
        else
        {
            NSLog(@"Upload Success: %@", _tileImgUrl);
        }
        
        if(!task.cancelled)
        {
            //ToDo: Hide Progress...
            transitionSoundUploadInProgress = false;
            
            if(!transitionUploadInProgress && !transitionSoundUploadInProgress)
                [self hideProgressAsync];
            
        }
        
        return task;
    }];
    
    //transitionUploadManager cancelAll
    
}

-(void)registerAWSCredentialsForTransferManager
{
    //Register AWS Credentials or Transfer
    
    /*AWSCognitoCredentialsProvider *credentialsProvider = [[AWSCognitoCredentialsProvider alloc]
                                                          initWithRegionType:AWSRegionUSEast1
                                                          identityPoolId:@"us-east-1:03036b3e-de1f-4f39-be0f-deaf60a7a7ac"];*/
    
    AWSStaticCredentialsProvider *credentialsProvider = [[AWSStaticCredentialsProvider alloc] initWithAccessKey:AWS_ACCESS_KEY secretKey:AWS_SECRET_KEY];
    
    AWSServiceConfiguration *configuration = [[AWSServiceConfiguration alloc] initWithRegion:AWSRegionUSWest1 credentialsProvider:credentialsProvider];
    
    [AWSS3TransferManager registerS3TransferManagerWithConfiguration:configuration forKey:@"ncalifornia"];
}

-(void)uploadTransitionAPNGImageToS3:(NSURL*)filePath
{
    //ToDo: Show Progress
    
    [self registerAWSCredentialsForTransferManager];
    
    NSURL *_tileImgUrl = filePath;//[[NSURL alloc] initFileURLWithPath:[filePath path]];
    
    //Create Upload Request Object
    AWSS3TransferManagerUploadRequest *thumbnailUploadRequest = [AWSS3TransferManagerUploadRequest new];
    thumbnailUploadRequest.bucket = @"com.bon2.userdatastore";
    thumbnailUploadRequest.key = [NSString stringWithFormat:@"%@/%@/%@", [_username lowercaseString], _currentSelectedProject.projectName, [filePath lastPathComponent]];
    thumbnailUploadRequest.body = _tileImgUrl;
    thumbnailUploadRequest.ACL = AWSS3ObjectCannedACLPublicRead;
    
    //Get Image Type (PNG/JPEG)
    NSString* extension = [_tileImgUrl pathExtension];
    if([extension isEqualToString:@"png"])
        thumbnailUploadRequest.contentType = @"image/png";
    
    
    transitionAPNGUploadManager = [AWSS3TransferManager S3TransferManagerForKey:@"ncalifornia"];
    
    //AWSKinesisRecorder *kinesisRecorder = [AWSKinesisRecorder defaultKinesisRecorder];
    
    //Start Upload
    [[transitionAPNGUploadManager upload:thumbnailUploadRequest] continueWithBlock:^id(AWSTask *task) {
        if(task.faulted || task.cancelled)
        {
            NSLog(@"Upload Error: %@", _tileImgUrl);
        }
        else
        {
            NSLog(@"Upload Success: %@", _tileImgUrl);
        }
        
        return task;
    }];
    
    //transitionUploadManager cancelAll
    
}

-(void)uploadTransitionImageToS3:(NSURL*)filePath transitionName:(NSString*)transitionName
{
    //ToDo: Show Progress
    
    [self registerAWSCredentialsForTransferManager];
    
    NSURL *_tileImgUrl = [[NSURL alloc] initFileURLWithPath:[filePath path]];
    
    //Create Upload Request Object
    AWSS3TransferManagerUploadRequest *thumbnailUploadRequest = [AWSS3TransferManagerUploadRequest new];
    thumbnailUploadRequest.bucket = @"com.bon2.userdatastore";
    thumbnailUploadRequest.key = [NSString stringWithFormat:@"%@/%@/%@", [_username lowercaseString], _currentSelectedProject.projectName, [filePath lastPathComponent]];
    thumbnailUploadRequest.body = _tileImgUrl;
    thumbnailUploadRequest.ACL = AWSS3ObjectCannedACLPublicRead;
    
    //Get Image Type (PNG/JPEG)
    NSString* extension = [_tileImgUrl pathExtension];
    if([extension isEqualToString:@"png"])
        thumbnailUploadRequest.contentType = @"image/png";
    
    
    transitionUploadManager = [AWSS3TransferManager S3TransferManagerForKey:@"ncalifornia"];
    
    //AWSKinesisRecorder *kinesisRecorder = [AWSKinesisRecorder defaultKinesisRecorder];
    
    //Start Upload
    [[transitionUploadManager upload:thumbnailUploadRequest] continueWithBlock:^id(AWSTask *task) {
        totalTransitionImagesToUpload--;
        if(task.faulted || task.cancelled)
        {
            NSLog(@"Upload Error: %@", _tileImgUrl);
        }
        else
        {
            NSLog(@"Upload Success: %@", _tileImgUrl);
        }
        
        if(!task.cancelled)
        {
            if(totalTransitionImagesToUpload == 0)
            {
                //ToDo: Hide Progress...
                transitionUploadInProgress = false;
                
                if(!transitionUploadInProgress && !transitionSoundUploadInProgress)
                    [self hideProgressAsync];
            }
        }
        
        return task;
    }];
    
    //transitionUploadManager cancelAll
    
}

-(void)showTransitionSoundPreview:(NSArray*)urls
{
    if(_currentSelectedProject.sounds == nil)
        _currentSelectedProject.sounds = [NSMutableArray array];
    
    [_currentSelectedProject.sounds addObject:[self replaceSpacesInName:transitionSoundName]];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [_soundsComboBox reloadData];
        
        [_soundsComboBox selectItemAtIndex:_currentSelectedProject.sounds.count-1];
        [_soundsComboBox setObjectValue:_currentSelectedProject.sounds[_currentSelectedProject.sounds.count-1]];
        selectedAudioTransitionIndex = _currentSelectedProject.sounds.count-1;
    });
}

-(void)showTransitionPreview:(NSArray*)urls
{
    [self loadTransitionImages:urls];
    
    [_currentSelectedProject.transitions addObject:[self replaceSpacesInName:transitionImageName]];
    dispatch_async(dispatch_get_main_queue(), ^{
        [_transitionComboBox reloadData];
        [_transitionComboBox selectItemAtIndex:_currentSelectedProject.transitions.count-1];
        [_transitionComboBox setObjectValue:_currentSelectedProject.transitions[_currentSelectedProject.transitions.count-1]];
        selectedImageTransitionIndex = _currentSelectedProject.transitions.count-1;
    });
}


-(void)deleteProductsAndPeople
{
    return;
    
    [_database open];
    NSString *deleteQuery = [NSString stringWithFormat:@"DELETE * FROM people"];
    
    [_database executeUpdate:deleteQuery];
    
    deleteQuery = [NSString stringWithFormat:@"DELETE * FROM products"];
    
    [_database executeUpdate:deleteQuery];
    [_database close];
}

-(void)deleteTransitions{
   
    return;
    
    //[_database open];
    NSString *deleteQuery = [NSString stringWithFormat:@"DELETE * FROM transitions"];
    
    BOOL status = [_database executeUpdate:deleteQuery];
    
    NSString *deleteFilesQuery = [NSString stringWithFormat:@"DELETE * FROM TRANSITIONFILES"];
    
    BOOL filesstatus = [_database executeUpdate:deleteFilesQuery];
    
   // [_database close];
}

-(void)updateProjectAudioDetailsInDatabase
{
    //insert in to database
    [_database open];
    
    
    //NSString *insertQuery = [NSString stringWithFormat:@"INSERT INTO transition_sounds (TRANSITION_NAME, TRANSITION_PRJ_ID, LOCAL_PATH, AWS_PATH) VALUES ('%@', %d, '%@', '%@')", [self replaceSpacesInName:transitionSoundName], _currentSelectedProject.projectId, transitionSoundLocalUrl, [self replaceSpaces:transitionSoundAWSUrl]];
    //NSString *insertQuery = [NSString stringWithFormat:@"INSERT INTO transition_sounds (TRANSITION_NAME, TRANSITION_PRJ_ID, LOCAL_PATH) VALUES ('%@', %d, '%@')", [self replaceSpacesInName:transitionSoundName], _currentSelectedProject.projectId, transitionSoundLocalUrl];
    
    BOOL result = [_database executeUpdate:@"INSERT INTO transition_sounds (TRANSITION_NAME, TRANSITION_PRJ_ID, LOCAL_PATH, LOCAL_BOOKMARK) VALUES (?, ?, ?, ?)", [self replaceSpacesInName:transitionSoundName], [NSNumber numberWithInt:_currentSelectedProject.projectId], transitionSoundLocalUrl, transitionSoundBookmark];
    //Get id from db
    //int transition_id = (int)[_database lastInsertRowId];
    //[_database close];
    
    //2. Insert in to assets table
    // [_database open];
    
    /*
    
    for (int i = 0; i < transitionLocalUrls.count; i++) {
        NSString* lUrl = [((NSURL*)transitionLocalUrls[i]) absoluteString];
        lUrl = [self replaceSpaces:lUrl];
        
        NSString *insertQuery = [NSString stringWithFormat:@"INSERT INTO TRANSITIONFILES (LOCAL_PATH, AWS_PATH, FILE_TRANSITION_ID) VALUES ('%@', '%@', %d)", lUrl , [self replaceSpaces:transitionAWSUrls[i]], transition_id];
        [_database executeUpdate:insertQuery];
    }
    */
    
    [_database close];
}

-(void)updateProjectDetailsInDatabase
{
    //insert in to database
    [_database open];
    
    NSString *insertQuery = [NSString stringWithFormat:@"INSERT INTO transitions (TRANSITION_NAME, TRANSITION_FRAME_COUNT, TRANSITION_PRJ_ID) VALUES ('%@', '%lu',%d)", [self replaceSpacesInName:transitionImageName], (unsigned long)transitionLocalUrls.count, _currentSelectedProject.projectId];
    [_database executeUpdate:insertQuery];
    //Get id from db
    int transition_id = (int)[_database lastInsertRowId];
    //[_database close];
    
    //2. Insert in to assets table
   // [_database open];
    

    
    for (int i = 0; i < transitionLocalUrls.count; i++) {
        NSString* lUrl = [((NSURL*)transitionLocalUrls[i]) absoluteString];
        lUrl = [self replaceSpaces:lUrl];
        
        NSData* transitionImageBookmark = (NSData*)transitionLocalBookmarks[i];
        //NSString *insertQuery = [NSString stringWithFormat:@"INSERT INTO TRANSITIONFILES (LOCAL_PATH, AWS_PATH, FILE_TRANSITION_ID) VALUES ('%@', '%@', %d)", lUrl , [self replaceSpaces:transitionAWSUrls[i]], transition_id];
        
        //NSString *insertQuery = [NSString stringWithFormat:@"INSERT INTO TRANSITIONFILES (LOCAL_PATH, FILE_TRANSITION_ID) VALUES ('%@', %d)", lUrl ,  transition_id];
        BOOL result = [_database executeUpdate:@"INSERT INTO TRANSITIONFILES (LOCAL_PATH, FILE_TRANSITION_ID, LOCAL_BOOKMARK) VALUES (?, ?, ?)", lUrl ,  [NSNumber numberWithInt:transition_id], transitionImageBookmark];
    }
    
    [_database close];
}

-(NSString*)replaceSpaces:(NSString*)url{
    NSString* name = [url copy];
    return [name stringByReplacingOccurrencesOfString:@" " withString:@"%20"];
}

-(NSString*)replaceSpacesInName:(NSString*)url{
    
    return url;
    
    NSString* name = [url copy];
    
    return [name stringByReplacingOccurrencesOfString:@" " withString:@"_"];
}

-(void)deleteAudioTransitionFromDB:(NSString*)transitionName{
    [_database open];
    //.. Preview current transition
    [self.database executeQuery:[NSString stringWithFormat:@"DELETE FROM transition_sounds WHERE TRANSITION_PRJ_ID=%d AND TRANSITION_NAME='%@' COLLATE NOCASE", _currentSelectedProject.projectId, [self replaceSpacesInName:transitionName]]];
    
    [_database close];
}

-(void)deleteTransitionFromDB:(NSString*)transitionName{
        [_database open];
        //.. Preview current transition
        FMResultSet* assetResults = [self.database executeQuery:[NSString stringWithFormat:@"SELECT * FROM TRANSITIONS WHERE TRANSITION_PRJ_ID=%d AND TRANSITION_NAME='%@' COLLATE NOCASE", _currentSelectedProject.projectId, [self replaceSpacesInName:transitionName]]];
        
        int transition_id = -1;
        while ([assetResults next]) {
            transition_id = [assetResults intForColumn:@"TRANSITION_ID"];
        }
        [assetResults close];
        
        [self.database executeUpdate:[NSString stringWithFormat:@"DELETE FROM TRANSITIONFILES WHERE FILE_TRANSITION_ID=%d",transition_id]];
        
        [self.database executeUpdate:[NSString stringWithFormat:@"DELETE FROM TRANSITIONS WHERE TRANSITION_ID=%d",transition_id]];
    
        [self.database commit];
    
        [_database close];
}

-(NSString*)getTransitionFilePath:(NSString*)transitionName{
    /*
    [_database open];
    //.. Preview current transition
    FMResultSet* assetResults = [self.database executeQuery:[NSString stringWithFormat:@"SELECT * FROM TRANSITIONS WHERE TRANSITION_PRJ_ID=%d AND TRANSITION_NAME='%@' COLLATE NOCASE", _currentSelectedProject.projectId, [self replaceSpacesInName:transitionName]]];
    
    int transition_id = -1;
    while ([assetResults next]) {
        transition_id = [assetResults intForColumn:@"TRANSITION_ID"];
    }
    [assetResults close];
    
    FMResultSet* transitionFileResults = [self.database executeQuery:[NSString stringWithFormat:@"SELECT * FROM TRANSITIONFILES WHERE FILE_TRANSITION_ID=%d",transition_id]];
    
    NSString* local_file_path = @"";
    
    while ([transitionFileResults next]) {
        local_file_path = [transitionFileResults stringForColumn:@"LOCAL_PATH"];
        break;
    }
    [transitionFileResults close];
    
    [_database close];
    
    
    local_file_path = [local_file_path stringByReplacingOccurrencesOfString:@"00000.png" withString:@"mvid"];*/
    
    NSString* local_file_path = @"";
    //NSString *outStr = @"";//[startFramePath stringByReplacingOccurrencesOfString:@"00000.png" withString:@"mvid"];
    
    
    NSString* fileName = transitionName;//[startFramePath lastPathComponent];
    fileName = [fileName stringByReplacingOccurrencesOfString:@"00000.png" withString:@"mvid"];
    
    NSString* tempDirPath = NSHomeDirectory();//NSTemporaryDirectory();
    
    tempDirPath = [tempDirPath stringByAppendingPathComponent:[NSString stringWithFormat:@"/%@/", _currentSelectedProject.projectName]];
    
    if(tempDirPath != nil)
    {
        local_file_path = [tempDirPath stringByAppendingPathComponent:fileName];
    }
    
    return local_file_path;
}

-(void)previewTransitionFromDB:(NSString*)transitionName{
    [_database open];
    //.. Preview current transition
    FMResultSet* assetResults = [self.database executeQuery:[NSString stringWithFormat:@"SELECT * FROM TRANSITIONS WHERE TRANSITION_PRJ_ID=%d AND TRANSITION_NAME='%@' COLLATE NOCASE", _currentSelectedProject.projectId, [self replaceSpacesInName:transitionName]]];
    
    int transition_id = -1;
    while ([assetResults next]) {
        transition_id = [assetResults intForColumn:@"TRANSITION_ID"];
    }
    [assetResults close];
    
    FMResultSet* transitionFileResults = [self.database executeQuery:[NSString stringWithFormat:@"SELECT * FROM TRANSITIONFILES WHERE FILE_TRANSITION_ID=%d",transition_id]];
    
    transitionLocalUrls = [NSMutableArray array];
    transitionLocalBookmarks = [NSMutableArray array];
    while ([transitionFileResults next]) {
        NSString* local_file_path = [transitionFileResults stringForColumn:@"LOCAL_PATH"];
        
        
        NSData* local_bookmark = [transitionFileResults dataForColumn:@"LOCAL_BOOKMARK"];
        //create and add local bookmark
        [transitionLocalBookmarks addObject:local_bookmark];
        if(local_bookmark != nil)
        {
            [transitionLocalUrls addObject:[self getURLfromBookmarkData:local_bookmark]];
        }
        else
        {
            [transitionLocalUrls addObject:local_file_path];
        }
    }
    [transitionFileResults close];
    
    [_database close];
    
    [self loadTransitionImages:transitionLocalUrls];
    
}

-(void)saveUpdateCurrentTile{
    if(isTileInEditMode)
    {
        if (currentEditingTileIndex == -1) {
            [self updateCurrentSelectedTile:currentEditingTile];
        }
        else {
            [self UpdateCurrentTile:currentEditingTile];
        }
    }
    else{
        [self SaveTileToLibrary];
    }
}

-(void)updateCurrentSelectedTile:(ADTile *)tile {
    //text, link, colors
    tile.tileHeadingText = _txtTileHeading.stringValue;
    tile.tileDescription = _txtTileDescription.stringValue;

    tile.tileLink = _txtTileLink.stringValue;
    tile.fbLink = _txtTileLink.stringValue;
    tile.instaLink = _txtInstaLink.stringValue;
    tile.pinterestLink = _txtPinterestLink.stringValue;
    tile.twLink = _txtTwitterLink.stringValue;
    tile.websiteLink = _txtWebsiteLink.stringValue;

    tile.headingColor = selectedTileTextColor;
    tile.descColor = selectedTileDescColor;
    //image
    //tile.assetImagePath = _selectedAssetForADTile.assetFilePath;
    //heading attribs
    tile.isHeadingBold = isTileTextBold;
    tile.isHeadingItalic = isTileTextItalic;
    tile.isHeadingUnderline = isTileTextUnderline;
    tile.tileHeadingAlignment = tileTextAlignment;
    //desc attribs
    tile.isDescBold = isTileDescBold;
    tile.isDescItalic = isTileDescItalic;
    tile.isDescUnderline = isTileDescUnderline;
    tile.tileDescAlignment = tileDescAlignment;
    //transition
    tile.tileTransition = [self getSelectedTransitionName];
    tile.tileTransitionFrameCount = [NSString stringWithFormat:@"%lu", (unsigned long)transitionLocalUrls.count];
    //audio transition
    tile.tileAudioTransition = [self getSelectedAudioTransitionName];

    //category
    tile.tileCategory = _tileCategoryComboBox.stringValue;

    tile.isTileDefault = _chkIsTileDefault.state == 1 ? YES : NO;
    tile.useProfileAsIcon = _chkUseProfilePicAsIcon.state == 1 ? YES : NO;

    tile.showTileInSidebox = _chkShowTileInSidebox.state == 1 ? YES : NO;

    //asset id
    //tile.tileAssetId = _selectedAssetForADTile.assetId;
    //project id
    //tile.tileProjectId = _selectedAssetForADTile.assetProjectId;
    //plate color
    tile.tilePlateColor = selectedTilePlateColor;
    tile.transparency = _tileTransparencySlider.floatValue;

    //tile thumbnail
    NSImage* tmpImg = _toolBtn.image;
    if(tmpImg != nil){
        tile.tileThumbnailImage = tmpImg;
    }

    //reset colors to default if nil
    if(tile.headingColor == nil)
        tile.headingColor = [NSColor blackColor];
    if(tile.descColor == nil)
        tile.descColor = [NSColor blackColor];
    if(tile.tilePlateColor == nil)
        tile.tilePlateColor = [NSColor lightGrayColor];

    isTileInEditMode = true;

    ///Show the tile details in side view
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [self showTileDetails:tile];
    });

    _ADTileView.layer.backgroundColor = [[NSColor whiteColor] CGColor];
    float alpha = 100 - tile.transparency;
    alpha = alpha/100;

    _ADTileView.layer.backgroundColor = [[tile.tilePlateColor colorWithAlphaComponent:alpha] CGColor];

    _ADTileView.fillColor = [tile.tilePlateColor colorWithAlphaComponent:alpha];
    [_ADTileView setNeedsDisplay:TRUE];

    _ADTileHeading.attributedStringValue = [self getAttributedHeadingForADTile:tile];
    _ADTileHeading.textColor = tile.headingColor;

    _ADTileDesc.attributedStringValue = [self getAttributedDescForADTile:tile];
    _ADTileDesc.textColor = tile.descColor;

    [[_ADTileDescView textStorage] setAttributedString:[self getAttributedDescForADTile:tile]];

    _ADTileDescView.textColor = tile.descColor;

    NSImage* profile_img = nil;
    if([tile.assetType isEqualToString:@"people"] || [tile.assetType isEqualToString:@"product"])
    {
        if([tile.assetType isEqualToString:@"product"] && tile.tileCategory != nil && [tile.tileCategory isNotEqualTo:@"No Category"])
        {
            profile_img = [NSImage imageNamed:[NSString stringWithFormat:@"%@.png",tile.tileCategory]];
        }
        else
            profile_img = [[NSImage alloc] initWithContentsOfURL:[NSURL URLWithString:tile.assetImagePath]];
    }
    else
        profile_img = [[NSImage alloc] initWithContentsOfFile:tile.assetImagePath];

    CGColorRef color = CGColorRetain([NSColor orangeColor].CGColor);
    [_ADTileImage.layer setBorderColor:color];

    [_ADTileImage setImage:profile_img];

    //enable/disable hyperlink button
    if(tile.websiteLink.length > 0)
        _ADTileURLBtn.enabled = true;
    else
        _ADTileURLBtn.enabled = false;

    if(tile.tileLink.length > 0)
        _ADTileFBBtn.enabled = true;
    else
        _ADTileFBBtn.enabled = false;

    if(tile.instaLink.length > 0)
        _ADTileInstaBtn.enabled = true;
    else
        _ADTileInstaBtn.enabled = false;

    if(tile.pinterestLink.length > 0)
        _ADTilePinterestBtn.enabled = true;
    else
        _ADTilePinterestBtn.enabled = false;

    if(tile.twLink.length > 0)
        _ADTileTwitterBtn.enabled = true;
    else
        _ADTileTwitterBtn.enabled = false;

    //play audio transition
    [self playAudioTransition:tile.tileAudioTransition];
}

-(void)UpdateCurrentTile:(ADTile*)tile
{
    //text, link, colors
    tile.tileHeadingText = _txtTileHeading.stringValue;
    tile.tileDescription = _txtTileDescription.stringValue;
    
    tile.tileLink = _txtTileLink.stringValue;
    tile.fbLink = _txtTileLink.stringValue;
    tile.instaLink = _txtInstaLink.stringValue;
    tile.pinterestLink = _txtPinterestLink.stringValue;
    tile.twLink = _txtTwitterLink.stringValue;
    tile.websiteLink = _txtWebsiteLink.stringValue;
    
    tile.headingColor = selectedTileTextColor;
    tile.descColor = selectedTileDescColor;
    //image
    //tile.assetImagePath = _selectedAssetForADTile.assetFilePath;
    //heading attribs
    tile.isHeadingBold = isTileTextBold;
    tile.isHeadingItalic = isTileTextItalic;
    tile.isHeadingUnderline = isTileTextUnderline;
    tile.tileHeadingAlignment = tileTextAlignment;
    //desc attribs
    tile.isDescBold = isTileDescBold;
    tile.isDescItalic = isTileDescItalic;
    tile.isDescUnderline = isTileDescUnderline;
    tile.tileDescAlignment = tileDescAlignment;
    //transition
    tile.tileTransition = [self getSelectedTransitionName];
    tile.tileTransitionFrameCount = [NSString stringWithFormat:@"%lu", (unsigned long)transitionLocalUrls.count];
    //audio transition
    tile.tileAudioTransition = [self getSelectedAudioTransitionName];
    
    //category
    tile.tileCategory = _tileCategoryComboBox.stringValue;
    
    tile.isTileDefault = _chkIsTileDefault.state == 1 ? YES : NO;
    tile.useProfileAsIcon = _chkUseProfilePicAsIcon.state == 1 ? YES : NO;
    
    tile.showTileInSidebox = _chkShowTileInSidebox.state == 1 ? YES : NO;
    
    //asset id
    //tile.tileAssetId = _selectedAssetForADTile.assetId;
    //project id
    //tile.tileProjectId = _selectedAssetForADTile.assetProjectId;
    //plate color
    tile.tilePlateColor = selectedTilePlateColor;
    tile.transparency = _tileTransparencySlider.floatValue;
    
    //tile thumbnail
    NSImage* tmpImg = _toolBtn.image;
    if(tmpImg != nil){
        tile.tileThumbnailImage = tmpImg;
    }
    
    //reset colors to default if nil
    if(tile.headingColor == nil)
        tile.headingColor = [NSColor blackColor];
    if(tile.descColor == nil)
        tile.descColor = [NSColor blackColor];
    if(tile.tilePlateColor == nil)
        tile.tilePlateColor = [NSColor lightGrayColor];
    
    [_database open];
    /*
    NSString *updateQuery = [NSString stringWithFormat:@"UPDATE library SET TILE_HEADING = ?, TILE_DESC = ?, TILE_PLATE_COLOR = ?, TILE_TRANSITION = ?, TILE_LINK = ?, TILE_HEADING_COLOR = ?, TILE_DESC_COLOR = ?, IS_HEADING_BOLD = ?, IS_HEADING_ITALIC = ?, IS_HEADING_UNDERLINE = ?, HEADING_ALIGNMENT = ?, IS_DESC_BOLD = ?, IS_DESC_ITALIC = ?, IS_DESC_UNDERLINE = ?, DESC_ALIGNMENT = ? WHERE ASSET_ID = ? AND PROJECT_ID = ?", currentTile.tileHeadingText, currentTile.tileDescription, [self hexadecimalValueOfAnNSColor:currentTile.tilePlateColor], currentTile.tileTransition, currentTile.tileLink, [self hexadecimalValueOfAnNSColor:currentTile.headingColor], [self hexadecimalValueOfAnNSColor:currentTile.descColor], currentTile.isHeadingBold ? @"YES" : @"NO", currentTile.isHeadingItalic ? @"YES" : @"NO", currentTile.isHeadingUnderline ? @"YES" : @"NO", currentTile.tileHeadingAlignment, currentTile.isDescBold ? @"YES" : @"NO", currentTile.isDescItalic ? @"YES" : @"NO", currentTile.isDescUnderline ? @"YES" : @"NO", currentTile.tileDescAlignment, currentTile.tileAssetId, currentTile.tileProjectId];*/
    
    NSString* plateColor = [tile.tilePlateColor hexadecimalValue];
    NSString* headingColor = [tile.headingColor hexadecimalValue];
    NSString* descColor = [tile.descColor hexadecimalValue];
    
    NSString* txtHeading = [tile.tileHeadingText stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSString* txtDesc = [tile.tileDescription stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    NSString* nickName = [tile.nickName stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    nickName = [nickName stringByReplacingOccurrencesOfString:@"'" withString:@"%27"];
    
    NSString* firstName = [tile.firstName stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    firstName = [firstName stringByReplacingOccurrencesOfString:@"'" withString:@"%27"];
    
    NSString* lastName = [tile.lastName stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    lastName = [lastName stringByReplacingOccurrencesOfString:@"'" withString:@"%27"];
    
    txtDesc = [txtDesc stringByReplacingOccurrencesOfString:@"'" withString:@"%27"];
    txtHeading = [txtHeading stringByReplacingOccurrencesOfString:@"'" withString:@"%27"];
    
    NSString* category = [tile.tileCategory stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    NSString* thumbnailIconName = [_toolBtn.image.name stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    NSString* updateQuery = [NSString stringWithFormat:@"UPDATE library SET CATEGORY = '%@',NICK_NAME = '%@', FIRST_NAME = '%@', LAST_NAME = '%@', USE_PROFILE_AS_ICON = '%@', SHOW_TILE_IN_SIDEBAR = '%@',IS_TILE_DEFAULT = '%@', TILE_ASSET_TYPE = '%@', TILE_ASSET_IMAGE_NAME = '%@', TILE_IMAGE_PATH = '%@', TILE_ICON = '%@', TILE_HEADING = '%@', TILE_DESC = '%@', TILE_PLATE_COLOR = '%@', TRANSPARENCY = '%f', TILE_TRANSITION = '%@', TILE_AUDIO_TRANSITION = '%@', TILE_LINK = '%@', TILE_HEADING_COLOR = '%@', TILE_DESC_COLOR = '%@', IS_HEADING_BOLD = '%@', IS_HEADING_ITALIC = '%@', IS_HEADING_UNDERLINE = '%@', HEADING_ALIGNMENT = '%@', IS_DESC_BOLD = '%@', IS_DESC_ITALIC = '%@', IS_DESC_UNDERLINE = '%@', DESC_ALIGNMENT = '%@' WHERE ASSET_ID = %d AND PROJECT_ID = %d",category, nickName, firstName, lastName, tile.useProfileAsIcon ? @"YES" : @"NO", tile.showTileInSidebox ? @"YES" : @"NO" ,tile.isTileDefault ? @"YES" : @"NO",  tile.assetType, tile.assetImageName, tile.assetImagePath, thumbnailIconName,txtHeading, txtDesc, plateColor, tile.transparency ,tile.tileTransition, tile.tileAudioTransition, tile.tileLink, headingColor, descColor, tile.isHeadingBold ? @"YES" : @"NO", tile.isHeadingItalic ? @"YES" : @"NO", tile.isHeadingUnderline ? @"YES" : @"NO", tile.tileHeadingAlignment, tile.isDescBold ? @"YES" : @"NO", tile.isDescItalic ? @"YES" : @"NO", tile.isDescUnderline ? @"YES" : @"NO", tile.tileDescAlignment, tile.tileAssetId, tile.tileProjectId];
    
    //NSLog(updateQuery);
    
    BOOL status = [_database executeUpdate:updateQuery];
    
    if (status) {
        NSLog(@"UPDATE LIBRARY OK");
        //[_database commit];
        //[_database close];
    }else {
        NSLog(@"FAIL");
    }
    
    [_database close];
    
    //Insert tile to library collection
    _ADTileLibrary[currentEditingTileIndex] = tile;
    
    isTileInEditMode = true;
    
    //Reload collection view
    //[_libraryCollectionView setNeedsDisplay:YES];
    //[_libraryCollectionView reloadData];
    
    NSIndexPath* _ip = [NSIndexPath indexPathForItem:currentEditingTileIndex inSection:0];
    NSArray<NSIndexPath*>* myset = [NSSet setWithObjects:_ip, nil];
    [_libraryCollectionView reloadItemsAtIndexPaths:myset];
    
    _btnApplyTile.enabled = true;
}

-(void)SaveTileToLibrary
{
    ADTile* currentTile = [[ADTile alloc] init];
    
    if(isTileInEditCTA == false)
    {
        if(_txtTileHeading.stringValue == nil || _txtTileHeading.stringValue.length <= 0)
        {
            [self showAlert:@"Incomplete Tile Details" message:@"Please enter heading"];
            return;
        }
    }
    else
    {
        currentTile.tileHeadingText = _selectedAssetForADTile.assetName;
        currentTile.tileDescription = @"";
        currentTile.tileLink = @"";
        currentTile.websiteLink = @"";
        currentTile.fbLink = @"";
        currentTile.instaLink = @"";
        currentTile.pinterestLink = @"";
        currentTile.twLink = @"";
    }
        
    if(_imgSelectedAssetImage.image == nil)//&& isTileInEditCTA == false)
    {
        [self showAlert:@"Incomplete Tile Details" message:@"Select a tile image"];
        return;
    }
    
    //text, link, colors
    if(isTileInEditCTA == false)
    {
        currentTile.tileHeadingText = _txtTileHeading.stringValue;
        currentTile.tileDescription = _txtTileDescription.stringValue;
        currentTile.tileLink = _txtTileLink.stringValue;
        currentTile.websiteLink = _txtWebsiteLink.stringValue;
        currentTile.fbLink = _txtTileLink.stringValue;
        currentTile.instaLink = _txtInstaLink.stringValue;
        currentTile.pinterestLink = _txtPinterestLink.stringValue;
        currentTile.twLink = _txtTwitterLink.stringValue;
    }
    currentTile.headingColor = selectedTileTextColor;
    currentTile.descColor = selectedTileDescColor;
    
    //image
    if(isTileInEditCTA)
    {
        currentTile.assetImagePath = _selectedAssetForADTile.assetFilePath;
        currentTile.assetImageName = _selectedAssetForADTile.assetName;
        currentTile.assetType = @"cta";
    }
    else{
        if([_tileCategoryComboBox.stringValue isEqualToString:@"No Category"])
        {
            currentTile.assetImagePath = _selectedAssetForADTile.assetFilePath;
            currentTile.assetImageName = _selectedAssetForADTile.assetName;
            currentTile.assetType = _selectedAssetForADTile.assetType;
        }
        else
        {
            currentTile.assetImagePath = @"";
            currentTile.assetImageName = _tileCategoryComboBox.stringValue;
            currentTile.assetType = @"product";
        }
    }
    
    //heading attribs
    currentTile.isHeadingBold = isTileTextBold;
    currentTile.isHeadingItalic = isTileTextItalic;
    currentTile.isHeadingUnderline = isTileTextUnderline;
    currentTile.tileHeadingAlignment = tileTextAlignment;
    
    //desc attribs
    currentTile.isDescBold = isTileDescBold;
    currentTile.isDescItalic = isTileDescItalic;
    currentTile.isDescUnderline = isTileDescUnderline;
    currentTile.tileDescAlignment = tileDescAlignment;
    
    currentTile.isTileDefault = _chkIsTileDefault.state == 1 ? YES : NO;
    
    currentTile.showTileInSidebox = _chkShowTileInSidebox.state == 1 ? YES : NO;
    
    currentTile.useProfileAsIcon = _chkUseProfilePicAsIcon.state == 1 ? YES : NO;
    
    //tile thumbnail
        if(isTileInEditCTA)
        {
            currentTile.tileThumbnailImage = [NSImage imageNamed:@"tap"];
        }
        else{
            currentTile.tileThumbnailImage = self.toolBtn.image;
        }
    
    //category
    currentTile.tileCategory = _tileCategoryComboBox.stringValue;
    
    //transition
    if(isTileInEditCTA)
    {
        currentTile.tileTransition = [NSString stringWithFormat:@"%d",_ctaDurationSlider.intValue];
        currentTile.tileTransitionFrameCount = @"-1";
    }
    else
    {
        currentTile.tileTransition = [self getSelectedTransitionName];
        currentTile.tileTransitionFrameCount = [NSString stringWithFormat:@"%lu", (unsigned long)transitionLocalUrls.count];
    }
    
    //audio transition
    currentTile.tileAudioTransition = [self getSelectedAudioTransitionName];
    
    //asset id
    currentTile.tileAssetId = _selectedAssetForADTile.assetId;
        
    currentTile.artistId = _selectedAssetForADTile.assetIdentifier;
    currentTile.productId = _selectedAssetForADTile.assetIdentifier;
    
    currentTile.nickName = _selectedAssetForADTile.nickName;
    
    currentTile.firstName = _selectedAssetForADTile.firstName;
    currentTile.lastName = _selectedAssetForADTile.lastName;
    
    //project id
    currentTile.tileProjectId = _currentSelectedProject.projectId;//_selectedAssetForADTile.assetProjectId;
    
    //plate color
    currentTile.tilePlateColor = selectedTilePlateColor;
    
    if(isTileInEditCTA == false)
        currentTile.transparency = _tileTransparencySlider.floatValue;
    else
        currentTile.transparency = _ctaDurationSlider.intValue;
    
    currentTile.x_pos = -1;
    currentTile.y_pos = -1;
    
    //reset colors to default if nil
    if(currentTile.headingColor == nil)
        currentTile.headingColor = [NSColor blackColor];
    if(currentTile.descColor == nil)
        currentTile.descColor = [NSColor blackColor];
    if(currentTile.tilePlateColor == nil)
        currentTile.tilePlateColor = [NSColor lightGrayColor];
    //To Do: Insert to database and get the tile id
    
    //NOTE: FOR EXISTING TILES THIS NEED TO BE UPDATE INSTEAD OF INSERT
    
    [_database open];
    
    NSString* plateColor = [currentTile.tilePlateColor hexadecimalValue];
    NSString* headingColor = [currentTile.headingColor hexadecimalValue];
    NSString* descColor = [currentTile.descColor hexadecimalValue];
    
    NSString* txtHeading = [currentTile.tileHeadingText stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSString* txtDesc = [currentTile.tileDescription stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        
    NSString* nickName = [currentTile.nickName stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    nickName = [nickName stringByReplacingOccurrencesOfString:@"'" withString:@"%27"];
        
    NSString* firstName = [currentTile.firstName stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    firstName = [firstName stringByReplacingOccurrencesOfString:@"'" withString:@"%27"];
    
    NSString* lastName = [currentTile.lastName stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    lastName = [lastName stringByReplacingOccurrencesOfString:@"'" withString:@"%27"];
        
    txtDesc = [txtDesc stringByReplacingOccurrencesOfString:@"'" withString:@"%27"];
    txtHeading = [txtHeading stringByReplacingOccurrencesOfString:@"'" withString:@"%27"];
    
    NSString* thumbnailIconName = [_toolBtn.image.name stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        
    if(isTileInEditCTA)
        thumbnailIconName = @"tap";
    
    NSString* category = [currentTile.tileCategory stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
        NSString *insertQuery = [NSString stringWithFormat:@"INSERT INTO library (CATEGORY, FIRST_NAME, LAST_NAME, NICK_NAME, TILE_ASSET_TYPE, USE_PROFILE_AS_ICON, SHOW_TILE_IN_SIDEBAR, IS_TILE_DEFAULT, TILE_ASSET_IMAGE_NAME, TILE_IMAGE_PATH, TILE_ICON, TILE_HEADING, TILE_DESC, TILE_PLATE_COLOR, TRANSPARENCY, TILE_TRANSITION, TILE_AUDIO_TRANSITION, TILE_LINK, INSTA_LINK, PINTEREST_LINK, TWITTER_LINK, TILE_HEADING_COLOR, TILE_DESC_COLOR, IS_HEADING_BOLD, IS_HEADING_ITALIC, IS_HEADING_UNDERLINE, HEADING_ALIGNMENT, IS_DESC_BOLD, IS_DESC_ITALIC, IS_DESC_UNDERLINE, DESC_ALIGNMENT, ASSET_ID, PROJECT_ID, ARTIST_ID, PRODUCT_ID) VALUES ('%@','%@', '%@','%@','%@','%@','%@','%@','%@','%@', '%@','%@' ,'%@', '%@','%f','%@','%@','%@', '%@', '%@', '%@', '%@', '%@', '%@', '%@', '%@', '%@', '%@', '%@', '%@', '%@', %d, %d, '%@', '%@')",category, firstName, lastName, nickName, currentTile.assetType, currentTile.useProfileAsIcon ? @"YES" : @"NO", currentTile.showTileInSidebox ? @"YES": @"NO", currentTile.isTileDefault ? @"YES" : @"NO", currentTile.assetImageName, currentTile.assetImagePath, thumbnailIconName, txtHeading, txtDesc, plateColor, currentTile.transparency, currentTile.tileTransition, currentTile.tileAudioTransition, currentTile.tileLink, currentTile.instaLink, currentTile.pinterestLink, currentTile.twLink, headingColor, descColor, currentTile.isHeadingBold ? @"YES" : @"NO", currentTile.isHeadingItalic ? @"YES" : @"NO", currentTile.isHeadingUnderline ? @"YES" : @"NO", currentTile.tileHeadingAlignment, currentTile.isDescBold ? @"YES" : @"NO", currentTile.isDescItalic ? @"YES" : @"NO", currentTile.isDescUnderline ? @"YES" : @"NO", currentTile.tileDescAlignment, currentTile.tileAssetId, currentTile.tileProjectId, currentTile.artistId, currentTile.productId];
    

    BOOL status = [_database executeUpdate:insertQuery];
    
    if (status) {
        NSLog(@"INSERT LIBRARY OK");
        //[_database commit];
        //[_database close];
    }else {
        NSError* lastError = [_database lastError];
        NSLog(@"INSERT LIBRARY FAILED:%@",lastError);
    }
    
    currentTile.tileId = (int)[_database lastInsertRowId];
    
    [_database close];
    
    //Insert tile to library collection
    [_ADTileLibrary addObject:currentTile];
    
    currentEditingTile = currentTile;
    isTileInEditMode = true;
    currentEditingTileIndex = _ADTileLibrary.count - 1;
    
    //Reload collection view
    [_libraryCollectionView setNeedsDisplay:YES];
    [_libraryCollectionView reloadData];
    
    _btnApplyTile.enabled = true;
    
}

- (IBAction)btnEditTileClick:(id)sender {
    
    NSArray<NSIndexPath*>* myset = [_libraryCollectionView selectionIndexPaths].allObjects;
    
    if(myset.count > 0)
    {
        if(isTileInEditMode && currentEditingTile == myset[0].item)
        {
            NSAlert *alert = [[NSAlert alloc] init];
            [alert addButtonWithTitle:@"Yes"];
            [alert addButtonWithTitle:@"No"];
            [alert addButtonWithTitle:@"Cancel"];
            [alert setMessageText:@"Save Changes?"];
            [alert setInformativeText:@"Do you want to save changes to the current Tile before loading a new one?"];
            [alert setAlertStyle:NSWarningAlertStyle];
            
            NSModalResponse response = [alert runModal];
            
            if (response == NSAlertFirstButtonReturn) {
                //yes
                [self saveUpdateCurrentTile];
            }
            else if(response == NSAlertSecondButtonReturn){
                //no
            }
            else{
                //cancel
                return;
            }
        }
        
        currentEditingTile = (ADTile*)_ADTileLibrary[myset[0].item];
        isTileInEditMode = true;
        currentEditingTileIndex = myset[0].item;
        
        [self btnPlateColorClick:nil];
        
        [self editSelectedTile];
    }
}

-(void)editSelectedTile{
    
    _btnDeleteTile.enabled = false;

    [_txtTileHeading setAttributedStringValue:[self getAttributedHeadingForADTile:currentEditingTile]];
    _txtTileHeading.textColor = currentEditingTile.headingColor;
    
    [_txtTileDescription setObjectValue:[self getAttributedDescForADTile:currentEditingTile]];
    _txtTileDescription.textColor = currentEditingTile.descColor;
    
    selectedImageTransitionIndex = -1;
    selectedAudioTransitionIndex = -1;
    //to do: select transition
    transitionLocalUrls = [NSMutableArray array];
    //to do: select audio
    
    isTileTextBold = currentEditingTile.isHeadingBold;
    isTileTextItalic = currentEditingTile.isHeadingItalic;
    isTileTextUnderline = currentEditingTile.isHeadingUnderline;
    tileTextAlignment = currentEditingTile.tileHeadingAlignment;
    selectedTileTextColor = currentEditingTile.headingColor;
    
    isTileDescBold = currentEditingTile.isDescBold;
    isTileDescItalic = currentEditingTile.isDescItalic;
    isTileDescUnderline = currentEditingTile.isDescUnderline;
    tileDescAlignment = currentEditingTile.tileDescAlignment;
    selectedTileDescColor = currentEditingTile.descColor;
    
    [_plateColorWell setColor:currentEditingTile.tilePlateColor];
    
    _chkIsTileDefault.state = currentEditingTile.isTileDefault ? 1 : 0;
    _chkShowTileInSidebox.state = currentEditingTile.showTileInSidebox ? 1 : 0;
    
    _chkUseProfilePicAsIcon.state = currentEditingTile.useProfileAsIcon ? 1 : 0;
     _chkUseProfilePicAsIcon.enabled = true;
    
    _tileCategoryComboBox.enabled = false;
    [_tileCategoryComboBox setObjectValue:@"No Category"];
    
    _toolBtn.enabled = true;
    _btnTileTransition.enabled = true;
    _btnTileLink.enabled =true;
    
    if([currentEditingTile.assetType isEqualToString:@"people"] || [currentEditingTile.assetType isEqualToString:@"product"]){
        if([currentEditingTile.assetType isEqualToString:@"product"] && currentEditingTile.tileCategory != nil && currentEditingTile.tileCategory.length > 0 && [currentEditingTile.tileCategory isNotEqualTo:@"No Category"]){
            NSString* imgName = [NSString stringWithFormat:@"%@.png",currentEditingTile.tileCategory];
            _imgSelectedAssetImage.image = [NSImage imageNamed:imgName];
            _chkUseProfilePicAsIcon.enabled = false;
            _chkUseProfilePicAsIcon.state = 0;
             _tileCategoryComboBox.enabled = true;
            _toolBtn.enabled = false;
            [_tileCategoryComboBox setObjectValue:currentEditingTile.tileCategory];
            _btnTileTransition.enabled = false;
            _btnTileLink.enabled =false;
        }
        else
        {
            _imgSelectedAssetImage.image = [[NSImage alloc] initWithContentsOfURL:[NSURL URLWithString:currentEditingTile.assetImagePath]];
        }
    }
    else
        _imgSelectedAssetImage.image = [[NSImage alloc] initWithContentsOfFile:currentEditingTile.assetImagePath];
    
    if([currentEditingTile.tileCategory isNotEqualTo:@"No Category"])
        [_tileCategoryComboBox setObjectValue:currentEditingTile.tileCategory];
    
    _txtTileLink.stringValue = currentEditingTile.tileLink == nil ? @"" : currentEditingTile.tileLink;
    _txtTileLink.stringValue = currentEditingTile.fbLink == nil ? @"" : currentEditingTile.fbLink;
    _txtInstaLink.stringValue = currentEditingTile.instaLink == nil ? @"" : currentEditingTile.instaLink;
    _txtPinterestLink.stringValue = currentEditingTile.pinterestLink == nil ? @"" : currentEditingTile.pinterestLink;
    _txtTwitterLink.stringValue = currentEditingTile.twLink == nil ? @"" : currentEditingTile.twLink;
    _txtWebsiteLink.stringValue = currentEditingTile.websiteLink == nil ? @"" : currentEditingTile.websiteLink;
    
    tileTransition = currentEditingTile.tileTransition;
    
    tileAudioTransition = currentEditingTile.tileAudioTransition;
    
    /*
    if([currentEditingTile.tileCategory isEqualToString:@""])
    {
        [_tileCategoryComboBox selectItemAtIndex:0];
        [_tileCategoryComboBox setObjectValue:@"No Category"];
    }
    else
    {
        [_tileCategoryComboBox setObjectValue:currentEditingTile.tileCategory];
    }*/
    
    _btnRadioZoom.state = 1;
    _btnRadioDissolve.state = 0;
    _btnRadioWipe.state = 0;
    
    if([tileTransition isEqualToString:@"Zoom"])
        _btnRadioZoom.state = 1;
    else if([tileTransition isEqualToString:@"Wipe"])
        _btnRadioWipe.state = 1;
    else
        _btnRadioDissolve.state = 1;
    
    [self UpdateButtonStatesToMatchTextAttributes:@"heading"];
    //[self UpdateButtonStatesToMatchTextAttributes:@"description"];
}

- (IBAction)btnApplyTileClick:(id)sender {
    //[self applyTileToEDL];
    if(_images.count > 0 && currentSceneIndex >= 0)
    {
        if(currentSceneIndex != 0 && ((ADTile*)_ADTileLibrary[_selectedLibraryItemIndex]).isTileDefault)
        {
            NSAlert *alert = [[NSAlert alloc] init];
            [alert addButtonWithTitle:@"Ok"];
            [alert setMessageText:@"Default Tile"];
            [alert setInformativeText:@"A default tile can be added only on the first edit/scene of the video."];
            [alert setAlertStyle:NSWarningAlertStyle];
            
            [alert runModal];
            
            return;
        }
        
        [_playerView.player pause];
        
        [self syncFrames:_playerView.player.currentTime];
        
        if(((EDL*)(_EDLs[currentSceneIndex])).tiles == nil)
            ((EDL*)(_EDLs[currentSceneIndex])).tiles = [NSMutableArray array];
        
        [((EDL*)(_EDLs[currentSceneIndex])).tiles addObject:[_ADTileLibrary[_selectedLibraryItemIndex] copy]];
        
        /*
        if(allSelectedEdits.count > 0)
        {
            for (int i = 0 ; i < allSelectedEdits.count; i++) {
                NSNumber *num = [allSelectedEdits objectAtIndex:i];
                int sceneIndex = num.integerValue;
                
                if(sceneIndex != currentSceneIndex)
                {
                    if(((EDL*)(_EDLs[sceneIndex])).tiles == nil)
                        ((EDL*)(_EDLs[sceneIndex])).tiles = [NSMutableArray array];
                
                    [((EDL*)(_EDLs[sceneIndex])).tiles addObject:[_ADTileLibrary[_selectedLibraryItemIndex] copy]];
                }
            }
        }
        */
        
        //int frameNumberInArray = currentFrameNumber - sceneStartFrame;
        
        
        //ANIMATION CODE TO BE UNCOMMENTED LATER
        /*
        int sceneStartFrame = [((EDL*)(_EDLs[currentSceneIndex])).reelName intValue];
        if(((EDL*)(_EDLs[currentSceneIndex])).frames == nil || ((EDL*)(_EDLs[currentSceneIndex])).frames.count == 0)
        {
            int capacity = currentVideoFrames.count - sceneStartFrame;
            if(currentSceneIndex+1 < _EDLs.count)
                capacity = [((EDL*)(_EDLs[currentSceneIndex+1])).reelName intValue] - [((EDL*)(_EDLs[currentSceneIndex])).reelName intValue];
            ((EDL*)(_EDLs[currentSceneIndex])).frames = [[NSMutableArray alloc] init];
            
            //Empty frames array
            for(int i=0; i < capacity; i++)
            {
                 Frame* currentFrame = [[Frame alloc] init];
                [((EDL*)(_EDLs[currentSceneIndex])).frames addObject:currentFrame];
            }
            
            //Create Frame and Tile Properties
            TileAnimationProperties* tileProperties = [[TileAnimationProperties alloc] init];
            Frame* currentFrame = [[Frame alloc] init];
            currentFrame.columns = [NSMutableArray array];
            [currentFrame.columns addObject:tileProperties];
            [((EDL*)(_EDLs[currentSceneIndex])).frames replaceObjectAtIndex:0 withObject:currentFrame];
            
        }
        else
        {
            if([((EDL*)(_EDLs[currentSceneIndex])).frames objectAtIndex:0] != nil)
            {
                TileAnimationProperties* tileProperties = [[TileAnimationProperties alloc] init];
                Frame* currentFrame = [((EDL*)(_EDLs[currentSceneIndex])).frames objectAtIndex:0];
                if(currentFrame.columns == nil || currentFrame.columns.count == 0)
                    currentFrame.columns = [NSMutableArray array];
                [currentFrame.columns addObject:tileProperties];
                [((EDL*)(_EDLs[currentSceneIndex])).frames replaceObjectAtIndex:0 withObject:currentFrame];
            }
            else
            {
                //...
            }
        }*/
        
        [self clearAllTileOnEditFrame];
        
        [self showADTilesForCurrentFrame];
        
        [self Save];
    }
    else
    {
        [self showAlert:@"Error" message:@"No frames found to complete the action. Select a frame and try again."];
    }
}

-(NSMutableArray*)getAnimationsForTile:(int)Index
{
    NSMutableArray* _animations = [NSMutableArray array];
    
    
    
    int sceneStartFrame = [((EDL*)(_EDLs[currentSceneIndex])).reelName intValue];
    int frameNumberInArray = currentFrameNumber - sceneStartFrame - 1;
        
    int nextSceneStartFrame = [[((NSDictionary*)[currentVideoFrames lastObject]) valueForKey:@"frame"] intValue];
    if(currentSceneIndex+1 < _EDLs.count){
        nextSceneStartFrame = [((EDL*)(_EDLs[currentSceneIndex+1])).reelName intValue];
        //nextSceneStartFrame++;
    }
    
    int frameLength = nextSceneStartFrame - sceneStartFrame;//to substiture
    
    if(frameNumberInArray < 0)
        frameNumberInArray = 0;
    
    Index = Index - 1;
    if(Index < 0)
        Index = 0;
    
    //Get the location at first frame of the scene
    CGRect previousFrameRect = CGRectMake(-1, -1, 0, 0);
    NSMutableDictionary* tileAnimation = [[NSMutableDictionary alloc] init];
    TileAnimationProperties* tileFromProerties = nil;
    
    Frame* fr = [((EDL*)(_EDLs[currentSceneIndex])).frames objectAtIndex:0];
    if(fr.columns != nil && Index < fr.columns.count)
    {
        tileFromProerties = [fr.columns objectAtIndex:Index];
        
        previousFrameRect.origin.x = tileFromProerties.x;
        previousFrameRect.origin.y = tileFromProerties.y;
        
        if(previousFrameRect.origin.x != -1 && previousFrameRect.origin.y != -1)
        {
            [tileAnimation setObject:tileFromProerties forKey:@"from_transform"];
            float beginTime = [[[currentVideoFrames objectAtIndex:sceneStartFrame] valueForKey:@"time"] floatValue];
            [tileAnimation setObject:[NSNumber numberWithFloat:beginTime] forKey:@"beginTime"];
        }
    }
    
    if(tileFromProerties != nil)
    {
        for (int frIndex = 0; frIndex < frameLength; frIndex++)
        {
            Frame* fr = [((EDL*)(_EDLs[currentSceneIndex])).frames objectAtIndex:frIndex];
            if(fr.columns != nil && Index < fr.columns.count)
            {
                //Get all stop points for the tile at index
                CGRect rect = CGRectMake(-1, -1, 0, 0);
                //Get this tiles's properties from each frame
                TileAnimationProperties* tileToProperties = [fr.columns objectAtIndex:Index];
                rect.origin.x = tileToProperties.x;
                rect.origin.y = tileToProperties.y;
                
                if(rect.origin.x != -1 && rect.origin.y != -1)
                {
                    //if there is a delta change in tile location
                    if(rect.origin.x != previousFrameRect.origin.x || rect.origin.y != previousFrameRect.origin.y)
                    {
                        [tileAnimation setObject:tileToProperties forKey:@"to_transform"];
                        float endTime = [[[currentVideoFrames objectAtIndex:frIndex] valueForKey:@"time"] floatValue];
                        [tileAnimation setValue:[NSNumber numberWithFloat:endTime] forKey:@"endTime"];
                        
                        [_animations addObject:[tileAnimation copy]]; //add to array as a copy
                        
                        //prep for identifying next change
                        tileFromProerties = [tileToProperties copy];
                        previousFrameRect.origin.x = tileFromProerties.x;
                        previousFrameRect.origin.y = tileFromProerties.y;
                        tileAnimation = [[NSMutableDictionary alloc] init];
                        [tileAnimation setObject:tileFromProerties forKey:@"from_transform"];
                        [tileAnimation setObject:[NSNumber numberWithFloat:endTime] forKey:@"beginTime"];
                        
                    }//end if
                }//end if
            }//end if
        }//end for
    }///end if

    return _animations;
}

-(CGRect)getTileLocationForCurrentFrameForTile:(int) index
{
    CGRect rect = CGRectMake(-1, -1, 0, 0);
    
    int sceneStartFrame = [((EDL*)(_EDLs[currentSceneIndex])).reelName intValue];
    int frameNumberInArray = currentFrameNumber - sceneStartFrame - 1;
    
    if(frameNumberInArray < 0)
        frameNumberInArray = 0;
    
    index = index - 1;
    if(index < 0)
        index = 0;
    
    Frame* fr = [((EDL*)(_EDLs[currentSceneIndex])).frames objectAtIndex:frameNumberInArray];
    if(fr.columns != nil && index < fr.columns.count)
    {
        TileAnimationProperties* tileProperties = [fr.columns objectAtIndex:index];
    
        rect.origin.x = tileProperties.x;
        rect.origin.y = tileProperties.y;
    }
    return rect;
}

-(void)updateTilePositionInFrames:(int)index x:(float)x y:(float)y{
    int sceneStartFrame = [((EDL*)(_EDLs[currentSceneIndex])).reelName intValue];
    int frameNumberInArray = currentFrameNumber - sceneStartFrame - 1;
    
    if(frameNumberInArray < 0)
        frameNumberInArray = 0;
    
    /*index = index - 1;*/
    if(index < 0)
        index = 0;
    
    
    if(frameNumberInArray < ((EDL*)(_EDLs[currentSceneIndex])).frames.count && [((EDL*)(_EDLs[currentSceneIndex])).frames objectAtIndex:frameNumberInArray] != nil)
    {
        TileAnimationProperties* tileProperties = [[TileAnimationProperties alloc] init];
        tileProperties.x = x;
        tileProperties.y = y;
        Frame* currentFrame = [((EDL*)(_EDLs[currentSceneIndex])).frames objectAtIndex:frameNumberInArray];
        if(currentFrame.columns == nil || currentFrame.columns.count == 0)
        {
            currentFrame.columns = [NSMutableArray array];
            [currentFrame.columns addObject:tileProperties];
        }
        else if(index < currentFrame.columns.count)
        {
            [currentFrame.columns replaceObjectAtIndex:index withObject:tileProperties];
        }
        else
        {
            [currentFrame.columns addObject:tileProperties];
        }
        
        [((EDL*)(_EDLs[currentSceneIndex])).frames replaceObjectAtIndex:frameNumberInArray withObject:currentFrame];
    }
    else
    {
        TileAnimationProperties* tileProperties = [[TileAnimationProperties alloc] init];
        tileProperties.x = x;
        tileProperties.y = y;
        Frame* currentFrame = [[Frame alloc] init];
        currentFrame.columns = [NSMutableArray array];
        [currentFrame.columns addObject:tileProperties];
        [((EDL*)(_EDLs[currentSceneIndex])).frames addObject:currentFrame];// atIndex:frameNumberInArray];
    }
}

- (void)ADTileThumbClicked:(NSImageView*)sender{
    
    ADTile* currentFrameTile;
    NSInteger tileTag = sender.tag;
    
    int tileIndex = tileTag - 1000;
    
    currentFrameTile = ((EDL*)(_EDLs[currentSceneIndex])).tiles[tileIndex-1];
    
    if([currentFrameTile.assetType isEqualToString:@"cta"])
        return;
    
    //NSInteger tileTag = sender.tag;
    
    //int tileIndex = tileTag - 1000;
    
    if(!_ADTileView.hidden && _ADTileImage.tag == tileIndex)
    {
        draggableItem = nil;
        
        CGRect _fr = _playerbox.frame;
        
        _fr.origin.x = _fr.origin.x + _fr.size.width/2;
        _fr.size.width = _fr.size.width/2;
        _fr.origin.y += 20;
        _fr.size.height -= 20;
        
        //[[_ADTileView animator] setFrame:_fr];
        
        [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
            context.duration = 2;
            //_ADTileView.frame =
        }
        completionHandler:^{
            _ADTileView.frame = CGRectMake(_fr.origin.x, _fr.origin.y, 0, 0);
            _ADTileView.hidden = true;
            [self pauseAudio];
        }];
        
        //[_playerView.player play];
        
        return;
    }
    
    [_playerView.player pause];
    
    
    //ADTile* currentFrameTile;
    //currentFrameTile = ((EDL*)(_EDLs[currentSceneIndex])).tiles[tileIndex-1];

    if(currentFrameTile != nil)
    {
        NSRect _s = _ADTileView.frame;
        
        NSString* previewDirection = @"left";
        
        //AVPlayerLayer *playerLayer = (AVPlayerLayer *)[_playerView layer];
        
        //AVPlayerLayer* playerLayer = [AVPlayerLayer playerLayerWithPlayer:_playerView.player];

        //_playerView.videoBounds
        
        NSRect _srcFr = _playerbox.frame;
        
        _s.size.height = _srcFr.size.height;
        _s.size.width = _srcFr.size.width/2;
        
        _s.origin.y = _srcFr.origin.y;
        
        if((draggableItem.frame.origin.x + draggableItem.frame.size.width/2) < _srcFr.size.width/2)
        {
            _s.origin.x = _srcFr.origin.x + _srcFr.size.width/2;
            //shadow offset -ve
            _ADTileView.layer.shadowOffset = NSMakeSize(-5, -5.0);
            
            NSRect _closeBtnFr = _btnCloseOpenTile.frame;
            _closeBtnFr.origin.x = 0;
            _btnCloseOpenTile.frame = _closeBtnFr;
            
        }
        else
        {
            _s.origin.x = _srcFr.origin.x;
            //shadow offset +ve
            _ADTileView.layer.shadowOffset = NSMakeSize(5, -5.0);
            
            NSRect _closeBtnFr = _btnCloseOpenTile.frame;
            _closeBtnFr.origin.x = _s.size.width - 25;
            _btnCloseOpenTile.frame = _closeBtnFr;
            
            previewDirection = @"right";
        }

        selectedTileTransDirection = previewDirection;
        
        _ADTileView.frame = _s;
        
        _ADTileImage.tag = tileIndex;
        
        _ADTileView.layer.backgroundColor = [[NSColor whiteColor] CGColor];
        float alpha = 100 - currentFrameTile.transparency;
        alpha = alpha/100;
        
    
        _ADTileView.layer.backgroundColor = [[currentFrameTile.tilePlateColor colorWithAlphaComponent:alpha] CGColor];
        //_ADTileView.layer.opacity = 100-currentFrameTile.transparency;
        
        //add border
        //_ADTileView.layer.borderWidth = 1;
        //_ADTileView.layer.borderColor =  [[NSColor cyanColor] CGColor];
        //shadow
        //_ADTileView.layer.shadowColor =  [[NSColor cyanColor] CGColor];
        //_ADTileView.layer.shadowOpacity = 0.5;
        
        _ADTileView.fillColor = [currentFrameTile.tilePlateColor colorWithAlphaComponent:alpha];
        [_ADTileView setNeedsDisplay:TRUE];
        
        _ADTileHeading.attributedStringValue = [self getAttributedHeadingForADTile:currentFrameTile];
        _ADTileHeading.textColor = currentFrameTile.headingColor;
        
        _ADTileDesc.attributedStringValue = [self getAttributedDescForADTile:currentFrameTile];
        _ADTileDesc.textColor = currentFrameTile.descColor;
        
        [[_ADTileDescView textStorage] setAttributedString:[self getAttributedDescForADTile:currentFrameTile]];
        
        _ADTileDescView.textColor = currentFrameTile.descColor;
        
        //Set description field to fill the gap between the heading and buttons
        NSRect _scrFr = _ADTileDescScrollView.frame;
        _scrFr.size.height = _ADTileHeading.frame.origin.y - _ADTileHeading.frame.size.height  - _ADTileBtnsStackView.frame.origin.y - _ADTileBtnsStackView.frame.size.height;
        _scrFr.origin.y = _ADTileBtnsStackView.frame.origin.y + _ADTileBtnsStackView.frame.size.height + 10;
        _ADTileDescScrollView.frame = _scrFr;
        [_ADTileDescScrollView setDrawsBackground:NO];
        _ADTileDescScrollView.backgroundColor = [NSColor clearColor];
        _ADTileDescView.drawsBackground = YES;
        _ADTileDescView.backgroundColor = [NSColor clearColor];
        
        //_ADTileImage = [[KPCScaleToFillNSImageView alloc] init];
        
        NSImage* profile_img = nil;
        if([currentFrameTile.assetType isEqualToString:@"people"] || [currentFrameTile.assetType isEqualToString:@"product"])
        {
            if([currentFrameTile.assetType isEqualToString:@"product"] && currentFrameTile.tileCategory != nil && [currentFrameTile.tileCategory isNotEqualTo:@"No Category"])
            {
                profile_img = [NSImage imageNamed:[NSString stringWithFormat:@"%@.png",currentFrameTile.tileCategory]];//[NSImage imageNamed:currentFrameTile.assetImageName];
            }
            else
                profile_img = [[NSImage alloc] initWithContentsOfURL:[NSURL URLWithString:currentFrameTile.assetImagePath]];//[NSImage imageNamed:currentFrameTile.assetImageName];
        }
        else
            profile_img = [[NSImage alloc] initWithContentsOfFile:currentFrameTile.assetImagePath];

        CALayer *layer = [[CALayer alloc] init];
        _ADTileImage.layer = layer;
        _ADTileImage.layer.contentsGravity = kCAGravityResizeAspectFill;
        _ADTileImage.layer.contents = profile_img;
        _ADTileImage.wantsLayer = true;
        _ADTileImage.layer.borderWidth = 3.0;
        _ADTileImage.layer.cornerRadius = 8.0;
        _ADTileImage.layer.masksToBounds = YES;
        CGColorRef color = CGColorRetain([NSColor orangeColor].CGColor);
        [_ADTileImage.layer setBorderColor:color];
        
        [_ADTileImage setImage:profile_img];

        //enable/disable hyperlink button
        if(currentFrameTile.websiteLink.length > 0)
            _ADTileURLBtn.enabled = true;
        else
            _ADTileURLBtn.enabled = false;
        
        _ADTileURLBtn.tag = tileTag;
        
        
        if(currentFrameTile.tileLink.length > 0)
            _ADTileFBBtn.enabled = true;
        else
            _ADTileFBBtn.enabled = false;
        
        if(currentFrameTile.instaLink.length > 0)
            _ADTileInstaBtn.enabled = true;
        else
            _ADTileInstaBtn.enabled = false;
        
        if(currentFrameTile.pinterestLink.length > 0)
            _ADTilePinterestBtn.enabled = true;
        else
            _ADTilePinterestBtn.enabled = false;
        
        if(currentFrameTile.twLink.length > 0)
            _ADTileTwitterBtn.enabled = true;
        else
            _ADTileTwitterBtn.enabled = false;
        
        _ADTileFBBtn.tag = tileTag;
        _ADTileInstaBtn.tag = tileTag;
        _ADTilePinterestBtn.tag = tileTag;
        _ADTileTwitterBtn.tag = tileTag;
        
        _ADTileFBBtn.image = [NSImage imageNamed:@"fb-icon"];
        _ADTileInstaBtn.image = [NSImage imageNamed:@"instagram-icon"];
        _ADTilePinterestBtn.image = [NSImage imageNamed:@"pinterest-icon"];
        _ADTileTwitterBtn.image = [NSImage imageNamed:@"tw_icon"];
        //_ADTileURLBtn.image = [NSImage imageNamed:@"website"];
        
        if([currentFrameTile.assetType isEqualToString:@"product"])
        {
            _ADTileFBBtn.image = [NSImage imageNamed:@"website"];
            _ADTileInstaBtn.image = [NSImage imageNamed:@"website"];
            _ADTilePinterestBtn.image = [NSImage imageNamed:@"website"];
            _ADTileTwitterBtn.image = [NSImage imageNamed:@"website"];
            //_ADTileURLBtn.image = [NSImage imageNamed:@"website"];
        }
        
        NSRect _imgFr = _ADTileImage.frame;
        
        _imgFr.size.width = _ADTileView.frame.size.width/2 > 120 ? 120 : _ADTileView.frame.size.width/2;
        _imgFr.size.height = _ADTileView.frame.size.width/2 > 120 ? 120 : _ADTileView.frame.size.width/2;
        
        _ADTileImage.layer.cornerRadius = 10.0f;
        
        _imgFr.origin.x = _ADTileView.frame.size.width/2 - _imgFr.size.width/2;
        
        //Adjust image position based on title and description
        /*if(_ADTileDesc.attributedStringValue.length == 0 && _ADTileHeading.attributedStringValue.length == 0)
        {
            long fr_c = _ADTileView.frame.size.height/2;
            _imgFr.origin.y = fr_c - _imgFr.size.height/2;
        }*/
        
        //set y values to 10px from top
        _imgFr.origin.y = _ADTileView.frame.size.height -_imgFr.size.height - 10;
        
         _ADTileImage.frame = _imgFr;
        
        _ADTileImage.hidden = false;
        
        //POPSpringAnimation *basicAnimation = [POPSpringAnimation animation];
        //basicAnimation.property = [POPAnimatableProperty propertyWithName:kPOPViewFrame];
        /*
        CGRect _fr = _playerbox.frame;
        
        _fr.origin.x = _fr.origin.x + _fr.size.width/2;
        _fr.size.width = _fr.size.width/2;
        _fr.origin.y += 25;
        _fr.size.height -= 50;
        */
        _ADTileView.hidden = true;
        _ADTileView.hidden = false;
        
        
        //[[_ADTileView animator] setFrame:_fr];
        /*
        [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
            context.duration = 2;
            _ADTileView.frame = CGRectMake(_s.origin.x, _s.origin.y, 0, 0);
        }
        completionHandler:^{
            _ADTileView.frame = _s;
        }];
        */
        /*
        //basicAnimation.fromValue = [NSValue valueWithCGRect:CGRectMake(_fr.origin.x, _fr.origin.y, 0, 0)];
        basicAnimation.toValue=[NSValue valueWithCGRect:_fr];
        basicAnimation.name=@"SomeAnimationNameYouChoose";
        basicAnimation.delegate=self;
        _ADTileView.hidden = false;
        [_ADTileView pop_addAnimation:basicAnimation forKey:@"WhatEverNameYouWant"];*/
        
        
        
        ///Show the tile details in side view
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            [self showTileDetails:currentFrameTile];
        });
        
        //play tile transition
        [self playTransition:currentFrameTile.tileTransition direction:previewDirection];
        
        //play audio transition
        [self playAudioTransition:currentFrameTile.tileAudioTransition];

        currentSelectedADTile = currentFrameTile;
    }
    else
    {
        _ADTileView.hidden = true;
        _tileDetailsView.hidden = true;
        _selectedTileFramesSlider.enabled = false;
        [self pauseAudio];

        currentSelectedADTile = nil;
    }
    
    draggableItem = nil;
}

-(void)showTileDetails:(ADTile*)currentFrameTile
{
    _tileDetailsView.hidden = false;
    int currentEditFrameNumber = [((EDL*)(_EDLs[currentSceneIndex])).reelName intValue];
    int nextEditFrameNumber = [[((NSDictionary*)[currentVideoFrames lastObject]) valueForKey:@"frame"] intValue];
    if(currentSceneIndex+1 < _EDLs.count)
        nextEditFrameNumber = [((EDL*)(_EDLs[currentSceneIndex+1])).reelName intValue];
    
    _selectedTileFramesSlider.enabled = true;
    _selectedTileFramesSlider.minValue = currentEditFrameNumber;
    _selectedTileFramesSlider.maxValue = nextEditFrameNumber - 1;
    
    [_selectedTileFramesSlider setNumberOfTickMarks:nextEditFrameNumber - currentEditFrameNumber - 1];
    [_selectedTileFramesSlider setIntValue:currentFrameNumber];
    
    if([currentFrameTile.assetType isEqualToString:@"people"] || [currentFrameTile.assetType isEqualToString:@"product"])
        _selectedTileImage.image = [[NSImage alloc] initWithContentsOfURL:[NSURL URLWithString:currentFrameTile.assetImagePath]];
    else
        _selectedTileImage.image = [[NSImage alloc] initWithContentsOfFile:currentFrameTile.assetImagePath];
}

-(void)clearAllCTATiles
{
    NSMutableArray* _tagsArray = [NSMutableArray array];
    
    //Remove existing imageviews if any
    for (NSView *subview in _playerbox.subviews)
    {
        for (NSView *imgView in subview.subviews)
        {
            if([imgView.toolTip isEqualToString:@"cta"]){
                    [_tagsArray addObject:[NSNumber numberWithInteger:imgView.tag]];
            }
        }
    }
    
    for (NSNumber *num in _tagsArray) {
        NSInteger i = [num integerValue];
        [[_mainView viewWithTag:i] removeFromSuperview];
    }
}

-(void)clearAllTileOnEditFrame
{
    NSMutableArray* _tagsArray = [NSMutableArray array];
    
    //Remove existing imageviews if any
    for (NSView *subview in _playerbox.subviews)
    {
        for (NSView *imgView in subview.subviews)
        {
            if (imgView.tag > 1000 && ![imgView.toolTip isEqualToString:@"cta"]) {
                [_tagsArray addObject:[NSNumber numberWithInteger:imgView.tag]];
            }
            else if([imgView.toolTip isEqualToString:@"cta"]){
                if(_playerView.player.rate > 0)
                {
                        //...
                }
                else
                {
                   [_tagsArray addObject:[NSNumber numberWithInteger:imgView.tag]];
                }
            }
        }
    }
    
    for (NSNumber *num in _tagsArray) {
        NSInteger i = [num integerValue];
        [[_mainView viewWithTag:i] removeFromSuperview];
    }
    
    
    activeTileIndex = -1;
    _btnRemoveTileFromEdit.hidden = YES;
    
    if(!isCurrentEditInLoop)
        _tileDetailsView.hidden = true;
}


- (NSRect)calculatedItemBounds
{
    NSRect calculatedRect;
    
    // calculate the bounds of the draggable item
    // relative to the location
    calculatedRect.origin = CGPointMake(0.0f, 0.0f);
    
    // the example assumes that the width and height
    // are fixed values
    calculatedRect.size=_playerbox.frame.size;
    
    
    return calculatedRect;
}

// -----------------------------------
// Modify the item location
// -----------------------------------

- (void)offsetLocationByX:(float)x andY:(float)y
{
    // tell the display to redraw the old rect
    [self.mainView setNeedsDisplayInRect:[self calculatedItemBounds]];
    
    // since the offset can be generated by both mouse moves
    // and moveUp:, moveDown:, etc.. actions, we'll invert
    // the deltaY amount based on if the view is flipped or
    // not.
    int invertDeltaY = [self.mainView isFlipped] ? -1: 1;
    
    NSRect _fr = draggableItem.frame;
    
    _fr.origin.x = _fr.origin.x+x;
    _fr.origin.y = _fr.origin.y+y*invertDeltaY;
    
    NSRect bounds = [self calculatedItemBounds];
    bounds.size.height -= _fr.size.height;
    bounds.size.width -= _fr.size.width;
    
    if(NSPointInRect(_fr.origin, bounds))
    {
        draggableItem.frame = _fr;
        
        //save tile position in the original tile object
        int tileIndex = draggableItem.tag - 1000;
        
        
        ADTile* currentFrameTile = ((EDL*)(_EDLs[currentSceneIndex])).tiles[tileIndex-1];
        currentFrameTile.x_pos = _fr.origin.x;
        currentFrameTile.y_pos = _fr.origin.y;
        
        ((EDL*)(_EDLs[currentSceneIndex])).tiles[tileIndex-1] = currentFrameTile;
        
        //To do: Enable this while working on animations
        //[self updateTilePositionInFrames:tileIndex-1 x:_fr.origin.x y:_fr.origin.y];
        
        [self Save];
        
    }
    
    // invalidate the new rect location so that it'll
    // be redrawn
    [self.mainView setNeedsDisplayInRect:[self calculatedItemBounds]];
    
}

// -----------------------------------
// Hit test the item
// -----------------------------------

-(BOOL)isPointInItem:(NSPoint)testPoint{
    BOOL itemHit=NO;
    BOOL hitInBounds = NO;
    // test first if we're in the rough bounds
    hitInBounds = NSPointInRect(testPoint,[self calculatedItemBounds]);
    
    // yes, lets further refine the testing
    if (hitInBounds) {
        for (NSView *mainview in _playerbox.subviews) {
            for (NSView *subview in mainview.subviews) {
                if(subview.tag > 1000)
                {
                    if(NSPointInRect(testPoint, subview.frame))
                    {
                        draggableItem = subview;
                        itemHit = YES;
                        break;
                    }
                }
            }
        }
    }
    
    return itemHit;
}

// -----------------------------------
// Handle Mouse Events
// -----------------------------------


NSPoint startLocation;
NSPoint endLocation;
-(void)mouseDown:(NSEvent *)event
{
    NSPoint clickLocation;
    BOOL itemHit=NO;
    
    // convert the click location into the view coords
    clickLocation = [self.playerbox convertPoint:[event locationInWindow]
                              fromView:nil];
    
    
    
    // did the click occur in the item?
    itemHit = [self isPointInItem:clickLocation];
    
    // Yes it did, note that we're starting to drag
    if (itemHit) {
        
        // flag the instance variable that indicates
        // a drag was actually started
        dragging=YES;
        startLocation = clickLocation;
        endLocation = clickLocation;
        
        _btnRemoveTileFromEdit.hidden = YES;
        
        // store the starting click location;
        lastDragLocation=clickLocation;
        
        // set the cursor to the closed hand cursor
        // for the duration of the drag
        [[NSCursor closedHandCursor] push];
    }
}

int activeTileIndex = -1;
-(void)mouseUp:(NSEvent *)theEvent
{
    if(draggableItem == nil)
        return;
    
    dragging = NO;
    
    CGRect _delfr = _btnRemoveTileFromEdit.frame;
    _delfr.origin.x = _playerbox.frame.origin.x + draggableItem.frame.origin.x - 10;
    _delfr.origin.y = _playerbox.frame.origin.y + draggableItem.frame.origin.y + draggableItem.frame.size.height - 10;
    
    _btnRemoveTileFromEdit.frame = _delfr;
    _btnRemoveTileFromEdit.hidden = NO;
    
    activeTileIndex = draggableItem.tag - 1000;
    
    if(round(endLocation.x) == round(startLocation.x) && round(endLocation.y) == round(startLocation.y))
    {
        [self ADTileThumbClicked:draggableItem];
    }
    else
    {
        draggableItem = nil;
        //_btnRemoveTileFromEdit.hidden = YES;
    }
    
    // finished dragging, restore the cursor
    [NSCursor pop];
    
    // the item has moved, we need to reset our cursor
    // rectangle
    
    [[[NSApplication sharedApplication] mainWindow] invalidateCursorRectsForView:self.mainView];
}

-(void)mouseDragged:(NSEvent *)event
{
 
    if (dragging) {
        NSPoint newDragLocation=[self.playerbox convertPoint:[event locationInWindow]
                                          fromView:nil];
        
        endLocation = newDragLocation;
        // offset the pill by the change in mouse movement
        // in the event
        [self offsetLocationByX:(newDragLocation.x-lastDragLocation.x)
                           andY:(newDragLocation.y-lastDragLocation.y)];
        
        // save the new drag location for the next drag event
        lastDragLocation=newDragLocation;
        
        _ADTileView.hidden = YES;
        [self pauseAudio];
        
        // support automatic scrolling during a drag
        // by calling NSView's autoscroll: method
        //[self autoscroll:event];
    }
    
    
}

-(void)joinFrames{
    if(currentSceneIndex+1 < [_EDLs count]){
        [_EDLs removeObjectAtIndex:currentSceneIndex+1];
        
        [_tblEDLs reloadData];
        
        [_images removeObjectAtIndex:currentSceneIndex+1];
        [_timeFrames removeObjectAtIndex:currentSceneIndex+1];
        [_actualTimes removeObjectAtIndex:currentSceneIndex+1];
        [_timelineCollection reloadData];
        
        [self Save];
        
        //select newly added frame
        dispatch_async(dispatch_get_main_queue(), ^{
            [self selectFrameAtIndex:currentSceneIndex];
        });
    }
}

-(void)updateFrameCountDisplay:(BOOL)ignoreSlider{
    dispatch_async(dispatch_get_main_queue(), ^{
        _txtCurrentFrame.stringValue = [NSString stringWithFormat:@"Frame: %d", currentFrameNumber];
        
        int h = currentTimeSeconds / 3600;
        int m = (currentTimeSeconds / 60) % 60;
        int s = currentTimeSeconds % 60;
        
        int displayTimeCodeFrame = currentTimeCodeFrame;
        
        if(displayTimeCodeFrame == -1)
            displayTimeCodeFrame = 0;
        
        curreneTimeCodeString = [NSString stringWithFormat:@"%02d:%02d:%02d:%02d", h, m, s, displayTimeCodeFrame];
        
        _lblFrameTime.stringValue = curreneTimeCodeString;
        
        //update frames slider
        if(!ignoreSlider)
            [_selectedTileFramesSlider setIntValue:currentFrameNumber];
    });
}

-(void)goToNextFrame{
    //if([self.playerView.player.currentItem canStepForward])
    //{
    userSelection = true;
    if(currentFrameNumber + 1 < [currentVideoFrames count]){
        userSelection = true;
        //[self.playerView.player.currentItem stepByCount:1];
        NSDictionary* frDict = [currentVideoFrames objectAtIndex:currentFrameNumber+1];
        
        CMTime timeToAdd;
        NSValue *startValue = [frDict objectForKey:@"cmtime"];
        [startValue getValue:&timeToAdd];
        
        [_playerView.player.currentItem seekToTime:timeToAdd toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
        [self updateEDLSlider];
        [self showCurrentFrameNumber:timeToAdd];
        //[self updateFrameCountDisplay];
        [self syncFrames:timeToAdd];
        [self updateCurrentFrameTileLocations];
    }
    //}
}

-(void)goToPreviousFrame{
    //if([self.playerView.player.currentItem canStepBackward])
    //{
    userSelection = true;
    if(currentFrameNumber-1 > 0){
        
        //[self.playerView.player.currentItem stepByCount:-1];
        NSDictionary* frDict = [currentVideoFrames objectAtIndex:currentFrameNumber-1];
        
        CMTime timeToAdd;
        NSValue *startValue = [frDict objectForKey:@"cmtime"];
        [startValue getValue:&timeToAdd];
        
        [_playerView.player.currentItem seekToTime:timeToAdd toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
        [self updateEDLSlider];
        [self showCurrentFrameNumber:timeToAdd];
        //[self updateFrameCountDisplay];
        [self syncFrames:timeToAdd];
        [self updateCurrentFrameTileLocations];
    }
    //}
}

- (IBAction)btnPlayAudioTransitionClick:(id)sender {
    //if(transitionSoundLocalUrl == nil )
      //  return;
    
    if([_btnPlayAudioTransition.image.name isEqualToString:@"play-black"]){
        
        if(transitionSoundLocalUrl != nil){
            [self playAudio:transitionSoundLocalUrl];
            _btnPlayAudioTransition.image = [NSImage imageNamed:@"pause-black"];
            _imgAudioGif.animates = true;
        }
        else if(selectedAudioTransitionIndex >= 0){
            [self playAudioTransition:_currentSelectedProject.sounds[selectedAudioTransitionIndex]];
            _btnPlayAudioTransition.image = [NSImage imageNamed:@"pause-black"];
            _imgAudioGif.animates = true;
        }
    }
    else{
        _btnPlayAudioTransition.image = [NSImage imageNamed:@"play-black"];
        _imgAudioGif.animates = false;
        [self pauseAudio];
    }
}

-(void)splitFrame
{
    //EDL* currentEDl = (EDL*)(_EDLs[currentSceneIndex]);
    CMTime currentFrameTime  = _playerView.player.currentTime;
    
    /*float flSeconds = CMTimeGetSeconds(currentFrameTime);
    
    NSString* secondsStr = [NSString stringWithFormat:@"%f", flSeconds];
    
    NSArray *timeComponents = [secondsStr componentsSeparatedByString:@"."];
    
    NSString* totalSecs = timeComponents[0];
    NSString* milliSecs = timeComponents[1];
    
    int totalSecsInInt = [totalSecs intValue];
    
    int minutes = totalSecsInInt / 60;
    int seconds = totalSecsInInt % 60;
    
    int milliseconds = flSeconds*1000;
    milliseconds= milliseconds%1000;*/
    
    EDL* newEDL = [[EDL alloc] init];
    //if([currentEDl.destIn containsString:@"."])
    //{
        //int milliSecsInt = [milliSecs intValue];
   /* if(currentFPS == 0)
        currentFPS = [self getFrameRateFromAVPlayer];
    milliseconds = milliseconds*currentFPS;
    milliseconds = milliseconds/1000;*/
    newEDL.destIn = curreneTimeCodeString;//[NSString stringWithFormat:@"00:%d:%d:%02d",minutes, seconds, (int)round(milliseconds)];
    newEDL.time = currentFrameTime;
    newEDL.reelName = [NSString stringWithFormat:@"%d", currentFrameNumber];
    
    /*}
    else
    {
        int milliSecsInt = [milliSecs intValue];
        milliSecsInt = floor((milliSecsInt/1000)*currentFPS);
        newEDL.destIn = [NSString stringWithFormat:@"00:%d:%d:%d",minutes, seconds, milliSecsInt];
    }*/
    
    newEDL.sourceOut = newEDL.sourceIn = newEDL.destOut = newEDL.destIn;
    
    int prevFrameIndex = -1;
    if(currentSceneIndex > 0)
        prevFrameIndex = currentSceneIndex - 1;
    
    if((prevFrameIndex != -1) && (prevFrameIndex < [_EDLs count])){
        EDL* prevEDL = (EDL*)(_EDLs[prevFrameIndex]);
        newEDL.editNumber = @"-";
    //newEDL.reelName = prevEDL.reelName;
        newEDL.channel = prevEDL.channel;
        newEDL.operation = prevEDL.operation;
    }
    else
    {
        newEDL.editNumber = @"-";
        newEDL.channel = @"C";
        newEDL.operation = @"";
    }
    int newFrameindex = currentSceneIndex + 1;
    
    
    if([_EDLs count] > newFrameindex)
    {
        //newFrameindex = currentSceneIndex + 1;
        [_EDLs insertObject:newEDL atIndex:newFrameindex];
    }
    else
    {
        [_EDLs addObject:newEDL];
    }

    [_tblEDLs reloadData];
    //[self selectEDLinTableAtIndex:currentSceneIndex];
    
    [self generateThumbnailAtTimeCode:currentFrameTime index:newFrameindex];
    
    [self Save];
    
}

-(void)handleToolBox:(id)sender{
    if (_colorPanelPopover.isShown) {
        [_colorPanelPopover close];
        return;
    }
    [self.colorPanelPopover showRelativeToRect:self.toolBtn.bounds ofView:self.toolBtn preferredEdge:NSRectEdgeMinY];
}

-(NSPopover *)colorPanelPopover{
    if (!_colorPanelPopover) {
        _colorPanelPopover = [[NSPopover alloc]init];
        _colorPanelPopover.behavior = NSPopoverBehaviorSemitransient;
        //_colorPanelPopover.contentSize = NSMakeSize(480, 200);
        ColorPanelViewController *colorPanelVC = [[ColorPanelViewController alloc]initWithNibName:@"ColorPanelViewController" bundle:nil];
        colorPanelVC.imageSourceArray = [NSMutableArray array];
        //load icons
            [colorPanelVC.imageSourceArray addObject:@"set1-BDAdbobe Spark2"];
            [colorPanelVC.imageSourceArray addObject:@"set1-BDAdobe Spark 1"];
            [colorPanelVC.imageSourceArray addObject:@"set1-BDAdobe Spark"];
            [colorPanelVC.imageSourceArray addObject:@"set1-BDadobe Spark3"];
            [colorPanelVC.imageSourceArray addObject:@"set1-BDadobe Spark4"];
            [colorPanelVC.imageSourceArray addObject:@"set1-BDadobe Spark5"];
            [colorPanelVC.imageSourceArray addObject:@"set1-BDadobe Spark6"];
            [colorPanelVC.imageSourceArray addObject:@"set1-BDadobe Spark7"];
            [colorPanelVC.imageSourceArray addObject:@"set1-BDadobe Spark8"];
            [colorPanelVC.imageSourceArray addObject:@"set1-BDadobe Spark9"];
            [colorPanelVC.imageSourceArray addObject:@"set1-BDadobe Spark10"];
            [colorPanelVC.imageSourceArray addObject:@"set1-BDadobe Spark11"];
            [colorPanelVC.imageSourceArray addObject:@"set1-BDadobe Spark12"];
            [colorPanelVC.imageSourceArray addObject:@"set1-BDadobe Spark13"];
            [colorPanelVC.imageSourceArray addObject:@"set1-BDadobe Spark14"];
            [colorPanelVC.imageSourceArray addObject:@"set1-BDadobe Spark15"];
            [colorPanelVC.imageSourceArray addObject:@"set1-BDadobe Spark16"];
            [colorPanelVC.imageSourceArray addObject:@"set1-BDadobe Spark17"];
            [colorPanelVC.imageSourceArray addObject:@"set1-BDadobe Spark18"];
            [colorPanelVC.imageSourceArray addObject:@"set1-BDadobe Spark19"];
            [colorPanelVC.imageSourceArray addObject:@"set1-BDadobe Spark20"];
            [colorPanelVC.imageSourceArray addObject:@"set1-BDadobe Spark21"];
            [colorPanelVC.imageSourceArray addObject:@"set1-BDadobe Spark22"];
            [colorPanelVC.imageSourceArray addObject:@"set1-BDadobe Spark23"];
            [colorPanelVC.imageSourceArray addObject:@"set1-BDadobe Spark24"];
            [colorPanelVC.imageSourceArray addObject:@"set1-bullseyeblk"];
            [colorPanelVC.imageSourceArray addObject:@"set1-bullseyewte"];
            [colorPanelVC.imageSourceArray addObject:@"set2actor 1"];
            [colorPanelVC.imageSourceArray addObject:@"set2actor 2"];
            [colorPanelVC.imageSourceArray addObject:@"set2actor 3"];
            [colorPanelVC.imageSourceArray addObject:@"set2beverage"];
            [colorPanelVC.imageSourceArray addObject:@"set2bon2"];
            [colorPanelVC.imageSourceArray addObject:@"set2camera"];
            [colorPanelVC.imageSourceArray addObject:@"set2car"];
            [colorPanelVC.imageSourceArray addObject:@"set2cart"];
            [colorPanelVC.imageSourceArray addObject:@"set2cooking"];
            [colorPanelVC.imageSourceArray addObject:@"set2director"];
            [colorPanelVC.imageSourceArray addObject:@"set2facebook"];
            [colorPanelVC.imageSourceArray addObject:@"set2female dancer"];
            [colorPanelVC.imageSourceArray addObject:@"set2film strip 1"];
            [colorPanelVC.imageSourceArray addObject:@"set2film strip 2"];
            [colorPanelVC.imageSourceArray addObject:@"set2headphones"];
            [colorPanelVC.imageSourceArray addObject:@"set2instagram"];
            [colorPanelVC.imageSourceArray addObject:@"set2jewelry"];
            [colorPanelVC.imageSourceArray addObject:@"set2lingerie and bikini"];
            [colorPanelVC.imageSourceArray addObject:@"set2male dancer"];
            [colorPanelVC.imageSourceArray addObject:@"set2microphone 1"];
            [colorPanelVC.imageSourceArray addObject:@"set2microphone 2"];
            [colorPanelVC.imageSourceArray addObject:@"set2point left diag"];
            [colorPanelVC.imageSourceArray addObject:@"set2point left"];
            [colorPanelVC.imageSourceArray addObject:@"set2point right diag"];
            [colorPanelVC.imageSourceArray addObject:@"set2point right"];
            [colorPanelVC.imageSourceArray addObject:@"set2point up 1"];
            [colorPanelVC.imageSourceArray addObject:@"set2point up 2"];
            [colorPanelVC.imageSourceArray addObject:@"set2quotes"];
            [colorPanelVC.imageSourceArray addObject:@"set2shoes"];
            [colorPanelVC.imageSourceArray addObject:@"set2snapchat"];
            [colorPanelVC.imageSourceArray addObject:@"set2star 2"];
            [colorPanelVC.imageSourceArray addObject:@"set2star 3"];
            [colorPanelVC.imageSourceArray addObject:@"set2star 4"];
            [colorPanelVC.imageSourceArray addObject:@"set2star"];
            [colorPanelVC.imageSourceArray addObject:@"set2sunglasses"];
            [colorPanelVC.imageSourceArray addObject:@"set2tag"];
            [colorPanelVC.imageSourceArray addObject:@"set2talent 1"];
            [colorPanelVC.imageSourceArray addObject:@"set2talent 2"];
            [colorPanelVC.imageSourceArray addObject:@"set2tap"];
            [colorPanelVC.imageSourceArray addObject:@"set2top"];
            [colorPanelVC.imageSourceArray addObject:@"set2trousers"];
            [colorPanelVC.imageSourceArray addObject:@"set2twitter"];
            [colorPanelVC.imageSourceArray addObject:@"set2website"];
            [colorPanelVC.imageSourceArray addObject:@"set2womens shoes"];
            [colorPanelVC.imageSourceArray addObject:@"set2youtube"];
            [colorPanelVC.imageSourceArray addObject:@"Set3-015-microphone-2_Gold_Mic"];
            [colorPanelVC.imageSourceArray addObject:@"Set3-015-microphone-3"];
            [colorPanelVC.imageSourceArray addObject:@"Set3-015-microphone-4"];
            [colorPanelVC.imageSourceArray addObject:@"Set3-015-microphone-5"];
            [colorPanelVC.imageSourceArray addObject:@"Set3-015-microphone-6"];
            [colorPanelVC.imageSourceArray addObject:@"Set3-015-microphone-7"];
            [colorPanelVC.imageSourceArray addObject:@"Set3-015-microphone-8"];
            [colorPanelVC.imageSourceArray addObject:@"Set3-016-necklace-1"];
            [colorPanelVC.imageSourceArray addObject:@"Set3-016-necklace-2"];
            [colorPanelVC.imageSourceArray addObject:@"Set3-016-necklace-3"];
            [colorPanelVC.imageSourceArray addObject:@"Set3-016-necklace-4"];
            [colorPanelVC.imageSourceArray addObject:@"Set3-016-necklace-5"];
            [colorPanelVC.imageSourceArray addObject:@"Set3-016-necklace-6"];
            [colorPanelVC.imageSourceArray addObject:@"Set3-016-necklace-7"];
            [colorPanelVC.imageSourceArray addObject:@"Set3-017-headphones-1"];
            [colorPanelVC.imageSourceArray addObject:@"Set3-017-headphones-2"];
            [colorPanelVC.imageSourceArray addObject:@"Set3-017-headphones-3"];
            [colorPanelVC.imageSourceArray addObject:@"Set3-017-headphones-4"];
            [colorPanelVC.imageSourceArray addObject:@"Set3-017-headphones-5"];
            [colorPanelVC.imageSourceArray addObject:@"Set3-017-headphones-6"];
            [colorPanelVC.imageSourceArray addObject:@"Set3-017-headphones-8"];
            [colorPanelVC.imageSourceArray addObject:@"Set3-017-headphones-9"];
            [colorPanelVC.imageSourceArray addObject:@"Set3-017-headphones-10"];
            [colorPanelVC.imageSourceArray addObject:@"Set3-018-guitar-player-1"];
            [colorPanelVC.imageSourceArray addObject:@"Set3-018-guitar-player-2"];
            [colorPanelVC.imageSourceArray addObject:@"Set3-018-guitar-player-3"];
            [colorPanelVC.imageSourceArray addObject:@"Set3-018-guitar-player-4"];
            [colorPanelVC.imageSourceArray addObject:@"Set3-018-guitar-player-5"];
            [colorPanelVC.imageSourceArray addObject:@"Set3-018-guitar-player-6"];
            [colorPanelVC.imageSourceArray addObject:@"Set3-018-guitar-player-7"];
            [colorPanelVC.imageSourceArray addObject:@"Set3-018-guitar-player-8"];
            [colorPanelVC.imageSourceArray addObject:@"Set3-019-microphone-1"];
            [colorPanelVC.imageSourceArray addObject:@"Set3-019-microphone-2"];
            [colorPanelVC.imageSourceArray addObject:@"Set3-019-microphone-3"];
            [colorPanelVC.imageSourceArray addObject:@"Set3-019-microphone-4"];
            [colorPanelVC.imageSourceArray addObject:@"Set3-019-microphone-5"];
            [colorPanelVC.imageSourceArray addObject:@"Set3-019-microphone-6"];
            [colorPanelVC.imageSourceArray addObject:@"Set3-019-microphone-7"];
            [colorPanelVC.imageSourceArray addObject:@"Set3-019-microphone-8"];
            [colorPanelVC.imageSourceArray addObject:@"Set3-031-shape-1"];
            [colorPanelVC.imageSourceArray addObject:@"Set3-031-shape-2"];
            [colorPanelVC.imageSourceArray addObject:@"Set3-031-shape-3"];
            [colorPanelVC.imageSourceArray addObject:@"Set3-031-shape-4"];
            [colorPanelVC.imageSourceArray addObject:@"Set3-031-shape-5"];
            [colorPanelVC.imageSourceArray addObject:@"Set3-031-shape-6"];
            [colorPanelVC.imageSourceArray addObject:@"Set3-031-shape-7"];
            [colorPanelVC.imageSourceArray addObject:@"Set3-031-shape-8"];
            [colorPanelVC.imageSourceArray addObject:@"Set3-037-cinema-1"];
            [colorPanelVC.imageSourceArray addObject:@"Set3-037-cinema-2"];
            [colorPanelVC.imageSourceArray addObject:@"Set3-037-cinema-3"];
            [colorPanelVC.imageSourceArray addObject:@"Set3-037-cinema-4"];
            [colorPanelVC.imageSourceArray addObject:@"Set3-037-cinema-5"];
            [colorPanelVC.imageSourceArray addObject:@"Set3-037-cinema-6"];
            [colorPanelVC.imageSourceArray addObject:@"Set3-037-cinema-7"];
            [colorPanelVC.imageSourceArray addObject:@"Set3-037-cinema-8"];
            [colorPanelVC.imageSourceArray addObject:@"Set3-037-cinema-9"];
            [colorPanelVC.imageSourceArray addObject:@"Set3-037-cinema-10"];
            [colorPanelVC.imageSourceArray addObject:@"Set3-037-cinema-11"];
            [colorPanelVC.imageSourceArray addObject:@"Set3-037-cinema-12"];
            [colorPanelVC.imageSourceArray addObject:@"Set3-037-cinema-13"];
            [colorPanelVC.imageSourceArray addObject:@"Set3-037-cinema-14"];
            [colorPanelVC.imageSourceArray addObject:@"Set3-037-cinema-15"];
            [colorPanelVC.imageSourceArray addObject:@"Set3-037-cinema-16"];
            [colorPanelVC.imageSourceArray addObject:@"Set3-037-cinema-17"];
            [colorPanelVC.imageSourceArray addObject:@"Set4-015-microphone-2"];
            [colorPanelVC.imageSourceArray addObject:@"Set4-015-microphone-9"];
            [colorPanelVC.imageSourceArray addObject:@"Set4-015-microphone-10"];
            [colorPanelVC.imageSourceArray addObject:@"Set4-015-microphone-11"];
            [colorPanelVC.imageSourceArray addObject:@"Set4-015-microphone-12"];
            [colorPanelVC.imageSourceArray addObject:@"Set4-015-microphone-13"];
            [colorPanelVC.imageSourceArray addObject:@"Set4-015-microphone-14"];
            [colorPanelVC.imageSourceArray addObject:@"Set4-016-necklace-8"];
            [colorPanelVC.imageSourceArray addObject:@"Set4-016-necklace-9"];
            [colorPanelVC.imageSourceArray addObject:@"Set4-016-necklace-10"];
            [colorPanelVC.imageSourceArray addObject:@"Set4-016-necklace-11"];
            [colorPanelVC.imageSourceArray addObject:@"Set4-016-necklace-12"];
            [colorPanelVC.imageSourceArray addObject:@"Set4-016-necklace-13"];
            [colorPanelVC.imageSourceArray addObject:@"Set4-017-headphones-11"];
            [colorPanelVC.imageSourceArray addObject:@"Set4-017-headphones-12"];
            [colorPanelVC.imageSourceArray addObject:@"Set4-017-headphones-13"];
            [colorPanelVC.imageSourceArray addObject:@"Set4-017-headphones-14"];
            [colorPanelVC.imageSourceArray addObject:@"Set4-017-headphones-15"];
            [colorPanelVC.imageSourceArray addObject:@"Set4-017-headphones-16"];
            [colorPanelVC.imageSourceArray addObject:@"Set4-017-headphones-17"];
            [colorPanelVC.imageSourceArray addObject:@"Set4-017-headphones-18"];
            [colorPanelVC.imageSourceArray addObject:@"Set4-018-guitar-player-9"];
            [colorPanelVC.imageSourceArray addObject:@"Set4-018-guitar-player-10"];
            [colorPanelVC.imageSourceArray addObject:@"Set4-018-guitar-player-11"];
            [colorPanelVC.imageSourceArray addObject:@"Set4-018-guitar-player-12"];
            [colorPanelVC.imageSourceArray addObject:@"Set4-018-guitar-player-13"];
            [colorPanelVC.imageSourceArray addObject:@"Set4-018-guitar-player-14"];
            [colorPanelVC.imageSourceArray addObject:@"Set4-018-guitar-player-15"];
            [colorPanelVC.imageSourceArray addObject:@"Set4-019-microphone-9"];
            [colorPanelVC.imageSourceArray addObject:@"Set4-019-microphone-10"];
            [colorPanelVC.imageSourceArray addObject:@"Set4-019-microphone-11"];
            [colorPanelVC.imageSourceArray addObject:@"Set4-019-microphone-12"];
            [colorPanelVC.imageSourceArray addObject:@"Set4-019-microphone-13"];
            [colorPanelVC.imageSourceArray addObject:@"Set4-019-microphone-14"];
            [colorPanelVC.imageSourceArray addObject:@"Set4-019-microphone-15"];
            [colorPanelVC.imageSourceArray addObject:@"Set4-031-shape-9"];
            [colorPanelVC.imageSourceArray addObject:@"Set4-031-shape-10"];
            [colorPanelVC.imageSourceArray addObject:@"Set4-031-shape-11"];
            [colorPanelVC.imageSourceArray addObject:@"Set4-031-shape-12"];
            [colorPanelVC.imageSourceArray addObject:@"Set4-031-shape-13"];
            [colorPanelVC.imageSourceArray addObject:@"Set4-031-shape-14"];
            [colorPanelVC.imageSourceArray addObject:@"Set4-031-shape-15"];
            [colorPanelVC.imageSourceArray addObject:@"Set4-031-shape-16"];
            [colorPanelVC.imageSourceArray addObject:@"Set4-037-cinema-18"];
            [colorPanelVC.imageSourceArray addObject:@"Set4-037-cinema-19"];
            [colorPanelVC.imageSourceArray addObject:@"Set4-037-cinema-20"];
            [colorPanelVC.imageSourceArray addObject:@"Set4-037-cinema-21"];
            [colorPanelVC.imageSourceArray addObject:@"Set4-037-cinema-22"];
            [colorPanelVC.imageSourceArray addObject:@"Set4-037-cinema-23"];
            [colorPanelVC.imageSourceArray addObject:@"Set4-037-cinema-24"];
            [colorPanelVC.imageSourceArray addObject:@"Set4-037-cinema-25"];
            [colorPanelVC.imageSourceArray addObject:@"Set4-037-cinema-26"];
            [colorPanelVC.imageSourceArray addObject:@"Set4-037-cinema-27"];
            [colorPanelVC.imageSourceArray addObject:@"Set4-037-cinema-28"];
            [colorPanelVC.imageSourceArray addObject:@"Set4-037-cinema-29"];
            [colorPanelVC.imageSourceArray addObject:@"Set4-037-cinema-30"];
            [colorPanelVC.imageSourceArray addObject:@"Set4-037-cinema-31"];
            [colorPanelVC.imageSourceArray addObject:@"Set4-037-cinema-32"];
            [colorPanelVC.imageSourceArray addObject:@"Set4-037-cinema-33"];
            [colorPanelVC.imageSourceArray addObject:@"Set4-037-cinema-34"];
            [colorPanelVC.imageSourceArray addObject:@"set5-1"];
            [colorPanelVC.imageSourceArray addObject:@"set5-2"];
            [colorPanelVC.imageSourceArray addObject:@"set5-3"];
            [colorPanelVC.imageSourceArray addObject:@"set5-4"];
            [colorPanelVC.imageSourceArray addObject:@"set5-5"];
            [colorPanelVC.imageSourceArray addObject:@"set5-6"];
            [colorPanelVC.imageSourceArray addObject:@"set5-7"];
            [colorPanelVC.imageSourceArray addObject:@"set5-8"];
            [colorPanelVC.imageSourceArray addObject:@"set5-9"];
            [colorPanelVC.imageSourceArray addObject:@"set5-10"];
            [colorPanelVC.imageSourceArray addObject:@"set5-11"];
            [colorPanelVC.imageSourceArray addObject:@"set5-12"];
            [colorPanelVC.imageSourceArray addObject:@"set5-13"];
            [colorPanelVC.imageSourceArray addObject:@"set5-14"];
            [colorPanelVC.imageSourceArray addObject:@"set5-15"];
            [colorPanelVC.imageSourceArray addObject:@"set6-1"];
            [colorPanelVC.imageSourceArray addObject:@"set6-2"];
            [colorPanelVC.imageSourceArray addObject:@"set6-3"];
            [colorPanelVC.imageSourceArray addObject:@"set6-4"];
            [colorPanelVC.imageSourceArray addObject:@"set6-5"];
            [colorPanelVC.imageSourceArray addObject:@"set6-6"];
            [colorPanelVC.imageSourceArray addObject:@"set7-1"];
            [colorPanelVC.imageSourceArray addObject:@"set7-2"];
            [colorPanelVC.imageSourceArray addObject:@"set7-3"];
            [colorPanelVC.imageSourceArray addObject:@"set7-4"];
            [colorPanelVC.imageSourceArray addObject:@"set7-5"];
            [colorPanelVC.imageSourceArray addObject:@"set7-6"];
            [colorPanelVC.imageSourceArray addObject:@"set7-7"];
            [colorPanelVC.imageSourceArray addObject:@"set7-8"];
            [colorPanelVC.imageSourceArray addObject:@"set7-9"];
            [colorPanelVC.imageSourceArray addObject:@"set7-10"];
            [colorPanelVC.imageSourceArray addObject:@"set7-11"];
            [colorPanelVC.imageSourceArray addObject:@"set7-12"];
            [colorPanelVC.imageSourceArray addObject:@"set7-13"];
            [colorPanelVC.imageSourceArray addObject:@"set7-14"];
            [colorPanelVC.imageSourceArray addObject:@"set7-15"];
            [colorPanelVC.imageSourceArray addObject:@"set7-16"];
            [colorPanelVC.imageSourceArray addObject:@"set8-1"];
            [colorPanelVC.imageSourceArray addObject:@"set8-3"];
            [colorPanelVC.imageSourceArray addObject:@"set8-4"];
            [colorPanelVC.imageSourceArray addObject:@"set8-5"];
            [colorPanelVC.imageSourceArray addObject:@"set8-6"];
            [colorPanelVC.imageSourceArray addObject:@"set8-7"];
            [colorPanelVC.imageSourceArray addObject:@"set8-8"];
            [colorPanelVC.imageSourceArray addObject:@"set8-9"];
            [colorPanelVC.imageSourceArray addObject:@"set8-10"];
            [colorPanelVC.imageSourceArray addObject:@"set8-11"];
            [colorPanelVC.imageSourceArray addObject:@"set8-12"];
            [colorPanelVC.imageSourceArray addObject:@"set8-13"];
            [colorPanelVC.imageSourceArray addObject:@"set8-14"];
            [colorPanelVC.imageSourceArray addObject:@"set8-15"];
            [colorPanelVC.imageSourceArray addObject:@"set8-16"];
            [colorPanelVC.imageSourceArray addObject:@"set8-17"];
            [colorPanelVC.imageSourceArray addObject:@"set9-1"];
            [colorPanelVC.imageSourceArray addObject:@"set9-2"];
            [colorPanelVC.imageSourceArray addObject:@"set9-3"];
            [colorPanelVC.imageSourceArray addObject:@"set9-4"];
            [colorPanelVC.imageSourceArray addObject:@"set9-5"];
            [colorPanelVC.imageSourceArray addObject:@"set9-6"];
            [colorPanelVC.imageSourceArray addObject:@"set9-7"];
            [colorPanelVC.imageSourceArray addObject:@"set9-8"];
            [colorPanelVC.imageSourceArray addObject:@"set9-9"];
            [colorPanelVC.imageSourceArray addObject:@"set9-10"];
            [colorPanelVC.imageSourceArray addObject:@"set9-11"];
            [colorPanelVC.imageSourceArray addObject:@"set9-12"];
            [colorPanelVC.imageSourceArray addObject:@"set9-13"];
            [colorPanelVC.imageSourceArray addObject:@"set9-14"];
            [colorPanelVC.imageSourceArray addObject:@"set9-15"];
            
        [self loadNewIcons:colorPanelVC];
        
        colorPanelVC.delegate = self;
        _colorPanelPopover.contentViewController = colorPanelVC;
    }
    return _colorPanelPopover;
}

-(void)loadNewIcons:(ColorPanelViewController *)colorPanelVC{
    [colorPanelVC.imageSourceArray addObject:@"ICON100"];
    [colorPanelVC.imageSourceArray addObject:@"ICON101"];
    [colorPanelVC.imageSourceArray addObject:@"ICON102"];
    [colorPanelVC.imageSourceArray addObject:@"ICON103"];
    [colorPanelVC.imageSourceArray addObject:@"ICON104"];
    [colorPanelVC.imageSourceArray addObject:@"ICON105"];
    [colorPanelVC.imageSourceArray addObject:@"ICON106"];
    [colorPanelVC.imageSourceArray addObject:@"ICON107"];
    [colorPanelVC.imageSourceArray addObject:@"ICON108"];
    [colorPanelVC.imageSourceArray addObject:@"ICON109"];
    [colorPanelVC.imageSourceArray addObject:@"ICON110"];
    [colorPanelVC.imageSourceArray addObject:@"ICON111"];
    [colorPanelVC.imageSourceArray addObject:@"ICON112"];
    [colorPanelVC.imageSourceArray addObject:@"ICON113"];
    [colorPanelVC.imageSourceArray addObject:@"ICON114"];
    [colorPanelVC.imageSourceArray addObject:@"ICON115"];
    [colorPanelVC.imageSourceArray addObject:@"ICON116"];
    [colorPanelVC.imageSourceArray addObject:@"ICON117"];
    [colorPanelVC.imageSourceArray addObject:@"ICON118"];
    [colorPanelVC.imageSourceArray addObject:@"ICON119"];
    [colorPanelVC.imageSourceArray addObject:@"ICON120"];
    [colorPanelVC.imageSourceArray addObject:@"ICON121"];
    [colorPanelVC.imageSourceArray addObject:@"ICON122"];
    [colorPanelVC.imageSourceArray addObject:@"ICON123"];
    [colorPanelVC.imageSourceArray addObject:@"ICON124"];
    [colorPanelVC.imageSourceArray addObject:@"ICON125"];
    [colorPanelVC.imageSourceArray addObject:@"ICON126"];
    [colorPanelVC.imageSourceArray addObject:@"ICON127"];
    [colorPanelVC.imageSourceArray addObject:@"ICON128"];
    [colorPanelVC.imageSourceArray addObject:@"ICON129"];
    [colorPanelVC.imageSourceArray addObject:@"ICON130"];
    [colorPanelVC.imageSourceArray addObject:@"ICON131"];
    [colorPanelVC.imageSourceArray addObject:@"ICON132"];
    [colorPanelVC.imageSourceArray addObject:@"ICON133"];
    [colorPanelVC.imageSourceArray addObject:@"ICON134"];
    [colorPanelVC.imageSourceArray addObject:@"ICON135"];
    [colorPanelVC.imageSourceArray addObject:@"ICON136"];
    [colorPanelVC.imageSourceArray addObject:@"ICON137"];
    [colorPanelVC.imageSourceArray addObject:@"ICON138"];
    [colorPanelVC.imageSourceArray addObject:@"ICON139"];
    [colorPanelVC.imageSourceArray addObject:@"ICON140"];
    [colorPanelVC.imageSourceArray addObject:@"ICON18"];
    [colorPanelVC.imageSourceArray addObject:@"ICON20"];
    [colorPanelVC.imageSourceArray addObject:@"ICON24"];
    [colorPanelVC.imageSourceArray addObject:@"ICON25"];
    [colorPanelVC.imageSourceArray addObject:@"ICON26"];
    [colorPanelVC.imageSourceArray addObject:@"ICON27"];
    [colorPanelVC.imageSourceArray addObject:@"ICON28"];
    [colorPanelVC.imageSourceArray addObject:@"ICON29"];
    [colorPanelVC.imageSourceArray addObject:@"ICON30"];
    [colorPanelVC.imageSourceArray addObject:@"ICON31"];
    [colorPanelVC.imageSourceArray addObject:@"ICON32"];
    [colorPanelVC.imageSourceArray addObject:@"ICON33"];
    [colorPanelVC.imageSourceArray addObject:@"ICON34"];
    [colorPanelVC.imageSourceArray addObject:@"ICON35"];
    [colorPanelVC.imageSourceArray addObject:@"ICON36"];
    [colorPanelVC.imageSourceArray addObject:@"ICON37"];
    [colorPanelVC.imageSourceArray addObject:@"ICON38"];
    [colorPanelVC.imageSourceArray addObject:@"ICON39"];
    [colorPanelVC.imageSourceArray addObject:@"ICON40"];
    [colorPanelVC.imageSourceArray addObject:@"ICON41"];
    [colorPanelVC.imageSourceArray addObject:@"ICON42"];
    [colorPanelVC.imageSourceArray addObject:@"ICON43"];
    [colorPanelVC.imageSourceArray addObject:@"ICON44"];
    [colorPanelVC.imageSourceArray addObject:@"ICON45"];
    [colorPanelVC.imageSourceArray addObject:@"ICON46"];
    [colorPanelVC.imageSourceArray addObject:@"ICON47"];
    [colorPanelVC.imageSourceArray addObject:@"ICON48"];
    [colorPanelVC.imageSourceArray addObject:@"ICON49"];
    [colorPanelVC.imageSourceArray addObject:@"ICON50"];
    [colorPanelVC.imageSourceArray addObject:@"ICON51"];
    [colorPanelVC.imageSourceArray addObject:@"ICON52"];
    [colorPanelVC.imageSourceArray addObject:@"ICON53"];
    [colorPanelVC.imageSourceArray addObject:@"ICON54"];
    [colorPanelVC.imageSourceArray addObject:@"ICON55"];
    [colorPanelVC.imageSourceArray addObject:@"ICON56"];
    [colorPanelVC.imageSourceArray addObject:@"ICON57"];
    [colorPanelVC.imageSourceArray addObject:@"ICON58"];
    [colorPanelVC.imageSourceArray addObject:@"ICON59"];
    [colorPanelVC.imageSourceArray addObject:@"ICON60"];
    [colorPanelVC.imageSourceArray addObject:@"ICON61"];
    [colorPanelVC.imageSourceArray addObject:@"ICON62"];
    [colorPanelVC.imageSourceArray addObject:@"ICON63"];
    [colorPanelVC.imageSourceArray addObject:@"ICON64"];
    [colorPanelVC.imageSourceArray addObject:@"ICON65"];
    [colorPanelVC.imageSourceArray addObject:@"ICON66"];
    [colorPanelVC.imageSourceArray addObject:@"ICON67"];
    [colorPanelVC.imageSourceArray addObject:@"ICON69"];
    [colorPanelVC.imageSourceArray addObject:@"ICON70"];
    [colorPanelVC.imageSourceArray addObject:@"ICON71"];
    [colorPanelVC.imageSourceArray addObject:@"ICON72"];
    [colorPanelVC.imageSourceArray addObject:@"ICON73"];
    [colorPanelVC.imageSourceArray addObject:@"ICON74"];
    [colorPanelVC.imageSourceArray addObject:@"ICON75"];
    [colorPanelVC.imageSourceArray addObject:@"ICON76"];
    [colorPanelVC.imageSourceArray addObject:@"ICON77"];
    [colorPanelVC.imageSourceArray addObject:@"ICON78"];
    [colorPanelVC.imageSourceArray addObject:@"ICON79"];
    [colorPanelVC.imageSourceArray addObject:@"ICON80"];
    [colorPanelVC.imageSourceArray addObject:@"ICON81"];
    [colorPanelVC.imageSourceArray addObject:@"ICON82"];
    [colorPanelVC.imageSourceArray addObject:@"ICON83"];
    [colorPanelVC.imageSourceArray addObject:@"ICON84"];
    [colorPanelVC.imageSourceArray addObject:@"ICON85"];
    [colorPanelVC.imageSourceArray addObject:@"ICON86"];
    [colorPanelVC.imageSourceArray addObject:@"ICON87"];
    [colorPanelVC.imageSourceArray addObject:@"ICON88"];
    [colorPanelVC.imageSourceArray addObject:@"ICON89"];
    [colorPanelVC.imageSourceArray addObject:@"ICON90"];
    [colorPanelVC.imageSourceArray addObject:@"ICON91"];
    [colorPanelVC.imageSourceArray addObject:@"ICON92"];
    [colorPanelVC.imageSourceArray addObject:@"ICON93"];
    [colorPanelVC.imageSourceArray addObject:@"ICON94"];
    [colorPanelVC.imageSourceArray addObject:@"ICON95"];
    [colorPanelVC.imageSourceArray addObject:@"ICON96"];
    [colorPanelVC.imageSourceArray addObject:@"ICON97"];
}

#pragma mark - ColorPanelViewControllerDelegate
-(void)colorPanel:(ColorPanelViewController *)colorPanelVC changeImageWithButtonImage:(NSImage *)imageName{
    [self.toolBtn setImage:imageName];
}

-(void)Save{
    //To do: Save
    if(_EDLs != nil && _EDLs.count > 0 && _currentSelectedProject != nil){
        
        int projectId = _currentSelectedProject.projectId;
        //Save EDLs
        NSData *EDLData = [NSKeyedArchiver archivedDataWithRootObject:_EDLs];
        [[NSUserDefaults standardUserDefaults] setObject:EDLData forKey:[NSString stringWithFormat:@"EDLData-%d%@", projectId, _username]];

        //Save Selected Video
        NSData *ConformVideoListData = [NSKeyedArchiver archivedDataWithRootObject:_conformVideoFiles];
        [[NSUserDefaults standardUserDefaults] setObject:ConformVideoListData forKey:[NSString stringWithFormat:@"ConformVideoListData-%d%@", projectId, _username]];
        
        [[NSUserDefaults standardUserDefaults] setValue:[NSNumber numberWithInt:conformVideoIndex] forKey:[NSString stringWithFormat:@"ConformVideoIndex-%d%@", projectId, _username]];
        
        //Save Selected EDL/CSV
        NSData *ConformEDLListData = [NSKeyedArchiver archivedDataWithRootObject:_conformEDLFiles];
        [[NSUserDefaults standardUserDefaults] setObject:ConformEDLListData forKey:[NSString stringWithFormat:@"ConformEDLListData-%d%@", projectId, _username]];
        
        [[NSUserDefaults standardUserDefaults] setValue:[NSNumber numberWithInt:conformEDLIndex] forKey:[NSString stringWithFormat:@"ConformEDLIndex-%d%@", projectId, _username]];

        //Save Quick Place SET Tiles
        NSData *quickPlaceSetData = [NSKeyedArchiver archivedDataWithRootObject:_quickPlaceSetTiles];
        [[NSUserDefaults standardUserDefaults] setObject:quickPlaceSetData forKey:[NSString stringWithFormat:@"QuickPlaceTileListData-%d%@", projectId, _username]];

        //Save Current Project Index
        //[[NSUserDefaults standardUserDefaults] setValue:[NSNumber numberWithInt:_currentProjectIndex] forKey:[NSString stringWithFormat:@"currentProjectIndex-%d", projectId]];
        
        //Set Data Saved Flag
        [[NSUserDefaults standardUserDefaults] setObject:@"Saved" forKey:[NSString stringWithFormat:@"IsSaved-%d%@", projectId, _username]];
        
        //Set last saved project id
        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:projectId] forKey:[NSString stringWithFormat:@"LastSavedProject-%@", _username]];
        
        //Synchronize
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

- (void)resetEDLPlayerAndFrames {
    [_tblConformVideos reloadData];
    [_tblConformEDLs reloadData];
    
    [_transitionComboBox reloadData];
    [_soundsComboBox reloadData];
    
    [self.playerView.player pause];
    self.playerView.player = nil;
    
    _EDLs = [NSMutableArray array];
    [_tblEDLs reloadData];
    
    _timeFrames = [[NSMutableArray alloc] init];
    _images = [[NSMutableArray alloc] init];
    
    [_timelineCollection reloadData];
    
    _btnExport.enabled = false;
    
    [self clearAllTileOnEditFrame];
}

-(void)checkSavedData{
    //Get back
    int projectId = _currentSelectedProject.projectId;
    
    NSString *saved = [[NSUserDefaults standardUserDefaults] objectForKey:[NSString stringWithFormat:@"IsSaved-%d%@", projectId, _username]];
    
    if([saved isEqualToString:@"Saved"])
    {
        /*NSAlert *alert = [[NSAlert alloc] init];
        [alert addButtonWithTitle:@"Yes"];
        [alert addButtonWithTitle:@"No"];
        [alert setMessageText:@"Load Saved State"];
        [alert setInformativeText:@"A working state of this project is saved to disk. Do you want restore it?"];
        [alert setAlertStyle:NSWarningAlertStyle];
        
        NSModalResponse response = [alert runModal];
        
        if (response == NSAlertFirstButtonReturn) {*/
        
            [self showProgress];
            // OK clicked, restore state
            NSData *_tEDLdata = [[NSUserDefaults standardUserDefaults] objectForKey:[NSString stringWithFormat:@"EDLData-%d%@", projectId, _username]];
            NSMutableArray *_tEDLs = [NSKeyedUnarchiver unarchiveObjectWithData:_tEDLdata];
            
            NSData *_tVideoListdata = [[NSUserDefaults standardUserDefaults] objectForKey:[NSString stringWithFormat:@"ConformVideoListData-%d%@", projectId, _username]];
            NSMutableArray *_tConformVideos = [NSKeyedUnarchiver unarchiveObjectWithData:_tVideoListdata];
            
            NSData *_tConformEDLData = [[NSUserDefaults standardUserDefaults] objectForKey:[NSString stringWithFormat:@"ConformEDLListData-%d%@", projectId, _username]];
            NSMutableArray *_tConformEDLs = [NSKeyedUnarchiver unarchiveObjectWithData:_tConformEDLData];

            NSData * quickPlaceSetTilesData = [[NSUserDefaults standardUserDefaults] objectForKey:[NSString stringWithFormat:@"QuickPlaceTileListData-%d%@", projectId, _username]];
            self.quickPlaceSetTiles = [NSKeyedUnarchiver unarchiveObjectWithData:quickPlaceSetTilesData];
            if (self.quickPlaceSetTiles == nil) {
                self.quickPlaceSetTiles = [NSMutableArray array];
                for (int i = 0; i < 20; i++) {
                    [self.quickPlaceSetTiles addObject:[NSNull null]];
                }
            }
            
            
            NSNumber* conformVideoIndexNumber = [[NSUserDefaults standardUserDefaults] valueForKey:[NSString stringWithFormat:@"ConformVideoIndex-%d%@", projectId, _username]];
            NSNumber* conformEDLIndexNumber = [[NSUserDefaults standardUserDefaults] valueForKey:[NSString stringWithFormat:@"ConformEDLIndex-%d%@", projectId, _username]];
            
            conformVideoIndex = [conformVideoIndexNumber intValue];
            conformEDLIndex = [conformEDLIndexNumber intValue];
            
            //_currentProjectIndex = [(NSNumber*)[[NSUserDefaults standardUserDefaults] valueForKey:[NSString stringWithFormat:@"currentProjectIndex-%d", projectId]] intValue];
            
            //Select Project At Index
            //[self LoadProjectAtIndex:_currentProjectIndex];
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW,
                                         2* NSEC_PER_SEC),
                           dispatch_get_main_queue(),
                           ^{
            //Import and Conform
            _boxBinView.hidden = NO;
            [self addToBin];
            [self ConformAssetsAddedToBin];
            
            //Load Lists from Disk
            _conformEDLFiles = [_tConformEDLs mutableCopy];
            _conformVideoFiles = [_tConformVideos mutableCopy];
           [_tblConformVideos reloadData];
           [_tblConformEDLs reloadData];
            
            //Select Video
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW,
                                         3* NSEC_PER_SEC),
                           dispatch_get_main_queue(),
                           ^{
                               [self SelectVideoAtIndexAndConform:conformVideoIndex];
                               
                               //Replace EDLs
                               _savedEDLs = [_tEDLs mutableCopy];
                               ReplaceEDLsFromDisk = true;
                              
                               //Select EDL
                               dispatch_after(dispatch_time(DISPATCH_TIME_NOW,
                                                            3* NSEC_PER_SEC),
                                              dispatch_get_main_queue(),
                                              ^{
                                                  [self ConformEDLAtIndex:[conformEDLIndexNumber intValue]];
                                              });
                               
                           });
            });
        /*
        }
        else if (response == NSAlertSecondButtonReturn)
        {
            //Clear userdefaults
            NSString *appDomain = [[NSBundle mainBundle] bundleIdentifier];
            [[NSUserDefaults standardUserDefaults] removePersistentDomainForName:appDomain];
            
            [self LoadProjectAtIndex:0];
        }*/
    }
    else
    {
        //load default data
        [self setActiveProjectTitle:_currentSelectedProject.projectName collapse:true];
        
        _btnAddFiles.hidden = NO;
        _boxBinView.hidden = YES;
        
        _embedImageAssets = [NSMutableArray array];
        _embedPeopleAssets = [NSMutableArray array];
        
        [self reloadAssets];
        
        [self resetEDLPlayerAndFrames];

        if (self.quickPlaceSetTiles == nil) {
            self.quickPlaceSetTiles = [NSMutableArray array];
            for (int i = 0; i < 20; i++) {
                [self.quickPlaceSetTiles addObject:[NSNull null]];
            }
        }
    }
}

-(void)updateCurrentFrameTileLocations
{
    if(activeTileIndex == -1)
        return;
    
    //Remove from view
    NSMutableArray* _tagsArray = [NSMutableArray array];
    
    //Remove existing imageviews if any
    for (NSView *mainview in _playerbox.subviews) {
        for (NSView *subview in mainview.subviews)
        {
            if (subview.tag > 1000) {
                [_tagsArray addObject:[NSNumber numberWithInteger:subview.tag]];
            }
        }
    }
    
    for (NSNumber *num in _tagsArray) {
        NSInteger i = [num integerValue];
        NSImageView* viewForTileImage = [_mainView viewWithTag:i];
        CGRect size = viewForTileImage.frame;
        
        /*
         //To do: UnComment this when implementing animation
        int tileIndex = i - 1000;
        CGRect savedLocation = [self getTileLocationForCurrentFrameForTile:tileIndex];
        if(savedLocation.origin.x != -1)
            size.origin.x = savedLocation.origin.x;
        if(savedLocation.origin.y != -1)
            size.origin.y = savedLocation.origin.y;
        */
        
        viewForTileImage.frame = size;
        _btnRemoveTileFromEdit.hidden = YES;
    }
}

-(void)showCTAforCurrentTile
{
    EDL* currentEDl = (EDL*)(_EDLs[currentSceneIndex]);
    
    //Add new tiles for the EDL
    if(currentEDl.tiles != nil && currentEDl.tiles.count > 0)
    {
        
        int r = 0, c = 0;
        
        for (int i = 0; i < currentEDl.tiles.count; i++)
        {
            ADTile* tile = (ADTile*)currentEDl.tiles[i];
            
            CGRect size;
            
            if([tile.assetType isEqualToString:@"cta"])
            {
                size = _playerbox.frame;
                size.size.height = 151;
                size.size.width = size.size.width*0.6;
                //Add CTA Tile
                //tile.x_pos = 0;
                //tile.y_pos = 0;
                
                size.origin.x = tile.x_pos;
                size.origin.y = tile.y_pos;
                
                ((EDL*)_EDLs[currentSceneIndex]).tiles[i] = tile;
                
                AVAssetTrack * videoATrack = [[self.playerView.player.currentItem.asset tracksWithMediaType:AVMediaTypeVideo] lastObject];
                CGSize videoSize = videoATrack.naturalSize;
                
                CGSize renderedSize = _playerView.videoBounds.size;
                
                CGFloat percentageWidth = renderedSize.width/videoSize.width;
                CGFloat percentageHeight = renderedSize.height/videoSize.height;
                
                //create textview
                Asset* _aForTile = [self getAssetForTile:tile.tileAssetId];
                
                NSImage* _img = [[NSImage alloc] initWithContentsOfURL:[self getURLfromBookmarkData:_aForTile.assetBookmark]];
                
                NSImageRep *rep = [[_img representations] objectAtIndex:0];
                NSSize imageSize = NSMakeSize(rep.pixelsWide, rep.pixelsHigh);
                
                CGFloat finalCTAWidth = imageSize.width * percentageWidth;
                CGFloat finalCTAHeight = imageSize.height * percentageHeight;
                
                imageSize.width = finalCTAWidth;
                imageSize.height = finalCTAHeight;
                
                size.size = imageSize;
                NSImageView* viewForTileImage = [[NSImageView alloc] initWithFrame:size];
                viewForTileImage.image = _img;
                
                [_playerbox addSubview:viewForTileImage];
                viewForTileImage.imageScaling = NSImageScaleProportionallyDown;
                
                [viewForTileImage sendActionOn:NSLeftMouseDownMask|NSLeftMouseUpMask|NSLeftMouseDraggedMask];
                
                viewForTileImage.tag = 1000 + (i+1);
                
                viewForTileImage.toolTip = @"cta";
                
                [viewForTileImage setTarget:self];
                
                [_playerbox addSubview:viewForTileImage];
                [viewForTileImage pop_removeAllAnimations];
                
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [self clearAllCTATiles];
                });
            }
            
            _currentSceneAnimations = [NSMutableArray array];
            
            c++;
            //show up to 8 columns
            if(c == 8)
            {
                r++;
                c = 0;
            }
        }
    }
    else
    {
        //[self showAlert:@"No Icons Found" message:@"No icons found in this edit"];
    }
}

-(void)showADTilesForCurrentFrame//:(BOOL)ignoreCTA
{
    _ADTileView.hidden = true;
    [self pauseAudio];
    
    EDL* currentEDl = (EDL*)(_EDLs[currentSceneIndex]);
    
    //NSMutableArray* tilesInEDL = currentEDl.tiles;
    
    //Add new tiles for the EDL
    if(currentEDl.tiles != nil && currentEDl.tiles.count > 0)
    {
        //[self showAlert:@"Icons Found" message:[NSString stringWithFormat:@"%lu icons found in this edit", (unsigned long)currentEDl.tiles.count]];
        
        int r = 0, c = 0;
        
        for (int i = 0; i < currentEDl.tiles.count; i++)
        {
            ADTile* tile = (ADTile*)currentEDl.tiles[i];
            
            CGRect size;
            
            if([tile.assetType isEqualToString:@"cta"])
            {
                if(_playerView.player.rate > 0 && _playerView.player.error == nil)
                {
                    NSLog(@"Skipping CTA as video's playing");
                    continue;
                }
                
                size = _playerbox.frame;
                size.size.height = 151;
                size.size.width = size.size.width*0.6;
                //Add CTA Tile
                if(tile.x_pos == -1 || tile.x_pos == 0)
                {
                    tile.x_pos = 0;
                }
                
                if(tile.y_pos == -1 || tile.y_pos == 0)
                {
                    tile.y_pos = 0;
                }
                
                size.origin.x = tile.x_pos;
                size.origin.y = tile.y_pos;
            }
            else
            {
                size = _ADTileThumb.frame;
                BOOL XorY_Changed = false;
                if(tile.x_pos == -1 || tile.x_pos == 0)
                {
                    tile.x_pos = size.origin.x + (c*50);
                    XorY_Changed = true;
                }
                
                if(tile.y_pos == -1 || tile.y_pos == 0)
                {
                    tile.y_pos = size.origin.y - (r*50);
                    
                    if(r > 0){
                        tile.y_pos -= 10;
                        XorY_Changed = true;
                    }
                }
                
                tile.height = size.size.height;
                
                size.origin.x = tile.x_pos;
                size.origin.y = tile.y_pos;
            }
            
            ((EDL*)_EDLs[currentSceneIndex]).tiles[i] = tile;
            
            /*
             //ANIMATION CODE TO BE UNCOMMENTED
            if(XorY_Changed)
                [self updateTilePositionInFrames:i x:tile.x_pos y:tile.y_pos];
            */
            if([tile.assetType isEqualToString:@"cta"]){
                
                AVAssetTrack * videoATrack = [[self.playerView.player.currentItem.asset tracksWithMediaType:AVMediaTypeVideo] lastObject];
                CGSize videoSize = videoATrack.naturalSize;
                
                CGSize renderedSize = _playerView.videoBounds.size;
                
                CGFloat percentageWidth = renderedSize.width/videoSize.width;
                CGFloat percentageHeight = renderedSize.height/videoSize.height;
                
                
                //create textview
                Asset* _aForTile = [self getAssetForTile:tile.tileAssetId];
                
                NSImage* _img = [[NSImage alloc] initWithContentsOfURL:[self getURLfromBookmarkData:_aForTile.assetBookmark]];
                
                NSImageRep *rep = [[_img representations] objectAtIndex:0];
                NSSize imageSize = NSMakeSize(rep.pixelsWide, rep.pixelsHigh);
                
                CGFloat finalCTAWidth = imageSize.width * percentageWidth;
                CGFloat finalCTAHeight = imageSize.height * percentageHeight;
                
                imageSize.width = finalCTAWidth;
                imageSize.height = finalCTAHeight;
                
                size.size = imageSize;
                NSImageView* viewForTileImage = [[NSImageView alloc] initWithFrame:size];
                viewForTileImage.image = _img;
            
                
                /*
                ctatileview* ctaTile = [[ctatileview alloc] initWithFrame:size];
                float alpha = 100 - tile.transparency;
                alpha = alpha/100;
                ctaTile.ctaTileBox.fillColor =  [tile.tilePlateColor colorWithAlphaComponent:alpha];
                ctaTile.ctaTileText.textStorage.attributedString = [self getAttributedHeadingForText:tile.tileHeadingText];
                ctaTile.ctaTileText.textColor = tile.headingColor;
                ctaTile.tag = 1000 + (i+1);*/
                
                [_playerbox addSubview:viewForTileImage];
                viewForTileImage.imageScaling = NSImageScaleProportionallyDown;
                
                [viewForTileImage sendActionOn:NSLeftMouseDownMask|NSLeftMouseUpMask|NSLeftMouseDraggedMask];
                
                viewForTileImage.tag = 1000 + (i+1);
                
                [viewForTileImage setTarget:self];
                
                [_playerbox addSubview:viewForTileImage];
                [viewForTileImage pop_removeAllAnimations];
            }
            else{
                //create imageview
                NSImageView* viewForTileImage = [[NSImageView alloc] initWithFrame:size];
                
                if(tile.tileThumbnailImage == nil)
                {
                    tile.tileThumbnailImage = [NSImage imageNamed:@"bon2.png"];
                }
                
                if([tile.assetType isEqualToString:@"product"] && tile.tileCategory != nil && tile.tileCategory.length > 0 && [tile.tileCategory isNotEqualTo:@"No Category"])
                {
                    viewForTileImage.image = [NSImage imageNamed:[NSString stringWithFormat:@"%@.png",tile.tileCategory]];
                }
                else if(tile.useProfileAsIcon){
                    viewForTileImage.image = [[NSImage alloc] initWithContentsOfURL:[NSURL URLWithString:tile.assetImagePath]];
                }
                else
                    viewForTileImage.image = tile.tileThumbnailImage;
                
                viewForTileImage.image.backgroundColor = [NSColor grayColor];
                viewForTileImage.layer.backgroundColor = [[NSColor grayColor] CGColor];
                viewForTileImage.imageScaling = NSImageScaleProportionallyDown;
                
                
                [viewForTileImage sendActionOn:NSLeftMouseDownMask|NSLeftMouseUpMask|NSLeftMouseDraggedMask];
                
                viewForTileImage.tag = 1000 + (i+1);
                
                [viewForTileImage setTarget:self];
                [viewForTileImage setAction:@selector(ADTileThumbClicked:)];
                [_playerbox addSubview:viewForTileImage];
                [viewForTileImage pop_removeAllAnimations];
            }
            
            
            
            //if(_playerView.player.error == nil && _playerView.player.rate != 0){
                //add animation to tile //todo: make it dynamic
            
            _currentSceneAnimations = [NSMutableArray array];
            
            /* //START REMOVE ANIMATIONS
                //animation reference
                //https://bon2.tv/music/proof-of-concept-3/
                CGRect tileFrame = viewForTileImage.frame;
                //Get all animations of curret tile
                NSMutableArray* animations = [self getAnimationsForTile:i];
                if(animations.count > 0){
                    for (int index = 0; index < animations.count; index++) {
                        NSMutableDictionary* animationProerties = animations[index];
                        
                        CGRect fromFrame = tileFrame;
                        CGRect toFrame = tileFrame;
                        
                        fromFrame.origin.x = ((TileAnimationProperties*)[animationProerties objectForKey:@"from_transform"]).x;
                        fromFrame.origin.y = ((TileAnimationProperties*)[animationProerties objectForKey:@"from_transform"]).y;
                        
                        toFrame.origin.x = ((TileAnimationProperties*)[animationProerties objectForKey:@"to_transform"]).x;
                        toFrame.origin.y = ((TileAnimationProperties*)[animationProerties objectForKey:@"to_transform"]).y;
                        
                        float beginTime = [[animationProerties objectForKey:@"beginTime"] floatValue];
                        float endTime = [[animationProerties objectForKey:@"endTime"] floatValue];
                        
                        POPBasicAnimation *basicAnimation = [POPBasicAnimation animation];
                        basicAnimation.property = [POPAnimatableProperty propertyWithName:kPOPViewFrame];
                        basicAnimation.fromValue = [NSValue valueWithRect:fromFrame];
                        basicAnimation.toValue = [NSValue valueWithRect:toFrame];
                        basicAnimation.duration = endTime - beginTime;
                        if(index == 0)
                            basicAnimation.beginTime = CACurrentMediaTime();
                        else
                            basicAnimation.beginTime = CACurrentMediaTime() + beginTime;
                        
                        if(index == 0)
                            viewForTileImage.layer.beginTime = CACurrentMediaTime();
                        [basicAnimation setPaused:TRUE];
                        [viewForTileImage pop_addAnimation:basicAnimation forKey:[NSString stringWithFormat:@"basicanim-%d",index]];
                        [_currentSceneAnimations addObject:basicAnimation];
                    }
                }
            //}
            */ //END REMOVE ANIMATIONS
            c++;
            //show up to 8 columns
            if(c == 8)
            {
                r++;
                c = 0;
            }
            
        }
    }
    else
    {
        //[self showAlert:@"No Icons Found" message:@"No icons found in this edit"];
    }
    
    /*
    ADTile* currentFrameTile;
    
    if(currentSceneIndex < _EDLs.count)
        currentFrameTile = ((EDL*)(_EDLs[currentSceneIndex])).tile;
    
    if(currentFrameTile != nil){
        //1. Show ADTile thumb at top left
        CGRect _videoFrame = _playerbox.frame;
        _videoFrame.origin.x += 15;
        _videoFrame.origin.y = _videoFrame.origin.y + _videoFrame.size.height - 140;
        _videoFrame.size.height = 125;
        _videoFrame.size.width = 100;
        
        _ADTileThumb.frame = _videoFrame;
        _ADTileThumb.image = [[NSImage alloc] initWithContentsOfFile:currentFrameTile.assetImagePath];
        _ADTileThumb.layer.backgroundColor = [currentFrameTile.tilePlateColor CGColor];
        _ADTileThumb.hidden = false;
    }
    else
    {
        _ADTileThumb.hidden = true;
        _ADTileView.hidden = true;
    }*/
    
}

-(void)resumeAnimations
{
    //To Do: Fix when animations work is resumed.
    return;
    
    _btnRemoveTileFromEdit.hidden = true;
    for (int i = 0; i < _currentSceneAnimations.count; i++) {
        POPBasicAnimation* basicAnim =  _currentSceneAnimations[i];
        [basicAnim setPaused:false];
    }
}

-(void)pauseAnimations{
    for (int i = 0; i < _currentSceneAnimations.count; i++) {
        POPBasicAnimation* basicAnim =  _currentSceneAnimations[i];
        [basicAnim setPaused:true];
    }
}

-(void)deleteTile{
    

        NSAlert *alert = [[NSAlert alloc] init];
        [alert addButtonWithTitle:@"Yes"];
        [alert addButtonWithTitle:@"No"];
        [alert setMessageText:@"Delete?"];
        [alert setInformativeText:@"Are you sure you want to delete this tile?"];
        [alert setAlertStyle:NSWarningAlertStyle];
        
        NSModalResponse response = [alert runModal];
        
        if (response == NSAlertFirstButtonReturn) {
            //yes
            //Delete from collection view
            int tileid = ((ADTile*)[_ADTileLibrary objectAtIndex:_selectedLibraryItemIndex]).tileId;
            [_ADTileLibrary removeObjectAtIndex:_selectedLibraryItemIndex];
            
            //Reload collection view
            [_libraryCollectionView setNeedsDisplay:YES];
            [_libraryCollectionView reloadData];
            
            //delete from database
            [_database open];
            NSString *insertQuery = [NSString stringWithFormat:@"DELETE FROM library WHERE TILE_ID = %d", tileid];
            
            BOOL status = [_database executeUpdate:insertQuery];
            
            if (status) {
                NSLog(@"DELETE FROM LIBRARY OK");
                [_database commit];
                //[_database close];
            }else {
                NSLog(@"DELETE FROM LIBRARY FAILED");
            }
            
            [_database close];
            
            if(currentEditingTileIndex == _selectedLibraryItemIndex)
            {
                [self resetADTileEditor:nil];
            }
        }
        else if(response == NSAlertSecondButtonReturn){
            
        }
}

- (IBAction)btnDeleteTileClick:(id)sender {
    [self deleteTile];
}

BOOL _colorClicked;
- (IBAction)btnSetTextColorClick:(id)sender {
    
    [_cgColorWell activate:YES];
    return;
    /*
    _colorClicked = true;
    
    [[BFColorPickerPopover sharedPopover] showRelativeToRect:_btnTextColorSelect.frame ofView:_btnTextColorSelect.superview preferredEdge:NSMinYEdge];
    [[BFColorPickerPopover sharedPopover] setTarget:self];
    [[BFColorPickerPopover sharedPopover] setAction:@selector(colorChanged:)];
    //[[BFColorPickerPopover sharedPopover] setColor:selectedTileTextColor];
     
     */
}

- (void)windowWillClose:(NSNotification *)notification {
    /*if ([notification.object isEqual:[NSColorPanel sharedColorPanel]]) {
        [[NSColorPanel sharedColorPanel] setAction:nil];
    }
    else if ([notification.object isEqual:[BFColorPickerPopover sharedPopover]]) {
        [[BFColorPickerPopover sharedPopover] setAction:nil];
    }*/
}

- (void)colorChanged:(id)sender {
    /*
    if(_colorClicked)
        _colorClicked = false;
    else
        return;*/
    
    /*
    _embedView.layer.backgroundColor = [[BFColorPickerPopover sharedPopover].color CGColor];
    
    if([lastEditedField isEqualToString:@"heading"])
    {
        selectedTileTextColor = [[BFColorPickerPopover sharedPopover].color copy];
        _txtTileHeading.textColor = [BFColorPickerPopover sharedPopover].color;
        //[self refreshTileText];
        //[_txtTileHeading becomeFirstResponder];
    }
    else if([lastEditedField isEqualToString:@"description"])
    {
        selectedTileDescColor = [[BFColorPickerPopover sharedPopover].color copy];
        _txtTileDescription.textColor = [BFColorPickerPopover sharedPopover].color;
        //[self refreshTileText];
        //[_txtTileDescription becomeFirstResponder];
    }
    
    */
}
-(void)UnderlineTileTextColorButton {
    //set button bottom border with color
    NSMutableAttributedString* string = [[NSMutableAttributedString alloc]initWithString:@"A"];
    [string addAttribute:NSFontAttributeName value:[NSFont fontWithName:@"Helvetica Neue" size:18] range:NSMakeRange(0, string.length)];
    [string addAttribute:NSForegroundColorAttributeName value:[NSColor blackColor] range:NSMakeRange(0, string.length)];//TextColor
    [string addAttribute:NSUnderlineStyleAttributeName value:[NSNumber numberWithInt:NSUnderlineStyleThick] range:NSMakeRange(0, string.length)];//Underline color
    [string addAttribute:NSUnderlineColorAttributeName value:selectedTileTextColor range:NSMakeRange(0, string.length)];//TextColor
    _btnTextColorSelect.attributedStringValue = string;
}

-(void)IntializeRichTextButtons
{
    //Color Button
    NSMutableAttributedString* stringForColor = [[NSMutableAttributedString alloc]initWithString:@"A"];
    [stringForColor addAttribute:NSFontAttributeName value:[NSFont fontWithName:@"Helvetica Neue" size:18] range:NSMakeRange(0, stringForColor.length)];
    [stringForColor addAttribute:NSForegroundColorAttributeName value:[NSColor blackColor] range:NSMakeRange(0, stringForColor.length)];//TextColor

    NSMutableAttributedString* onStringForColor = [[NSMutableAttributedString alloc]initWithString:@"A"];
    [onStringForColor addAttribute:NSFontAttributeName value:[NSFont fontWithName:@"Helvetica Neue" size:18] range:NSMakeRange(0, onStringForColor.length)];
    [onStringForColor addAttribute:NSForegroundColorAttributeName value:[NSColor orangeColor] range:NSMakeRange(0, onStringForColor.length)];//TextColor
    
    _btnTextColorSelect.attributedStringValue = stringForColor;
    _btnTextColorSelect.attributedAlternateTitle = onStringForColor;

    //Bold Button
    NSMutableAttributedString* stringForBold = [[NSMutableAttributedString alloc]initWithString:@"B"];
    [stringForBold addAttribute:NSFontAttributeName value:[NSFont fontWithName:@"Helvetica Neue Bold" size:18] range:NSMakeRange(0, stringForBold.length)];
    [stringForBold addAttribute:NSForegroundColorAttributeName value:[NSColor blackColor] range:NSMakeRange(0, stringForBold.length)];//TextColor
    
    NSMutableAttributedString* onStringForBold = [[NSMutableAttributedString alloc]initWithString:@"B"];
    [onStringForBold addAttribute:NSFontAttributeName value:[NSFont fontWithName:@"Helvetica Neue Bold" size:18] range:NSMakeRange(0, onStringForBold.length)];
    [onStringForBold addAttribute:NSForegroundColorAttributeName value:[NSColor orangeColor] range:NSMakeRange(0, onStringForBold.length)];//TextColor
    
    _btnTextColorSelect.attributedStringValue = stringForBold;
    _btnTextColorSelect.attributedAlternateTitle = onStringForBold;
    
    //Italic Button
    NSMutableAttributedString* stringForItalic = [[NSMutableAttributedString alloc]initWithString:@"I"];
    [stringForItalic addAttribute:NSFontAttributeName value:[NSFont fontWithName:@"Helvetica Neue Italic" size:18] range:NSMakeRange(0, stringForItalic.length)];
    [stringForItalic addAttribute:NSForegroundColorAttributeName value:[NSColor blackColor] range:NSMakeRange(0, stringForItalic.length)];//TextColor
    
    
    NSMutableAttributedString* onStringForItalic = [[NSMutableAttributedString alloc]initWithString:@"I"];
    [onStringForItalic addAttribute:NSFontAttributeName value:[NSFont fontWithName:@"Helvetica Neue Italic" size:18] range:NSMakeRange(0, onStringForItalic.length)];
    [onStringForItalic addAttribute:NSForegroundColorAttributeName value:[NSColor orangeColor] range:NSMakeRange(0, onStringForItalic.length)];//TextColor
    
    _btnTextColorSelect.attributedStringValue = stringForItalic;
    _btnTextColorSelect.attributedAlternateTitle = onStringForItalic;
    
    //Underline Button
    NSMutableAttributedString* stringForUndeline = [[NSMutableAttributedString alloc]initWithString:@"U"];
    [stringForUndeline addAttribute:NSFontAttributeName value:[NSFont fontWithName:@"Helvetica Neue" size:18] range:NSMakeRange(0, stringForUndeline.length)];
    [stringForUndeline addAttribute:NSForegroundColorAttributeName value:[NSColor blackColor] range:NSMakeRange(0, stringForUndeline.length)];//TextColor
    [stringForUndeline addAttribute:NSUnderlineStyleAttributeName value:[NSNumber numberWithInt:NSUnderlineStyleSingle] range:NSMakeRange(0, stringForUndeline.length)];//Underline color
    
    NSMutableAttributedString* onStringForUnderline = [[NSMutableAttributedString alloc]initWithString:@"U"];
    [onStringForUnderline addAttribute:NSFontAttributeName value:[NSFont fontWithName:@"Helvetica Neue" size:18] range:NSMakeRange(0, onStringForUnderline.length)];
    [onStringForUnderline addAttribute:NSForegroundColorAttributeName value:[NSColor orangeColor] range:NSMakeRange(0, onStringForUnderline.length)];//TextColor
    [onStringForUnderline addAttribute:NSUnderlineStyleAttributeName value:[NSNumber numberWithInt:NSUnderlineStyleSingle] range:NSMakeRange(0, onStringForUnderline.length)];//Underline color
    
    _btnTextColorSelect.attributedStringValue = stringForUndeline;
    _btnTextColorSelect.attributedAlternateTitle = onStringForUnderline;
    
}


-(NSMutableAttributedString*)getAttributedHeadingForText:(NSString*)text{

    NSMutableAttributedString* _headingString = [[NSMutableAttributedString alloc]initWithString:text];
    
    NSString* fontName = @"Helvetica Neue";
    
    if(isTileTextBold)
    {
        fontName = [NSString stringWithFormat:@"%@ %@", fontName, @"Bold"];
    }
    
    if(isTileTextItalic)
    {
        fontName = [NSString stringWithFormat:@"%@ %@", fontName, @"Italic"];
    }
    
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc]init] ;
    
    if([tileTextAlignment isEqualToString:@"left"])
        [paragraphStyle setAlignment:NSTextAlignmentLeft];
    else if([tileTextAlignment isEqualToString:@"center"])
        [paragraphStyle setAlignment:NSTextAlignmentCenter];
    else
        [paragraphStyle setAlignment:NSTextAlignmentRight];
    
    [_headingString addAttribute:NSFontAttributeName value:[NSFont fontWithName:fontName size:18] range:NSMakeRange(0, _headingString.length)];//font style
    [_headingString addAttribute:NSForegroundColorAttributeName value:selectedTileTextColor range:NSMakeRange(0, _headingString.length)];//TextColor
    [_headingString addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:NSMakeRange(0, _headingString.length)];
    if(isTileTextUnderline){
        [_headingString addAttribute:NSUnderlineStyleAttributeName value:[NSNumber numberWithInt:NSUnderlineStyleSingle] range:NSMakeRange(0, _headingString.length)];//Underline
    }
    
    return _headingString;
}

-(NSMutableAttributedString*)getAttributedHeadingForADTile:(ADTile*)adTile{
    
    NSMutableAttributedString* _headingString = [[NSMutableAttributedString alloc]initWithString:adTile.tileHeadingText];
    
    NSString* fontName = @"Helvetica Neue";
    
    if(adTile.isHeadingBold)
    {
        fontName = [NSString stringWithFormat:@"%@ %@", fontName, @"Bold"];
    }
    
    if(adTile.isHeadingItalic)
    {
        fontName = [NSString stringWithFormat:@"%@ %@", fontName, @"Italic"];
    }
    
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc]init] ;
    
    if([adTile.tileHeadingAlignment isEqualToString:@"left"])
        [paragraphStyle setAlignment:NSTextAlignmentLeft];
    else if([adTile.tileHeadingAlignment isEqualToString:@"center"])
        [paragraphStyle setAlignment:NSTextAlignmentCenter];
    else
        [paragraphStyle setAlignment:NSTextAlignmentRight];
    
    [_headingString addAttribute:NSFontAttributeName value:[NSFont fontWithName:fontName size:18] range:NSMakeRange(0, _headingString.length)];//font style
    [_headingString addAttribute:NSForegroundColorAttributeName value:adTile.headingColor range:NSMakeRange(0, _headingString.length)];//TextColor
    [_headingString addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:NSMakeRange(0, _headingString.length)];
    if(adTile.isHeadingUnderline){
        [_headingString addAttribute:NSUnderlineStyleAttributeName value:[NSNumber numberWithInt:NSUnderlineStyleSingle] range:NSMakeRange(0, _headingString.length)];//Underline
    }
    
    return _headingString;
}

-(NSMutableAttributedString*)getAttributedDescForADTile:(ADTile*)adTile{
    NSMutableAttributedString* _descString = [[NSMutableAttributedString alloc]initWithString:adTile.tileDescription];
    
    NSString* fontName = @"Helvetica Neue";
    
    if(adTile.isDescBold)
    {
        fontName = [NSString stringWithFormat:@"%@ %@", fontName, @"Bold"];
    }
    
    if(adTile.isDescItalic)
    {
        fontName = [NSString stringWithFormat:@"%@ %@", fontName, @"Italic"];
    }
    
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc]init] ;
    
    if([adTile.tileDescAlignment isEqualToString:@"left"])
        [paragraphStyle setAlignment:NSTextAlignmentLeft];
    else if([adTile.tileDescAlignment isEqualToString:@"center"])
        [paragraphStyle setAlignment:NSTextAlignmentCenter];
    else
        [paragraphStyle setAlignment:NSTextAlignmentRight];
    
    [_descString addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:NSMakeRange(0, _descString.length)];
    [_descString addAttribute:NSFontAttributeName value:[NSFont fontWithName:fontName size:12] range:NSMakeRange(0, _descString.length)];//font style
    [_descString addAttribute:NSForegroundColorAttributeName value:adTile.descColor range:NSMakeRange(0, _descString.length)];//TextColor
    if(adTile.isDescUnderline){
        [_descString addAttribute:NSUnderlineStyleAttributeName value:[NSNumber numberWithInt:NSUnderlineStyleSingle] range:NSMakeRange(0, _descString.length)];//Underline
    }
    
    return _descString;
}

-(void)refreshTileText{
    //return;
    NSMutableAttributedString* _headingString = nil;
    NSMutableAttributedString* _descString = nil;
    
    if([lastEditedField isEqualToString:@"heading"] && _txtTileHeading.stringValue.length > 0)
    {
        _headingString = [self getAttributedHeadingForText:_txtTileHeading.stringValue];
        
        _txtTileHeading.attributedStringValue = _headingString;
        _txtTileHeading.textColor = selectedTileTextColor;
    }
    else if([lastEditedField isEqualToString:@"description"] && _txtTileDescription.stringValue.length > 0)
    {
        _descString = [[NSMutableAttributedString alloc]initWithString:_txtTileDescription.stringValue];

        NSString* fontName = @"Helvetica Neue";
        
        if(isTileDescBold)
        {
            fontName = [NSString stringWithFormat:@"%@ %@", fontName, @"Bold"];
        }
        
        if(isTileDescItalic)
        {
            fontName = [NSString stringWithFormat:@"%@ %@", fontName, @"Italic"];
        }
        
        NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc]init] ;
        
        if([tileDescAlignment isEqualToString:@"left"])
            [paragraphStyle setAlignment:NSTextAlignmentLeft];
        else if([tileDescAlignment isEqualToString:@"center"])
            [paragraphStyle setAlignment:NSTextAlignmentCenter];
        else
            [paragraphStyle setAlignment:NSTextAlignmentRight];
        
        [_descString addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:NSMakeRange(0, _descString.length)];
        [_descString addAttribute:NSFontAttributeName value:[NSFont fontWithName:fontName size:12] range:NSMakeRange(0, _descString.length)];//font style
        [_descString addAttribute:NSForegroundColorAttributeName value:selectedTileDescColor range:NSMakeRange(0, _descString.length)];//TextColor
        if(isTileDescUnderline){
            [_descString addAttribute:NSUnderlineStyleAttributeName value:[NSNumber numberWithInt:NSUnderlineStyleSingle] range:NSMakeRange(0, _descString.length)];//Underline
        }
        
        _txtTileDescription.attributedStringValue = _descString;
        _txtTileDescription.textColor = selectedTileDescColor;
    }
}

- (IBAction)btnSetTextBoldClick:(id)sender {
    if(_btnSetTextBold.state == 1)
    {
        //_btnSetTextBold.state = 1;
        if([self isTextFieldInFocus:_txtTileHeading]){
            isTileTextBold = true;
            lastEditedField = @"heading";
        }
        else if([self isTextFieldInFocus:_txtTileDescription])
        {
            isTileDescBold = true;
            lastEditedField = @"description";
        }
        [self refreshTileText];
    }
    else
    {
        //_btnSetTextBold.state = 0;
        if([self isTextFieldInFocus:_txtTileHeading])
        {
            lastEditedField = @"heading";
            isTileTextBold = false;
        }
        else if([self isTextFieldInFocus:_txtTileDescription])
        {
            lastEditedField = @"description";
            isTileDescBold = false;
        }
        
        [self refreshTileText];
    }
}

- (IBAction)btnSetTextItalicClick:(id)sender {
    if(_btnSetTextItalic.state == 1)
    {
        //_btnSetTextItalic.state = 1;
        
        if([self isTextFieldInFocus:_txtTileHeading])
        {
            lastEditedField = @"heading";
            isTileTextItalic = true;
        }
        else if([self isTextFieldInFocus:_txtTileDescription]){
            lastEditedField = @"description";
            isTileDescItalic = true;
        }
        
        [self refreshTileText];
    }
    else
    {
        //_btnSetTextItalic.state = 0;
        if([self isTextFieldInFocus:_txtTileHeading])
        {
            lastEditedField = @"heading";
            isTileTextItalic = false;
        }
        else if([self isTextFieldInFocus:_txtTileDescription]){
            lastEditedField = @"description";
            isTileDescItalic =  false;
        }
        
        [self refreshTileText];
    }
}

- (IBAction)btnSetTextUnderlineClick:(id)sender {
    if(_btnSetTextUnderline.state == 1)
    {
        //_btnSetTextUnderline.state = 1;
        
        if([self isTextFieldInFocus:_txtTileHeading])
        {
            lastEditedField = @"heading";
            isTileTextUnderline = true;
        }
        else if([self isTextFieldInFocus:_txtTileDescription]){
            lastEditedField = @"description";
            isTileDescUnderline = true;
        }
        [self refreshTileText];
    }
    else
    {
        //_btnSetTextUnderline.state = 0;
        
        if([self isTextFieldInFocus:_txtTileHeading]){
            lastEditedField = @"heading";
            isTileTextUnderline = false;
        }
        else if([self isTextFieldInFocus:_txtTileDescription])
        {
            lastEditedField = @"description";
            isTileDescUnderline = false;
        }
        [self refreshTileText];
    }
}

- (IBAction)btnSetTextLeftAlignClick:(id)sender {
    _btnSetTextAlignLeft.state = 1;
    
    
    if([self isTextFieldInFocus:_txtTileHeading])
    {
        lastEditedField = @"heading";
        tileTextAlignment = @"left";
    }
    else if([self isTextFieldInFocus:_txtTileDescription]){
        lastEditedField = @"description";
        tileDescAlignment = @"left";
    }
    
    [self refreshTileText];
    _btnSetTextAlignCenter.state = 0;
    _btnSetTextAlignRight.state = 0;
}

- (IBAction)btnSetTextCenterAlignClick:(id)sender {
    _btnSetTextAlignCenter.state = 1;
    
    if([self isTextFieldInFocus:_txtTileHeading])
    {
        lastEditedField = @"heading";
        tileTextAlignment = @"center";
    }
    else if([self isTextFieldInFocus:_txtTileDescription]){
        lastEditedField = @"description";
        tileDescAlignment = @"center";
    }
    
    [self refreshTileText];
    
    _btnSetTextAlignLeft.state = 0;
    _btnSetTextAlignRight.state = 0;
}

- (IBAction)btnSetTextRightAlignClick:(id)sender {
    _btnSetTextAlignRight.state = 1;
    
    
    if([self isTextFieldInFocus:_txtTileHeading])
    {
        lastEditedField = @"heading";
        tileTextAlignment = @"right";
    }
    else if([self isTextFieldInFocus:_txtTileDescription]){
        lastEditedField = @"description";
        tileDescAlignment = @"right";
    }
    
    [self refreshTileText];
    
    _btnSetTextAlignLeft.state = 0;
    _btnSetTextAlignCenter.state = 0;
}

- (BOOL)isTextFieldInFocus:(NSTextField *)textField
{
    /*BOOL inFocus = NO;
    
    inFocus = ([[[textField window] firstResponder] isKindOfClass:[NSTextView class]]
               && [[textField window] fieldEditor:NO forObject:nil]!=nil
               && [textField isEqualTo:(id)[(NSTextView *)[[textField window] firstResponder]delegate]]);
    
    return inFocus;*/
    
    if([lastEditedField isEqualToString:textField.identifier])
        return true;
    else
        return false;
}

- (IBAction)colorSelected:(id)sender {
    
    if([self isTextFieldInFocus:_txtTileHeading])
    {
        selectedTileTextColor = [(NSColorWell*)sender color];
        lastEditedField = @"heading";
        [self refreshTileText];
    }
    else if([self isTextFieldInFocus:_txtTileDescription])
    {
        selectedTileDescColor = [(NSColorWell*)sender color];
        lastEditedField = @"description";
        [self refreshTileText];
    }
}

- (IBAction)plateColorSelected:(id)sender {
    selectedTilePlateColor = [(NSColorWell*)sender color];
}

- (IBAction)headingSelected:(id)sender {
    NSLog(@"heading control lost...");
}

- (IBAction)descriptionSelected:(id)sender {
    NSLog(@"description control lost...");
}
- (IBAction)selectTransitionOption:(id)sender {
    ((NSButton*)sender).state = 1;
    
    tileTransition = ((NSButton*)sender).title;
}
- (IBAction)btnPreviouClick:(id)sender {
    if(_EDLs.count > 0 && _images.count > 0)
    {
        int _r = _tblEDLs.selectedRow;
        
        _r--;
        
        if(_r >= 0){
            [self selectEDLinTableAtIndex:_r];
            [self selectFrameAtIndex:_r];
            
            _btnNext.enabled = true;
            
//            CMTime _t = [self parseTimecodeStringIntoCMTime:((EDL*)(_EDLs[_r])).destIn];
            CMTime _t = ((EDL*)(_EDLs[_r])).time;
            
            [self seekToTimeAtVideo:_t frameIndex:_r];
            
            if(_r == 0)
                _btnPrevious.enabled = false;
        }
    }
}

- (IBAction)btnNextClick:(id)sender {
    if(_EDLs.count > 0 && _images.count > 0)
    {
        int _r = _tblEDLs.selectedRow;
        
        _r++;
        
        if(_r < _EDLs.count){
            [self selectEDLinTableAtIndex:_r];
            [self selectFrameAtIndex:_r];
            
            _btnPrevious.enabled = true;
            
//            CMTime _t = [self parseTimecodeStringIntoCMTime:((EDL*)(_EDLs[_r])).destIn];
            CMTime _t = ((EDL*)(_EDLs[_r])).time;
            
            [self seekToTimeAtVideo:_t frameIndex:_r];
            
            if(_r == _EDLs.count - 1)
                _btnNext.enabled = false;
        }
    }
}

- (IBAction)btnLoopClick:(id)sender {
    //loop
    isCurrentEditInLoop = !isCurrentEditInLoop;
}

- (IBAction)btnPlayPauseClick:(id)sender {
    [self playPause];
}

-(void)playPause{
    if(_playerView.player.currentItem != nil)
    {
        if(_playerView.player.rate > 0 && _playerView.player.error == nil)
        {
            [_playerView.player pause];
            [_btnPlayPause setImage:[NSImage imageNamed:@"play" ]];
        }
        else
        {
            userSelection = false;
            
            [_playerView.player play];
            
            [_btnPlayPause setImage:[NSImage imageNamed:@"pause" ]];
        }
    }
}
- (IBAction)btnRemoveTileFromFrameClick:(id)sender {
    if(activeTileIndex == -1)
        return;
    
    //Remove from view
    NSMutableArray* _tagsArray = [NSMutableArray array];
    
    //Remove existing imageviews if any
    for (NSView *mainview in _playerbox.subviews) {
        for (NSView *subview in mainview.subviews)
        {
            if (subview.tag == 1000 + activeTileIndex) {
                [_tagsArray addObject:[NSNumber numberWithInteger:subview.tag]];
            }
        }
    }
    
    for (NSNumber *num in _tagsArray) {
        NSInteger i = [num integerValue];
        [[_mainView viewWithTag:i] removeFromSuperview];
    }
    
    //Remove from EDIT frame
    _ADTileView.hidden = true;
    [self pauseAudio];
    [((EDL*)(_EDLs[currentSceneIndex])).tiles removeObjectAtIndex:activeTileIndex-1];
    
    [self Save];
    //reset and hide
    activeTileIndex = -1;
    _btnRemoveTileFromEdit.hidden = YES;
    
    [self clearAllTileOnEditFrame];
    [self showADTilesForCurrentFrame];
}

-(BOOL)isEmailAdmin{
    NSString* email = [[NSUserDefaults standardUserDefaults] valueForKey:@"email"];
    
    if(email != nil && email.length > 0 && ([email hasSuffix:@"bon2.tv"] || [email hasSuffix:@"bon2.com"] || [email hasSuffix:@"watchtele.tv"])){
        return true;
    }
    else{
        return false;
    }
}

- (IBAction)menuInviteUsersClick:(id)sender {
    
    /*
    self.exportViewController = [self.storyboard instantiateControllerWithIdentifier:@"ExportViewController"];
    
    
    //[self presentViewControllerAsSheet:self.exportViewController];
    
    NSRect mainRect = self.mainView.frame;
    mainRect.size.height -= 25;
    
    [self presentViewController:self.exportViewController asPopoverRelativeToRect:mainRect ofView:self.mainView preferredEdge:NSRectEdgeMaxY behavior:NSPopoverBehaviorApplicationDefined];
    
    return;*/
    
    
    NSString* userId = [[NSUserDefaults standardUserDefaults] valueForKey:@"userId"];
    if(![userId isEqualToString:@"the.people"] && ![userId isEqualToString:@"rajani"] && ![userId.lowercaseString isEqualToString:@"bon2admin"] && ![self isEmailAdmin])
    {
        [self showAlert:@"Insufficient Permissions" message:@"You don't have permissions to perform this operation."];
        return;
    }
    
    self.inviteWindowController = [[InviteUserModalController alloc] initWithWindowNibName:@"inviteuserview"];
    
    
    [[[NSApplication sharedApplication] mainWindow]beginSheet:self.inviteWindowController.window  completionHandler:^(NSModalResponse returnCode) {
        NSLog(@"Sheet closed");
        
        switch (returnCode) {
            case NSModalResponseOK:
                NSLog(@"Done button tapped in Custom Sheet");
                break;
            case NSModalResponseCancel:
                NSLog(@"Cancel button tapped in Custom Sheet");
                break;
                
            default:
                break;
        }
        
        self.inviteWindowController = nil;
    }];

    
}

-(void)openURL:(NSString*)urlToOpen{
    if(urlToOpen.length > 0)
    {
        if([urlToOpen hasPrefix:@"http"] || [urlToOpen hasPrefix:@"https"] )
        {
            [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:urlToOpen]];
        }
        else
        {
            urlToOpen = [NSString stringWithFormat:@"http://%@", urlToOpen];
            [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:urlToOpen]];
        }
    }
}

- (IBAction)btnFbLinkClicked:(id)sender {
    NSInteger tileTag = ((NSButton*)sender).tag;
    int tileIndex = tileTag - 1000;
    ADTile* currentFrameTile = ((EDL*)(_EDLs[currentSceneIndex])).tiles[tileIndex-1];
    NSString* urlToOpen = currentFrameTile.fbLink;
    [self openURL:urlToOpen];
}

- (IBAction)btnInstaLinkClicked:(id)sender {
    NSInteger tileTag = ((NSButton*)sender).tag;
    int tileIndex = tileTag - 1000;
    ADTile* currentFrameTile = ((EDL*)(_EDLs[currentSceneIndex])).tiles[tileIndex-1];
    NSString* urlToOpen = currentFrameTile.instaLink;
    [self openURL:urlToOpen];
}

- (IBAction)btnPinterestLinkClicked:(id)sender {
    NSInteger tileTag = ((NSButton*)sender).tag;
    int tileIndex = tileTag - 1000;
    ADTile* currentFrameTile = ((EDL*)(_EDLs[currentSceneIndex])).tiles[tileIndex-1];
    NSString* urlToOpen = currentFrameTile.pinterestLink;
    [self openURL:urlToOpen];
}

- (IBAction)btnTwitterLinkClicked:(id)sender {
    NSInteger tileTag = ((NSButton*)sender).tag;
    int tileIndex = tileTag - 1000;
    ADTile* currentFrameTile = ((EDL*)(_EDLs[currentSceneIndex])).tiles[tileIndex-1];
    NSString* urlToOpen = currentFrameTile.twLink;
    [self openURL:urlToOpen];
}

- (IBAction)ADTileURLBtnClicked:(id)sender{
    NSInteger tileTag = ((NSButton*)sender).tag;
    int tileIndex = tileTag - 1000;
    ADTile* currentFrameTile = ((EDL*)(_EDLs[currentSceneIndex])).tiles[tileIndex-1];
    NSString* urlToOpen = currentFrameTile.websiteLink;
    [self openURL:urlToOpen];
}

- (IBAction)edlTimeSliderChanged:(id)sender {
    NSSlider *slider = sender;
    double value = slider.doubleValue;
    [_playerView.player seekToTime:CMTimeMakeWithSeconds(value, NSEC_PER_SEC) toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
    [_playerView.player pause];
    [self showCurrentFrameNumber:CMTimeMakeWithSeconds(value, NSEC_PER_SEC)];
}

- (IBAction)createArtistClick:(id)sender {
    NSString* userId = [[NSUserDefaults standardUserDefaults] valueForKey:@"userId"];
    if(![userId isEqualToString:@"the.people"] && ![userId isEqualToString:@"rajani"] && ![userId.lowercaseString isEqualToString:@"bon2admin"] && ![self isEmailAdmin])
    {
        [self showAlert:@"Insufficient Permissions" message:@"You don't have permissions to perform this operation."];
        return;
    }
    
    NSRect mainRect = self.mainView.frame;
    mainRect.size.height -= 25;
    
    [self presentViewController:self.createArtistController asPopoverRelativeToRect:mainRect ofView:self.mainView preferredEdge:NSRectEdgeMaxY behavior:NSPopoverBehaviorApplicationDefined];
    //[self presentViewControllerAsSheet:self.exportViewController];
    return;
}

- (IBAction)createProductClick:(id)sender {
    NSString* userId = [[NSUserDefaults standardUserDefaults] valueForKey:@"userId"];
    if(![userId isEqualToString:@"the.people"] && ![userId isEqualToString:@"rajani"] && ![userId isEqualToString:@"BON2admin"] && ![self isEmailAdmin])
    {
        [self showAlert:@"Insufficient Permissions" message:@"You don't have permissions to perform this operation."];
        return;
    }
    NSRect mainRect = self.mainView.frame;
    mainRect.size.height -= 25;
    
    [self presentViewController:self.createProductController asPopoverRelativeToRect:mainRect ofView:self.mainView preferredEdge:NSRectEdgeMaxY behavior:NSPopoverBehaviorApplicationDefined];
    //[self presentViewControllerAsSheet:self.exportViewController];
    return;
}

- (IBAction)searchArtistsClick:(id)sender {
    [self showArtistSearch];
}

-(void)showArtistSearch{
    NSRect mainRect = self.mainView.frame;
    mainRect.size.height += 25;
    [self presentViewController:self.searchArtistsController asPopoverRelativeToRect:mainRect ofView:self.mainView preferredEdge:NSRectEdgeMaxY behavior:NSPopoverBehaviorApplicationDefined];
    //[self presentViewControllerAsSheet:self.exportViewController];
}

-(void)showProductSearch{
    NSRect mainRect = self.mainView.frame;
    mainRect.size.height += 25;
    [self presentViewController:self.searchProductsController asPopoverRelativeToRect:mainRect ofView:self.mainView preferredEdge:NSRectEdgeMaxY behavior:NSPopoverBehaviorApplicationDefined];
    //[self presentViewControllerAsSheet:self.exportViewController];
}

-(void)showCreateSeries{
//    NSRect mainRect = self.mainView.frame;
//    mainRect.size.height += 25;
////    [self presentViewController:self.createSeriesController asPopoverRelativeToRect:mainRect ofView:self.mainView preferredEdge:NSRectEdgeMaxY behavior:NSPopoverBehaviorApplicationDefined];
//    [self presentViewControllerAsModalWindow:self.createSeriesController];
    NSStoryboard *storyBoard = [NSStoryboard storyboardWithName:@"Main" bundle:nil];
    CreateSeriesViewController *controller = [storyBoard instantiateControllerWithIdentifier:@"CreateSeriesViewController"];
    [self presentViewController:controller asPopoverRelativeToRect:NSRectFromCGRect(CGRectMake(0, 0, 1200, 800)) ofView:self.view preferredEdge:NSRectEdgeMaxY behavior:NSPopoverBehaviorApplicationDefined];
}

- (IBAction)selectedTilesFrameSliderChanged:(id)sender {
    
    NSSlider *slider = sender;
    int value = slider.intValue;
    
    NSDictionary* fr = [currentVideoFrames objectAtIndex:value+1]; //+1 as the frame values start from 0
    NSNumber* time = [fr valueForKey:@"time"];
    [_playerView.player seekToTime:CMTimeMakeWithSeconds([time doubleValue], NSEC_PER_SEC) toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
    [_playerView.player pause];
    
    currentFrameNumber = value;
    currentFrameNumber = [[(NSDictionary*)[currentVideoFrames objectAtIndex:value] objectForKey:@"frame"] intValue];
    
    [self updateFrameCountDisplay:true];
    [self updateCurrentFrameTileLocations];
    
    _ADTileView.hidden = true;
    [self pauseAudio];
}

-(void)comboBoxSelectionDidChange:(NSNotification *)notification
{
    
}

-(NSString*)getSelectedAudioTransitionName
{
    //int index = [_transitionComboBox indexOfSelectedItem];
    if(selectedAudioTransitionIndex != -1 && selectedAudioTransitionIndex < _currentSelectedProject.sounds.count)
    {
        return _currentSelectedProject.sounds[selectedAudioTransitionIndex];
    }
    return @"";
}

-(NSString*)getSelectedTransitionName
{
    //int index = [_transitionComboBox indexOfSelectedItem];
    if(selectedImageTransitionIndex != -1 && selectedImageTransitionIndex < _currentSelectedProject.transitions.count)
    {
        return _currentSelectedProject.transitions[selectedImageTransitionIndex];
    }
    return @"";
}

int selectedImageTransitionIndex = -1;
int selectedAudioTransitionIndex = -1;

- (IBAction)transitionComboBoxChanged:(id)sender {
    selectedImageTransitionIndex = [_transitionComboBox indexOfSelectedItem];
    if(selectedImageTransitionIndex < _currentSelectedProject.transitions.count)
    {
        NSString *strValue = _currentSelectedProject.transitions[selectedImageTransitionIndex];
        [self previewTransitionFromDB:strValue];
    }
}

- (IBAction)btnCloseOpenTileClick:(id)sender {
    _ADTileView.hidden = true;
    [self pauseAudio];
}

- (IBAction)btnSaveEdlClick:(id)sender {
    if(_currentSelectedProject != nil)
    {
        if(_EDLs.count > 0)
        {
            NSString* finalStr = @"";
            for (int i = 0; i < _EDLs.count - 1; i++) {
                EDL* _currEDL = [_EDLs objectAtIndex:i];
                EDL* nextEDL = [_EDLs objectAtIndex:i+1];
                NSString* _currStr = [NSString stringWithFormat:@"%d %@ %@ %@ %@ %@ %@ %@",i, @"AX", @"V", @"C",_currEDL.sourceIn, nextEDL.sourceIn, _currEDL.destIn, nextEDL.destIn];
                
                finalStr = [NSString stringWithFormat:@"%@ \n %@",finalStr, _currStr];
            }
            [self saveEDLToFile:_currentSelectedProject.projectName contents:finalStr];
        }
    }
}

- (IBAction)btnCreateSeriesClicked:(id)sender {
    [self showCreateSeries];
}

-(IBAction)btnShowTileIconClick:(id)sender {

}

-(IBAction)btnHideTileIconClick:(id)sender {
    
}

- (IBAction)soundsComboBoxChanged:(id)sender {
    selectedAudioTransitionIndex = [_soundsComboBox indexOfSelectedItem];
}

- (IBAction)tileTransparencySliderChanged:(id)sender {
    _txtTileTransparency.stringValue = [NSString stringWithFormat:@"Transparency: %.f %%", _tileTransparencySlider.floatValue];
}

- (IBAction)btnDeleteTransitionClick:(id)sender {
    if(_currentSelectedProject != nil && _currentSelectedProject.transitions != nil && _currentSelectedProject.transitions.count > 0)
    {
        NSInteger _i = [_transitionComboBox indexOfSelectedItem];
        if(_i != -1)
        {
            NSAlert *alert = [[NSAlert alloc] init];
            [alert addButtonWithTitle:@"Yes"];
            [alert addButtonWithTitle:@"No"];
            [alert setMessageText:@"Delete Transition"];
            [alert setInformativeText:@"This will remove the transition from the project. The files will remain on the disk. Remove transition?"];
            [alert setAlertStyle:NSWarningAlertStyle];

            NSModalResponse response = [alert runModal];

            if (response == NSAlertFirstButtonReturn) {
                // Yes Clicked
                [self deleteTransitionFromDB:[_currentSelectedProject.transitions objectAtIndex:_i]];

                [_currentSelectedProject.transitions removeObjectAtIndex:_i];
                [_transitionComboBox reloadData];
                if(_currentSelectedProject.transitions.count > 0){
                    [_transitionComboBox selectItemAtIndex:0];
                    [_transitionComboBox setObjectValue:_currentSelectedProject.transitions[0]];
                    [self.transitionPreviewView.layer removeAllAnimations];
                }
            }
            else if (response == NSAlertSecondButtonReturn)
            {
                //No Clicked

            }
            else{
                return;//exit
            }
        }
    }
}

-(void)deleteAudioTransition{
    if(_currentSelectedProject != nil && _currentSelectedProject.sounds != nil && _currentSelectedProject.sounds.count > 0)
    {
        NSInteger _i = [_soundsComboBox indexOfSelectedItem];
        if(_i != -1)
        {
            NSAlert *alert = [[NSAlert alloc] init];
            [alert addButtonWithTitle:@"Yes"];
            [alert addButtonWithTitle:@"No"];
            [alert setMessageText:@"Delete Transition"];
            [alert setInformativeText:@"This will remove the transition from the project. The files will remain on the disk. Remove transition?"];
            [alert setAlertStyle:NSWarningAlertStyle];

            NSModalResponse response = [alert runModal];

            if (response == NSAlertFirstButtonReturn) {
                // Yes Clicked
                [self deleteAudioTransitionFromDB:[_currentSelectedProject.sounds objectAtIndex:_i]];

                [_currentSelectedProject.sounds removeObjectAtIndex:_i];
                [_soundsComboBox reloadData];
                if(_currentSelectedProject.sounds.count > 0){
                    [_soundsComboBox selectItemAtIndex:0];

                        [_soundsComboBox setObjectValue:_currentSelectedProject.sounds[0]];
                        selectedAudioTransitionIndex = 0;

                }
            }
            else if (response == NSAlertSecondButtonReturn)
            {
                //No Clicked

            }
            else{
                return;//exit
            }
        }
    }
}

- (IBAction)btnTransitionImageClick:(id)sender {
    [self setButtonTitle:_btnTransitionImage toString:@"IMAGES" withColor:[NSColor orangeColor] withSize:18];
    [self setButtonTitle:_btnTransitionAudio toString:@"Sounds" withColor:[NSColor grayColor] withSize:18];
    //[self.transitionView.layer setBackgroundColor:[[NSColor colorFromHexadecimalValue:@"#ECECEC"] CGColor]];
    self.transitionPreviewView.hidden = false;
    [self.transitionPreviewView.layer removeAllAnimations];
    _btnTransitionImage.state = 1;
    _btnTransitionAudio.state = 0;
    [_transitionComboBox deselectItemAtIndex:_transitionComboBox.indexOfSelectedItem];
    [_transitionComboBox reloadData];
    
    if(selectedImageTransitionIndex != -1 && selectedImageTransitionIndex < _currentSelectedProject.transitions.count){
        [_transitionComboBox selectItemAtIndex:selectedImageTransitionIndex];
        [_transitionComboBox setObjectValue:_currentSelectedProject.transitions[selectedImageTransitionIndex]];

    }
    
    _btnPlayAudioTransition.hidden = true;
    _imgAudioGif.hidden = true;
}

- (IBAction)btnTransitionAudioClick:(id)sender {
    [self setButtonTitle:_btnTransitionImage toString:@"Images" withColor:[NSColor grayColor] withSize:18];
    [self setButtonTitle:_btnTransitionAudio toString:@"SOUNDS" withColor:[NSColor orangeColor] withSize:18];
    //[self.transitionView.layer setBackgroundColor:[[NSColor whiteColor] CGColor]];
    self.transitionPreviewView.hidden = true;
    _btnTransitionImage.state = 0;
    _btnTransitionAudio.state = 1;
    [_transitionComboBox deselectItemAtIndex:_transitionComboBox.indexOfSelectedItem];
    [_transitionComboBox reloadData];
    
    if(selectedAudioTransitionIndex != -1 && selectedAudioTransitionIndex < _currentSelectedProject.sounds.count){
        [_transitionComboBox selectItemAtIndex:selectedAudioTransitionIndex];
        [_transitionComboBox setObjectValue:_currentSelectedProject.sounds[selectedAudioTransitionIndex]];
    }
    
    _btnPlayAudioTransition.hidden = false;
    _imgAudioGif.imageScaling = NSImageScaleNone;
    _imgAudioGif.canDrawSubviewsIntoLayer = YES;
    _imgAudioGif.hidden = false;
    _imgAudioGif.animates = false;
}

- (IBAction)btnAddNewTransitionClick:(id)sender {
    [self addNewImageTransition];
}

- (IBAction)btnAddNewSoundClick:(id)sender {
    [self addNewSoundTransition];
}

- (IBAction)btnDeleteSoundClick:(id)sender {
    [self deleteAudioTransition];
}

- (IBAction)tileCategoryChanged:(id)sender {
    if([_tileCategoryComboBox.stringValue isNotEqualTo:@"No Category"])
    {
        NSString* imgName = [NSString stringWithFormat:@"%@.png",_tileCategoryComboBox.stringValue];
        _imgSelectedAssetImage.image = [NSImage imageNamed:imgName];
        //NSLog(imgName);
    }
    else
    {
        _imgSelectedAssetImage.image = nil;
    }
}

- (IBAction)btnCreateCategoryTileClick:(id)sender {
    [self resetADTileEditor:nil];
    _plateview.hidden = NO;
    _transitionView.hidden = YES;
    _tileTextView.hidden = YES;
    _tileLinkView.hidden = YES;
    _chkUseProfilePicAsIcon.enabled = false;
    _chkUseProfilePicAsIcon.state = 0;
    _toolBtn.enabled = false;
    _btnTileTransition.enabled = false;
    _btnTileLink.enabled = false;
}

- (void)saveEDLToFile:(NSString*)fileName contents:(NSString*)contents {
    // create the save panel
    NSSavePanel *panel = [NSSavePanel savePanel];
    
    // set a new file name
    [panel setNameFieldStringValue:[NSString stringWithFormat:@"%@.edl", fileName]];
    
    // display the panel
    [panel beginWithCompletionHandler:^(NSInteger result) {
        
        if (result == NSFileHandlingPanelOKButton) {
            
            // create a file namaner and grab the save panel's returned URL
            ///NSFileManager *manager = [NSFileManager defaultManager];
            NSURL *saveURL = [panel URL];
            
            //[[NSFileManager defaultManager] createFileAtPath:saveURL.absoluteString contents:nil attributes:nil];
            NSError *error;
            [contents writeToFile:saveURL.path atomically:YES encoding:NSUTF8StringEncoding error:&error];
            if(error != nil)
            {
                NSLog(error);
            }
            // then copy a previous file to the new location
            //[manager copyItemAtURL:self.myURL toURL:saveURL error:nil];
        }
    }];
}

- (IBAction)createNewLocationClick:(id)sender {
    NSString* userId = [[NSUserDefaults standardUserDefaults] valueForKey:@"userId"];
    if(![userId isEqualToString:@"the.people"] && ![userId isEqualToString:@"rajani"] && ![userId.lowercaseString isEqualToString:@"bon2admin"] && ![self isEmailAdmin])
    {
        [self showAlert:@"Insufficient Permissions" message:@"You don't have permissions to perform this operation."];
        return;
    }
    
    NSRect mainRect = self.mainView.frame;
    mainRect.size.height -= 25;
    
    [self presentViewController:self.createLocationController asPopoverRelativeToRect:mainRect ofView:self.mainView preferredEdge:NSRectEdgeMaxY behavior:NSPopoverBehaviorApplicationDefined];
    //[self presentViewControllerAsSheet:self.exportViewController];
    return;
}

-(IBAction)createNewBrandClick:(id)sender{
    NSString* userId = [[NSUserDefaults standardUserDefaults] valueForKey:@"userId"];
    if(![userId isEqualToString:@"the.people"] && ![userId isEqualToString:@"rajani"] && ![userId.lowercaseString isEqualToString:@"bon2admin"]  && ![self isEmailAdmin])
    {
        [self showAlert:@"Insufficient Permissions" message:@"You don't have permissions to perform this operation."];
        return;
    }
    
    NSRect mainRect = self.mainView.frame;
    mainRect.size.height -= 25;
    
    [self presentViewController:self.createBrandController asPopoverRelativeToRect:mainRect ofView:self.mainView preferredEdge:NSRectEdgeMaxY behavior:NSPopoverBehaviorApplicationDefined];
    //[self presentViewControllerAsSheet:self.exportViewController];
    return;
}

- (IBAction)menuSearchProductsClick:(id)sender {
    [self showProductSearch];
}

-(void)selectCTAImage{
    NSOpenPanel* openDlg = [NSOpenPanel openPanel];
    // Enable the selection of files in the dialog.
    [openDlg setCanChooseFiles:YES];
    
    // Can't select a directory
    [openDlg setCanChooseDirectories:NO];
    [openDlg setAllowsMultipleSelection: false];
    [openDlg setAllowedFileTypes:[NSArray arrayWithObjects:@"png", @"jpg", @"jpeg", nil]];
    
    if ( [openDlg runModal] == NSModalResponseOK )
    {
        [self hideDialogView];
        
        // Get an array containing the full filenames of all
        // files and directories selected.
        NSArray* urls = [openDlg URLs];
        
        if(urls.count > 0)
        {
            NSURL* url = [urls objectAtIndex:0];
            NSLog(@"Url: %@", url);
            
            NSData *bookmark = nil;
            NSError *error = nil;
            bookmark = [url bookmarkDataWithOptions:NSURLBookmarkCreationWithSecurityScope
                     includingResourceValuesForKeys:nil
                                      relativeToURL:nil // Make it app-scoped
                                              error:&error];
            if (error) {
                NSLog(@"Error creating bookmark for URL (%@): %@", url, error);
                NSString* err = [NSString stringWithFormat:@"%@",error];
                [self showAlert:@"Error" message:err];
            }
            else{
                //1. Read file details and create asset object
                Asset* _cta = [self CreateCTAAssetAndAddtoDB:url bookmark:bookmark];
                
                isTileInEditCTA = true;
                [self resetADTileEditor:nil];
                [self updateTileEditorForCTA];
                _selectedAssetForADTile = _cta;
                _imgSelectedAssetImage.image = [[NSImage alloc] initWithContentsOfURL:[self getURLfromBookmarkData:_cta.assetBookmark]];
            }
        }
    }
}

- (IBAction)btnCreateCTATileClick:(id)sender {
    AVAssetTrack * videoATrack = [[self.playerView.player.currentItem.asset tracksWithMediaType:AVMediaTypeVideo] lastObject];
    CGSize videoSize = videoATrack.naturalSize;
    
    int _w = round(videoSize.width);
    _w = _w * 0.6;
    _w = round(_w);
    
    int _h = round(videoSize.height);
    _h = _h * 0.6;
    _h = round(_h);
    
    CALayer *backgroundLayer = [CALayer layer];
    [_dialogView setLayer:backgroundLayer];
    [_dialogView setWantsLayer:YES];
    
    CIFilter *blurFilter = [CIFilter filterWithName:@"CIGaussianBlur"];
    [blurFilter setValue:@"3.0" forKey:@"inputRadius"];
    
    _dialogView.backgroundFilters = [NSArray arrayWithObject:blurFilter];
    
    _txtCTASize.stringValue = [NSString stringWithFormat:@"Recommended CTA Image Max Width is %d and Max Height is %d", _w, _h];
    
    _projectDialog.hidden = true;
    _projectCreatedDialog.hidden = true;
    
    _dialogView.hidden = false;
    _ctaDialog.hidden = false;
    _btnCloseDialog.hidden = false;
}

-(void)resetTileEditorFromCTA{
    _plateview.hidden = NO;
    _transitionView.hidden = NO;
    _tileTextView.hidden = NO;
    _tileLinkView.hidden = NO;
    _chkUseProfilePicAsIcon.enabled = true;
    _chkUseProfilePicAsIcon.state = 1;
    _chkIsTileDefault.enabled = true;
    _chkIsTileDefault.state = 1;
    _chkShowTileInSidebox.enabled = true;
    _chkShowTileInSidebox.state = 1;
    _tileCategoryComboBox.enabled = true;
    _txtTileDescription.enabled = true;
    _toolBtn.enabled = true;
    _btnTileTransition.enabled = true;
    _btnTileLink.enabled = true;
    _btnTileText.enabled = true;
    _tileTransparencySlider.enabled = true;
    _lblCTAduration.enabled = false;
    _ctaDurationSlider.enabled = false;
    
    //_toolBtn.image = [NSImage imageNamed:@"tap"];
}

-(void)updateTileEditorForCTA{
    _plateview.hidden = NO;
    _transitionView.hidden = YES;
    _tileTextView.hidden = YES;
    _tileLinkView.hidden = YES;
    _chkUseProfilePicAsIcon.enabled = false;
    _chkUseProfilePicAsIcon.state = 0;
    _chkIsTileDefault.enabled = false;
    _chkIsTileDefault.state = 0;
    _chkShowTileInSidebox.enabled = false;
    _chkShowTileInSidebox.state = 0;
    _tileCategoryComboBox.enabled = false;
    _txtTileDescription.enabled = false;
    _toolBtn.enabled = false;
    _btnTileTransition.enabled = false;
    _btnTileLink.enabled = false;
    _btnTileText.enabled = false;
    _tileTransparencySlider.enabled = false;
    _lblCTAduration.enabled = true;
    _ctaDurationSlider.enabled = true;
    
    //_toolBtn.image = [NSImage imageNamed:@"tap"];
}
- (IBAction)ctaDurationChanged:(id)sender {
    _lblCTAduration.stringValue = [NSString stringWithFormat:@"Duration: %d secs", _ctaDurationSlider.intValue];
}


- (IBAction)btnAddCtaClick:(id)sender {
    _projectDialog.hidden = true;
    _projectCreatedDialog.hidden = true;
    
    _dialogView.hidden = true;
    _ctaDialog.hidden = true;
    _btnCloseDialog.hidden = true;
    
    [self hideDialogView];
    [self selectCTAImage];
}

#pragma mark - ImportVideoDelegate
-(void) openFileDialog {
    [self openVideo];
}

-(void) importYoutubeVideo:(NSString *)youtubeUrl {
    if (![youtubeUrl hasPrefix:@"https://www.youtube.com/"] && ![youtubeUrl hasPrefix:@"https://youtube.com/"]) {
        [self showAlert:@"Invalid Youtube url" message:@"example : https://www.youtube.com/watch?v=Dh-ULbQmmF8"];
        return;
    }
    _currentAssetFileUrl = [NSURL URLWithString:youtubeUrl];

    _boxProjectAssets.hidden = false;
    _imgMyProjectsIndicator.hidden = false;
    _imgAssetsIndicator.hidden = false;
    _boxAssetFiles.hidden = false;
    _btnAddFiles.hidden = false;

    Asset* currentAsset = [[Asset alloc] init];
    NSString * youtubeIdentifier = [[youtubeUrl componentsSeparatedByString: @"watch?v="] lastObject];

    [self showProgress];
    [[XCDYouTubeClient defaultClient] getVideoWithIdentifier:youtubeIdentifier completionHandler:^(XCDYouTubeVideo *video, NSError *error) {
        [self hideProgress];
        if (video)
        {
            currentAsset.assetName = video.title;
            currentAsset.assetFilePath = youtubeUrl;
            currentAsset.assetBookmark = nil;
            currentAsset.assetType = @"video";
//            NSString* stationPartner = [[NSUserDefaults standardUserDefaults] valueForKey:@"isStationPartner"];
//            if([stationPartner isEqualToString:@"Y"] || [stationPartner isEqualToString:@"y"])
//            {
//                if (video.duration > 25 * 60) {
//                    [self showAlert:@"Invalid Video Duration" message:@"The maximum allow video length is 25 minutes."];
//                    return;
//                }
//            }
//            else
//            {
//                if (video.duration > 5.5 * 60) {
//                    [self showAlert:@"Invalid Video Duration" message:@"The maximum allow video length is 5.5 minutes."];
//                    return;
//                }
//            }

            currentAsset.assetProjectId = _currentSelectedProject.projectId;
            currentAsset.assetBookmark = @"";

            //2. Insert in to assets table
            [_database open];

            BOOL result = [_database executeUpdate:@"INSERT INTO assets (ASSET_NAME, ASSET_PATH, ASSET_TYPE, ASSET_PRJ_ID, BOOKMARK_DATA) VALUES (?, ?, ?, ?, ?)", currentAsset.assetName, currentAsset.assetFilePath, currentAsset.assetType, [NSNumber numberWithInt:currentAsset.assetProjectId], @""];

            //3. Get last id and Update asset object
            currentAsset.assetId = (int)[_database lastInsertRowId];

            [_database close];

            //4. Add to current project's assets array
            [((Project*)[_userProjects objectAtIndex:_currentProjectIndex]).assets addObject:currentAsset];
            [_tblImportAssets reloadData];
        }
        else
        {
            [self hideProgress];
            // Handle error
            [self showAlert:@"Video Error" message:@"There is no found valid video."];
        }
    }];
}

-(void) onSave:(NSString *)savePath forThreshold:(double)threshold {
    if ([_currentAssetFileUrl.absoluteString hasPrefix: @"https://www.youtube.com"] || [_currentAssetFileUrl.absoluteString hasPrefix:@"https://youtube.com"]) {
        NSString * youtubeIdentifier = [[_currentAssetFileUrl.absoluteString componentsSeparatedByString: @"watch?v="] lastObject];
        [self showProgress];
        [[XCDYouTubeClient defaultClient] getVideoWithIdentifier:youtubeIdentifier completionHandler:^(XCDYouTubeVideo *video, NSError *error) {
            [self hideProgress];
            if (video)
            {
                if (video.streamURLs != nil) {
                    NSURL *streamURL = video.streamURL;

                    if (streamURL == nil) {
                        return;
                    }
                    [self detectScenesWithFFmpeg:streamURL savePath:savePath threshold:threshold];
                }
            }
            else
            {
                // Handle error
            }
        }];
    }
    else {
        [self detectScenesWithFFmpeg:_currentAssetFileUrl.path savePath:savePath threshold:threshold];
    }
}

-(void)detectScenesWithFFmpeg:(NSString *)filePath savePath: (NSString *) savePath threshold: (double) threshold
{
    NSString* launchPath = [[NSBundle mainBundle] pathForResource:@"ffmpeg" ofType:@""];
    if (launchPath == nil) {
        [self showAlert:@"Error" message:@"Failed to load ffmpeg"];
        return;
    }

    [self showProgress];
    _currentAssetFileUrl = [NSURL fileURLWithPath:savePath isDirectory:false];

    dispatch_async(dispatch_get_main_queue(), ^(void){
        NSString *logFilePath = [_currentAssetFileUrl path];
        NSString *dirPath = [logFilePath stringByDeletingLastPathComponent];
        NSString *frameDirPath = [NSString stringWithFormat:@"%@/frames", dirPath];

        BOOL isDir = false;
        NSFileManager *fileManager= [NSFileManager defaultManager];
        if(![fileManager fileExistsAtPath:frameDirPath isDirectory:&isDir])
            if(![fileManager createDirectoryAtPath:frameDirPath withIntermediateDirectories:YES attributes:nil error:NULL])
                NSLog(@"Error: Create folder failed %@", frameDirPath);

        NSTask *processTask = [[NSTask alloc] init];
        [processTask setLaunchPath:launchPath];

        NSString *stringPath = [NSString stringWithFormat:@"%@", filePath];
        [processTask setArguments: @[
            @"-i", stringPath,
            @"-filter_complex", [NSString stringWithFormat:@"select='gt(scene,%f)',metadata=print:file=%@", threshold, logFilePath],
            @"-vsync", @"0",
            [NSString stringWithFormat:@"%@/img%%03d.png", frameDirPath]
        ]];

        processTask.standardInput = [NSFileHandle fileHandleWithNullDevice];
        [processTask launch];
        [processTask waitUntilExit];

        //get pts
        NSPipe *pipe = [NSPipe pipe];
        NSFileHandle *file = pipe.fileHandleForReading;

        NSTask *task = [[NSTask alloc] init];
        task.launchPath = @"/usr/bin/grep";
        task.arguments = @[@"pts_time:[0-9.]*", logFilePath];
        task.standardOutput = pipe;

        [task launch];

        NSData *data = [file readDataToEndOfFile];
        [file closeFile];

        NSString *grepOutput = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
        NSLog (@"grep returned:\n%@", grepOutput);

        //create csv
        NSString *csvString = @"Scene Number ,Time Code ,Start time (seconds) ,Length(seconds)\n";
        AVAsset* asset = _playerView.player.currentItem.asset;
        double duration = CMTimeGetSeconds(asset.duration);
        //get video track
        NSArray *videoTracks = [asset tracksWithMediaType:AVMediaTypeVideo];
        AVAssetTrack *track = [videoTracks objectAtIndex:0];

        int frameRate = 25;
        if(track != nil) {
            frameRate = track.nominalFrameRate;
        }

        NSArray<NSString *> * array = [grepOutput componentsSeparatedByString:@"\n"];
        NSMutableArray *objectArray = [NSMutableArray array];
        for (NSString * item in array) {
            if ([[item stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]  length] > 0) {
                NSMutableDictionary *itemDict = [NSMutableDictionary dictionary];
                NSArray *itemArray = [item componentsSeparatedByString:@" "];
                int subIndex = 0;
                for (NSString *comp in itemArray) {
                    if ([comp length] == 0) {
                        continue;
                    }
                    NSString * value = [[comp componentsSeparatedByString:@":"] objectAtIndex:1];

                    if (subIndex == 0) {
                        [itemDict setObject:[NSString stringWithFormat:@"%d", [value intValue] + 1] forKey:@"Scene Number"];
                    }
                    else if (subIndex == 2) {
                        NSDate *date = [NSDate dateWithTimeIntervalSince1970:[value doubleValue]];
                        NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
                        [dateFormat setTimeZone:[NSTimeZone timeZoneWithName:@"GMT"]];
                        [dateFormat setDateFormat:@"HH:mm:ss.SSS"];
                        [itemDict setObject:[dateFormat stringFromDate:date] forKey:@"Time Code"];

                        [itemDict setObject:value forKey:@"Start Time"];
                    }

                    subIndex += 1;
                }

                [objectArray addObject:itemDict];
            }
        }

        for (int i = 0; i < [objectArray count]; i++) {
            NSDictionary *itemDict = [objectArray objectAtIndex:i];

            csvString = [csvString stringByAppendingFormat:@"%@ ,%@ ,%@", itemDict[@"Scene Number"], itemDict[@"Time Code"], itemDict[@"Start Time"]];

            if (i < [objectArray count] - 1) {
                NSDictionary *nextItem = [objectArray objectAtIndex:i+1];
                double startTime = [itemDict[@"Start Time"] doubleValue];
                double endTime = [nextItem[@"Start Time"] doubleValue];
                csvString = [csvString stringByAppendingFormat:@" ,%f\n", (endTime - startTime)];
            }
            else {
                if (track != nil) {
                    double startTime = [itemDict[@"Start Time"] doubleValue];
                    csvString = [csvString stringByAppendingFormat:@", %f\n", (duration - startTime)];
                }
            }
        }
        [fileManager removeItemAtURL:[NSURL fileURLWithPath:frameDirPath isDirectory:true] error:nil];
        [fileManager removeItemAtURL:[NSURL fileURLWithPath:logFilePath isDirectory:false] error:nil];

        NSString *name = [[logFilePath lastPathComponent] stringByDeletingPathExtension];
        name = [name stringByAppendingFormat:@"%@", @".csv"];
        name = [dirPath stringByAppendingFormat:@"/%@", name];
        NSURL *url = [NSURL fileURLWithPath:name];

        NSError *error = nil;
        if ([csvString writeToFile:name atomically:true encoding:NSUTF8StringEncoding error:&error]) {
            //import csv
            Asset* _a = nil;
            //load edl with csv file
            NSData *bookmark = nil;
            NSError *bookmarkError = nil;
            bookmark = [url bookmarkDataWithOptions:NSURLBookmarkCreationWithSecurityScope
                     includingResourceValuesForKeys:nil
                                      relativeToURL:nil // Make it app-scoped
                                              error:&bookmarkError];
            if (bookmarkError) {
                NSLog(@"Error creating bookmark for URL (%@): %@", filePath, bookmarkError);
                [self showAlert:@"Error" message:@"Error creating file bookmark."];
            }
            else{
                //1. Read file details and create asset object
                _a  = [self CreateAssetAndAddtoDB:url bookmark:bookmark];
            }

            //Asset* _a = [self CreateAssetAndAddtoDB:filePath];
            [_binFiles addObject:_a];
            [_conformEDLFiles addObject:_a];
            [_tblConformEDLs reloadData];
            [_tblImportAssets reloadData];

            for (int i = 0; i < _conformEDLFiles.count; i++) {
                // Get row at specified index
                ItemSelectionCellView *selectedRow = [_tblConformEDLs viewAtColumn:0 row:i makeIfNecessary:YES];
                selectedRow.ListItem.state = 0;
                selectedRow.isSelected = NO;
            }
            // Select last item
            int i = (int)_conformEDLFiles.count - 1;
            ItemSelectionCellView *selectedRow = [_tblConformEDLs viewAtColumn:0 row:i makeIfNecessary:YES];
            selectedRow.ListItem.state = 1;
            selectedRow.isSelected = YES;

            [self hideProgress];
            [self loadEDLfromCSV:url.path];
        }
        else {
            NSLog(@"%@", error);
            [self hideProgress];
            [self showAlert:@"Error" message:[error localizedDescription]];
        }
    });
}

- (IBAction)onQuickPlaceBtn1Clicked:(id)sender {
    [self addOrPlaceQuickPlaceSet:[self.quickPlaceSet indexOfSelectedItem] * 10 + 1 forcePlace:true];
}

- (IBAction)onQuickPlaceBtn2Clicked:(id)sender {
    [self addOrPlaceQuickPlaceSet:[self.quickPlaceSet indexOfSelectedItem] * 10 + 2 forcePlace:true];
}

- (IBAction)onQuickPlaceBtn3Clicked:(id)sender {
    [self addOrPlaceQuickPlaceSet:[self.quickPlaceSet indexOfSelectedItem] * 10 + 3 forcePlace:true];
}

- (IBAction)onQuickPlaceBtn4Clicked:(id)sender {
    [self addOrPlaceQuickPlaceSet:[self.quickPlaceSet indexOfSelectedItem] * 10 + 4 forcePlace:true];
}

- (IBAction)onQuickPlaceBtn5Clicked:(id)sender {
    [self addOrPlaceQuickPlaceSet:[self.quickPlaceSet indexOfSelectedItem] * 10 + 5 forcePlace:true];
}

- (IBAction)onQuickPlaceBtn6Clicked:(id)sender {
    [self addOrPlaceQuickPlaceSet:[self.quickPlaceSet indexOfSelectedItem] * 10 + 6 forcePlace:true];
}

- (IBAction)onQuickPlaceBtn7Clicked:(id)sender {
    [self addOrPlaceQuickPlaceSet:[self.quickPlaceSet indexOfSelectedItem] * 10 + 7 forcePlace:true];
}

- (IBAction)onQuickPlaceBtn8Clicked:(id)sender {
    [self addOrPlaceQuickPlaceSet:[self.quickPlaceSet indexOfSelectedItem] * 10 + 8 forcePlace:true];
}

- (IBAction)onQuickPlaceBtn9Clicked:(id)sender {
    [self addOrPlaceQuickPlaceSet:[self.quickPlaceSet indexOfSelectedItem] * 10 + 9 forcePlace:true];
}

- (IBAction)onQuickPlaceBtn10Clicked:(id)sender {
    [self addOrPlaceQuickPlaceSet:[self.quickPlaceSet indexOfSelectedItem] * 10 + 10 forcePlace:true];
}

- (void)addOrPlaceQuickPlaceSet:(int) number forcePlace:(BOOL)forcePlace {
    NSLog(@"add or place quick Place");
    if (currentSelectedADTile != nil && !forcePlace) {
        if (self.quickPlaceSetTiles == nil) {
            self.quickPlaceSetTiles = [NSMutableArray array];
            for(int i = 0; i < 20; i++) {
                [self.quickPlaceSetTiles addObject:[NSNull null]];
            }
        }
        
        [self.quickPlaceSetTiles replaceObjectAtIndex:number - 1 withObject:[currentSelectedADTile copy]];

        if (number > 10) {
            [self.quickPlaceSet selectItemAtIndex:1];
        }
        [self updateQuickPlaceBtnState];

        [self Save];
    }
    else {
        if (self.quickPlaceSetTiles != nil) {
            if (![[self.quickPlaceSetTiles objectAtIndex:number - 1] isKindOfClass:[NSNull class]]) {
                ADTile * tile = [self.quickPlaceSetTiles objectAtIndex:number - 1];

                if(currentSceneIndex == 0)
                {
                    NSAlert *alert = [[NSAlert alloc] init];
                    [alert addButtonWithTitle:@"Ok"];
                    [alert setMessageText:@"No selected scene"];
                    [alert setInformativeText:@"There is no proper selected scene to place tile"];
                    [alert setAlertStyle:NSWarningAlertStyle];

                    [alert runModal];

                    return;
                }

                [_playerView.player pause];

                [self syncFrames:_playerView.player.currentTime];

                if(((EDL*)(_EDLs[currentSceneIndex])).tiles == nil)
                    ((EDL*)(_EDLs[currentSceneIndex])).tiles = [NSMutableArray array];


                [((EDL*)(_EDLs[currentSceneIndex])).tiles addObject:[tile copy]];

                [self clearAllTileOnEditFrame];
                [self showADTilesForCurrentFrame];
                [self Save];
            }
        }
    }
}

- (void)removeQuickPlaceSet:(int) number {
    NSLog(@"remove quick Place");
    if (self.quickPlaceSetTiles == nil) {
        self.quickPlaceSetTiles = [NSMutableArray array];
        for(int i = 0; i < 20; i++) {
            [self.quickPlaceSetTiles addObject:[NSNull null]];
        }
    }
    else {
        [self.quickPlaceSetTiles replaceObjectAtIndex:[self.quickPlaceSet indexOfSelectedItem] * 10 + number - 1 withObject:[NSNull null]];

        [self updateQuickPlaceBtnState];

        [self Save];
    }
}

- (IBAction)onChangePlaceSet:(id)sender {
    [self updateQuickPlaceBtnState];
}

- (void) updateQuickPlaceBtnState {
    if (self.quickPlaceSetTiles != nil) {
        long currentSetNumber = [self.quickPlaceSet indexOfSelectedItem];
        for (int i = currentSetNumber * 10; i < (currentSetNumber + 1) * 10; i++) {
            if (![[self.quickPlaceSetTiles objectAtIndex:i] isKindOfClass: [NSNull class]]) {
                switch (i % 10) {
                    case 0:
                        [self setButtonTitle:_quickPlaceBtn1 toString:@"1" withColor:[NSColor systemRedColor] withSize:13];
                        break;
                    case 1:
                        [self setButtonTitle:_quickPlaceBtn2 toString:@"2" withColor:[NSColor systemRedColor] withSize:13];
                        break;
                    case 2:
                        [self setButtonTitle:_quickPlaceBtn3 toString:@"3" withColor:[NSColor systemRedColor] withSize:13];
                        break;
                    case 3:
                        [self setButtonTitle:_quickPlaceBtn4 toString:@"4" withColor:[NSColor systemRedColor] withSize:13];
                        break;
                    case 4:
                        [self setButtonTitle:_quickPlaceBtn5 toString:@"5" withColor:[NSColor systemRedColor] withSize:13];
                        break;
                    case 5:
                        [self setButtonTitle:_quickPlaceBtn6 toString:@"6" withColor:[NSColor systemRedColor] withSize:13];
                        break;
                    case 6:
                        [self setButtonTitle:_quickPlaceBtn7 toString:@"7" withColor:[NSColor systemRedColor] withSize:13];
                        break;
                    case 7:
                        [self setButtonTitle:_quickPlaceBtn8 toString:@"8" withColor:[NSColor systemRedColor] withSize:13];
                        break;
                    case 8:
                        [self setButtonTitle:_quickPlaceBtn9 toString:@"9" withColor:[NSColor systemRedColor] withSize:13];
                        break;
                    case 9:
                        [self setButtonTitle:_quickPlaceBtn10 toString:@"10" withColor:[NSColor systemRedColor] withSize:13];
                        break;

                    default:
                        break;
                }
            }
            else {
                switch (i % 10) {
                    case 0:
                        [self setButtonTitle:_quickPlaceBtn1 toString:@"1" withColor:[NSColor whiteColor] withSize:13];
                        break;
                    case 1:
                        [self setButtonTitle:_quickPlaceBtn2 toString:@"2" withColor:[NSColor whiteColor] withSize:13];
                        break;
                    case 2:
                        [self setButtonTitle:_quickPlaceBtn3 toString:@"3" withColor:[NSColor whiteColor] withSize:13];
                        break;
                    case 3:
                        [self setButtonTitle:_quickPlaceBtn4 toString:@"4" withColor:[NSColor whiteColor] withSize:13];
                        break;
                    case 4:
                        [self setButtonTitle:_quickPlaceBtn5 toString:@"5" withColor:[NSColor whiteColor] withSize:13];
                        break;
                    case 5:
                        [self setButtonTitle:_quickPlaceBtn6 toString:@"6" withColor:[NSColor whiteColor] withSize:13];
                        break;
                    case 6:
                        [self setButtonTitle:_quickPlaceBtn7 toString:@"7" withColor:[NSColor whiteColor] withSize:13];
                        break;
                    case 7:
                        [self setButtonTitle:_quickPlaceBtn8 toString:@"8" withColor:[NSColor whiteColor] withSize:13];
                        break;
                    case 8:
                        [self setButtonTitle:_quickPlaceBtn9 toString:@"9" withColor:[NSColor whiteColor] withSize:13];
                        break;
                    case 9:
                        [self setButtonTitle:_quickPlaceBtn10 toString:@"10" withColor:[NSColor whiteColor] withSize:13];
                        break;

                    default:
                        break;
                }
            }
        }
    }
}
- (IBAction)btnSelectedTilePlateClick:(id)sender {
    NSArray<NSIndexPath*>* myset = [_libraryCollectionView selectionIndexPaths].allObjects;

    if(myset.count > 0)
    {
        if(isTileInEditMode && currentEditingTile == myset[0].item)
        {
            NSAlert *alert = [[NSAlert alloc] init];
            [alert addButtonWithTitle:@"Yes"];
            [alert addButtonWithTitle:@"No"];
            [alert addButtonWithTitle:@"Cancel"];
            [alert setMessageText:@"Save Changes?"];
            [alert setInformativeText:@"Do you want to save changes to the current Tile before loading a new one?"];
            [alert setAlertStyle:NSWarningAlertStyle];

            NSModalResponse response = [alert runModal];

            if (response == NSAlertFirstButtonReturn) {
                //yes
                [self saveUpdateCurrentTile];
            }
            else if(response == NSAlertSecondButtonReturn){
                //no
            }
            else{
                //cancel
                return;
            }
        }
    }

    if (currentSelectedADTile != nil) {
        currentEditingTile = currentSelectedADTile;
        isTileInEditMode = true;
        currentEditingTileIndex = -1;

        [self btnPlateColorClick:nil];

        [self editSelectedTile];
    }
}

- (IBAction)btnSelectedTileTransitionClick:(id)sender {
    NSArray<NSIndexPath*>* myset = [_libraryCollectionView selectionIndexPaths].allObjects;

    if(myset.count > 0)
    {
        if(isTileInEditMode && currentEditingTile == myset[0].item)
        {
            NSAlert *alert = [[NSAlert alloc] init];
            [alert addButtonWithTitle:@"Yes"];
            [alert addButtonWithTitle:@"No"];
            [alert addButtonWithTitle:@"Cancel"];
            [alert setMessageText:@"Save Changes?"];
            [alert setInformativeText:@"Do you want to save changes to the current Tile before loading a new one?"];
            [alert setAlertStyle:NSWarningAlertStyle];

            NSModalResponse response = [alert runModal];

            if (response == NSAlertFirstButtonReturn) {
                //yes
                [self saveUpdateCurrentTile];
            }
            else if(response == NSAlertSecondButtonReturn){
                //no
            }
            else{
                //cancel
                return;
            }
        }
    }

    if (currentSelectedADTile != nil) {
        currentEditingTile = currentSelectedADTile;
        isTileInEditMode = true;
        currentEditingTileIndex = -1;

        [self btnTileTransitionClick:nil];

        [self editSelectedTile];
    }
}

- (IBAction)btnSelectedTileTextClick:(id)sender {
    NSArray<NSIndexPath*>* myset = [_libraryCollectionView selectionIndexPaths].allObjects;

    if(myset.count > 0)
    {
        if(isTileInEditMode && currentEditingTile == myset[0].item)
        {
            NSAlert *alert = [[NSAlert alloc] init];
            [alert addButtonWithTitle:@"Yes"];
            [alert addButtonWithTitle:@"No"];
            [alert addButtonWithTitle:@"Cancel"];
            [alert setMessageText:@"Save Changes?"];
            [alert setInformativeText:@"Do you want to save changes to the current Tile before loading a new one?"];
            [alert setAlertStyle:NSWarningAlertStyle];

            NSModalResponse response = [alert runModal];

            if (response == NSAlertFirstButtonReturn) {
                //yes
                [self saveUpdateCurrentTile];
            }
            else if(response == NSAlertSecondButtonReturn){
                //no
            }
            else{
                //cancel
                return;
            }
        }
    }

    if (currentSelectedADTile != nil) {
        currentEditingTile = currentSelectedADTile;
        isTileInEditMode = true;
        currentEditingTileIndex = -1;

        [self btnTileTextClick:nil];

        [self editSelectedTile];
    }
}

- (IBAction)btnSelectedTileLinksClick:(id)sender {
    NSArray<NSIndexPath*>* myset = [_libraryCollectionView selectionIndexPaths].allObjects;

    if(myset.count > 0)
    {
        if(isTileInEditMode && currentEditingTile == myset[0].item)
        {
            NSAlert *alert = [[NSAlert alloc] init];
            [alert addButtonWithTitle:@"Yes"];
            [alert addButtonWithTitle:@"No"];
            [alert addButtonWithTitle:@"Cancel"];
            [alert setMessageText:@"Save Changes?"];
            [alert setInformativeText:@"Do you want to save changes to the current Tile before loading a new one?"];
            [alert setAlertStyle:NSWarningAlertStyle];

            NSModalResponse response = [alert runModal];

            if (response == NSAlertFirstButtonReturn) {
                //yes
                [self saveUpdateCurrentTile];
            }
            else if(response == NSAlertSecondButtonReturn){
                //no
            }
            else{
                //cancel
                return;
            }
        }
    }

    if (currentSelectedADTile != nil) {
        currentEditingTile = currentSelectedADTile;
        isTileInEditMode = true;
        currentEditingTileIndex = -1;

        [self btnTileLinkClick:nil];

        [self editSelectedTile];
    }
}

- (IBAction)btnRemoveProjectClicked:(id)sender {
    Project *prj = [_userProjects objectAtIndex:_currentSelectedProjectIndex];
    [_userProjects removeObjectAtIndex:_currentSelectedProjectIndex];

    //remove from database
    [_database open];
    [_database executeUpdate:[NSString stringWithFormat:@"DELETE FROM ASSETS WHERE ASSET_PRJ_ID=%d COLLATE NOCASE", prj.projectId]];
    [_database executeUpdate:[NSString stringWithFormat:@"DELETE FROM TRANSITIONS WHERE TRANSITION_PRJ_ID=%d COLLATE NOCASE", prj.projectId]];
    [_database executeUpdate:[NSString stringWithFormat:@"DELETE FROM transition_sounds WHERE TRANSITION_PRJ_ID=%d COLLATE NOCASE", prj.projectId]];
    [_database executeUpdate:[NSString stringWithFormat:@"DELETE FROM PROJECTS WHERE PROJECT_NAME='%@' COLLATE NOCASE", prj.projectName]];
    NSLog(@"Error %d: %@", [_database lastErrorCode], [_database lastErrorMessage]);

    [_database close];
    [_tblProjectsList reloadData];

    if (_currentSelectedProjectIndex < _currentProjectIndex) {
        _currentProjectIndex -= 1;
    }
    _currentSelectedProjectIndex = -1;
    [self highlightSelectedProjectInList:-1];
    [_btnRemoveProject setHidden:true];
}
@end

