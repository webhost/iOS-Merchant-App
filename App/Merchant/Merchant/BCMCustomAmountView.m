//
//  BCMCustomAmountView.m
//  Merchant
//
//  Created by User on 10/28/14.
//  Copyright (c) 2014 com. All rights reserved.
//

#import "BCMCustomAmountView.h"

#import "BCMTextField.h"

#import "UIColor+Utilities.h"

@interface BCMCustomAmountView () <UITextFieldDelegate>

@property (strong, nonatomic) UIView *inputAccessoryView;

@end

@implementation BCMCustomAmountView

- (void)clear
{
    self.customAmountTextField.text = @"";
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    textField.inputAccessoryView = [self inputAccessoryView];
    
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    
    return YES;
}

- (UIView *)inputAccessoryView {
    if (!_inputAccessoryView) {
        UIView *parentView = [self superview];
        CGRect accessFrame = CGRectMake(0.0, 0.0, CGRectGetWidth(parentView.frame), 54.0f);
        self.inputAccessoryView = [[UIView alloc] initWithFrame:accessFrame];
        self.inputAccessoryView.backgroundColor = [UIColor colorWithHexValue:BCM_BLUE];
        UIButton *compButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        compButton.frame = CGRectMake(CGRectGetWidth(parentView.frame) - 80.0f, 10.0, 80.0f, 40.0f);
        [compButton.titleLabel setFont:[UIFont fontWithName:@"HelveticaNeue-Light" size:20.0f]];
        [compButton setTitle: NSLocalizedString(@"general.done", nil) forState:UIControlStateNormal];
        [compButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [compButton addTarget:self action:@selector(accessoryDoneAction:)
             forControlEvents:UIControlEventTouchUpInside];
        
        UIButton *cancelButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        cancelButton.frame = CGRectMake(0, 10.0, 80.0f, 40.0f);
        [cancelButton.titleLabel setFont:[UIFont fontWithName:@"HelveticaNeue-Light" size:20.0f]];
        [cancelButton setTitle: NSLocalizedString(@"action.cancel", nil) forState:UIControlStateNormal];
        [cancelButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [cancelButton addTarget:self action:@selector(accessoryCancelAction:)
             forControlEvents:UIControlEventTouchUpInside];
        [self.inputAccessoryView addSubview:cancelButton];
        [self.inputAccessoryView addSubview:compButton];
    }
    return _inputAccessoryView;
}

- (void)accessoryCancelAction:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(customAmountViewDidCancelEntry:)]) {
        [self.delegate customAmountViewDidCancelEntry:self];
    }
    
    [self endEditing:YES];
}

- (void)accessoryDoneAction:(id)sender
{
    NSString *amountText = self.customAmountTextField.text;
    
    if ([amountText length] == 0) {
        amountText = @"0.00";
    }
    
    if ([self.delegate respondsToSelector:@selector(customAmountView:addCustomAmount:)]) {
        [self.delegate customAmountView:self addCustomAmount:[amountText floatValue]];
    }
    
    [self endEditing:YES];
}

@end
