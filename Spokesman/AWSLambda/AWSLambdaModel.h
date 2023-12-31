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

#import <Foundation/Foundation.h>
#import "AWSNetworking.h"
#import "AWSModel.h"

FOUNDATION_EXPORT NSString *const AWSLambdaErrorDomain;

typedef NS_ENUM(NSInteger, AWSLambdaErrorType) {
    AWSLambdaErrorUnknown,
    AWSLambdaErrorIncompleteSignature,
    AWSLambdaErrorInvalidClientTokenId,
    AWSLambdaErrorMissingAuthenticationToken,
    AWSLambdaErrorCodeStorageExceeded,
    AWSLambdaErrorInvalidParameterValue,
    AWSLambdaErrorInvalidRequestContent,
    AWSLambdaErrorPolicyLengthExceeded,
    AWSLambdaErrorRequestTooLarge,
    AWSLambdaErrorResourceConflict,
    AWSLambdaErrorResourceNotFound,
    AWSLambdaErrorService,
    AWSLambdaErrorTooManyRequests,
    AWSLambdaErrorUnsupportedMediaType,
};

typedef NS_ENUM(NSInteger, AWSLambdaEventSourcePosition) {
    AWSLambdaEventSourcePositionUnknown,
    AWSLambdaEventSourcePositionTrimHorizon,
    AWSLambdaEventSourcePositionLatest,
};

typedef NS_ENUM(NSInteger, AWSLambdaInvocationType) {
    AWSLambdaInvocationTypeUnknown,
    AWSLambdaInvocationTypeEvent,
    AWSLambdaInvocationTypeRequestResponse,
    AWSLambdaInvocationTypeDryRun,
};

typedef NS_ENUM(NSInteger, AWSLambdaLogType) {
    AWSLambdaLogTypeUnknown,
    AWSLambdaLogTypeNone,
    AWSLambdaLogTypeTail,
};

typedef NS_ENUM(NSInteger, AWSLambdaRuntime) {
    AWSLambdaRuntimeUnknown,
    AWSLambdaRuntimeNodejs,
};

@class AWSLambdaAddPermissionRequest;
@class AWSLambdaAddPermissionResponse;
@class AWSLambdaCreateEventSourceMappingRequest;
@class AWSLambdaCreateFunctionRequest;
@class AWSLambdaDeleteEventSourceMappingRequest;
@class AWSLambdaDeleteFunctionRequest;
@class AWSLambdaEventSourceMappingConfiguration;
@class AWSLambdaFunctionCode;
@class AWSLambdaFunctionCodeLocation;
@class AWSLambdaFunctionConfiguration;
@class AWSLambdaGetEventSourceMappingRequest;
@class AWSLambdaGetFunctionConfigurationRequest;
@class AWSLambdaGetFunctionRequest;
@class AWSLambdaGetFunctionResponse;
@class AWSLambdaGetPolicyRequest;
@class AWSLambdaGetPolicyResponse;
@class AWSLambdaInvocationRequest;
@class AWSLambdaInvocationResponse;
@class AWSLambdaInvokeAsyncRequest;
@class AWSLambdaInvokeAsyncResponse;
@class AWSLambdaListEventSourceMappingsRequest;
@class AWSLambdaListEventSourceMappingsResponse;
@class AWSLambdaListFunctionsRequest;
@class AWSLambdaListFunctionsResponse;
@class AWSLambdaRemovePermissionRequest;
@class AWSLambdaUpdateEventSourceMappingRequest;
@class AWSLambdaUpdateFunctionCodeRequest;
@class AWSLambdaUpdateFunctionConfigurationRequest;

/**
 
 */
@interface AWSLambdaAddPermissionRequest : AWSRequest


/**
 <p>The AWS Lambda action you want to allow in this statement. Each Lambda action is a string starting with "lambda:" followed by the API name (see <a>Operations</a>). For example, "lambda:CreateFunction". You can use wildcard ("lambda:*") to grant permission for all AWS Lambda actions. </p>
 */
@property (nonatomic, strong) NSString *action;

/**
 <p>Name of the Lambda function whose access policy you are updating by adding a new permission.</p><p> You can specify an unqualified function name (for example, "Thumbnail") or you can specify Amazon Resource Name (ARN) of the function (for example, "arn:aws:lambda:us-west-2:account-id:function:ThumbNail"). AWS Lambda also allows you to specify only the account ID qualifier (for example, "account-id:Thumbnail"). Note that the length constraint applies only to the ARN. If you specify only the function name, it is limited to 64 character in length. </p>
 */
@property (nonatomic, strong) NSString *functionName;

/**
 <p>The principal who is getting this permission. It can be Amazon S3 service Principal ("s3.amazonaws.com") if you want Amazon S3 to invoke the function, an AWS account ID if you are granting cross-account permission, or any valid AWS service principal such as "sns.amazonaws.com". For example, you might want to allow a custom application in another AWS account to push events to AWS Lambda by invoking your function. </p>
 */
@property (nonatomic, strong) NSString *principal;

/**
 <p>The AWS account ID (without a hyphen) of the source owner. If the <code>SourceArn</code> identifies a bucket, then this is the bucket owner's account ID. You can use this additional condition to ensure the bucket you specify is owned by a specific account (it is possible the bucket owner deleted the bucket and some other AWS account created the bucket). You can also use this condition to specify all sources (that is, you don't specify the <code>SourceArn</code>) owned by a specific account. </p>
 */
@property (nonatomic, strong) NSString *sourceAccount;

/**
 <p>This is optional; however, when granting Amazon S3 permission to invoke your function, you should specify this field with the bucket Amazon Resource Name (ARN) as its value. This ensures that only events generated from the specified bucket can invoke the function. </p><important>If you add a permission for the Amazon S3 principal without providing the source ARN, any AWS account that creates a mapping to your function ARN can send events to invoke your Lambda function from Amazon S3.</important>
 */
@property (nonatomic, strong) NSString *sourceArn;

/**
 <p>A unique statement identifier.</p>
 */
@property (nonatomic, strong) NSString *statementId;

@end

/**
 
 */
@interface AWSLambdaAddPermissionResponse : AWSModel


/**
 <p>The permission statement you specified in the request. The response returns the same as a string using "\" as an escape character in the JSON. </p>
 */
@property (nonatomic, strong) NSString *statement;

@end

/**
 
 */
@interface AWSLambdaCreateEventSourceMappingRequest : AWSRequest


/**
 <p>The largest number of records that AWS Lambda will retrieve from your event source at the time of invoking your function. Your function receives an event with all the retrieved records. The default is 100 records.</p>
 */
@property (nonatomic, strong) NSNumber *batchSize;

/**
 <p>Indicates whether AWS Lambda should begin polling the event source. </p>
 */
@property (nonatomic, strong) NSNumber *enabled;

/**
 <p>The Amazon Resource Name (ARN) of the Amazon Kinesis or the Amazon DynamoDB stream that is the event source. Any record added to this stream could cause AWS Lambda to invoke your Lambda function, it depends on the <code>BatchSize</code>. AWS Lambda POSTs the Amazon Kinesis event, containing records, to your Lambda function as JSON.</p>
 */
@property (nonatomic, strong) NSString *eventSourceArn;

/**
 <p>The Lambda function to invoke when AWS Lambda detects an event on the stream.</p><p> You can specify an unqualified function name (for example, "Thumbnail") or you can specify Amazon Resource Name (ARN) of the function (for example, "arn:aws:lambda:us-west-2:account-id:function:ThumbNail"). AWS Lambda also allows you to specify only the account ID qualifier (for example, "account-id:Thumbnail"). Note that the length constraint applies only to the ARN. If you specify only the function name, it is limited to 64 character in length. </p>
 */
@property (nonatomic, strong) NSString *functionName;

/**
 <p>The position in the stream where AWS Lambda should start reading. For more information, go to <a href="http://docs.aws.amazon.com/kinesis/latest/APIReference/API_GetShardIterator.html#Kinesis-GetShardIterator-request-ShardIteratorType">ShardIteratorType</a> in the <i>Amazon Kinesis API Reference</i>. </p>
 */
@property (nonatomic, assign) AWSLambdaEventSourcePosition startingPosition;

@end

/**
 
 */
@interface AWSLambdaCreateFunctionRequest : AWSRequest


/**
 <p>The code for the Lambda function. </p>
 */
@property (nonatomic, strong) AWSLambdaFunctionCode *code;

/**
 <p>A short, user-defined function description. Lambda does not use this value. Assign a meaningful description as you see fit.</p>
 */
@property (nonatomic, strong) NSString *detail;

/**
 <p>The name you want to assign to the function you are uploading. You can specify an unqualified function name (for example, "Thumbnail") or you can specify Amazon Resource Name (ARN) of the function (for example, "arn:aws:lambda:us-west-2:account-id:function:ThumbNail"). AWS Lambda also allows you to specify only the account ID qualifier (for example, "account-id:Thumbnail"). Note that the length constraint applies only to the ARN. If you specify only the function name, it is limited to 64 character in length. The function names appear in the console and are returned in the <a>ListFunctions</a> API. Function names are used to specify functions to other AWS Lambda APIs, such as <a>Invoke</a>. </p>
 */
@property (nonatomic, strong) NSString *functionName;

/**
 <p>The function within your code that Lambda calls to begin execution. For Node.js, it is the <i>module-name</i>.<i>export</i> value in your function. </p>
 */
@property (nonatomic, strong) NSString *handler;

/**
 <p>The amount of memory, in MB, your Lambda function is given. Lambda uses this memory size to infer the amount of CPU and memory allocated to your function. Your function use-case determines your CPU and memory requirements. For example, a database operation might need less memory compared to an image processing function. The default value is 128 MB. The value must be a multiple of 64 MB.</p>
 */
@property (nonatomic, strong) NSNumber *memorySize;

/**
 <p>The Amazon Resource Name (ARN) of the IAM role that Lambda assumes when it executes your function to access any other Amazon Web Services (AWS) resources. For more information, see <a href="http://docs.aws.amazon.com/lambda/latest/dg/lambda-introduction.html">AWS Lambda: How it Works</a></p>
 */
@property (nonatomic, strong) NSString *role;

/**
 <p>The runtime environment for the Lambda function you are uploading. Currently, Lambda supports only "nodejs" as the runtime.</p>
 */
@property (nonatomic, assign) AWSLambdaRuntime runtime;

/**
 <p>The function execution time at which Lambda should terminate the function. Because the execution time has cost implications, we recommend you set this value based on your expected execution time. The default is 3 seconds. </p>
 */
@property (nonatomic, strong) NSNumber *timeout;

@end

/**
 
 */
@interface AWSLambdaDeleteEventSourceMappingRequest : AWSRequest


/**
 <p>The event source mapping ID.</p>
 */
@property (nonatomic, strong) NSString *UUID;

@end

/**
 
 */
@interface AWSLambdaDeleteFunctionRequest : AWSRequest


/**
 <p>The Lambda function to delete.</p><p> You can specify an unqualified function name (for example, "Thumbnail") or you can specify Amazon Resource Name (ARN) of the function (for example, "arn:aws:lambda:us-west-2:account-id:function:ThumbNail"). AWS Lambda also allows you to specify only the account ID qualifier (for example, "account-id:Thumbnail"). Note that the length constraint applies only to the ARN. If you specify only the function name, it is limited to 64 character in length. </p>
 */
@property (nonatomic, strong) NSString *functionName;

@end

/**
 <p>Describes mapping between an Amazon Kinesis stream and a Lambda function.</p>
 */
@interface AWSLambdaEventSourceMappingConfiguration : AWSModel


/**
 <p>The largest number of records that AWS Lambda will retrieve from your event source at the time of invoking your function. Your function receives an event with all the retrieved records.</p>
 */
@property (nonatomic, strong) NSNumber *batchSize;

/**
 <p>The Amazon Resource Name (ARN) of the Amazon Kinesis stream that is the source of events.</p>
 */
@property (nonatomic, strong) NSString *eventSourceArn;

/**
 <p>The Lambda function to invoke when AWS Lambda detects an event on the stream.</p>
 */
@property (nonatomic, strong) NSString *functionArn;

/**
 <p>The UTC time string indicating the last time the event mapping was updated.</p>
 */
@property (nonatomic, strong) NSDate *lastModified;

/**
 <p>The result of the last AWS Lambda invocation of your Lambda function.</p>
 */
@property (nonatomic, strong) NSString *lastProcessingResult;

/**
 <p>The state of the event source mapping. It can be "Creating", "Enabled", "Disabled", "Enabling", "Disabling", "Updating", or "Deleting".</p>
 */
@property (nonatomic, strong) NSString *state;

/**
 <p>The reason the event source mapping is in its current state. It is either user-requested or an AWS Lambda-initiated state transition.</p>
 */
@property (nonatomic, strong) NSString *stateTransitionReason;

/**
 <p>The AWS Lambda assigned opaque identifier for the mapping.</p>
 */
@property (nonatomic, strong) NSString *UUID;

@end

/**
 <p>The code for the Lambda function.</p>
 */
@interface AWSLambdaFunctionCode : AWSModel


/**
 <p>Amazon S3 bucket name where the .zip file containing your deployment package is stored. This bucket must reside in the same AWS region where you are creating the Lambda function. </p>
 */
@property (nonatomic, strong) NSString *s3Bucket;

/**
 <p>The Amazon S3 object (the deployment package) key name you want to upload. </p>
 */
@property (nonatomic, strong) NSString *s3Key;

/**
 <p>The Amazon S3 object (the deployment package) version you want to upload.</p>
 */
@property (nonatomic, strong) NSString *s3ObjectVersion;

/**
 <p>A base64-encoded .zip file containing your deployment package. For more information about creating a .zip file, go to <a href="http://docs.aws.amazon.com/lambda/latest/dg/intro-permission-model.html#lambda-intro-execution-role.html">Execution Permissions</a> in the <i>AWS Lambda Developer Guide</i>. </p>
 */
@property (nonatomic, strong) NSData *zipFile;

@end

/**
 <p>The object for the Lambda function location.</p>
 */
@interface AWSLambdaFunctionCodeLocation : AWSModel


/**
 <p>The presigned URL you can use to download the function's .zip file that you previously uploaded. The URL is valid for up to 10 minutes.</p>
 */
@property (nonatomic, strong) NSString *location;

/**
 <p>The repository from which you can download the function.</p>
 */
@property (nonatomic, strong) NSString *repositoryType;

@end

/**
 <p>A complex type that describes function metadata.</p>
 */
@interface AWSLambdaFunctionConfiguration : AWSModel


/**
 <p>The size, in bytes, of the function .zip file you uploaded.</p>
 */
@property (nonatomic, strong) NSNumber *codeSize;

/**
 <p>The user-provided description.</p>
 */
@property (nonatomic, strong) NSString *detail;

/**
 <p>The Amazon Resource Name (ARN) assigned to the function.</p>
 */
@property (nonatomic, strong) NSString *functionArn;

/**
 <p>The name of the function.</p>
 */
@property (nonatomic, strong) NSString *functionName;

/**
 <p>The function Lambda calls to begin executing your function.</p>
 */
@property (nonatomic, strong) NSString *handler;

/**
 <p>The timestamp of the last time you updated the function.</p>
 */
@property (nonatomic, strong) NSString *lastModified;

/**
 <p>The memory size, in MB, you configured for the function. Must be a multiple of 64 MB.</p>
 */
@property (nonatomic, strong) NSNumber *memorySize;

/**
 <p>The Amazon Resource Name (ARN) of the IAM role that Lambda assumes when it executes your function to access any other Amazon Web Services (AWS) resources. </p>
 */
@property (nonatomic, strong) NSString *role;

/**
 <p>The runtime environment for the Lambda function.</p>
 */
@property (nonatomic, assign) AWSLambdaRuntime runtime;

/**
 <p>The function execution time at which Lambda should terminate the function. Because the execution time has cost implications, we recommend you set this value based on your expected execution time. The default is 3 seconds. </p>
 */
@property (nonatomic, strong) NSNumber *timeout;

@end

/**
 
 */
@interface AWSLambdaGetEventSourceMappingRequest : AWSRequest


/**
 <p>The AWS Lambda assigned ID of the event source mapping.</p>
 */
@property (nonatomic, strong) NSString *UUID;

@end

/**
 
 */
@interface AWSLambdaGetFunctionConfigurationRequest : AWSRequest


/**
 <p>The name of the Lambda function for which you want to retrieve the configuration information.</p><p> You can specify an unqualified function name (for example, "Thumbnail") or you can specify Amazon Resource Name (ARN) of the function (for example, "arn:aws:lambda:us-west-2:account-id:function:ThumbNail"). AWS Lambda also allows you to specify only the account ID qualifier (for example, "account-id:Thumbnail"). Note that the length constraint applies only to the ARN. If you specify only the function name, it is limited to 64 character in length. </p>
 */
@property (nonatomic, strong) NSString *functionName;

@end

/**
 
 */
@interface AWSLambdaGetFunctionRequest : AWSRequest


/**
 <p>The Lambda function name. </p><p> You can specify an unqualified function name (for example, "Thumbnail") or you can specify Amazon Resource Name (ARN) of the function (for example, "arn:aws:lambda:us-west-2:account-id:function:ThumbNail"). AWS Lambda also allows you to specify only the account ID qualifier (for example, "account-id:Thumbnail"). Note that the length constraint applies only to the ARN. If you specify only the function name, it is limited to 64 character in length. </p>
 */
@property (nonatomic, strong) NSString *functionName;

@end

/**
 <p>This response contains the object for the Lambda function location (see <a>API_FunctionCodeLocation</a></p>
 */
@interface AWSLambdaGetFunctionResponse : AWSModel


/**
 <p>The object for the Lambda function location.</p>
 */
@property (nonatomic, strong) AWSLambdaFunctionCodeLocation *code;

/**
 <p>A complex type that describes function metadata.</p>
 */
@property (nonatomic, strong) AWSLambdaFunctionConfiguration *configuration;

@end

/**
 
 */
@interface AWSLambdaGetPolicyRequest : AWSRequest


/**
 <p>Function name whose access policy you want to retrieve. </p><p> You can specify an unqualified function name (for example, "Thumbnail") or you can specify Amazon Resource Name (ARN) of the function (for example, "arn:aws:lambda:us-west-2:account-id:function:ThumbNail"). AWS Lambda also allows you to specify only the account ID qualifier (for example, "account-id:Thumbnail"). Note that the length constraint applies only to the ARN. If you specify only the function name, it is limited to 64 character in length. </p>
 */
@property (nonatomic, strong) NSString *functionName;

@end

/**
 
 */
@interface AWSLambdaGetPolicyResponse : AWSModel


/**
 <p>The access policy associated with the specified function. The response returns the same as a string using "\" as an escape character in the JSON. </p>
 */
@property (nonatomic, strong) NSString *policy;

@end

/**
 
 */
@interface AWSLambdaInvocationRequest : AWSRequest


/**
 <p>Using the <code>ClientContext</code> you can pass client-specific information to the Lambda function you are invoking. You can then process the client information in your Lambda function as you choose through the context variable. For an example of a ClientContext JSON, go to <a href="http://docs.aws.amazon.com/mobileanalytics/latest/ug/PutEvents.html">PutEvents</a> in the <i>Amazon Mobile Analytics API Reference and User Guide</i>.</p><p>The ClientContext JSON must be base64-encoded.</p>
 */
@property (nonatomic, strong) NSString *clientContext;

/**
 <p>The Lambda function name. </p><p> You can specify an unqualified function name (for example, "Thumbnail") or you can specify Amazon Resource Name (ARN) of the function (for example, "arn:aws:lambda:us-west-2:account-id:function:ThumbNail"). AWS Lambda also allows you to specify only the account ID qualifier (for example, "account-id:Thumbnail"). Note that the length constraint applies only to the ARN. If you specify only the function name, it is limited to 64 character in length. </p>
 */
@property (nonatomic, strong) NSString *functionName;

/**
 <p>By default, the <code>Invoke</code> API assumes "RequestResponse" invocation type. You can optionally request asynchronous execution by specifying "Event" as the <code>InvocationType</code>. You can also use this parameter to request AWS Lambda to not execute the function but do some verification, such as if the caller is authorized to invoke the function and if the inputs are valid. You request this by specifying "DryRun" as the <code>InvocationType</code>. This is useful in a cross-account scenario when you want to verify access to a function without running it. </p>
 */
@property (nonatomic, assign) AWSLambdaInvocationType invocationType;

/**
 <p>You can set this optional parameter to "Tail" in the request only if you specify the <code>InvocationType</code> parameter with value "RequestResponse". In this case, AWS Lambda returns the base64-encoded last 4 KB of log data produced by your Lambda function in the <code>x-amz-log-results</code> header. </p>
 */
@property (nonatomic, assign) AWSLambdaLogType logType;

/**
 <p>JSON that you want to provide to your Lambda function as input.</p>
 */
@property (nonatomic, strong) id payload;

@end

/**
 <p>Upon success, returns an empty response. Otherwise, throws an exception.</p>
 */
@interface AWSLambdaInvocationResponse : AWSModel


/**
 <p>Indicates whether an error occurred while executing the Lambda function. If an error occurred this field will have one of two values; <code>Handled</code> or <code>Unhandled</code>. <code>Handled</code> errors are errors that are reported by the function while the <code>Unhandled</code> errors are those detected and reported by AWS Lambda. Unhandled errors include out of memory errors and function timeouts. For information about how to report an <code>Handled</code> error, see <a href="http://docs.aws.amazon.com/lambda/latest/dg/programming-model.html">Programming Model</a>. </p>
 */
@property (nonatomic, strong) NSString *functionError;

/**
 <p> It is the base64-encoded logs for the Lambda function invocation. This is present only if the invocation type is "RequestResponse" and the logs were requested. </p>
 */
@property (nonatomic, strong) NSString *logResult;

/**
 <p> It is the JSON representation of the object returned by the Lambda function. In This is present only if the invocation type is "RequestResponse". </p><p>In the event of a function error this field contains a message describing the error. For the <code>Handled</code> errors the Lambda function will report this message. For <code>Unhandled</code> errors AWS Lambda reports the message. </p>
 */
@property (nonatomic, strong) id payload;

/**
 <p>The HTTP status code will be in the 200 range for successful request. For the "RequestResonse" invocation type this status code will be 200. For the "Event" invocation type this status code will be 202. For the "DryRun" invocation type the status code will be 204. </p>
 */
@property (nonatomic, strong) NSNumber *statusCode;

@end

/**
 
 */
@interface AWSLambdaInvokeAsyncRequest : AWSRequest


/**
 <p>The Lambda function name.</p>
 */
@property (nonatomic, strong) NSString *functionName;

/**
 <p>JSON that you want to provide to your Lambda function as input.</p>
 */
@property (nonatomic, strong) NSData *invokeArgs;

@end

/**
 <p>Upon success, it returns empty response. Otherwise, throws an exception.</p>
 */
@interface AWSLambdaInvokeAsyncResponse : AWSModel


/**
 <p>It will be 202 upon success.</p>
 */
@property (nonatomic, strong) NSNumber *status;

@end

/**
 
 */
@interface AWSLambdaListEventSourceMappingsRequest : AWSRequest


/**
 <p>The Amazon Resource Name (ARN) of the Amazon Kinesis stream.</p>
 */
@property (nonatomic, strong) NSString *eventSourceArn;

/**
 <p>The name of the Lambda function.</p><p> You can specify an unqualified function name (for example, "Thumbnail") or you can specify Amazon Resource Name (ARN) of the function (for example, "arn:aws:lambda:us-west-2:account-id:function:ThumbNail"). AWS Lambda also allows you to specify only the account ID qualifier (for example, "account-id:Thumbnail"). Note that the length constraint applies only to the ARN. If you specify only the function name, it is limited to 64 character in length. </p>
 */
@property (nonatomic, strong) NSString *functionName;

/**
 <p>Optional string. An opaque pagination token returned from a previous <code>ListEventSourceMappings</code> operation. If present, specifies to continue the list from where the returning call left off. </p>
 */
@property (nonatomic, strong) NSString *marker;

/**
 <p>Optional integer. Specifies the maximum number of event sources to return in response. This value must be greater than 0.</p>
 */
@property (nonatomic, strong) NSNumber *maxItems;

@end

/**
 <p>Contains a list of event sources (see <a>API_EventSourceMappingConfiguration</a>)</p>
 */
@interface AWSLambdaListEventSourceMappingsResponse : AWSModel


/**
 <p>An array of <code>EventSourceMappingConfiguration</code> objects.</p>
 */
@property (nonatomic, strong) NSArray *eventSourceMappings;

/**
 <p>A string, present if there are more event source mappings.</p>
 */
@property (nonatomic, strong) NSString *nextMarker;

@end

/**
 
 */
@interface AWSLambdaListFunctionsRequest : AWSRequest


/**
 <p>Optional string. An opaque pagination token returned from a previous <code>ListFunctions</code> operation. If present, indicates where to continue the listing. </p>
 */
@property (nonatomic, strong) NSString *marker;

/**
 <p>Optional integer. Specifies the maximum number of AWS Lambda functions to return in response. This parameter value must be greater than 0.</p>
 */
@property (nonatomic, strong) NSNumber *maxItems;

@end

/**
 <p>Contains a list of AWS Lambda function configurations (see <a>FunctionConfiguration</a>.</p>
 */
@interface AWSLambdaListFunctionsResponse : AWSModel


/**
 <p>A list of Lambda functions.</p>
 */
@property (nonatomic, strong) NSArray *functions;

/**
 <p>A string, present if there are more functions.</p>
 */
@property (nonatomic, strong) NSString *nextMarker;

@end

/**
 
 */
@interface AWSLambdaRemovePermissionRequest : AWSRequest


/**
 <p>Lambda function whose access policy you want to remove a permission from.</p><p> You can specify an unqualified function name (for example, "Thumbnail") or you can specify Amazon Resource Name (ARN) of the function (for example, "arn:aws:lambda:us-west-2:account-id:function:ThumbNail"). AWS Lambda also allows you to specify only the account ID qualifier (for example, "account-id:Thumbnail"). Note that the length constraint applies only to the ARN. If you specify only the function name, it is limited to 64 character in length. </p>
 */
@property (nonatomic, strong) NSString *functionName;

/**
 <p>Statement ID of the permission to remove.</p>
 */
@property (nonatomic, strong) NSString *statementId;

@end

/**
 
 */
@interface AWSLambdaUpdateEventSourceMappingRequest : AWSRequest


/**
 <p>The maximum number of stream records that can be sent to your Lambda function for a single invocation.</p>
 */
@property (nonatomic, strong) NSNumber *batchSize;

/**
 <p>Specifies whether AWS Lambda should actively poll the stream or not. If disabled, AWS Lambda will not poll the stream.</p>
 */
@property (nonatomic, strong) NSNumber *enabled;

/**
 <p>The Lambda function to which you want the stream records sent.</p><p> You can specify an unqualified function name (for example, "Thumbnail") or you can specify Amazon Resource Name (ARN) of the function (for example, "arn:aws:lambda:us-west-2:account-id:function:ThumbNail"). AWS Lambda also allows you to specify only the account ID qualifier (for example, "account-id:Thumbnail"). Note that the length constraint applies only to the ARN. If you specify only the function name, it is limited to 64 character in length. </p>
 */
@property (nonatomic, strong) NSString *functionName;

/**
 <p>The event source mapping identifier.</p>
 */
@property (nonatomic, strong) NSString *UUID;

@end

/**
 
 */
@interface AWSLambdaUpdateFunctionCodeRequest : AWSRequest


/**
 <p>The existing Lambda function name whose code you want to replace.</p><p> You can specify an unqualified function name (for example, "Thumbnail") or you can specify Amazon Resource Name (ARN) of the function (for example, "arn:aws:lambda:us-west-2:account-id:function:ThumbNail"). AWS Lambda also allows you to specify only the account ID qualifier (for example, "account-id:Thumbnail"). Note that the length constraint applies only to the ARN. If you specify only the function name, it is limited to 64 character in length. </p>
 */
@property (nonatomic, strong) NSString *functionName;

/**
 <p>Amazon S3 bucket name where the .zip file containing your deployment package is stored. This bucket must reside in the same AWS region where you are creating the Lambda function.</p>
 */
@property (nonatomic, strong) NSString *s3Bucket;

/**
 <p>The Amazon S3 object (the deployment package) key name you want to upload. </p>
 */
@property (nonatomic, strong) NSString *s3Key;

/**
 <p>The Amazon S3 object (the deployment package) version you want to upload.</p>
 */
@property (nonatomic, strong) NSString *s3ObjectVersion;

/**
 <p>Based64-encoded .zip file containing your packaged source code.</p>
 */
@property (nonatomic, strong) NSData *zipFile;

@end

/**
 
 */
@interface AWSLambdaUpdateFunctionConfigurationRequest : AWSRequest


/**
 <p>A short user-defined function description. AWS Lambda does not use this value. Assign a meaningful description as you see fit.</p>
 */
@property (nonatomic, strong) NSString *detail;

/**
 <p>The name of the Lambda function.</p><p> You can specify an unqualified function name (for example, "Thumbnail") or you can specify Amazon Resource Name (ARN) of the function (for example, "arn:aws:lambda:us-west-2:account-id:function:ThumbNail"). AWS Lambda also allows you to specify only the account ID qualifier (for example, "account-id:Thumbnail"). Note that the length constraint applies only to the ARN. If you specify only the function name, it is limited to 64 character in length. </p>
 */
@property (nonatomic, strong) NSString *functionName;

/**
 <p>The function that Lambda calls to begin executing your function. For Node.js, it is the <i>module-name.export</i> value in your function. </p>
 */
@property (nonatomic, strong) NSString *handler;

/**
 <p>The amount of memory, in MB, your Lambda function is given. AWS Lambda uses this memory size to infer the amount of CPU allocated to your function. Your function use-case determines your CPU and memory requirements. For example, a database operation might need less memory compared to an image processing function. The default value is 128 MB. The value must be a multiple of 64 MB.</p>
 */
@property (nonatomic, strong) NSNumber *memorySize;

/**
 <p>The Amazon Resource Name (ARN) of the IAM role that Lambda will assume when it executes your function. </p>
 */
@property (nonatomic, strong) NSString *role;

/**
 <p>The function execution time at which AWS Lambda should terminate the function. Because the execution time has cost implications, we recommend you set this value based on your expected execution time. The default is 3 seconds. </p>
 */
@property (nonatomic, strong) NSNumber *timeout;

@end
