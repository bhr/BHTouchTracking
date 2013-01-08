//
//  GCDSingleton.h
//  BHTouchTrackingSample
//
//  Created by Benedikt Hirmer on 08.01.13.
//  Copyright (c) 2013 HIRMER.me. All rights reserved.
//

#ifndef VirtualUIElements_GCDSingleton_h
#define VirtualUIElements_GCDSingleton_h

#define DEFINE_SHARED_INSTANCE_USING_BLOCK(block) \
static dispatch_once_t pred = 0; \
__strong static id _sharedObject = nil; \
dispatch_once(&pred, ^{ \
_sharedObject = block(); \
}); \
return _sharedObject; \


#endif
