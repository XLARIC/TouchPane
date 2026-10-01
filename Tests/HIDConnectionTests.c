// Exercise the production callbacks without creating virtual devices or
// opening/seizing the user's real USB hardware.
#include <assert.h>
#include <CoreFoundation/CoreFoundation.h>
#include <IOKit/hid/IOHIDManager.h>
#include <IOKit/hid/IOHIDQueue.h>

static CFMutableSetRef wingDevices;
static CFMutableSetRef genericDevices;
static IOHIDManagerRef wingManager;
static IOHIDManagerRef genericManager;
static int connectionEvents;
static int removalEvents;
static CFIndex countObservedByDelegate;

static CFTypeRef MockDeviceProperty(IOHIDDeviceRef device, CFStringRef key) {
    return CFDictionaryGetValue((CFDictionaryRef)device, key);
}

static CFSetRef MockCopyDevices(IOHIDManagerRef manager) {
    return CFSetCreateCopy(NULL, manager == wingManager ? wingDevices : genericDevices);
}

static IOHIDQueueRef MockCreateQueue(CFAllocatorRef allocator, IOHIDDeviceRef device,
                                    CFIndex depth, IOOptionBits options) {
    return (IOHIDQueueRef)CFRetain(device);
}

static IOHIDDeviceRef MockQueueDevice(IOHIDQueueRef queue) {
    return (IOHIDDeviceRef)queue;
}

static void MockQueueStop(IOHIDQueueRef queue) {}
static void MockQueueUnschedule(IOHIDQueueRef queue, CFRunLoopRef loop, CFStringRef mode) {}
static void MockManagerUnschedule(IOHIDManagerRef manager, CFRunLoopRef loop, CFStringRef mode) {}
static IOReturn MockManagerClose(IOHIDManagerRef manager, IOOptionBits options) {
    return kIOReturnSuccess;
}

#define IOHIDDeviceGetProperty MockDeviceProperty
#define IOHIDManagerCopyDevices MockCopyDevices
#define IOHIDQueueCreate MockCreateQueue
#define IOHIDQueueGetDevice MockQueueDevice
#define IOHIDQueueStop MockQueueStop
#define IOHIDQueueUnscheduleFromRunLoop MockQueueUnschedule
#define IOHIDManagerUnscheduleFromRunLoop MockManagerUnschedule
#define IOHIDManagerClose MockManagerClose
#include "../Core/HIDInterpreter.c"

void TouchInputManagerDidConnectTouchscreen(void *self) {
    ++connectionEvents;
    countObservedByDelegate = ConnectedTouchscreenCount();
}

void TouchInputManagerDidDisconnectTouchscreen(void *self) {
    ++removalEvents;
    countObservedByDelegate = ConnectedTouchscreenCount();
}

Boolean TouchInputManagerCanPostMouseEvents(void *self) { return FALSE; }
void TouchInputManagerAbsoluteMouse(void *self, CGFloat x, CGFloat y, uint8_t buttons, int8_t wheel) {}
void TouchInputManagerUpdateTouchPosition(void *self, CFIndex contactID, CGFloat x, CGFloat y, Boolean onSurface, Boolean valid) {}
void TouchInputManagerUpdateTouchSize(void *self, CFIndex contactID, CGFloat width, CGFloat height, CGFloat azimuth) {}
void TouchInputManagerDidProcessReport(void *self) {}

static IOHIDDeviceRef MakeDevice(CFStringRef name, int vendor, int product) {
    CFMutableDictionaryRef device = CFDictionaryCreateMutable(NULL, 0,
        &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
    CFNumberRef vendorValue = CFNumberCreate(NULL, kCFNumberIntType, &vendor);
    CFNumberRef productValue = CFNumberCreate(NULL, kCFNumberIntType, &product);
    CFDictionarySetValue(device, CFSTR("TestName"), name);
    CFDictionarySetValue(device, CFSTR(kIOHIDVendorIDKey), vendorValue);
    CFDictionarySetValue(device, CFSTR(kIOHIDProductIDKey), productValue);
    CFRelease(vendorValue);
    CFRelease(productValue);
    return (IOHIDDeviceRef)device;
}

static void ResetFixture(void) {
    CloseHIDManager();
    CFSetRemoveAllValues(wingDevices);
    CFSetRemoveAllValues(genericDevices);
    wingManager = (IOHIDManagerRef)CFRetain(CFSTR("WingCool manager"));
    genericManager = (IOHIDManagerRef)CFRetain(CFSTR("Generic manager"));
    gWingCoolManager = wingManager;
    gHidManager = genericManager;
    gConnectedTouchscreens = CFSetCreateMutable(NULL, 0, &kCFTypeSetCallBacks);
    connectionEvents = removalEvents = 0;
    countObservedByDelegate = -1;
}

int main(void) {
    wingDevices = CFSetCreateMutable(NULL, 0, &kCFTypeSetCallBacks);
    genericDevices = CFSetCreateMutable(NULL, 0, &kCFTypeSetCallBacks);
    IOHIDDeviceRef wing = MakeDevice(CFSTR("WingCool mouse"), 0x27c0, 0x0858);
    IOHIDDeviceRef wingDigitizer = MakeDevice(CFSTR("WingCool digitizer"), 0x27c0, 0x0858);
    IOHIDDeviceRef first = MakeDevice(CFSTR("First digitizer"), 0x1234, 1);
    IOHIDDeviceRef second = MakeDevice(CFSTR("Second digitizer"), 0x1234, 2);

    ResetFixture();
    assert(ConnectedTouchscreenCount() == 0);
    CFSetAddValue(wingDevices, wing);
    TrackEnumeratedTouchscreens(gWingCoolManager);
    assert(ConnectedTouchscreenCount() == 1); // No matching callback required at startup.
    WingCoolConnected(NULL, kIOReturnSuccess, wingManager, wing);
    assert(ConnectedTouchscreenCount() == 1 && connectionEvents == 0);
    WingCoolRemoved(NULL, kIOReturnSuccess, wingManager, wing);
    // macOS invokes the removal callback before removing the device from CopyDevices.
    assert(CFSetContainsValue(wingDevices, wing));
    assert(ConnectedTouchscreenCount() == 0 && countObservedByDelegate == 0);
    WingCoolRemoved(NULL, kIOReturnSuccess, wingManager, wing);
    assert(removalEvents == 1);
    WingCoolConnected(NULL, kIOReturnSuccess, wingManager, wing);
    assert(ConnectedTouchscreenCount() == 1 && countObservedByDelegate == 1);
    puts("PASS startup enumeration, duplicate callbacks, removal ordering, reconnect");

    CFSetAddValue(genericDevices, wingDigitizer);
    TrackEnumeratedTouchscreens(gHidManager);
    Handle_DeviceMatchingCallback(NULL, kIOReturnSuccess, genericManager, wingDigitizer);
    assert(ConnectedTouchscreenCount() == 1 && gQueue == NULL);
    WingCoolConnected(NULL, kIOReturnSuccess, genericManager, second);
    assert(ConnectedTouchscreenCount() == 1);
    puts("PASS WingCool interface deduplication and stale-manager callbacks");

    ResetFixture();
    CFSetAddValue(genericDevices, first);
    CFSetAddValue(genericDevices, second);
    TrackEnumeratedTouchscreens(gHidManager);
    Handle_DeviceMatchingCallback(NULL, kIOReturnSuccess, genericManager, first);
    assert(ConnectedTouchscreenCount() == 2 && IOHIDQueueGetDevice(gQueue) == first);
    gAreElementRefsSet = 1;
    Handle_DeviceMatchingCallback(NULL, kIOReturnSuccess, genericManager, first);
    assert(gAreElementRefsSet == 1);
    Handle_RemovalCallback(NULL, kIOReturnSuccess, genericManager, second);
    assert(ConnectedTouchscreenCount() == 1 && countObservedByDelegate == 1);
    assert(IOHIDQueueGetDevice(gQueue) == first && gAreElementRefsSet == 1);
    Handle_RemovalCallback(NULL, kIOReturnSuccess, genericManager, first);
    assert(ConnectedTouchscreenCount() == 0 && gQueue == NULL);
    puts("PASS unrelated removal preserves active input; final removal disconnects");

    ResetFixture();
    CFSetAddValue(genericDevices, first);
    CFSetAddValue(genericDevices, second);
    TrackEnumeratedTouchscreens(gHidManager);
    Handle_DeviceMatchingCallback(NULL, kIOReturnSuccess, genericManager, first);
    Handle_RemovalCallback(NULL, kIOReturnSuccess, genericManager, first);
    assert(ConnectedTouchscreenCount() == 1 && IOHIDQueueGetDevice(gQueue) == second);
    CloseHIDManager();
    assert(ConnectedTouchscreenCount() == 0 && gQueue == NULL);
    puts("PASS active-device failover and input shutdown");

    ResetFixture();
    CFSetAddValue(wingDevices, wing);
    TrackEnumeratedTouchscreens(gWingCoolManager);
    assert(ConnectedTouchscreenCount() == 1);
    CloseHIDManager();
    assert(ConnectedTouchscreenCount() == 0);
    puts("PASS restart restores device presence without a matching callback");

    CFRelease(wing);
    CFRelease(wingDigitizer);
    CFRelease(first);
    CFRelease(second);
    CFRelease(wingDevices);
    CFRelease(genericDevices);
    return 0;
}
