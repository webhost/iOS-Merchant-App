//
//  BCPinEntryViewController.m
//  Merchant
//
//  Created by User on 11/19/14.
//  Copyright (c) 2014 com. All rights reserved.
//

#import "BCPinEntryViewController.h"

#import "BCPinEntryView.h"
#import "BCPinNumberKey.h"

typedef NS_ENUM(NSUInteger, PinEntryModeCreateState) {
    PinEntryModeCreateStateEnter,
    PinEntryModeCreateStateValidate,
    PinEntryModeCreateStateComplete,
    PinEntryModeCreateStateFail
};

typedef NS_ENUM(NSUInteger, PinEntryModeResetState) {
    PinEntryModeResetStateEnter,
    PinEntryModeResetStateEnterCurrentFail,
    PinEntryModeResetStateEnterNew,
    PinEntryModeResetStateValidate,
    PinEntryModeResetStateComplete,
    PinEntryModeResetStateFail,
    PinEntryModeResetStateEnterFail
};

typedef NS_ENUM(NSUInteger, PinEntryModeAccess) {
    PinEntryModeAccessEnter,
    PinEntryModeAccessComplete,
    PinEntryModeAccessFail
};

NSString *const kPinEntryStoryboardId = @"pinEntryViewControllerId";

@interface BCPinEntryViewController () <BCPinEntryViewDelegate>

@property (weak, nonatomic) IBOutlet UIView *keypadContainerView;
@property (weak, nonatomic) IBOutlet BCPinEntryView *pinEntryView;

@property (weak, nonatomic) IBOutlet UILabel *titleLbl;
@property (weak, nonatomic) IBOutlet UIImageView *entryImageView1;
@property (weak, nonatomic) IBOutlet UIImageView *entryImageView2;
@property (weak, nonatomic) IBOutlet UIImageView *entryImageView3;
@property (weak, nonatomic) IBOutlet UIImageView *entryImageView4;

@property (strong, nonatomic) NSArray *entryImageViews;
@property (strong, nonatomic) NSMutableString *pin;
@property (strong, nonatomic) NSString *firstEnteredPin;
@property (strong, nonatomic) NSString *secondEnteredPin;

@property (assign, nonatomic) NSUInteger entryCounter;

@property (assign, nonatomic) PinEntryModeCreateState createState;
@property (assign, nonatomic) PinEntryModeResetState resetState;
@property (assign, nonatomic) PinEntryModeAccess entryState;

@property (weak, nonatomic) IBOutlet UILabel *infoLbl;

@end

@implementation BCPinEntryViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.pinEntryView.delegate = self;
    
    self.entryImageViews = @[ self.entryImageView1, self.entryImageView2, self.entryImageView3, self.entryImageView4 ];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (self.userMode == PinEntryUserModeCreate || self.userMode == PinEntryUserModeReset) {
        [self addNavigationType:BCMNavigationTypeCancel position:BCMNavigationPositionLeft selector:@selector(cancelAction:)];
    }
}

- (void)clearPinImageViews
{
    for (UIImageView *imageView in self.entryImageViews) {
        imageView.image = [UIImage imageNamed:@"PEPin-off"];
    }
}

@synthesize userMode = _userMode;

- (void)setUserMode:(PinEntryUserMode)userMode
{
    _userMode = userMode;

    if (_userMode == PinEntryUserModeCreate) {
        self.createState = PinEntryModeCreateStateEnter;
    } else if (_userMode == PinEntryUserModeReset) {
        self.resetState = PinEntryModeResetStateEnter;
    } else if (_userMode == PinEntryUserModeAccess) {
        self.entryState = PinEntryModeAccessEnter;
    }
}

@synthesize entryCounter = _entryCounter;

- (void)setEntryCounter:(NSUInteger)entryCounter
{
    NSUInteger previousEntryCounter = _entryCounter;
    
    _entryCounter = entryCounter;
    
    if (previousEntryCounter >= _entryCounter) {
        // We need to clear out the last entry image
        previousEntryCounter = MAX(1, previousEntryCounter);
        UIImageView *previousEntryImageView = [self.entryImageViews objectAtIndex:previousEntryCounter - 1];
        previousEntryImageView.image = [UIImage imageNamed:@"PEPin-off"];
    }
    
    if (_entryCounter > 0) {
        _entryCounter = MAX(1, _entryCounter);
        UIImageView *entryImageView = [self.entryImageViews objectAtIndex:_entryCounter - 1];
        entryImageView.image = [UIImage imageNamed:@"PEPin-on"];
    }
}

#pragma mark - Actions

- (void)cancelAction:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - BCPinEntryViewDelegate

- (void)pinEntryView:(BCPinEntryView *)entryView selectedPinKey:(BCPinNumberKey *)key
{
    if (key.keyTag == PinKeyEntryButtonDelete) {
        if (self.entryCounter > 0) {
            self.entryCounter--;
            [self.pin substringWithRange:NSMakeRange(0, self.entryCounter)];
        }
    } else {
        self.entryCounter++;
        [self.pin appendString:[NSString stringWithFormat:@"%lu", (unsigned long)key.keyTag]];
    }
    
    if (self.entryCounter == 4) {
        _entryCounter = 0;
        // We have enough to move on to the next state
        if (self.userMode == PinEntryUserModeAccess) {
            if ([self.delegate respondsToSelector:@selector(pinEntryViewController:validatePin:)]) {
                BOOL validPin = [self.delegate pinEntryViewController:self validatePin:self.pin];
                if (validPin) {
                    self.entryState = PinEntryModeAccessComplete;
                } else {
                    self.entryState = PinEntryModeAccessFail;
                }
            }
        } else if (self.userMode == PinEntryUserModeCreate) {
            if (self.createState == PinEntryModeCreateStateEnter) {
                self.createState++;
            } else if (self.createState == PinEntryModeCreateStateValidate) {
                if ([self.firstEnteredPin isEqualToString:self.pin]) {
                    self.createState = PinEntryModeCreateStateComplete;
                } else {
                    self.createState = PinEntryModeCreateStateFail;
                }
            }
        } else if (self.userMode == PinEntryUserModeReset) {
            if (self.resetState == PinEntryModeResetStateEnter) {
                if ([self.delegate respondsToSelector:@selector(pinEntryViewController:validatePin:)]) {
                    BOOL validPin = [self.delegate pinEntryViewController:self validatePin:self.pin];
                    if (validPin) {
                        self.resetState = PinEntryModeResetStateEnterNew;
                    } else {
                        self.resetState = PinEntryModeResetStateEnterCurrentFail;
                    }
                }
            } else if (self.resetState == PinEntryModeResetStateEnterNew) {
                self.resetState = PinEntryModeResetStateValidate;
            } else if (self.resetState == PinEntryModeResetStateValidate) {
                if ([self.firstEnteredPin isEqualToString:self.pin]) {
                    self.resetState = PinEntryModeResetStateComplete;
                } else {
                    self.resetState = PinEntryModeResetStateFail;
                }
            }
        }
    }
}

@synthesize createState = _createState;

- (void)setCreateState:(PinEntryModeCreateState)createState
{
    _createState = createState;
    
    self.infoLbl.text = @"";

    if (_createState == PinEntryModeCreateStateEnter) {
        // We need the user to enter it twice
        self.titleLbl.text = @"Enter your passcode";
        self.pin = [[NSMutableString alloc] init];
        self.firstEnteredPin = @"";
        self.secondEnteredPin = @"";
        self.entryCounter = 0;
        [self clearPinImageViews];
    } else if (_createState == PinEntryModeCreateStateValidate) {
        self.titleLbl.text = @"Re-enter your passcode";
        self.firstEnteredPin = self.pin;
        self.pin = [[NSMutableString alloc] init];
        [self clearPinImageViews];
    } else if (_createState == PinEntryModeCreateStateComplete) {
        [self dismissViewControllerAnimated:YES completion:^{
            if ([self.delegate respondsToSelector:@selector(pinEntryViewController:successfulEntry:pin:)]) {
                [self.delegate pinEntryViewController:self successfulEntry:YES pin:self.pin];
            }
        }];
    } else if (_createState == PinEntryModeCreateStateFail) {
        _createState = PinEntryModeCreateStateEnter;
        // We need the user to enter it twice
        self.titleLbl.text = @"Enter your passcode";
        self.pin = [[NSMutableString alloc] init];
        self.firstEnteredPin = @"";
        self.secondEnteredPin = @"";
        [self clearPinImageViews];
        if ([self.delegate respondsToSelector:@selector(pinEntryViewController:successfulEntry:pin:)]) {
            [self.delegate pinEntryViewController:self successfulEntry:YES pin:self.pin];
        }
    }
}

@synthesize resetState = _resetState;

- (void)setResetState:(PinEntryModeResetState)resetState
{
    _resetState = resetState;

    self.infoLbl.text = @"";

    if (_resetState == PinEntryModeResetStateEnter) {
        self.titleLbl.text = @"Enter current passcode";
        self.pin = [[NSMutableString alloc] init];
        self.firstEnteredPin = @"";
        self.secondEnteredPin = @"";
        [self clearPinImageViews];
    } else if (_resetState == PinEntryModeResetStateEnterCurrentFail) {
        self.infoLbl.text = @"Passcode Validation Failed";
        self.pin = [[NSMutableString alloc] init];
        self.firstEnteredPin = @"";
        self.secondEnteredPin = @"";
        _resetState = PinEntryModeResetStateEnter;
        [self clearPinImageViews];
    } else if (_resetState == PinEntryModeResetStateEnterNew) {
        self.titleLbl.text = @"Enter new passcode";
        self.firstEnteredPin = @"";
        self.secondEnteredPin = @"";
        self.pin = [[NSMutableString alloc] init];
        [self clearPinImageViews];
    } else if (_resetState == PinEntryModeResetStateValidate) {
        self.titleLbl.text = @"Re-enter passcode";
        self.firstEnteredPin = self.pin;
        self.pin = [[NSMutableString alloc] init];
        [self clearPinImageViews];
    }  else if (_resetState == PinEntryModeResetStateFail) {
        self.titleLbl.text = @"Enter new passcode";
        self.pin = [[NSMutableString alloc] init];
        self.firstEnteredPin = @"";
        self.secondEnteredPin = @"";
        _resetState = PinEntryModeResetStateEnterNew;
        self.infoLbl.text = @"Passcode Validation Failed";
        [self clearPinImageViews];
    } else if (_resetState == PinEntryModeResetStateComplete) {
        if ([self.delegate respondsToSelector:@selector(pinEntryViewController:successfulEntry:pin:)]) {
            [self.delegate pinEntryViewController:self successfulEntry:YES pin:self.pin];
        }
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

@synthesize entryState = _entryState;

- (void)setEntryState:(PinEntryModeAccess)entryState
{
    _entryState = entryState;
    self.infoLbl.text = @"";

    if(_entryState == PinEntryModeAccessEnter) {
        self.titleLbl.text = @"Enter your passcode";
        self.pin = [[NSMutableString alloc] init];
        self.firstEnteredPin = @"";
        self.secondEnteredPin = @"";
        [self clearPinImageViews];
    } else if (_entryState == PinEntryModeAccessFail) {
        self.titleLbl.text = @"Enter your passcode";
        self.pin = [[NSMutableString alloc] init];
        self.firstEnteredPin = @"";
        self.secondEnteredPin = @"";
        [self clearPinImageViews];
        self.infoLbl.text = @"Passcode Incorrect";
    } else if (_entryState == PinEntryModeAccessComplete) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

@end