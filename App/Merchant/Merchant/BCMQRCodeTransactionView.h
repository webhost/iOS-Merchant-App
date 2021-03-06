//
//  BCMQRCodeTransactionView.h
//  Merchant
//
//  Created by User on 10/31/14.
//  Copyright (c) 2014 com. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Transaction;

@class BCMQRCodeTransactionView;

@protocol BCMQRCodeTransactionViewDelegate <NSObject>

- (void)transactionViewDidComplete:(BCMQRCodeTransactionView *)transactionView;
- (void)transactionViewDidClear:(BCMQRCodeTransactionView *)transactionView;

@end

@interface BCMQRCodeTransactionView : UIView

@property (strong, nonatomic) Transaction *activeTransaction;
@property (weak, nonatomic) id <BCMQRCodeTransactionViewDelegate> delegate;

@end
