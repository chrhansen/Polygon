//
//  ATSurveyGetSurveyTask.h
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 7/20/12.
//  Copyright (c) 2012 Apptentive, Inc. All rights reserved.
//

#import "ATTask.h"

#import "ATAPIRequest.h"

@interface ATSurveyGetSurveyTask : ATTask <ATAPIRequestDelegate> {
@private
	ATAPIRequest *checkSurveyRequest;
}

@end
