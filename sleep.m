/* gcc -o sleep sleep.m -framework ApplicationServices -framework Foundation */
#include <CoreServices/CoreServices.h>

void
MyTimerCallback(CFRunLoopTimerRef timer, void *info)
{
    UpdateSystemActivity(OverallAct);
}


int
main (int argc, const char * argv[])
{
    CFRunLoopTimerRef timer;
    CFRunLoopTimerContext context = { 0, NULL, NULL, NULL, NULL };

    timer = CFRunLoopTimerCreate(NULL, CFAbsoluteTimeGetCurrent(), 30, 0, 0, MyTimerCallback, &context);
    if (timer != NULL) {
        CFRunLoopAddTimer(CFRunLoopGetCurrent(), timer, kCFRunLoopCommonModes);
    }

    /* Start the run loop to receive timer callbacks. You don't need to
    call this if you already have a Carbon or Cocoa EventLoop running. */
    CFRunLoopRun();

    CFRunLoopTimerInvalidate(timer);
    CFRelease(timer);

    return (0);
}

