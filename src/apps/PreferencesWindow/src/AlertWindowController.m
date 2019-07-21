#import "AlertWindowController.h"
#import "KarabinerKit/KarabinerKit.h"
#import "libkrbn/libkrbn.h"
#import <libkern/OSKextLib.h>
#import <pqrs/weakify.h>

@interface AlertWindowController ()

@property(weak) IBOutlet NSWindow* preferencesWindow;
@property BOOL shown;

- (void)kextdStateJsonFileChangedCallback:(NSString*)filePath;

@end

static void staticKextdStateJsonFileChangedCallback(const char* filePath,
                                                    void* context) {
  AlertWindowController* p = (__bridge AlertWindowController*)(context);
  if (p) {
    [p kextdStateJsonFileChangedCallback:[NSString stringWithUTF8String:filePath]];
  }
}

@implementation AlertWindowController

- (void)setup {
  libkrbn_enable_kextd_state_json_file_monitor(staticKextdStateJsonFileChangedCallback,
                                               (__bridge void*)(self));
}

- (void)dealloc {
  libkrbn_disable_kextd_state_json_file_monitor();
}

- (void)kextdStateJsonFileChangedCallback:(NSString*)filePath {
  @weakify(self);
  dispatch_async(dispatch_get_main_queue(), ^{
    @strongify(self);
    if (!self) {
      return;
    }

    NSDictionary* jsonObject = [KarabinerKitJsonUtility loadFile:filePath];
    if (jsonObject) {
      NSString* result = jsonObject[@"kext_load_result"];
      if ([result isKindOfClass:[NSString class]]) {
        if ([result isEqualToString:@"kOSKextReturnSystemPolicy"]) {
          if (!self.shown) {
            self.shown = YES;
            [self.preferencesWindow beginSheet:self.window
                             completionHandler:^(NSModalResponse returnCode){}];
            return;
          }
        }
      }
    }

    [self.preferencesWindow endSheet:self.window];
    self.shown = NO;
  });
}

- (IBAction)openSystemPreferencesSecurity:(id)sender {
  [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"x-apple.systempreferences:com.apple.preference.security?General"]];
}

- (IBAction)closeAlert:(id)sender {
  [self.preferencesWindow endSheet:self.window];
}

- (IBAction)openSystemPolicyPreventsLoadingKextHelpWebPage:(id)sender {
  [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://pqrs.org/osx/karabiner/help.html#kext-allow-button-does-not-work"]];
}

@end
