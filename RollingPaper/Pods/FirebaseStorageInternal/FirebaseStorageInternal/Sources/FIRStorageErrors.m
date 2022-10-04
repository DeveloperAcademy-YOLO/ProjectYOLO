// Copyright 2017 Google
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#import "FirebaseStorageInternal/Sources/FIRStorageErrors.h"

#import "FirebaseStorageInternal/Sources/Public/FirebaseStorageInternal/FIRStorageReference.h"

#import "FirebaseStorageInternal/Sources/FIRStorageConstants_Private.h"
#import "FirebaseStorageInternal/Sources/FIRStorageReference_Private.h"

@implementation FIRStorageErrors

+ (NSError *)errorWithCode:(FIRIMPLStorageErrorCode)code {
  return [FIRStorageErrors errorWithCode:code infoDictionary:nil];
}

+ (NSError *)errorWithCode:(FIRIMPLStorageErrorCode)code
            infoDictionary:(nullable NSDictionary *)dictionary {
  NSMutableDictionary *errorDictionary;
  if (dictionary) {
    errorDictionary = [dictionary mutableCopy];
  } else {
    errorDictionary = [[NSMutableDictionary alloc] init];
  }

  NSString *errorMessage;
  switch (code) {
    case FIRIMPLStorageErrorCodeObjectNotFound:
      errorMessage =
          [NSString stringWithFormat:@"Object %@ does not exist.", errorDictionary[@"object"]];
      break;

    case FIRIMPLStorageErrorCodeBucketNotFound:
      errorMessage =
          [NSString stringWithFormat:@"Bucket %@ does not exist.", errorDictionary[@"bucket"]];
      break;

    case FIRIMPLStorageErrorCodeProjectNotFound:
      errorMessage =
          [NSString stringWithFormat:@"Project %@ does not exist.", errorDictionary[@"project"]];
      break;

    case FIRIMPLStorageErrorCodeQuotaExceeded: {
      NSString *const kQuotaExceededFormat =
          @"Quota for bucket %@ exceeded, please view quota on firebase.google.com.";
      errorMessage = [NSString stringWithFormat:kQuotaExceededFormat, errorDictionary[@"bucket"]];
      break;
    }

    case FIRIMPLStorageErrorCodeDownloadSizeExceeded: {
      int64_t total = [errorDictionary[@"totalSize"] longLongValue];
      int64_t size = [errorDictionary[@"maxAllowedSize"] longLongValue];
      NSString *totalString = total ? @(total).stringValue : @"unknown";
      NSString *sizeString = total ? @(size).stringValue : @"unknown";
      NSString *const kSizeExceededErrorFormat =
          @"Attempted to download object with size of %@ bytes, "
          @"which exceeds the maximum size of %@ bytes. "
          @"Consider raising the maximum download size, or using "
          @"[FIRIMPLStorageReference writeToFile:]";
      errorMessage = [NSString stringWithFormat:kSizeExceededErrorFormat, totalString, sizeString];
      break;
    }

    case FIRIMPLStorageErrorCodeUnauthenticated:
      errorMessage = @"User is not authenticated, please authenticate using Firebase "
                     @"Authentication and try again.";
      break;

    case FIRIMPLStorageErrorCodeUnauthorized: {
      NSString *bucket = errorDictionary[@"bucket"];
      NSString *object = errorDictionary[@"object"];
      NSString *const kUnauthorizedFormat = @"User does not have permission to access gs://%@/%@.";
      errorMessage = [NSString stringWithFormat:kUnauthorizedFormat, bucket, object];
      break;
    }

    case FIRIMPLStorageErrorCodeRetryLimitExceeded:
      errorMessage = @"Max retry time for operation exceeded, please try again.";
      break;

    case FIRIMPLStorageErrorCodeNonMatchingChecksum: {
      // TODO: replace with actual checksum strings when we choose to implement.
      NSString *const kChecksumFailedErrorFormat =
          @"Uploaded/downloaded object %@ has checksum: %@ "
          @"which does not match server checksum: %@. Please retry the upload/download.";
      errorMessage = [NSString stringWithFormat:kChecksumFailedErrorFormat, @"object",
                                                @"client checksum", @"server checksum"];
      break;
    }

    case FIRIMPLStorageErrorCodeCancelled:
      errorMessage = @"User cancelled the upload/download.";
      break;

    case FIRIMPLStorageErrorCodeUnknown:
      /* Fall through to default case for unknown errors */

    default:
      errorMessage = @"An unknown error occurred, please check the server response.";
      break;
  }

  errorDictionary[NSLocalizedDescriptionKey] = errorMessage;

  NSError *err = [NSError errorWithDomain:FIRStorageErrorDomainInternal
                                     code:code
                                 userInfo:errorDictionary];
  return err;
}

+ (nullable NSError *)errorWithServerError:(nullable NSError *)error
                                 reference:(nullable FIRIMPLStorageReference *)reference {
  if (error == nil) {
    return nil;
  }

  FIRIMPLStorageErrorCode errorCode;
  switch (error.code) {
    case 400:
      errorCode = FIRIMPLStorageErrorCodeUnknown;
      break;

    case 401:
      errorCode = FIRIMPLStorageErrorCodeUnauthenticated;
      break;

    case 402:
      errorCode = FIRIMPLStorageErrorCodeQuotaExceeded;
      break;

    case 403:
      errorCode = FIRIMPLStorageErrorCodeUnauthorized;
      break;

    case 404:
      errorCode = FIRIMPLStorageErrorCodeObjectNotFound;
      break;

    default:
      errorCode = FIRIMPLStorageErrorCodeUnknown;
      break;
  }

  NSMutableDictionary *errorDictionary =
      [[[NSDictionary alloc] initWithDictionary:error.userInfo] mutableCopy];
  errorDictionary[kFIRStorageResponseErrorDomain] = error.domain;
  errorDictionary[kFIRStorageResponseErrorCode] = @(error.code);

  // Turn raw response into a string
  NSData *responseData = errorDictionary[@"data"];
  if (responseData) {
    NSString *errorString = [[NSString alloc] initWithData:responseData
                                                  encoding:NSUTF8StringEncoding];
    errorDictionary[kFIRStorageResponseBody] = errorString ?: @"No Response from Server.";
  }

  errorDictionary[@"bucket"] = reference.path.bucket;
  errorDictionary[@"object"] = reference.path.object;

  NSError *clientError = [FIRStorageErrors errorWithCode:errorCode infoDictionary:errorDictionary];
  return clientError;
}

+ (NSError *)errorWithInvalidRequest:(NSData *)request {
  NSString *requestString = [[NSString alloc] initWithData:request encoding:NSUTF8StringEncoding];
  NSString *invalidDataString =
      [NSString stringWithFormat:kFIRStorageInvalidDataFormat, requestString];
  NSDictionary *dict;
  if (invalidDataString.length > 0) {
    dict = @{NSLocalizedFailureReasonErrorKey : invalidDataString};
  }
  return [FIRStorageErrors errorWithCode:FIRIMPLStorageErrorCodeUnknown infoDictionary:dict];
}

+ (NSError *)errorWithCustomMessage:(NSString *)errorMessage {
  return [NSError errorWithDomain:FIRStorageErrorDomainInternal
                             code:FIRIMPLStorageErrorCodeUnknown
                         userInfo:@{NSLocalizedDescriptionKey : errorMessage}];
}

@end
