//
//  ExportViewController.m
//  Spokesman
//
//  Created by Chaitanya VRK on 20/09/16.
//  Copyright © 2016 troomobile. All rights reserved.
//

#import "ExportViewController.h"
#import "AFAmazonS3Manager.h"


@interface ExportViewController ()<AAPLMovieViewControllerDelegateExp,AAPLMovieTimelineUpdateDelgate,NSPopoverDelegate>
{
    NSMutableArray* teleSeriesData;
    NSString* mode;
}
@end

int _chkPublicstate;
NSString* txtExportTitle;

@implementation ExportViewController

AWSS3TransferManager* transition7zUploadManager;

NSString* auto_tags;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
    //[self setButtonTitle:_btnPost toString:@"POST" withColor:[NSColor whiteColor] withSize:18];
    //[self setButtonTitle:_btnCancel toString:@"Cancel" withColor:[NSColor whiteColor] withSize:14];
    
    NSView *contentView = [_exportThumbsScrollView contentView];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(boundDidChange:) name:NSViewBoundsDidChangeNotification object:contentView];
    auto_tags = @"";
    _exportThumbsView.delegate = self;
    _exportThumbsView.dataSource = self;
    NSNib *nib1 = [[NSNib alloc] initWithNibNamed:@"timelineItem" bundle:nil];
    [_exportThumbsView registerNib:nib1 forItemWithIdentifier:@"timelineItem"];
    
    self.IsUploadInProgress = false;
    
    _popoverViewController = [self.storyboard instantiateControllerWithIdentifier:@"GenrePopoverViewController"];
    _popoverViewController.isArtist = false;
    
    teleSeriesData = [NSMutableArray array];
    //[_chkSkit setWantsLayer:true];
    //_chkSkit.layer.backgroundColor = [NSColor whiteColor].CGColor;
    
    mode = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"mode"];
    
    if([mode isEqualToString:@"tele"])
    {
        _txtEpisodeNumber.enabled = true;
        _seriesDropdown.enabled = true;
    }
    else{
        _txtEpisodeNumber.enabled = false;
        _seriesDropdown.enabled = false;
    }
}

// -------------------------------------------------------------------------------
//  createPopover
// -------------------------------------------------------------------------------
- (void)createPopover
{
    if (self.myPopover == nil)
    {
        // create and setup our popover
        _myPopover = [[NSPopover alloc] init];
        
        // the popover retains us and we retain the popover,
        // we drop the popover whenever it is closed to avoid a cycle
        
        self.myPopover.contentViewController = self.popoverViewController;
        self.myPopover.contentSize = CGSizeMake(660, 336);
        
        self.myPopover.appearance = [NSAppearance appearanceNamed:NSAppearanceNameVibrantLight];
        
        self.myPopover.animates = true;
        
        // AppKit will close the popover when the user interacts with a user interface element outside the popover.
        // note that interacting with menus or panels that become key only when needed will not cause a transient popover to close.
        self.myPopover.behavior = NSPopoverBehaviorTransient;
        
        // so we can be notified when the popover appears or closes
        self.myPopover.delegate = self;
    }
}

- (void)boundDidChange:(NSNotification *)notification
{
    NSRect collectionViewVisibleRect = _exportThumbsView.visibleRect;
    //collectionViewVisibleRect.size.height += 300; //If you want some preloading for lower cells...
    
    for (int i = 0; i < _images.count; i++) {
        NSCollectionViewItem *item = [_exportThumbsView itemAtIndex:i];
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

-(void)loadSeries{
    
    NSString* userId = [[NSUserDefaults standardUserDefaults] valueForKey:@"userId"];
    NSString* accessToken = [[NSUserDefaults standardUserDefaults] valueForKey:@"accessToken"];
    
    NSMutableDictionary *postUserData = [[NSMutableDictionary alloc] init];
    [postUserData setValue:userId forKey:@"userId"];
    [postUserData setValue:accessToken forKey:@"accessToken"];
    [postUserData setValue:@"1" forKey:@"startRange"];
    [postUserData setValue:@"999" forKey:@"endRange"];
    
    
    NSString *url = [NSString stringWithFormat:@"%@%@",BASE_URL, @"getSeries"];
    
    NSError *error = nil;
    NSData* json = [NSJSONSerialization dataWithJSONObject:postUserData options:NSJSONWritingPrettyPrinted error:&error];
    
    NSString *jsonString;
    // If no errors, let's view the JSON
    if (json != nil && error == nil)
    {
        jsonString = [[NSString alloc] initWithData:json encoding:NSUTF8StringEncoding];
        
        NSLog(@"JSON: %@", jsonString);
        
        //[self showAlert:@"Send Search request" message:jsonString];
    }
    //}
    NSDictionary *params = @{@"data" : jsonString};
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    
    [manager POST:url parameters:params
          success:^(NSURLSessionDataTask * _Nonnull task, id _Nonnull responseObject)
     {
        
         NSMutableDictionary* response = responseObject;
         NSString* status = [response valueForKey:@"responseStatus"];
         NSLog(@"Status: %@", status);
         if([status isEqualToString:@"200"])
         {
             teleSeriesData = [[response valueForKey:@"responseObj"] mutableCopy];
             if(teleSeriesData != nil)
             {
                 NSLog(@"response not nil %lu", (unsigned long)teleSeriesData.count);
                 for (int i = 0; i < teleSeriesData.count; i++) {
                     NSDictionary* userData = teleSeriesData[i];
                     [_seriesDropdown addItemWithTitle:[userData objectForKey:@"title"]];
                     NSLog(@"User Name: %@", [userData valueForKey:@"firstName"]);
                }
             }
         }
         else
         {
             [self showAlert:@"Error getting series list" message:[NSString stringWithFormat:@"Invalid response code: %@", status] dismiss:false];
         }
     }
          failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error)
     {
         [self showAlert:@"Error getting series list:" message:error.localizedDescription dismiss:false];
         NSLog(@"Error finding artists");
     }];
}

-(void)viewDidAppear{
    _exportDialog.hidden = false;
    [_exportThumbsView reloadData];
    self.playerExport.player = [AVPlayer playerWithPlayerItem:[self.movieMutator makePlayerItem]];
    [self.playerExport.player seekToTime:CMTimeMakeWithSeconds(1, 1)];
    [_seriesDropdown removeAllItems];
    [_seriesDropdown addItemWithTitle:@"None"];
    if([mode isEqualToString:@"tele"])
        [self loadSeries];
    
    _projectName = [_projectName lowercaseString];
    _projectName = [_projectName stringByRemovingPercentEncoding];//:NSUTF8StringEncoding];
    
    _chkPublish.state = NSControlStateValueOff;

    _publishStartTime.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_GB"];
    _publishStartTime.minDate = [NSDate date];
    _publishStartTime.dateValue = [NSDate date];
    _publishEndTime.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_GB"];
    _publishEndTime.minDate = [NSDate date];
    _publishEndTime.dateValue = [NSDate date];

    _addSkitPicker.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_GB"];
    
    _btnPost.enabled = true;
    _btnCancel.enabled = true;
    
    if (@available(macOS 10.13, *)) {
        [self.exportThumbsView setFrameSize: self.exportThumbsView.collectionViewLayout.collectionViewContentSize];
    }
    
    NSPoint pt = NSMakePoint(0.0, [[_exportDialog documentView]
                                   bounds].size.height);
    [[_exportDialog documentView] scrollPoint:pt];
    auto_tags = @"";
    for (int i = 0; i < _EDLs.count; i++) {
        EDL* edl = (EDL*)_EDLs[i];
        
        if(edl.tiles.count > 0)
        {
            for (int t=0; t < edl.tiles.count; t++) {
                ADTile* tile = (ADTile*)edl.tiles[t];
                
                if(![auto_tags containsString:[NSString stringWithFormat:@"%@ %@, %@,",tile.firstName, tile.lastName, tile.nickName]])
                {
                    NSString* tagtext = [NSString stringWithFormat:@"%@ %@, %@,",tile.firstName, tile.lastName, tile.nickName];
                    auto_tags = [NSString stringWithFormat:@"%@ %@", auto_tags, tagtext];
                }
            }
        }
    }//end for
    
    if(auto_tags.length > 0)
    {
        auto_tags = [auto_tags stringByReplacingOccurrencesOfString:@"null" withString:@""];
        auto_tags = [auto_tags stringByReplacingOccurrencesOfString:@"(" withString:@""];
        auto_tags = [auto_tags stringByReplacingOccurrencesOfString:@")" withString:@""];
        
        //replace repeated commas with single comma
        NSError *error = nil;
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@",,+" options:NSRegularExpressionCaseInsensitive error:&error];
        auto_tags = [regex stringByReplacingMatchesInString:auto_tags options:0 range:NSMakeRange(0, [auto_tags length]) withTemplate:@","];

        //_txtTags.stringValue = auto_tags;
    }

    _txtTags.stringValue = auto_tags;
    
    if(_exportedProject != nil)
    {
        
        _txtExportTitle.stringValue = [_exportedProject valueForKey:@"title"];
        _txtExportArtist.stringValue = [_exportedProject valueForKey:@"artist"];
        
        if([_exportedProject valueForKey:@"tags"] != nil){
            /*if(auto_tags.length > 0 && auto_tags.length > ((NSString*)[_exportedProject valueForKey:@"tags"]).length)
                _txtTags.stringValue = [NSString stringWithFormat:@"%@, %@", auto_tags, [_exportedProject valueForKey:@"tags"]];
            else*/
                NSString* tags = [_exportedProject valueForKey:@"tags"];
            if(tags)
            _txtTags.stringValue = tags;
        }
        
        if([_exportedProject valueForKey:@"edlFilePath"] != nil)
            _txtStations.stringValue = [_exportedProject valueForKey:@"edlFilePath"];
        
        if([_exportedProject valueForKey:@"description"] != nil)
            _txtDescription.stringValue = [_exportedProject valueForKey:@"description"];
        
        if([_exportedProject valueForKey:@"isFeatured"] != nil)
        {
            if([[_exportedProject valueForKey:@"isFeatured"] isEqualToString:@"Y"])
            {
                _chkFeatured.state = NSControlStateValueOn;
            }
            else
            {
                _chkFeatured.state = NSControlStateValueOff;
            }
        }
        
        if([_exportedProject valueForKey:@"isSkit"] != nil)
        {
            if([[_exportedProject valueForKey:@"isSkit"] isEqualToString:@"true"])
            {
                _chkSkit.state = NSControlStateValueOn;
            }
            else
            {
                _chkSkit.state = NSControlStateValueOff;
            }
        }
        
        if([_exportedProject valueForKey:@"privilege"] != nil){
            if([[_exportedProject valueForKey:@"privilege"] isEqualToString:@"public"])
            {
                _chkPublic.state = NSControlStateValueOn;
                _chkPrivate.state = NSControlStateValueOff;
                _chkFollowers.state = NSControlStateValueOff;
            }
            else if([[_exportedProject valueForKey:@"privilege"] isEqualToString:@"private"])
            {
                _chkPublic.state = NSControlStateValueOff;
                _chkPrivate.state = NSControlStateValueOn;
                _chkFollowers.state = NSControlStateValueOff;
            }
            else
            {
                _chkPublic.state = NSControlStateValueOff;
                _chkPrivate.state = NSControlStateValueOff;
                _chkFollowers.state = NSControlStateValueOn;
            }
        }
    }

    unsigned int flags = NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay;
    NSCalendar* calendar = [NSCalendar currentCalendar];
    NSDateComponents* components = [calendar components:flags fromDate:[[NSDate alloc] init]];
    NSDate* dateOnly = [calendar dateFromComponents:components];

    flags = NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond;
    components = [calendar components:flags fromDate:dateOnly];
    NSDate * startTime = [calendar dateFromComponents:components];
    _startTimeMarker.dateValue = startTime;
    _startTimeMarker.minDate = startTime;
    _endTimeMarker.minDate = startTime;
    _addSkitPicker.minDate = startTime;
    _addSkitPicker.dateValue = startTime;

    startTime = [startTime dateByAddingTimeInterval: CMTimeGetSeconds(_playerExport.player.currentItem.asset.duration)];
    components = [calendar components:flags fromDate:startTime];
    NSDate* endTime = [calendar dateFromComponents:components];

    _startTimeMarker.maxDate = endTime;
    _endTimeMarker.maxDate = endTime;
    _endTimeMarker.dateValue = endTime;

    _addSkitPicker.maxDate = endTime;
}

-(NSInteger)collectionView:(NSCollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return _images.count;
}

-(NSCollectionViewItem *)collectionView:(NSCollectionView *)collectionView itemForRepresentedObjectAtIndexPath:(NSIndexPath *)indexPath
{
    if([collectionView.identifier isEqualToString:@"exportCollectionView"])
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
    else
        return nil;
}

-(void)collectionView:(NSCollectionView *)collectionView didSelectItemsAtIndexPaths:(NSSet<NSIndexPath *> *)indexPaths
{
    NSArray<NSIndexPath*>* myset = indexPaths.allObjects;
    if([collectionView.identifier isEqualToString:@"exportCollectionView"])
    {
//        NSNumber* secs = [_actualTimes objectAtIndex:myset[0].item];
//        [self.playerExport.player seekToTime:CMTimeMakeWithSeconds(secs.doubleValue, NSEC_PER_SEC)];
        [self.playerExport.player seekToTime:((EDL*)(_EDLs[myset[0].item])).time toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
        _selectedThumbnail = [_images objectAtIndex:myset[0].item];

        _imgCustomThumbnail.image = _selectedThumbnail;
    }
}

- (void)movieViewController:(NSUInteger)numberOfImages edlArray:(NSArray<NSValue *> *)edlArray completionHandler:(ImageGenerationCompletionHandler)completionHandler {
    [self.movieMutator generateImages:numberOfImages edlArray:(NSArray<NSValue *> *)edlArray withCompletionHandler:completionHandler];
}

- (BOOL)copyMovieTimeRange:(CMTimeRange)timeRange error:(NSError *)error { 
    return true;
}

- (BOOL)cutMovieTimeRange:(CMTimeRange)timeRange error:(NSError *)error { 
    return true;
}

- (BOOL)pasteMovieAtTime:(CMTime)time error:(NSError *)error { 
    return true;
}

- (CMTime)timeAtPercentage:(float)percentage { 
    return kCMTimeZero;
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

-(void)createAndUpload7z
{
    if(_mvidFiles.count > 0)
    {
        //Create APNG - Run in background
        NSString *execPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"7za"];
        //Arguments
        //NSString *out7zPath = @"";
        __block NSString *out7zPath = [_mvidFiles objectAtIndex:0];
        out7zPath = [out7zPath stringByDeletingLastPathComponent];
        out7zPath = [NSString stringWithFormat:@"%@/%@.7z",out7zPath,_projectName];
        
        NSMutableArray *args = [NSMutableArray array];
        
        [args addObject:@"a"];
        [args addObject:@"-mx=9"];
        [args addObject:[NSString stringWithFormat:@"-w%@",NSTemporaryDirectory()]];
        
        out7zPath = [out7zPath stringByReplacingOccurrencesOfString:@"file://" withString:@""];
        out7zPath = [out7zPath stringByReplacingOccurrencesOfString:@"file:" withString:@""];
        
        out7zPath = [out7zPath stringByRemovingPercentEncoding];
        
        [args addObject:out7zPath];
        
        
        for(int i = 0; i < _mvidFiles.count; i++)
        {
            NSString* currentFile = [_mvidFiles objectAtIndex:i];
            
            currentFile = [currentFile stringByReplacingOccurrencesOfString:@"file://" withString:@""];
            currentFile = [currentFile stringByReplacingOccurrencesOfString:@"file:" withString:@""];
            currentFile = [currentFile stringByRemovingPercentEncoding];
            
            [args addObject:currentFile];
        }
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            
            NSTask * task = [[NSTask alloc] init];
            
            //NSTask* task  = [NSTask launchedTaskWithLaunchPath:execPath arguments:args];
            [task setLaunchPath:execPath];
            [task setArguments:args];
            
            NSPipe * out = [NSPipe pipe];
            [task setStandardOutput:out];
            
            [task launch];
            [task waitUntilExit];
            
            int status = [task terminationStatus];
            
            NSFileHandle * read = [out fileHandleForReading];
            NSData * dataRead = [read readDataToEndOfFile];
            NSString * stringRead = [[NSString alloc] initWithData:dataRead encoding:NSUTF8StringEncoding];
            NSLog(@"output: %@", stringRead);
            
            if (status == 0) {
                dispatch_async(dispatch_get_main_queue(),
                               ^{
                    //[self showAlert:@"Successs" message:@"APNG genearated"];
                    //out7zPath = [out7zPath  stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLHostAllowedCharacterSet]];
                    [self upload7z:[[NSURL alloc] initFileURLWithPath:out7zPath]];
                });
            } else {
                dispatch_async(dispatch_get_main_queue(),
                               ^{
                    //[self showAlert:@"APNG Failed" message:@"Failed to generate APNG"];
                    [self showAlert:@"7z creation error" message:stringRead dismiss:false];
                });
            }
        });
    }
}

-(void)upload7z:(NSURL*)filePath
{
    //ToDo: Show Progress
    
    [self registerAWSCredentialsForTransferManagerWest];
    
    NSURL *_tileImgUrl = filePath;//[[NSURL alloc] initFileURLWithPath:[filePath path]];
    
    //Create Upload Request Object
    AWSS3TransferManagerUploadRequest *thumbnailUploadRequest = [AWSS3TransferManagerUploadRequest new];
    thumbnailUploadRequest.bucket = @"com.bon2.userdatastore";
    thumbnailUploadRequest.key = [NSString stringWithFormat:@"%@/%@/%@", [_username lowercaseString], _projectName, [filePath lastPathComponent]];
    thumbnailUploadRequest.body = _tileImgUrl;
    thumbnailUploadRequest.ACL = AWSS3ObjectCannedACLPublicRead;
    
    NSString* extension = [_tileImgUrl pathExtension];
    
    transition7zUploadManager = [AWSS3TransferManager S3TransferManagerForKey:@"ncalifornia"];
    
    //AWSKinesisRecorder *kinesisRecorder = [AWSKinesisRecorder defaultKinesisRecorder];
    
    //Start Upload
    [[transition7zUploadManager upload:thumbnailUploadRequest] continueWithBlock:^id(AWSTask *task) {
        if(task.faulted || task.cancelled)
        {
            [self showAlert:@"7z error" message:task.error.localizedDescription dismiss:false];
            NSLog(@"Upload Error: %@", _tileImgUrl);
        }
        else
        {
            NSLog(@"Upload Success: %@", _tileImgUrl);
        }
        
        return task;
    }];
}

-(NSString*)getSelectedSeriesId
{
    int i = (int)_seriesDropdown.indexOfSelectedItem;
    
    if(i > 0)
        return [teleSeriesData[i-1] objectForKey:@"seriesId"];
    else
        return @"-1";
    
}

-(NSString*) convertDateToTimeString:(NSDate *) date
{
    NSDateFormatter *dateFormatter=[[NSDateFormatter alloc]init];

    [dateFormatter setDateFormat:@"HH:mm:ss"];
    return [dateFormatter stringFromDate:date];
}

-(void)makePostAPICall:(NSString*)videoUrl thumbnailUrl:(NSString*)thumbnailUrl
{
    [self showupload:@"Sending metadata..."];
    
//    [self createAndUpload7z]; //removed by passion
    
    //return;
    
    //_btnExport.enabled = false;
    NSData *json;
    NSString *jsonString;
    
    NSMutableDictionary *postUserData = [[NSMutableDictionary alloc] init];
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    
    NSError *error = nil;
    
    NSString* userId = [[NSUserDefaults standardUserDefaults] valueForKey:@"userId"];
    NSString* accessToken = [[NSUserDefaults standardUserDefaults] valueForKey:@"accessToken"];
    
    NSString* _tags = @"";
    NSString* _stations = @"";
    NSString* _description = @"";
    NSString* _privilege = @"";
    NSString* _mediaTitle = txtExportTitle;
    
    if(_chkPublicstate == 1)
        _privilege = @"public";
    else if(_chkFollowers.state == 1)
        _privilege = @"followers";
    else
        _privilege = @"private";

    NSString *_filename = [NSString stringWithFormat:@"%@",[[_currentAssetFileUrl path] lastPathComponent]];
    if ([_currentAssetFileUrl.absoluteString hasPrefix: @"https://www.youtube.com"] || [_currentAssetFileUrl.absoluteString hasPrefix:@"https://youtube.com"]) {
        _filename = [[_currentAssetFileUrl.absoluteString componentsSeparatedByString: @"watch?v="] lastObject];
    }
    
    _tags = _txtTags.stringValue;
    
    _tags = [NSString stringWithFormat:@"%@,%@",_tags,_videoRating.titleOfSelectedItem];
    
    _stations = [self getStationsString];
    
    _stations = [_stations stringByAppendingString:_txtStations.stringValue];
    
    _description = _txtDescription.stringValue;
    
    [postUserData setValue:[userId lowercaseString] forKey:@"userId"];
    [postUserData setValue:accessToken forKey:@"accessToken"];
    [postUserData setValue:_privilege forKey:@"privilege"];
    [postUserData setValue:_filename forKey:@"fileName"];
    [postUserData setValue:@"video" forKey:@"fileType"];
    [postUserData setValue:_tags forKey:@"tags"];
    [postUserData setValue:_description forKey:@"description"];
    [postUserData setValue:[_projectName lowercaseString] forKey:@"projectName"];
    
    //[postUserData setValue:@"null" forKey:@"musicPrefId"];
    
    [postUserData setValue:videoUrl forKey:@"path"];
    [postUserData setValue:@"N" forKey:@"isAd"];
    [postUserData setValue:@"N" forKey:@"skipFlag"];
    [postUserData setValue:_txtExportArtist.stringValue forKey:@"artist"];
    [postUserData setValue:thumbnailUrl forKey:@"thumbnail"];
    
    //set episode and series
    if([mode isEqualToString:@"tele"])
    {
        [postUserData setValue:_txtEpisodeNumber.stringValue forKey:@"episodeNumber"];
        [postUserData setValue:[self getSelectedSeriesId] forKey:@"seriesId"];
    }
    else
    {
        [postUserData setValue:@"0" forKey:@"episodeNumber"];
        [postUserData setValue:@"-1" forKey:@"seriesId"];
    }
    
    NSUInteger dTotalSeconds = CMTimeGetSeconds(_playerExport.player.currentItem.asset.duration);
    
    [postUserData setValue:[NSString stringWithFormat:@"%02lu", (unsigned long)dTotalSeconds] forKey:@"mediaLength"];
    [postUserData setValue:_mediaTitle forKey:@"title"];
    [postUserData setValue:_mediaTitle forKey:@"songTitle"];
    
    if(_chkSkit.state == 1)
        [postUserData setValue:@"Y" forKey:@"isSkit"];
    else
        [postUserData setValue:@"N" forKey:@"isSkit"];
    
    if(_chkFeatured.state == 1)
        [postUserData setValue:@"Y" forKey:@"isFeatured"];
    else
        [postUserData setValue:@"N" forKey:@"isFeatured"];
    
    NSString* metadataJson = [self createEDLJson];

    [postUserData setValue:_stations forKey:@"edlFilePath"];
    [postUserData setValue:metadataJson forKey:@"metadataFilePath"];
    
    if(_chkPublish.state == NSControlStateValueOn)
    {
        NSDateFormatter * dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];
        [dateFormatter setDateFormat:@"yyyy'-'MM'-'dd"];
        
        [postUserData setValue:@"Y" forKey:@"isScheduled"];
        [postUserData setValue:[dateFormatter stringFromDate:_publishStartTime.dateValue] forKey:@"scheduledStartTime"];
        [postUserData setValue:[dateFormatter stringFromDate:_publishEndTime.dateValue] forKey:@"scheduledEndTime"];

        NSString* weekdaysStr = @"";

        if(_monday.state == 1) {
            weekdaysStr = [weekdaysStr stringByAppendingString:@"Monday,"];
        }
        if(_tuesday.state == 1) {
            weekdaysStr = [weekdaysStr stringByAppendingString:@"Tuesday,"];
        }
        if(_wendesday.state == 1) {
            weekdaysStr = [weekdaysStr stringByAppendingString:@"Wendesday,"];
        }
        if(_thursday.state == 1) {
            weekdaysStr = [weekdaysStr stringByAppendingString:@"Thursday,"];
        }
        if(_friday.state == 1) {
            weekdaysStr = [weekdaysStr stringByAppendingString:@"Friday,"];
        }
        if(_saturday.state == 1) {
            weekdaysStr = [weekdaysStr stringByAppendingString:@"Saturday,"];
        }
        if(_sunday.state == 1) {
            weekdaysStr = [weekdaysStr stringByAppendingString:@"Sunday,"];
        }

        [postUserData setValue:weekdaysStr forKey:@"scheduledWeekdays"];
    }
    else
    {
        [postUserData setValue:@"N" forKey:@"isScheduled"];
    }
    
    [postUserData setValue:_tierSelectors.stringValue forKey:@"rank"];
    //[postUserData setValue:songTitle forKey:@"albumId"];
    //[postUserData setValue:isSkit forKey:@"artistId"];
    //[postUserData setValue:isSkit forKey:@"location"];
    [postUserData setValue:@"false" forKey:@"isLibrary"];
    
    [postUserData setValue:@"12.991605" forKey:@"latitude"];
    [postUserData setValue:@"77.710187" forKey:@"longitude"];

    [postUserData setValue:_SourceRating.stringValue forKey:@"mediaSource"];
    [postUserData setValue:[self convertDateToTimeString:_startTimeMarker.dateValue] forKey:@"inTimeMarker"];
    [postUserData setValue:[self convertDateToTimeString:_endTimeMarker.dateValue] forKey:@"outTimeMarker"];
    [postUserData setValue:_textLocation.stringValue forKey:@"location"];

    [postUserData setValue:_textSkit.stringValue forKey:@"skitMarker"];
    
    NSString *url = [NSString stringWithFormat:@"%@%@",BASE_URL, ADD_USER_MEDIA];
    
    json = [NSJSONSerialization dataWithJSONObject:postUserData options:NSJSONWritingPrettyPrinted error:&error];
    
    // If no errors, let's view the JSON
    if (json != nil && error == nil)
    {
        jsonString = [[NSString alloc] initWithData:json encoding:NSUTF8StringEncoding];
        
        NSLog(@"JSON: %@", jsonString);
    }
    //}
    NSDictionary *params = @{@"data" : jsonString};
    
    [manager POST:url parameters:params
          success:^(NSURLSessionDataTask * _Nonnull task, id  _Nonnull responseObject)
     {
        self.IsUploadInProgress = false;
        [self hideupload];
        NSString *status = [responseObject valueForKey:@"responseStatus"];
        // NSString *status = [response valueForKey:@"responseStatus"];
        if ([status isEqualToString:@"503"])
        {
            [self showAlert:@"Error" message:@"Please try again." dismiss:false];
            NSLog(@"Error posting to Bon2");
            //_txtUploadStatus.stringValue = @"Error occurred.";
        }
        else if([status isEqualToString:@"200"])
        {
            [self showAlert:@"Success" message:@"Video uploaded successfully" dismiss:true];
            
            NSLog(@"Successfully posted to bon2");
            //_txtUploadStatus.stringValue = @"Completed.";
        }
        else{
            [self showAlert:@"Error" message:@"Please try again" dismiss:false];
            NSLog(@"Error posting to Bon2");
        }

        
        [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
            context.duration = 2;
            //_txtUploadStatus.animator.alphaValue = 0;
        }
                            completionHandler:^{
            //_txtUploadStatus.hidden = YES;
            //_txtUploadStatus.alphaValue = 1;
            //_txtUploadStatus.stringValue = @"Uploading...";
        }];
        
    }
          failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error)
     {
        self.IsUploadInProgress = false;
        //[self hideExportDialog];
        [self hideupload];
        [self showAlert:@"Error" message:@"Please try again" dismiss:false];
        //[_uploadProgress stopAnimation:_uploadProgress];
        //_uploadProgress.hidden = true;
        //_txtUploadStatus.stringValue = @"Error occurred.";
        ///_btnExport.enabled = true;
        ///_btnExport.state = 0;
        [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
            context.duration = 1;
            //_txtUploadStatus.animator.alphaValue = 0;
        }
                            completionHandler:^{
            //_txtUploadStatus.hidden = YES;
            //_txtUploadStatus.alphaValue = 1;
            //_txtUploadStatus.stringValue = @"Uploading...";
        }];
        NSLog(@"Error posting to Bon2");
    }
     ];
}


-(NSString*)getColorWithTransparecy:(NSColor*)color transparency:(CGFloat)transparency{
    NSString* hexString = [color hexadecimalValue];
    
    float alpha = 100 - transparency; //45
    alpha = alpha/100; //0.45
    alpha = alpha *255;//114.75
    int al = round(alpha); //115
    
    return [NSString stringWithFormat:@"%@0x%X", hexString, al];
    
    return hexString;
}

-(NSImage*)generateThumbnailAtTimeCode:(CMTime) time index:(int)currentSceneIndex{
    
    AVAssetImageGenerator *generate = [[AVAssetImageGenerator alloc] initWithAsset:_playerExport.player.currentItem.asset];
    generate.requestedTimeToleranceAfter = kCMTimeZero;
    generate.requestedTimeToleranceBefore = kCMTimeZero;
    generate.appliesPreferredTrackTransform = true;
    NSError *err = NULL;
    
    CGImageRef imgRef = [generate copyCGImageAtTime:time actualTime:NULL error:&err];
    
    NSImage* thumbnail = [[NSImage alloc] initWithCGImage:imgRef size:NSMakeSize(1920, 1024)];
    
    return thumbnail;
}

-(int)getSelectedStationsCount
{
    int i = 0;
    
    if(_stationBon2Tv.state == 1)
        i++;
    if(_stationComedy.state == 1)
        i++;
    if(_stationCooking.state == 1)
        i++;
    if(_stationDIY.state == 1)
        i++;
    if(_stationDance.state == 1)
        i++;
    if(_stationFamily.state == 1)
        i++;
    if(_stationFashion.state == 1)
        i++;
    if(_stationHealthBeauty.state == 1)
        i++;
    if(_stationJustForPics.state == 1)
        i++;
    if(_stationLifestyle.state == 1)
        i++;
    if(_stationMovieTrailers.state == 1)
        i++;
    if(_stationMusicVideos.state == 1)
        i++;
    if(_stationShortFilms.state == 1)
        i++;
    if(_stationSkit.state == 1)
        i++;
    if(_stationSports.state == 1)
        i++;
    if(_stationTVTeaser.state == 1)
        i++;
    if(_stationTravel.state == 1)
        i++;
    if(_stationBuyNow.state == 1)
        i++;
    
    if(_stationPrometheus.state == 1)
        i++;
    if(_stationTravelNinja.state == 1)
        i++;
    if(_stationNowThis.state == 1)
        i++;
    if(_stationWatchMojo.state == 1)
        i++;
    if(_stationShandy.state == 1)
        i++;
    if(_stationRecipe305.state == 1)
        i++;
    
    return i;
}

-(NSString*)getStationsString
{
    NSString* stationsStr = @"";
    
    if(_stationBon2Tv.state == 1)
        stationsStr = [stationsStr stringByAppendingString:@"BON2tv,"];
    if(_stationComedy.state == 1)
        stationsStr = [stationsStr stringByAppendingString:@"Comedy,"];
    if(_stationCooking.state == 1)
        stationsStr = [stationsStr stringByAppendingString:@"Cooking,Food,"];
    if(_stationDIY.state == 1)
        stationsStr = [stationsStr stringByAppendingString:@"D.I.Y and How to,"];
    if(_stationDance.state == 1)
        stationsStr = [stationsStr stringByAppendingString:@"Dance,"];
    if(_stationFamily.state == 1)
        stationsStr = [stationsStr stringByAppendingString:@"Family,"];
    if(_stationFashion.state == 1)
        stationsStr = [stationsStr stringByAppendingString:@"Fashion,"];
    if(_stationHealthBeauty.state == 1)
        stationsStr = [stationsStr stringByAppendingString:@"Health & Beauty,"];
    if(_stationJustForPics.state == 1)
        stationsStr = [stationsStr stringByAppendingString:@"Just for Pics,"];
    if(_stationLifestyle.state == 1)
        stationsStr = [stationsStr stringByAppendingString:@"Lifestyle,"];
    if(_stationMovieTrailers.state == 1)
        stationsStr = [stationsStr stringByAppendingString:@"Movie Trailers,"];
    if(_stationMusicVideos.state == 1)
        stationsStr = [stationsStr stringByAppendingString:@"Music Videos,"];
    if(_stationShortFilms.state == 1)
        stationsStr = [stationsStr stringByAppendingString:@"Short Films,"];
    if(_stationSkit.state == 1)
        stationsStr = [stationsStr stringByAppendingString:@"Skit,"];
    if(_stationSports.state == 1)
        stationsStr = [stationsStr stringByAppendingString:@"Sports,"];
    if(_stationTVTeaser.state == 1)
        stationsStr = [stationsStr stringByAppendingString:@"BON2 News,"]; // TV Teaser station used as BON2 News
    if(_stationTravel.state == 1)
        stationsStr = [stationsStr stringByAppendingString:@"Travel,"];
    if(_stationBuyNow.state == 1)
        stationsStr = [stationsStr stringByAppendingString:@"BuyNow,"];
    
    if(_stationPrometheus.state == 1)
        stationsStr = [stationsStr stringByAppendingString:@"Prometheus,"];
    if(_stationTravelNinja.state == 1)
        stationsStr = [stationsStr stringByAppendingString:@"Travel Ninja,"];
    if(_stationNowThis.state == 1)
        stationsStr = [stationsStr stringByAppendingString:@"NowThis,"];
    if(_stationWatchMojo.state == 1)
        stationsStr = [stationsStr stringByAppendingString:@"WatchMojo,"];
    if(_stationShandy.state == 1)
        stationsStr = [stationsStr stringByAppendingString:@"Shandy,"];
    if(_stationRecipe305.state == 1)
        stationsStr = [stationsStr stringByAppendingString:@"Recipe 305,"];
    
    if([mode isEqualToString:@"tele"])
        stationsStr = [stationsStr stringByAppendingString:@"tele"];
    
    return stationsStr;
}

-(bool)isSubGenreValid
{
    bool valid = true;
    
    NSString* substations = [_txtStations.stringValue lowercaseString];
    
    if([substations containsString:@"bon2tv"])
        valid = false;
    
    if([substations containsString:@"comedy"])
        valid = false;
    
    if([substations containsString:@"cooking"])
        valid = false;
    
    if([substations containsString:@"food"])
        valid = false;
    
    if([substations containsString:@"dance"])
        valid = false;
    
    if([substations containsString:@"health"] || [substations containsString:@"beauty"])
        valid = false;
    
    if([substations containsString:@"diy"] || [substations containsString:@"d.i.y"] || [substations containsString:@"how to"])
        valid = false;
    
    if([substations containsString:@"family"])
        valid = false;
    
    if([substations containsString:@"fashion"])
        valid = false;
    
    if([substations containsString:@"just for pics"])
        valid = false;
    
    if([substations containsString:@"lifestyle"])
        valid = false;
    
    if([substations containsString:@"movie trailers"])
        valid = false;
    
    if([substations containsString:@"music videos"])
        valid = false;
    
    if([substations containsString:@"short films"])
        valid = false;
    
    if([substations containsString:@"skit"])
        valid = false;
    
    if([substations containsString:@"sports"])
        valid = false;
    
    if([substations containsString:@"tv teaser"])
        valid = false;
    
    if([substations containsString:@"travel"])
        valid = false;
    
    if([substations containsString:@"Prometheus"])
        valid = false;
    
    if([substations containsString:@"Travel Ninja"])
        valid = false;
    
    if([substations containsString:@"NowThis"])
        valid = false;
    
    if([substations containsString:@"WatchMojo"])
        valid = false;
    
    if([substations containsString:@"Shandy"])
        valid = false;
    
    if([substations containsString:@"Recipe 305"])
        valid = false;
    
    if([substations containsString:@"BON2 News"])
        valid = false;
    
    return valid;
}

-(NSString*)createEDLJson{
    NSString* jsonString;
    
    NSMutableArray* editsArray = [NSMutableArray array];
    
    for (int i = 0; i < _EDLs.count; i++) {
        EDL* edl = (EDL*)_EDLs[i];
        
        if(edl.tiles.count > 0)
        {
            NSMutableArray* tilesArray = [NSMutableArray array];
            
            for (int t=0; t < edl.tiles.count; t++) {
                NSMutableDictionary *tileData = [[NSMutableDictionary alloc] init];
                
                ADTile* tile = [(ADTile*)edl.tiles[t] copy];
                
                [tileData setValue:[tile.tilePlateColor hexadecimalValue] forKey:@"platecolor"];
                float alpha = 100 - tile.transparency;
                alpha = alpha/100;
                [tileData setValue:[NSString stringWithFormat:@"%f",alpha] forKey:@"transparency"];
                [tileData setValue:tile.tileHeadingText forKey:@"heading"];
                [tileData setValue:tile.tileDescription forKey:@"desc"];
                [tileData setValue:tile.tileLink forKey:@"link"];
                
                [tileData setValue:tile.isTileDefault ? @"yes" : @"no" forKey:@"is_tile_default"];
                
                [tileData setValue:tile.showTileInSidebox ? @"yes" : @"no" forKey:@"show_tile_in_sidebox"];
                
                [tileData setValue:tile.useProfileAsIcon ? @"yes" : @"no" forKey:@"use_profile_as_icon"];
                
                [tileData setValue:tile.assetType forKey:@"asset_type"];
                
                [tileData setValue:tile.fbLink forKey:@"fb_Link"];
                [tileData setValue:tile.instaLink forKey:@"instagram_Link"];
                [tileData setValue:tile.pinterestLink forKey:@"pinterest_Link"];
                [tileData setValue:tile.twLink forKey:@"twitter_Link"];
                [tileData setValue:tile.websiteLink forKey:@"website_Link"];
                
                [tileData setValue:tile.artistId forKey:@"artist_id"];
                [tileData setValue:tile.productId forKey:@"product_id"];
                
                [tileData setValue:tile.tileCategory forKey:@"category"];
                
                [tileData setValue:tile.isGeneralCategory ? @"yes" : @"no" forKey:@"isGeneralCategory"];
                
                NSString *escapedTransitionString = [self getAWSURLForFile:[tile.tileTransition stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLHostAllowedCharacterSet]]];
                
                NSString *escapedTransitionAudio = [self getAWSURLForFile:[tile.tileAudioTransition stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLHostAllowedCharacterSet]]];
                
                [tileData setValue:escapedTransitionString forKey:@"transition"];
                [tileData setValue:tile.tileTransitionFrameCount forKey:@"transitionFrameCount"];
                [tileData setValue:escapedTransitionAudio forKey:@"audio_transition"];
                
                [tileData setValue:tile.isHeadingBold ? @"yes" : @"no" forKey:@"headingbold"];
                [tileData setValue:tile.isHeadingItalic ? @"yes" : @"no" forKey:@"headingitalic"];
                [tileData setValue:tile.isHeadingUnderline ? @"yes" : @"no" forKey:@"headingunderline"];
                [tileData setValue:[tile.headingColor hexadecimalValue] forKey:@"headingcolor"];
                
                [tileData setValue:tile.isDescBold ? @"yes" : @"no" forKey:@"descbold"];
                [tileData setValue:tile.isDescItalic ? @"yes" : @"no" forKey:@"descitalic"];
                [tileData setValue:tile.isDescUnderline ? @"yes" : @"no" forKey:@"descunderline"];
                [tileData setValue:[tile.descColor hexadecimalValue] forKey:@"desccolor"];
                [tileData setValue:tile.tileThumbnailImage.name forKey:@"thumbnail"];
                
                //convert to percentage
                tile.x_pos = tile.x_pos/_playerWidth;
                tile.x_pos = tile.x_pos * 100;
                
                tile.y_pos = tile.y_pos/_playerHeight;
                tile.y_pos = tile.y_pos * 100;
                
                float _h = tile.height/_playerHeight;
                _h = _h*100;
                
                //add tile height percentage to the y position
                if(![tile.assetType isEqualToString:@"cta"])
                    tile.y_pos += _h;
                
                //set tile position
                NSNumber *tile_x_pos = [NSNumber numberWithDouble:tile.x_pos];
                NSNumber *tile_y_pos = [NSNumber numberWithDouble:tile.y_pos];
                
                [tileData setValue:[tile_x_pos stringValue] forKey:@"x_pos"];
                [tileData setValue:[tile_y_pos stringValue] forKey:@"y_pos"];
                if([tile.assetType isEqualToString:@"people"] || [tile.assetType isEqualToString:@"product"])
                    tile.assetImageServerPath = tile.assetImagePath;
                else
                    tile.assetImageServerPath = [self getAWSURLForFile:[tile.assetImagePath lastPathComponent]];
                
                [tileData setValue:tile.assetImageServerPath forKey:@"image"];
                
                NSMutableDictionary *tileForEdit = [[NSMutableDictionary alloc] init];
                [tileForEdit setValue:tileData forKey:@"tile"];
                
                [tilesArray addObject:tileForEdit];
            }
            
            NSMutableDictionary *editData = [[NSMutableDictionary alloc] init];
            [editData setValue:[NSString stringWithFormat:@"%d", i] forKey:@"position"];
            [editData setValue:[NSString stringWithFormat:@"%f", CMTimeGetSeconds(edl.time)] forKey:@"frame_start_time"];
            
            if(i+1 < _EDLs.count)
            {
                [editData setValue:[NSString stringWithFormat:@"%f", CMTimeGetSeconds(((EDL*)_EDLs[i+1]).time)] forKey:@"frame_end_time"];
            }
            else{
                [editData setValue:[NSString stringWithFormat:@"%f", _playDuration] forKey:@"frame_end_time"];
            }
            [editData setValue:tilesArray forKey:@"tiles"];
            
            [editsArray addObject:editData];
        }
    }//end for
    
    NSMutableDictionary *projectEdits = [[NSMutableDictionary alloc] init];
    [projectEdits setValue:editsArray forKey:@"edits"];
    [projectEdits setValue:_projectName forKey:@"name"];
    
    NSMutableDictionary *project = [[NSMutableDictionary alloc] init];
    [project setValue:projectEdits forKey:@"project"];
    [project setValue:_projectName forKey:@"projectName"];
    
    NSNumber *videoWidth = [NSNumber numberWithDouble:_originalVideoWidth];
    NSNumber *videoHeight = [NSNumber numberWithDouble:_originalVideoHeight];
    
    [project setValue:[videoWidth stringValue] forKey:@"originalVideoWidth"];
    [project setValue:videoHeight forKey:@"originalVideoHeight"];
    
    NSError *error = nil;
    NSData *json = [NSJSONSerialization dataWithJSONObject:project options:NSJSONWritingPrettyPrinted error:&error];
    
    // If no errors, let's view the JSON
    if (json != nil && error == nil)
    {
        jsonString = [[NSString alloc] initWithData:json encoding:NSUTF8StringEncoding];
        
        NSLog(@"JSON: %@", jsonString);
    }
    
    return jsonString;
}

-(void)hideupload{
    dispatch_async(dispatch_get_main_queue(), ^{
        [_uploadProgressIndicator stopAnimation:self];
        _uploadProgressIndicator.hidden = true;
        _progressView.hidden = true;
        _btnPost.enabled = true;
        _btnCancel.enabled = true;
        
        
        
        //[self dismissViewController:self];
        
        
    });
}

-(void)showupload:(NSString*)status{
    dispatch_async(dispatch_get_main_queue(), ^{
        _btnPost.enabled = false;
        _btnCancel.enabled = false;
        _progressView.hidden = false;
        _uploadProgressIndicator.hidden = false;
        [_uploadProgressIndicator startAnimation:self];
        _uploadStatusText.stringValue = status;
    });
}

-(void)prepareForUpload{
    
    [self showupload:@"Preparing for upload..."];
    
    //1. Check if there are any embed tiles and Upload Images
    bool embed = false;
    for (int i = 0; i < _EDLs.count; i++) {
        EDL* edl = (EDL*)_EDLs[i];
        if(edl.tiles.count > 0)
        {
            embed = true;
            break;
        }
    }
    if(embed)
    {
        self.IsUploadInProgress = true;
        //Upload Tile Images
        [self uploadADTileImagesToS3];
    }
    else{
        self.IsUploadInProgress = true;
        //2. Upload Video and Thumbnail
        [self uploadToS3];
    }
}

int totalTileImagesToUpload;

-(void)uploadADTileImagesToS3{
    //upload each image using operation block
    
    totalTileImagesToUpload = 0;
    for (int i = 0; i < _EDLs.count; i++) {
        EDL* edl = (EDL*)_EDLs[i];
        
        if(edl.tiles.count > 0)
        {
            for (int t=0; t < edl.tiles.count; t++) {
                ADTile* tile = (ADTile*)edl.tiles[t];
                
                if(![tile.assetType isEqualToString:@"people"])
                    totalTileImagesToUpload++;
                
                //[self uploadADTileImageToS3:tile];
            }
        }
    }
    
    if(totalTileImagesToUpload > 0)
    {
        [self showupload:@"Uploading Images..."];
        
        for (int i = 0; i < _EDLs.count; i++) {
            EDL* edl = (EDL*)_EDLs[i];
            
            if(edl.tiles.count > 0)
            {
                for (int t=0; t < edl.tiles.count; t++) {
                    ADTile* tile = (ADTile*)edl.tiles[t];
                    
                    //totalTileImagesToUpload++;
                    if(![tile.assetType isEqualToString:@"people"])
                        [self uploadADTileImageToS3:tile];
                }
            }
        }
    }
    else
    {
        self.IsUploadInProgress = true;
        //2. Upload Video and Thumbnail
        [self uploadToS3];
    }
}

-(void)uploadADTileImageToS3:(ADTile*)tile
{
    //ToDo: Show Progress
    
    [self registerAWSCredentialsForTransferManager];
    
    NSURL *_tileImgUrl = [[NSURL alloc] initFileURLWithPath:tile.assetImagePath];
    
    //Create Upload Request Object
    AWSS3TransferManagerUploadRequest *thumbnailUploadRequest = [AWSS3TransferManagerUploadRequest new];
    thumbnailUploadRequest.bucket = @"mediadatastore";
    thumbnailUploadRequest.key = [NSString stringWithFormat:@"%@/%@/%@", [_username lowercaseString], _projectName, [[tile.assetImagePath lastPathComponent] lowercaseString]];//[tile.assetImagePath lastPathComponent];
    thumbnailUploadRequest.body = _tileImgUrl;
    thumbnailUploadRequest.ACL = AWSS3ObjectCannedACLPublicRead;
    
    //Get Image Type (PNG/JPEG)
    NSString* extension = [_tileImgUrl pathExtension];
    if([extension isEqualToString:@"png"])
        thumbnailUploadRequest.contentType = @"image/png";
    else
        thumbnailUploadRequest.contentType = @"image/jpeg";
    
    //Start Upload
    [[[AWSS3TransferManager S3TransferManagerForKey:@"USEast1S3TransferManager" ] upload:thumbnailUploadRequest] continueWithBlock:^id(AWSTask *task) {
        totalTileImagesToUpload--;
        if(task.error)
        {
            NSLog(@"Upload Error: %@", tile.assetImagePath);
        }
        else
        {
            NSLog(@"Upload Success: %@", tile.assetImagePath);
        }
        
        if(totalTileImagesToUpload == 0)
        {
            //ToDo: Hide Progress...
            [self uploadToS3];
        }
        
        return nil;
    }];
}

-(NSString*)getAWSURLForFile:(NSString*)filename{
    //NSString *filename = [NSString stringWithFormat:@"%@",[[_currentAssetFileUrl path] lastPathComponent]];
    //NSString *filename = [filepath lastPathComponent];
    if(_username != nil && filename != nil && _username.length > 0 && filename.length > 0){
        //return [NSString stringWithFormat:@"https://s3-us-west-1.amazonaws.com/com.bon2.mediadatastore/%@/%@", _username,filename];
        //return [NSString stringWithFormat:@"https://d7ern3kcbeqmo.cloudfront.net/%@/%@", [_username lowercaseString],filename];
        return [NSString stringWithFormat:@"https://d7ern3kcbeqmo.cloudfront.net/%@/%@/%@", [_username lowercaseString], _projectName, [filename lowercaseString]];
    }
    else
        return @"";
}

-(void)showAlert:(NSString*)title message:(NSString*)message dismiss:(Boolean)dismiss{
    
    dispatch_async(dispatch_get_main_queue(), ^{
        NSAlert *alert = [[NSAlert alloc] init];
        [alert addButtonWithTitle:@"OK"];
        [alert setMessageText:title];
        [alert setInformativeText:message];
        [alert setAlertStyle:NSWarningAlertStyle];
        
        if ([alert runModal] == NSAlertFirstButtonReturn) {
            // OK clicked, delete the record
            if(dismiss){
                [self dismissViewController:self];
            }
        }
    });
    
}

- (IBAction)btnPostClick:(id)sender {
    
    //[self makePostAPICall:@"http://www.bon2.com/video/2.mp4" thumbnailUrl:@"http://www.bon2.com/videothumbs/2.mp4"];
    //return;
    
    if([_txtExportTitle stringValue].length > 0)
    {
        if(_txtExportArtist.stringValue.length > 0)
        {
            if(_selectedThumbnail == nil)
            {
                [self showAlert:@"Video Thumbnail" message:@"Select a thumbnail for the video" dismiss:false];
            }
            else if([self getSelectedStationsCount] > 3)
            {
                [self showAlert:@"Stations" message:@"You cannot select more than 3 stations" dismiss:false];
            }
            else if(![self isSubGenreValid])
            {
                [self showAlert:@"Sub Genre" message:@"Sub Genre sholud not contain any main station names." dismiss:false];
            }
            else
            {
                if(_chkSkit.state == 1)
                {
                    if(CMTimeGetSeconds(_playerExport.player.currentItem.duration) > 65)
                    {
                        [self showAlert:@"Invalid Skit" message:@"The length of skit videos must be less than a minute." dismiss:false];
                        _btnPost.enabled = true;
                        _btnCancel.enabled = true;
                        return;
                    }
                }
                
                //Commented prepareForUpload for this build to test EDL json
                _btnPost.enabled = false;
                _btnCancel.enabled = false;
                _chkPublicstate = _chkPublic.state;
                txtExportTitle =_txtExportTitle.stringValue;
                
                if(_stationFamily.state == 1 || [_txtTags.stringValue containsString:@"family"] || [_txtTags.stringValue containsString:@"Family"]){
                    NSAlert *alert = [[NSAlert alloc] init];
                    [alert addButtonWithTitle:@"Post Video to Family Station"];
                    [alert addButtonWithTitle:@"Cancel"];
                    [alert setMessageText:@"Confirm posting to family station"];
                    [alert setInformativeText:@"Please adhere to our terms of service agreement when you are posting to the family station. Publishing  Family friendly content to a public arena is serious and by law, may have dire consequences if taken lightly."];
                    [alert setAlertStyle:NSWarningAlertStyle];
                    
                    NSInteger answer = [alert runModal] ;
                    
                    if (answer == NSAlertFirstButtonReturn)
                    {
                        [self prepareForUpload];
                    }
                    else
                    {
                        _btnPost.enabled = true;
                        _btnCancel.enabled = true;
                        return;
                    }
                }
                else
                {
                    [self prepareForUpload];
                }
                
                //Call MakePostAPICall directly to test JSON creation
                //[self makePostAPICall:@"http://www.bon2.com/video/2.mp4" thumbnailUrl:@"http://www.bon2.com/videothumbs/2.mp4"];
                
                //Comment this - added for this build
                //[self hideExportDialog];
                
                
                //[self uploadToS3];
                //[self hideExportDialog];
            }
        }
        else
        {
            [self showAlert:@"No album artist" message:@"Artist name is required." dismiss:false];
        }
    }
    else
    {
        [self showAlert:@"Empty Title" message:@"Please set a title for the video" dismiss:false];
    }
}

- (IBAction)btnCancelExportClick:(id)sender {
    
    //[self hideExportDialog];
    [self dismissViewController:self];
}
- (IBAction)chkPublicClick:(id)sender {
    _chkPublic.state = 1;
    _chkPrivate.state = 0;
    _chkFollowers.state = 0;
}

- (IBAction)chkFollowersClick:(id)sender {
    _chkPublic.state = 0;
    _chkPrivate.state = 0;
    _chkFollowers.state = 1;
}

- (IBAction)chkPrivateClick:(id)sender {
    _chkPublic.state = 0;
    _chkPrivate.state = 1;
    _chkFollowers.state = 0;
}

-(void)registerAWSCredentialsForTransferManagerWest
{
    //Register AWS Credentials or Transfer
    
    /*AWSCognitoCredentialsProvider *credentialsProvider = [[AWSCognitoCredentialsProvider alloc]
     initWithRegionType:AWSRegionUSEast1
     identityPoolId:@"us-east-1:03036b3e-de1f-4f39-be0f-deaf60a7a7ac"];*/
    
    AWSStaticCredentialsProvider *credentialsProvider = [[AWSStaticCredentialsProvider alloc] initWithAccessKey:AWS_ACCESS_KEY secretKey:AWS_SECRET_KEY];
    
    AWSServiceConfiguration *configuration = [[AWSServiceConfiguration alloc] initWithRegion:AWSRegionUSWest1 credentialsProvider:credentialsProvider];
    
    [AWSS3TransferManager registerS3TransferManagerWithConfiguration:configuration forKey:@"ncalifornia"];
}

-(void)registerAWSCredentialsForTransferManager
{
    //Register AWS Credentials or Transfer
    
    /*AWSCognitoCredentialsProvider *credentialsProvider = [[AWSCognitoCredentialsProvider alloc]
     initWithRegionType:AWSRegionUSEast1
     identityPoolId:@"us-east-1:03036b3e-de1f-4f39-be0f-deaf60a7a7ac"];*/
    
    AWSStaticCredentialsProvider *credentialsProvider = [[AWSStaticCredentialsProvider alloc] initWithAccessKey:AWS_ACCESS_KEY secretKey:AWS_SECRET_KEY];
    
    
    AWSServiceConfiguration *configuration = [[AWSServiceConfiguration alloc] initWithRegion:AWSRegionUSEast1 credentialsProvider:credentialsProvider];
    
    [AWSS3TransferManager registerS3TransferManagerWithConfiguration:configuration forKey:@"USEast1S3TransferManager"];
}

-(void)uploadToS3 {
    [self showupload:@"Uploading video..."];
    
    [self registerAWSCredentialsForTransferManager];
    //AWSS3TransferManager *transferManager = [AWSS3TransferManager defaultS3TransferManager];////
    
    NSString *filename = [[[_currentAssetFileUrl path] lastPathComponent] lowercaseString];

    if ([_currentAssetFileUrl.absoluteString hasPrefix: @"https://www.youtube.com"] || [_currentAssetFileUrl.absoluteString hasPrefix:@"https://youtube.com"]) {
        filename = [[_currentAssetFileUrl.absoluteString componentsSeparatedByString: @"watch?v="] lastObject];
    }

    AWSS3TransferManagerUploadRequest *uploadRequest = [AWSS3TransferManagerUploadRequest new];
    uploadRequest.bucket = @"mediadatastore";
    uploadRequest.key = [NSString stringWithFormat:@"%@/%@/%@", [_username lowercaseString], _projectName, filename];//[NSString stringWithFormat:@"%@/%@", [_username lowercaseString], filename];
    uploadRequest.body = _currentAssetFileUrl;
    uploadRequest.ACL = AWSS3ObjectCannedACLPublicRead;
    
    //uploadRequest.contentLength = [NSNumber numberWithUnsignedLongLong:fileSize];
    
    //_uploadProgress.hidden = false;
    //[_uploadProgress startAnimation:_uploadProgress];
    //_txtUploadStatus.hidden = false;
    
    __block NSString* videoUrl = nil;
    __block NSString* thumbnailUrl = nil;
    
    //_btnExport.enabled = false;
    //AWSS3 *s3Client = [AWSS3 defaultS3];
    //AWSS3HeadObjectRequest *request = [[AWSS3HeadObjectRequest alloc] init];
    //request.bucket = @"com.bon2.mediadatastore";
    //request.key = [NSString stringWithFormat:@"%@/%@", _username, filename];;
    
    /*
     AFAmazonS3Manager *s3Manager = [[AFAmazonS3Manager alloc] initWithAccessKeyID:@"AKIAJG5KES65EKTJM6EQ" secret:@"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"];
     s3Manager.requestSerializer.region = AFAmazonS3USWest1Region;
     s3Manager.requestSerializer.bucket = @"com.bon2.mediadatastore";*/

    if ([_currentAssetFileUrl.absoluteString hasPrefix: @"https://www.youtube.com"] || [_currentAssetFileUrl.absoluteString hasPrefix:@"https://youtube.com"]) {
        videoUrl = _currentAssetFileUrl.absoluteString;
    }
    else {
    
        NSString* _tvideoUrl = [self getAWSURLForFile:filename];

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
            //don't upload the video
            videoUrl = _tvideoUrl;
            if(videoUrl != nil && thumbnailUrl != nil)
            {
                [self makePostAPICall:videoUrl thumbnailUrl:thumbnailUrl];
                videoUrl = nil;
            }
        }
        else{
            //upload video
            [[[AWSS3TransferManager S3TransferManagerForKey:@"USEast1S3TransferManager" ] upload:uploadRequest] continueWithBlock:^id(AWSTask *task) {
                if(task.error)
                {
                    //[_uploadProgress stopAnimation:_uploadProgress];
                    //_uploadProgress.hidden = true;
                    //_btnExport.enabled = true;
                    //_btnExport.state = 0;
                    self.IsUploadInProgress = false;
                    NSLog(@"Video Upload Error:%@", task.error);
                }
                else
                {
                    //videoUrl = [NSString stringWithFormat:@"https://s3-us-west-1.amazonaws.com/com.bon2.mediadatastore/%@/%@", _username,filename];
                    //d2r5k0sucjqrm.cloudfront.net
                    //videoUrl = [NSString stringWithFormat:@"https://d7ern3kcbeqmo.cloudfront.net/%@/%@", [_username lowercaseString],filename];
                    videoUrl = [NSString stringWithFormat:@"https://d7ern3kcbeqmo.cloudfront.net/%@/%@/%@", [_username lowercaseString], _projectName, filename];
                    if(videoUrl != nil && thumbnailUrl != nil)
                    {
                        [self makePostAPICall:videoUrl thumbnailUrl:thumbnailUrl];
                        videoUrl = nil;
                    }
                    NSLog(@"%@", @"Uploaded.");
                }

                return nil;
            }];
        }
    }
    
    
    //upload thumbnail
    NSString* tempPath = [NSTemporaryDirectory() stringByAppendingString:@"tempThumb.png"];
    
    if(_imgCustomThumbnail.image == nil || CGSizeEqualToSize(_imgCustomThumbnail.image.size, CGSizeZero))
    {
        _selectedThumbnail = [self generateThumbnailAtTimeCode:_playerExport.player.currentTime index:1];
    }
    else{
        _selectedThumbnail = _imgCustomThumbnail.image;
    }
    
    CGImageRef cgRef = [_selectedThumbnail CGImageForProposedRect:NULL
                                                          context:nil
                                                            hints:nil];
    
    NSBitmapImageRep *newRep = [[NSBitmapImageRep alloc] initWithCGImage:cgRef];
    [newRep setSize:[_selectedThumbnail size]];   // if you want the same resolution
    
    NSDictionary *imageProps = [NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:1.0] forKey:NSImageCompressionFactor];
    
    NSData *pngData = [newRep representationUsingType:NSPNGFileType properties:imageProps];
    
    [pngData writeToFile:tempPath atomically:YES];
    NSURL *_selectedThumbnailUrl = [[NSURL alloc] initFileURLWithPath:tempPath];
    
    AWSS3TransferManagerUploadRequest *thumbnailUploadRequest = [AWSS3TransferManagerUploadRequest new];
    thumbnailUploadRequest.bucket = @"mediadatastore";
    thumbnailUploadRequest.key = [NSString stringWithFormat:@"%@/%@/%@.png", [_username lowercaseString], _projectName, filename];
    //[NSString stringWithFormat:@"%@/%@.png", [_username lowercaseString], filename];
    thumbnailUploadRequest.body = _selectedThumbnailUrl;
    thumbnailUploadRequest.ACL = AWSS3ObjectCannedACLPublicRead;
    thumbnailUploadRequest.contentType = @"image/png";
    //uploadRequest.contentLength = [NSNumber numberWithUnsignedLongLong:fileSize];
    
    
    //TODO [OPTIONAL]: Check if file exists before uploading
    /*
     AWSS3 *s3 = [AWSS3 defaultS3];
     AWSS3HeadObjectRequest *headObjectRequest = [AWSS3HeadObjectRequest new];
     headObjectRequest.bucket =  @"com.bon2.mediadatastore";;
     headObjectRequest.key = [NSString stringWithFormat:@"%@/%@", _username, filename];
     AWSTask* headObjTask = [s3 headObject:headObjectRequest];
     AWSS3HeadObjectOutput *headObjectOutput = headObjTask.result;
     */
    
    [[[AWSS3TransferManager S3TransferManagerForKey:@"USEast1S3TransferManager"] upload:thumbnailUploadRequest] continueWithBlock:^id(AWSTask *task) {
        if(task.error)
        {
            
            //[_uploadProgress stopAnimation:_uploadProgress];
            //_uploadProgress.hidden = true;
            
            NSLog(@"%@", task.error);
            //_btnExport.enabled = true;
            //_btnExport.state = 0;
            self.IsUploadInProgress = false;
        }
        else
        {
            dispatch_sync(dispatch_get_main_queue(), ^{
                //thumbnailUrl = [NSString stringWithFormat:@"https://s3-us-west-1.amazonaws.com/com.bon2.mediadatastore/%@/%@.png", _username, filename];
                //d2r5k0sucjqrm.cloudfront.net
                //thumbnailUrl = [NSString stringWithFormat:@"https://d7ern3kcbeqmo.cloudfront.net/%@/%@.png", [_username lowercaseString], filename];

                thumbnailUrl = [NSString stringWithFormat:@"https://d7ern3kcbeqmo.cloudfront.net/%@/%@/%@.png", [_username lowercaseString], _projectName, filename];
                //videoUrl = @"test";
                if(videoUrl != nil && thumbnailUrl != nil)
                {
                    [self makePostAPICall:videoUrl thumbnailUrl:thumbnailUrl];
                    thumbnailUrl = nil;
                }

                NSLog(@"%@", @"Image Uploaded.");
            });
        }
        
        return nil;
    }];
}
- (IBAction)familyStationSelected:(id)sender {
    if(_stationFamily.state == 1)
    {
        [_videoRating selectItemAtIndex:0];
        _videoRating.enabled = false;
    }
    else
    {
        [_videoRating selectItemAtIndex:2];
        _videoRating.enabled = true;
    }
}

- (IBAction)onAddSkitMarker:(id)sender {
    if (_textSkit.stringValue.length == 0) {
        _textSkit.stringValue = [self convertDateToTimeString:_addSkitPicker.dateValue];
    }
    else {
        _textSkit.stringValue = [NSString stringWithFormat:@"%@,%@", _textSkit.stringValue, [self convertDateToTimeString:_addSkitPicker.dateValue]];
    }
}

- (IBAction)videoRatingSelected:(id)sender {
    if([_videoRating.titleOfSelectedItem isEqualToString:@"Family"])
    {
        _stationFamily.state = 1;
    }
    else
        _stationFamily.state = 0;
}

- (IBAction)btnSelectTagsClick:(id)sender {
    [self createPopover];

    NSButton *targetButton = (NSButton *)sender;
    [self.myPopover showRelativeToRect:targetButton.bounds ofView:sender preferredEdge:NSMaxXEdge];
}

// -------------------------------------------------------------------------------
// Invoked on the delegate when the NSPopoverDidCloseNotification notification is sent.
// This method will also be invoked on the popover.
// -------------------------------------------------------------------------------
- (void)popoverDidClose:(NSNotification *)notification
{
    NSString *closeReason = [notification.userInfo valueForKey:NSPopoverCloseReasonKey];
    if (closeReason)
    {
        // closeReason can be:
        //      NSPopoverCloseReasonStandard
        //      NSPopoverCloseReasonDetachToWindow
        //
        // add new code here if you want to respond "after" the popover closes
        //
        NSString* selectedTags = @"";
        for (int i = 0; i < _popoverViewController.selectedGenres.count; i++) {
            selectedTags = [selectedTags stringByAppendingString:[NSString stringWithFormat:@"%@, ",[_popoverViewController.selectedGenres objectAtIndex:i]] ];
        }
        
        if([selectedTags hasSuffix:@", "])
        {
            selectedTags = [selectedTags substringToIndex:[selectedTags length] - 2];
        }
        
        _txtStations.stringValue = selectedTags;
    }
    
    // release our popover since it closed
    _myPopover = nil;
}

// -------------------------------------------------------------------------------
// Invoked on the delegate to give permission to detach popover as a separate window.
// -------------------------------------------------------------------------------
- (BOOL)popoverShouldDetach:(NSPopover *)popover
{
    return NO;
}
-(void)didSelectTimelinePoint:(NSPoint)point {

}
                                
                                - (void)didSelectTimelineRangeFromPoint:(NSPoint)fromPoint toPoint:(NSPoint)toPoint { 

}
                                
                                - (void)movieTimeline:(AAPLMovieTimeline *)timeline didUpdateCursorToPoint:(NSPoint)toPoint { 

}
                                
                                - (BOOL)commitEditingAndReturnError:(NSError *__autoreleasing  _Nullable * _Nullable)error { 
return true;
}
                                
                                - (void)encodeWithCoder:(nonnull NSCoder *)coder { 

}
                            

@end
