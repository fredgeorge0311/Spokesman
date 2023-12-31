/*
 Copyright 2010-2015 Amazon.com, Inc. or its affiliates. All Rights Reserved.

 Licensed under the Apache License, Version 2.0 (the "License").
 You may not use this file except in compliance with the License.
 A copy of the License is located at

 http://aws.amazon.com/apache2.0

 or in the "license" file accompanying this file. This file is distributed
 on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
 express or implied. See the License for the specific language governing
 permissions and limitations under the License.
 */

// #import <UIKit/UIKit.h>
#import "AWSCore.h"

NS_ASSUME_NONNULL_BEGIN

@class AWSS3TransferUtilityTask;
@class AWSS3TransferUtilityUploadTask;
@class AWSS3TransferUtilityDownloadTask;
@class AWSS3TransferUtilityExpression;
@class AWSS3TransferUtilityUploadExpression;
@class AWSS3TransferUtilityDownloadExpression;

/**
 The upload completion handler.

 @param task  The upload task object.
 @param error Returns the error object when the download failed.
 */
typedef void (^AWSS3TransferUtilityUploadCompletionHandlerBlock) (AWSS3TransferUtilityUploadTask *task,
                                                                  NSError * __nullable error);

/**
 The download completion handler.

 @param task     The download task object.
 @param location When downloading an Amazon S3 object to a file, returns a file URL of the returned object. Otherwise, returns `nil`.
 @param data     When downloading an Amazon S3 object as an `NSData`, returns the returned object as an instance of `NSData`. Otherwise, returns `nil`.
 @param error    Returns the error object when the download failed. Returns `nil` on successful downlaod.
 */
typedef void (^AWSS3TransferUtilityDownloadCompletionHandlerBlock) (AWSS3TransferUtilityDownloadTask *task,
                                                                    NSURL * __nullable location,
                                                                    NSData * __nullable data,
                                                                    NSError * __nullable error);

/**
 The upload progress feedback block.

 @param task                     The upload task object.
 @param bytesSent                The number of bytes sent since the last time this block was called.
 @param totalBytesSent           The total number of bytes sent so far.
 @param totalBytesExpectedToSend The expected length of the body data.

 @note Refer to `- URLSession:task:didSendBodyData:totalBytesSent:totalBytesExpectedToSend:` in `NSURLSessionTaskDelegate` for more details.
 */
typedef void (^AWSS3TransferUtilityUploadProgressBlock) (AWSS3TransferUtilityUploadTask *task,
                                                         int64_t bytesSent,
                                                         int64_t totalBytesSent,
                                                         int64_t totalBytesExpectedToSend);

/**
 The download progress feedback block.

 @param task                      The download task object.
 @param bytesWritten              The number of bytes transferred since the last time this delegate method was called.
 @param totalBytesWritten         The total number of bytes transferred so far.
 @param totalBytesExpectedToWrite The expected length of the file, as provided by the `Content-Length` header. If this header was not provided, the value is `NSURLSessionTransferSizeUnknown`.

 @note Refer to `- URLSession:downloadTask:didWriteData:totalBytesWritten:totalBytesExpectedToWrite:` in `NSURLSessionDownloadDelegate` for more details.
 */
typedef void (^AWSS3TransferUtilityDownloadProgressBlock) (AWSS3TransferUtilityDownloadTask *task,
                                                           int64_t bytesWritten,
                                                           int64_t totalBytesWritten,
                                                           int64_t totalBytesExpectedToWrite);

#pragma mark - AWSS3TransferUtility

/**
 A high-level utility for managing background uploads and downloads. The transfers continue even when the app is suspended. You must call `+ application:handleEventsForBackgroundURLSession:completionHandler:` in the `- application:handleEventsForBackgroundURLSession:completionHandler:` application delegate in order for the background transfer callback to work.
 */
@interface AWSS3TransferUtility : AWSService

/**
 Returns the singleton service client. If the singleton object does not exist, the SDK instantiates the default service client with `defaultServiceConfiguration` from `[AWSServiceManager defaultServiceManager]`. The reference to this object is maintained by the SDK, and you do not need to retain it manually.

 For example, set the default service configuration in `- application:didFinishLaunchingWithOptions:`

 *Swift*

     func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
         let credentialProvider = AWSCognitoCredentialsProvider(regionType: .USEast1, identityPoolId: "YourIdentityPoolId")
         let configuration = AWSServiceConfiguration(region: .USEast1, credentialsProvider: credentialProvider)
         AWSServiceManager.defaultServiceManager().defaultServiceConfiguration = configuration

         return true
     }

 *Objective-C*

     - (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
          AWSCognitoCredentialsProvider *credentialsProvider = [[AWSCognitoCredentialsProvider alloc] initWithRegionType:AWSRegionUSEast1
                                                                                                          identityPoolId:@"YourIdentityPoolId"];
          AWSServiceConfiguration *configuration = [[AWSServiceConfiguration alloc] initWithRegion:AWSRegionUSEast1
                                                                               credentialsProvider:credentialsProvider];
          [AWSServiceManager defaultServiceManager].defaultServiceConfiguration = configuration;

          return YES;
      }

 Then call the following to get the default service client:

 *Swift*

     let S3TransferUtility = AWSS3TransferUtility.defaultS3TransferUtility()

 *Objective-C*

     AWSS3TransferUtility *S3TransferUtility = [AWSS3TransferUtility defaultS3TransferUtility];

 @return The default service client.
 */
+ (nullable instancetype)defaultS3TransferUtility;

/**
 Creates a service client with the given service configuration and registers it for the key.

 For example, set the default service configuration in `- application:didFinishLaunchingWithOptions:`

 *Swift*

     func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
         let credentialProvider = AWSCognitoCredentialsProvider(regionType: .USEast1, identityPoolId: "YourIdentityPoolId")
         let configuration = AWSServiceConfiguration(region: .USWest2, credentialsProvider: credentialProvider)
         AWSS3TransferUtility.registerS3TransferUtilityWithConfiguration(configuration, forKey: "USWest2S3TransferUtility")

         return true
     }

 *Objective-C*

     - (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
         AWSCognitoCredentialsProvider *credentialsProvider = [[AWSCognitoCredentialsProvider alloc] initWithRegionType:AWSRegionUSEast1
                                                                                                         identityPoolId:@"YourIdentityPoolId"];
         AWSServiceConfiguration *configuration = [[AWSServiceConfiguration alloc] initWithRegion:AWSRegionUSWest2
                                                                              credentialsProvider:credentialsProvider];

         [AWSS3TransferUtility registerS3TransferUtilityWithConfiguration:configuration forKey:@"USWest2S3TransferUtility"];

         return YES;
     }

 Then call the following to get the service client:

 *Swift*

     let S3TransferUtility = AWSS3TransferUtility(forKey: "USWest2S3TransferUtility")

 *Objective-C*

     AWSS3TransferUtility *S3TransferUtility = [AWSS3TransferUtility S3TransferUtilityForKey:@"USWest2S3TransferUtility"];

 @warning After calling this method, do not modify the configuration object. It may cause unspecified behaviors.

 @param configuration A service configuration object.
 @param key           A string to identify the service client.
 */
+ (void)registerS3TransferUtilityWithConfiguration:(AWSServiceConfiguration *)configuration
                                            forKey:(NSString *)key;

/**
 Retrieves the service client associated with the key. You need to call `+ registerS3TransferUtilityWithConfiguration:forKey:` before invoking this method. If `+ registerS3TransferUtilityWithConfiguration:forKey:` has not been called in advance or the key does not exist, this method returns `nil`.

 For example, set the default service configuration in `- application:didFinishLaunchingWithOptions:`

     - (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
         AWSCognitoCredentialsProvider *credentialsProvider = [AWSCognitoCredentialsProvider credentialsWithRegionType:AWSRegionUSEast1 identityPoolId:@"YourIdentityPoolId"];
         AWSServiceConfiguration *configuration = [[AWSServiceConfiguration alloc] initWithRegion:AWSRegionUSWest2 credentialsProvider:credentialsProvider];

         [AWSS3TransferUtility registerS3TransferUtilityWithConfiguration:configuration forKey:@"USWest2S3TransferUtility"];

         return YES;
     }

 Then call the following to get the service client:

     AWSS3TransferUtility *S3TransferUtility = [AWSS3TransferUtility S3ForKey:@"USWest2S3TransferUtility"];

 @param key A string to identify the service client.

 @return An instance of the service client.
 */
+ (nullable instancetype)S3TransferUtilityForKey:(NSString *)key;

/**
 Removes the service client associated with the key and release it.

 @warning Before calling this method, make sure no method is running on this client.

 @param key A string to identify the service client.
 */
+ (void)removeS3TransferUtilityForKey:(NSString *)key;

/**
 Tells `AWSS3TransferUtility` that events related to a URL session are waiting to be processed. This method needs to be called in the `- application:handleEventsForBackgroundURLSession:completionHandler:` applicatoin delegate for `AWSS3TransferUtility` to work.

 @param application       The singleton app object.
 @param identifier        The identifier of the URL session requiring attention.
 @param completionHandler The completion handler to call when you finish processing the events.
 */
// + (void)interceptApplication:(UIApplication *)application
// handleEventsForBackgroundURLSession:(NSString *)identifier
//            completionHandler:(void (^)())completionHandler;

/**
 Saves the `NSData` to a temporary directory and uploads it to the specified Amazon S3 bucket.

 @param data              The data to upload.
 @param bucket            The Amazon S3 bucket name.
 @param key               The Amazon S3 object key name.
 @param contentType       `Content-Type` of the data.
 @param expression        The container object to configure the upload request.
 @param completionHandler The completion hanlder when the upload completes.

 @return Returns an instance of `AWSTask`. On successful initialization, `task.result` contains an instance of `AWSS3TransferUtilityUploadTask`.
 */
- (AWSTask *)uploadData:(NSData *)data
                 bucket:(NSString *)bucket
                    key:(NSString *)key
            contentType:(NSString *)contentType
             expression:(nullable AWSS3TransferUtilityUploadExpression *)expression
       completionHander:(nullable AWSS3TransferUtilityUploadCompletionHandlerBlock)completionHandler;

/**
 Uploads the file to the specified Amazon S3 bucket.

 @param fileURL           The file URL of the file to upload.
 @param bucket            The Amazon S3 bucket name.
 @param key               The Amazon S3 object key name.
 @param contentType       `Content-Type` of the file.
 @param expression        The container object to configure the upload request.
 @param completionHandler The completion hanlder when the upload completes.

 @return Returns an instance of `AWSTask`. On successful initialization, `task.result` contains an instance of `AWSS3TransferUtilityUploadTask`.
 */
- (AWSTask *)uploadFile:(NSURL *)fileURL
                 bucket:(NSString *)bucket
                    key:(NSString *)key
            contentType:(NSString *)contentType
             expression:(nullable AWSS3TransferUtilityUploadExpression *)expression
       completionHander:(nullable AWSS3TransferUtilityUploadCompletionHandlerBlock)completionHandler;

/**
 Downloads the specified Amazon S3 object as `NSData`.

 @param bucket            The Amazon S3 bucket name.
 @param key               The Amazon S3 object key name.
 @param expression        The container object to configure the download request.
 @param completionHandler The completion hanlder when the download completes.

 @return Returns an instance of `AWSTask`. On successful initialization, `task.result` contains an instance of `AWSS3TransferUtilityDownloadTask`.
 */
- (AWSTask *)downloadDataFromBucket:(NSString *)bucket
                                key:(NSString *)key
                         expression:(nullable AWSS3TransferUtilityDownloadExpression *)expression
                   completionHander:(nullable AWSS3TransferUtilityDownloadCompletionHandlerBlock)completionHandler;

/**
 Downloads the specified Amazon S3 object to a file URL.

 @param fileURL           The file URL to download the object to. Should not be `nil` even though it is marked as `nullable`.
 @param bucket            The Amazon S3 bucket name.
 @param key               The Amazon S3 object key name.
 @param expression        The container object to configure the download request.
 @param completionHandler The completion hanlder when the download completes.

 @return Returns an instance of `AWSTask`. On successful initialization, `task.result` contains an instance of `AWSS3TransferUtilityDownloadTask`.
 */
- (AWSTask *)downloadToURL:(nullable NSURL *)fileURL
                    bucket:(NSString *)bucket
                       key:(NSString *)key
                expression:(nullable AWSS3TransferUtilityDownloadExpression *)expression
          completionHander:(nullable AWSS3TransferUtilityDownloadCompletionHandlerBlock)completionHandler;

// Without disabling the nullability completeness, the compiler shows the following warning (Xcode 6.4):
// Block pointer is missing a nullability type specifier (__nonnull or __nullable)
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnullability-completeness"

/**
 Assigns progress feedback and completion handler blocks. This method should be called when the app was suspended while the transfer is still happening.

 @param uploadBlocksAssigner   The block for assigning the upload pregree feedback and completion handler blocks.
 @param downloadBlocksAssigner The block for assigning the download pregree feedback and completion handler blocks.
 */
- (void)enumerateToAssignBlocksForUploadTask:(nullable void (^)(AWSS3TransferUtilityUploadTask *uploadTask,
                                                                AWSS3TransferUtilityUploadProgressBlock * __nullable uploadProgressBlockReference,
                                                                AWSS3TransferUtilityUploadCompletionHandlerBlock * __nullable completionHandlerReference))uploadBlocksAssigner
                                downloadTask:(nullable void (^)(AWSS3TransferUtilityDownloadTask *downloadTask,
                                                                AWSS3TransferUtilityDownloadProgressBlock * __nullable downloadProgressBlockReference,
                                                                AWSS3TransferUtilityDownloadCompletionHandlerBlock * __nullable completionHandlerReference))downloadBlocksAssigner;
#pragma clang diagnostic pop

/**
 Retrieves all running tasks.

 @return An array of `AWSS3TransferUtilityTask`.
 */
- (AWSTask *)getAllTasks;

/**
 Retrieves all running upload tasks.

 @return An array of `AWSS3TransferUtilityUploadTask`.
 */
- (AWSTask *)getUploadTasks;

/**
 Retrieves all running download tasks.

 @return An array of `AWSS3TransferUtilityDownloadTask`.
 */
- (AWSTask *)getDownloadTasks;

@end

#pragma mark - AWSS3TransferUtilityTasks

/**
 The task object to represent a upload or download task.
 */
@interface AWSS3TransferUtilityTask : NSObject

/**
 An identifier uniquely identifies the task within a given `AWSS3TransferUtility` instance.
 */
@property (readonly) NSUInteger taskIdentifier;

/**
 The Amazon S3 bucket name associated with the transfer.
 */
@property (readonly) NSString *bucket;

/**
 The Amazon S3 object key name associated with the transfer.
 */
@property (readonly) NSString *key;

/**
 Cancels the task.
 */
- (void)cancel;

/**
 Resumes the task, if it is suspended.
 */
- (void)resume;

/**
 Temporarily suspends a task.
 */
- (void)suspend;

@end

/**
 The task object to represent a upload task.
 */
@interface AWSS3TransferUtilityUploadTask : AWSS3TransferUtilityTask

@end

/**
 The task object to represent a download task.
 */
@interface AWSS3TransferUtilityDownloadTask : AWSS3TransferUtilityTask

@end

#pragma mark - AWSS3TransferUtilityExpressions

/**
 The expression object for configuring a upload or download task.
 */
@interface AWSS3TransferUtilityExpression : NSObject

/**
 The request parameters. It is an dictionary of `<NSString *, NSString *>`.
 */
@property (readonly, nullable) NSDictionary *requestParameters;

/**
 Sets value for the request parameter.

 @param value            The request parameter value.
 @param requestParameter The key for the request parameter value.
 */
- (void)setValue:(NSString *)value forRequestParameter:(NSString *)requestParameter;

@end

/**
 The expression object for configuring a upload task.
 */
@interface AWSS3TransferUtilityUploadExpression : AWSS3TransferUtilityExpression

/**
 The upload progress feedback block.
 */
@property (copy, nonatomic, nullable) AWSS3TransferUtilityUploadProgressBlock uploadProgress;

/**
 `Content-Type` of the uploading data.
 */
@property (strong, nonatomic, nullable) NSString *contentMD5;

@end

/**
 The expression object for configuring a download task.
 */
@interface AWSS3TransferUtilityDownloadExpression : AWSS3TransferUtilityExpression

/**
 The download progress feedback block.
 */
@property (copy, nonatomic, nullable) AWSS3TransferUtilityDownloadProgressBlock downloadProgress;

@end

NS_ASSUME_NONNULL_END
