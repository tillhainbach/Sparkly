//
//  SparkleCore.h
//  Sparkle
//
//  Created by Mayur Pawashe on 8/20/16.
//  Copyright © 2016 Sparkle Project. All rights reserved.
//

// Copied mostly from Sparkle.h

#ifndef SPARKLE_CORE_H
#define SPARKLE_CORE_H

// This list should include the shared headers. It doesn't matter if some of them aren't shared (unless
// there are name-space collisions) so we can list all of them to start with:

#pragma clang diagnostic push
// Do not use <> style includes since 2.x has two frameworks that need to work: Sparkle and SparkleCore
#pragma clang diagnostic ignored "-Wquoted-include-in-framework-header"

#import "SUAppcast.h"
#import "SUAppcastItem.h"
#import "SUStandardVersionComparator.h"
#import "SPUUpdater.h"
#import "SPUUpdaterDelegate.h"
#import "SPUUpdaterSettings.h"
#import "SUVersionComparisonProtocol.h"
#import "SUErrors.h"
#import "SPUUpdatePermissionRequest.h"
#import "SUUpdatePermissionResponse.h"
#import "SPUUserDriver.h"
#import "SPUDownloadData.h"

#pragma clang diagnostic pop

#endif
