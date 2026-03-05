#include "airun_ui_host.h"

#ifdef __APPLE__

#import <AppKit/AppKit.h>
#include <ctype.h>
#include <math.h>
#include <stdio.h>
#include <string.h>

typedef struct {
    int64_t handle;
    NSWindow* window;
    id delegate_ref;
    int close_pending;
} NativeUiWindowSlot;

static NativeUiWindowSlot g_native_ui_windows[8];
static int64_t g_native_ui_next_handle = 1;
static int g_native_ui_app_initialized = 0;

static NSColor* native_ui_parse_color(const char* color, NSColor* fallback)
{
    unsigned int r;
    unsigned int g;
    unsigned int b;
    if (color == NULL || color[0] == '\0') {
        return fallback;
    }
    if (color[0] == '#') {
        if (sscanf(color + 1, "%02x%02x%02x", &r, &g, &b) == 3) {
            return [NSColor colorWithCalibratedRed:(CGFloat)r / 255.0
                                             green:(CGFloat)g / 255.0
                                              blue:(CGFloat)b / 255.0
                                             alpha:1.0];
        }
        return fallback;
    }
    if (strcasecmp(color, "white") == 0) {
        return [NSColor whiteColor];
    }
    if (strcasecmp(color, "black") == 0) {
        return [NSColor blackColor];
    }
    if (strcasecmp(color, "red") == 0) {
        return [NSColor redColor];
    }
    if (strcasecmp(color, "green") == 0) {
        return [NSColor greenColor];
    }
    if (strcasecmp(color, "blue") == 0) {
        return [NSColor blueColor];
    }
    return fallback;
}

static int native_ui_lock_focus(NativeUiWindowSlot* slot, NSRect* out_bounds)
{
    NSView* content_view;
    if (slot == NULL || slot->window == nil) {
        return 0;
    }
    content_view = [slot->window contentView];
    if (content_view == nil) {
        return 0;
    }
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    if (![content_view lockFocusIfCanDraw]) {
#pragma clang diagnostic pop
        return 0;
    }
    if (out_bounds != NULL) {
        *out_bounds = [content_view bounds];
    }
    return 1;
}

static void native_ui_unlock_focus(NativeUiWindowSlot* slot)
{
    NSView* content_view;
    if (slot == NULL || slot->window == nil) {
        return;
    }
    content_view = [slot->window contentView];
    if (content_view != nil) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        [content_view unlockFocus];
#pragma clang diagnostic pop
    }
}

static CGFloat native_ui_y_to_cocoa(NSRect bounds, int y_top)
{
    return NSMaxY(bounds) - (CGFloat)y_top;
}

static const char* native_ui_path_skip_separators(const char* cursor)
{
    while (cursor != NULL && *cursor != '\0') {
        if (!isspace((unsigned char)*cursor) && *cursor != ',') {
            break;
        }
        cursor += 1;
    }
    return cursor;
}

static int native_ui_path_parse_number(const char** io_cursor, double* out_number)
{
    char* end_ptr = NULL;
    const char* cursor;
    if (io_cursor == NULL || *io_cursor == NULL || out_number == NULL) {
        return 0;
    }
    cursor = native_ui_path_skip_separators(*io_cursor);
    if (cursor == NULL || *cursor == '\0') {
        return 0;
    }
    *out_number = strtod(cursor, &end_ptr);
    if (end_ptr == cursor) {
        return 0;
    }
    *io_cursor = end_ptr;
    return 1;
}

static int native_ui_draw_svg_path(NSRect bounds, const char* path_text, const char* color, int stroke_width)
{
    const char* cursor;
    char cmd = '\0';
    double x = 0.0;
    double y = 0.0;
    NSBezierPath* bezier;
    NSColor* stroke_color;
    if (path_text == NULL) {
        return 0;
    }
    bezier = [NSBezierPath bezierPath];
    cursor = path_text;
    while (cursor != NULL && *cursor != '\0') {
        double a = 0.0;
        double b = 0.0;
        cursor = native_ui_path_skip_separators(cursor);
        if (*cursor == '\0') {
            break;
        }
        if (isalpha((unsigned char)*cursor)) {
            cmd = *cursor;
            cursor += 1;
            continue;
        }
        if (cmd == '\0') {
            return 0;
        }
        if (cmd == 'M' || cmd == 'm' || cmd == 'L' || cmd == 'l') {
            if (!native_ui_path_parse_number(&cursor, &a) || !native_ui_path_parse_number(&cursor, &b)) {
                return 0;
            }
            if (cmd == 'm' || cmd == 'l') {
                x += a;
                y += b;
            } else {
                x = a;
                y = b;
            }
            if (cmd == 'M' || cmd == 'm') {
                [bezier moveToPoint:NSMakePoint((CGFloat)x, native_ui_y_to_cocoa(bounds, (int)lround(y)))];
                cmd = (cmd == 'm') ? 'l' : 'L';
            } else {
                [bezier lineToPoint:NSMakePoint((CGFloat)x, native_ui_y_to_cocoa(bounds, (int)lround(y)))];
            }
            continue;
        }
        if (cmd == 'H' || cmd == 'h') {
            if (!native_ui_path_parse_number(&cursor, &a)) {
                return 0;
            }
            x = (cmd == 'h') ? (x + a) : a;
            [bezier lineToPoint:NSMakePoint((CGFloat)x, native_ui_y_to_cocoa(bounds, (int)lround(y)))];
            continue;
        }
        if (cmd == 'V' || cmd == 'v') {
            if (!native_ui_path_parse_number(&cursor, &a)) {
                return 0;
            }
            y = (cmd == 'v') ? (y + a) : a;
            [bezier lineToPoint:NSMakePoint((CGFloat)x, native_ui_y_to_cocoa(bounds, (int)lround(y)))];
            continue;
        }
        if (cmd == 'Z' || cmd == 'z') {
            [bezier closePath];
            cmd = '\0';
            continue;
        }
        return 0;
    }
    stroke_color = native_ui_parse_color(color, [NSColor blackColor]);
    [stroke_color setStroke];
    [bezier setLineWidth:(stroke_width > 0) ? (CGFloat)stroke_width : 1.0];
    [bezier stroke];
    return 1;
}

static NativeUiWindowSlot* native_ui_find_slot(int64_t handle)
{
    size_t i;
    if (handle <= 0) {
        return NULL;
    }
    for (i = 0U; i < sizeof(g_native_ui_windows) / sizeof(g_native_ui_windows[0]); i += 1U) {
        if (g_native_ui_windows[i].handle == handle && g_native_ui_windows[i].window != nil) {
            return &g_native_ui_windows[i];
        }
    }
    return NULL;
}

static NativeUiWindowSlot* native_ui_find_empty_slot(void)
{
    size_t i;
    for (i = 0U; i < sizeof(g_native_ui_windows) / sizeof(g_native_ui_windows[0]); i += 1U) {
        if (g_native_ui_windows[i].window == nil) {
            return &g_native_ui_windows[i];
        }
    }
    return NULL;
}

static int native_ui_init_app(void)
{
    if (g_native_ui_app_initialized != 0) {
        return 1;
    }
    [NSApplication sharedApplication];
    [NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];
    [NSApp finishLaunching];
    g_native_ui_app_initialized = 1;
    return 1;
}

@interface NativeUiWindowDelegate : NSObject<NSWindowDelegate>
@property(nonatomic, assign) NativeUiWindowSlot* slot;
@end

@implementation NativeUiWindowDelegate
- (void)windowWillClose:(NSNotification*)notification
{
    (void)notification;
    if (self.slot != NULL) {
        self.slot->close_pending = 1;
    }
}
@end

static void native_ui_set_string(char* out, size_t out_capacity, const char* text)
{
    if (out == NULL || out_capacity == 0U) {
        return;
    }
    if (text == NULL) {
        out[0] = '\0';
        return;
    }
    (void)snprintf(out, out_capacity, "%s", text);
}

static const char* native_ui_normalize_key(NSEvent* event)
{
    unsigned short key_code;
    NSString* chars;
    if (event == nil) {
        return "";
    }
    key_code = [event keyCode];
    switch (key_code) {
        case 36:
        case 76:
            return "enter";
        case 48:
            return "tab";
        case 49:
            return "space";
        case 51:
            return "backspace";
        case 53:
            return "escape";
        case 123:
            return "left";
        case 124:
            return "right";
        case 125:
            return "down";
        case 126:
            return "up";
        case 117:
            return "delete";
        default:
            break;
    }
    chars = [event charactersIgnoringModifiers];
    if (chars == nil || [chars length] == 0U) {
        return "";
    }
    return [[chars lowercaseString] UTF8String];
}

static void native_ui_set_text_from_event(char* out, size_t out_capacity, NSEvent* event)
{
    NSString* chars;
    if (out == NULL || out_capacity == 0U) {
        return;
    }
    out[0] = '\0';
    if (event == nil) {
        return;
    }
    chars = [event characters];
    if (chars == nil || [chars length] == 0U) {
        return;
    }
    native_ui_set_string(out, out_capacity, [chars UTF8String]);
}

void native_host_ui_reset(void)
{
    size_t i;
    for (i = 0U; i < sizeof(g_native_ui_windows) / sizeof(g_native_ui_windows[0]); i += 1U) {
        g_native_ui_windows[i].handle = 0;
        g_native_ui_windows[i].window = nil;
        g_native_ui_windows[i].delegate_ref = nil;
        g_native_ui_windows[i].close_pending = 0;
    }
    g_native_ui_next_handle = 1;
}

void native_host_ui_shutdown(void)
{
    size_t i;
    for (i = 0U; i < sizeof(g_native_ui_windows) / sizeof(g_native_ui_windows[0]); i += 1U) {
        if (g_native_ui_windows[i].window != nil) {
            [g_native_ui_windows[i].window close];
            g_native_ui_windows[i].window = nil;
            g_native_ui_windows[i].delegate_ref = nil;
            g_native_ui_windows[i].handle = 0;
            g_native_ui_windows[i].close_pending = 0;
        }
    }
}

int native_host_ui_create_window(const char* title, int width, int height, int64_t* out_handle)
{
    NativeUiWindowSlot* slot;
    NSRect frame;
    NSWindow* window;
    NativeUiWindowDelegate* delegate;
    NSString* window_title;
    if (out_handle == NULL || width <= 0 || height <= 0) {
        return 0;
    }
    *out_handle = 0;
    if (!native_ui_init_app()) {
        return 0;
    }
    slot = native_ui_find_empty_slot();
    if (slot == NULL) {
        return 0;
    }
    frame = NSMakeRect(120, 120, width, height);
    window = [[NSWindow alloc] initWithContentRect:frame
                                         styleMask:(NSWindowStyleMaskTitled |
                                                    NSWindowStyleMaskClosable |
                                                    NSWindowStyleMaskResizable |
                                                    NSWindowStyleMaskMiniaturizable)
                                           backing:NSBackingStoreBuffered
                                             defer:NO];
    if (window == nil) {
        return 0;
    }
    window_title = [NSString stringWithUTF8String:(title == NULL || title[0] == '\0') ? "AiLang" : title];
    [window setTitle:window_title];
    [window setReleasedWhenClosed:NO];
    delegate = [NativeUiWindowDelegate new];
    delegate.slot = slot;
    [window setDelegate:delegate];
    [window makeKeyAndOrderFront:nil];
    [NSApp activateIgnoringOtherApps:YES];
    slot->handle = g_native_ui_next_handle++;
    slot->window = window;
    slot->delegate_ref = delegate;
    slot->close_pending = 0;
    *out_handle = slot->handle;
    return 1;
}

int native_host_ui_close_window(int64_t handle)
{
    NativeUiWindowSlot* slot = native_ui_find_slot(handle);
    if (slot == NULL) {
        return 0;
    }
    [slot->window close];
    slot->close_pending = 1;
    return 1;
}

int native_host_ui_begin_frame(int64_t handle)
{
    NativeUiWindowSlot* slot = native_ui_find_slot(handle);
    NSRect bounds;
    if (slot == NULL) {
        return 0;
    }
    if (!native_ui_lock_focus(slot, &bounds)) {
        return 0;
    }
    [[NSColor whiteColor] setFill];
    NSRectFill(bounds);
    native_ui_unlock_focus(slot);
    return 1;
}

int native_host_ui_end_frame(int64_t handle)
{
    return native_ui_find_slot(handle) != NULL ? 1 : 0;
}

int native_host_ui_present(int64_t handle)
{
    NativeUiWindowSlot* slot = native_ui_find_slot(handle);
    if (slot == NULL) {
        return 0;
    }
    [slot->window displayIfNeeded];
    return 1;
}

int native_host_ui_wait_frame(int64_t handle)
{
    if (native_ui_find_slot(handle) == NULL) {
        return 0;
    }
    [NSThread sleepForTimeInterval:(1.0 / 60.0)];
    return 1;
}

int native_host_ui_draw_rect(int64_t handle, int x, int y, int width, int height, const char* color)
{
    NativeUiWindowSlot* slot = native_ui_find_slot(handle);
    NSRect bounds;
    NSRect rect;
    if (slot == NULL || width <= 0 || height <= 0) {
        return 0;
    }
    if (!native_ui_lock_focus(slot, &bounds)) {
        return 0;
    }
    rect = NSMakeRect((CGFloat)x, native_ui_y_to_cocoa(bounds, y + height), (CGFloat)width, (CGFloat)height);
    [native_ui_parse_color(color, [NSColor blackColor]) setFill];
    NSRectFill(rect);
    native_ui_unlock_focus(slot);
    return 1;
}

int native_host_ui_draw_text(int64_t handle, int x, int y, const char* text, const char* color, int font_size)
{
    NativeUiWindowSlot* slot = native_ui_find_slot(handle);
    NSRect bounds;
    NSString* ns_text;
    NSDictionary* attrs;
    NSFont* font;
    if (slot == NULL || text == NULL) {
        return 0;
    }
    if (!native_ui_lock_focus(slot, &bounds)) {
        return 0;
    }
    ns_text = [NSString stringWithUTF8String:text];
    if (ns_text == nil) {
        native_ui_unlock_focus(slot);
        return 0;
    }
    font = [NSFont systemFontOfSize:(font_size > 0) ? (CGFloat)font_size : 12.0];
    attrs = @{
        NSForegroundColorAttributeName: native_ui_parse_color(color, [NSColor blackColor]),
        NSFontAttributeName: font
    };
    [ns_text drawAtPoint:NSMakePoint((CGFloat)x, native_ui_y_to_cocoa(bounds, y + ((font_size > 0) ? font_size : 12)))
          withAttributes:attrs];
    native_ui_unlock_focus(slot);
    return 1;
}

int native_host_ui_draw_line(int64_t handle, int x1, int y1, int x2, int y2, const char* color, int stroke_width)
{
    NativeUiWindowSlot* slot = native_ui_find_slot(handle);
    NSRect bounds;
    NSBezierPath* path;
    if (slot == NULL) {
        return 0;
    }
    if (!native_ui_lock_focus(slot, &bounds)) {
        return 0;
    }
    path = [NSBezierPath bezierPath];
    [path moveToPoint:NSMakePoint((CGFloat)x1, native_ui_y_to_cocoa(bounds, y1))];
    [path lineToPoint:NSMakePoint((CGFloat)x2, native_ui_y_to_cocoa(bounds, y2))];
    [path setLineWidth:(stroke_width > 0) ? (CGFloat)stroke_width : 1.0];
    [native_ui_parse_color(color, [NSColor blackColor]) setStroke];
    [path stroke];
    native_ui_unlock_focus(slot);
    return 1;
}

int native_host_ui_draw_path(int64_t handle, const char* path, const char* color, int stroke_width)
{
    NativeUiWindowSlot* slot = native_ui_find_slot(handle);
    NSRect bounds;
    int ok;
    if (slot == NULL) {
        return 0;
    }
    if (!native_ui_lock_focus(slot, &bounds)) {
        return 0;
    }
    ok = native_ui_draw_svg_path(bounds, path, color, stroke_width);
    native_ui_unlock_focus(slot);
    return ok;
}

int native_host_ui_poll_event(int64_t handle, NativeHostUiEvent* out_event)
{
    NativeUiWindowSlot* slot = native_ui_find_slot(handle);
    NSEvent* event;
    if (slot == NULL || out_event == NULL) {
        return 0;
    }
    memset(out_event, 0, sizeof(*out_event));
    native_ui_set_string(out_event->type, sizeof(out_event->type), "none");
    if (slot->close_pending != 0) {
        native_ui_set_string(out_event->type, sizeof(out_event->type), "closed");
        slot->close_pending = 0;
        return 1;
    }
    event = [NSApp nextEventMatchingMask:NSEventMaskAny
                               untilDate:[NSDate dateWithTimeIntervalSinceNow:0.0]
                                  inMode:NSDefaultRunLoopMode
                                 dequeue:YES];
    if (event == nil) {
        return 1;
    }
    switch ([event type]) {
        case NSEventTypeLeftMouseDown: {
            NSWindow* source_window = [event window];
            NSPoint location = [event locationInWindow];
            NSRect content_bounds;
            int y_top;
            if (source_window == nil) {
                source_window = slot->window;
            }
            content_bounds = [[source_window contentView] bounds];
            y_top = (int)llround(content_bounds.size.height - location.y);
            out_event->x = (int)llround(location.x);
            out_event->y = y_top < 0 ? 0 : y_top;
            native_ui_set_string(out_event->type, sizeof(out_event->type), "click");
            break;
        }
        case NSEventTypeKeyDown: {
            NSUInteger flags = [event modifierFlags];
            const char* key_name = native_ui_normalize_key(event);
            native_ui_set_string(out_event->type, sizeof(out_event->type), "key");
            native_ui_set_string(out_event->key, sizeof(out_event->key), key_name);
            native_ui_set_text_from_event(out_event->text, sizeof(out_event->text), event);
            out_event->repeat = [event isARepeat] ? 1 : 0;
            out_event->modifiers =
                ((flags & NSEventModifierFlagShift) != 0 ? 1 : 0) |
                ((flags & NSEventModifierFlagControl) != 0 ? 2 : 0) |
                ((flags & NSEventModifierFlagOption) != 0 ? 4 : 0) |
                ((flags & NSEventModifierFlagCommand) != 0 ? 8 : 0);
            break;
        }
        default:
            break;
    }
    [NSApp sendEvent:event];
    [NSApp updateWindows];
    return 1;
}

int native_host_ui_get_window_size(int64_t handle, int* out_width, int* out_height)
{
    NativeUiWindowSlot* slot = native_ui_find_slot(handle);
    NSRect content_bounds;
    if (slot == NULL || out_width == NULL || out_height == NULL) {
        return 0;
    }
    content_bounds = [[slot->window contentView] bounds];
    *out_width = (int)llround(content_bounds.size.width);
    *out_height = (int)llround(content_bounds.size.height);
    return 1;
}

#endif
