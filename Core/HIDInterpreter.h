//
//  HIDInterpreter.h
//  Touch Up Core
//
//  Created by Sebastian Hueber on 03.02.23.
//

#ifndef HIDInterpreter_h
#define HIDInterpreter_h

#include <stdio.h>
#include <CoreFoundation/CoreFoundation.h>

void OpenHIDManager(void *delegate);

void CloseHIDManager(void);

CFIndex ConnectedTouchscreenCount(void);

#endif /* HIDInterpreter_h */
