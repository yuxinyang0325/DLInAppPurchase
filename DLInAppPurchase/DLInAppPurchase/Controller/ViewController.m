//
//  ViewController.m
//  DLInAppPurchase
//
//  Created by FT_David on 2017/2/16.
//  Copyright © 2017年 FT_David. All rights reserved.
//

#import "ViewController.h"
#import "DLProductCell.h"
#import "SVProgressHUD.h"
#import <StoreKit/StoreKit.h>

@interface ViewController ()<UITableViewDelegate,UITableViewDataSource,SKProductsRequestDelegate,SKPaymentTransactionObserver>
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property(nonatomic,strong)NSMutableArray *productIDArray;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView.tableFooterView = [UIView new];
    NSString *plistPath = [[NSBundle mainBundle] pathForResource:@"productIDS" ofType:@"plist"];
    self.productIDArray =  [[NSMutableArray alloc] initWithContentsOfFile:plistPath];
    
     [[SKPaymentQueue defaultQueue] addTransactionObserver:self];

}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.productIDArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    DLProductCell *cell = [tableView dequeueReusableCellWithIdentifier:@"productCellID"];
    cell.productID = self.productIDArray[indexPath.row];
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSString *productID = self.productIDArray[indexPath.row];
    SKProductsRequest *request = [[SKProductsRequest alloc] initWithProductIdentifiers:[NSSet setWithArray:@[productID]]];
    request.delegate = self;
    [request start];
    [SVProgressHUD showWithStatus:@"正在加载"];
}

-(void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response
{
    if (response.invalidProductIdentifiers.count > 0) {
        [SVProgressHUD showErrorWithStatus:@"ProductID为无效ID"];
    }else{
        SKMutablePayment *payment = [SKMutablePayment paymentWithProduct:response.products.firstObject];
        [[SKPaymentQueue defaultQueue] addPayment:payment];
    }
}

- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions {
    for (SKPaymentTransaction *transaction in transactions)
    {
        switch (transaction.transactionState)
        {
            case SKPaymentTransactionStatePurchased:
                [self completeTransaction:transaction];
                break;
            case SKPaymentTransactionStateFailed:
                [self failedTransaction:transaction];
                break;
            case SKPaymentTransactionStateRestored:
                [self restoreTransaction:transaction];
                break;
            case SKPaymentTransactionStatePurchasing:
                break;
            default:
                break;
        }
    }
    
}

- (void)completeTransaction:(SKPaymentTransaction *)transaction {
    NSString *productIdentifier = transaction.payment.productIdentifier;
    NSData *data = [NSData dataWithContentsOfURL:[[NSBundle mainBundle] appStoreReceiptURL]];
    NSString *receipt = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    if ([receipt length] > 0 && [productIdentifier length] > 0) {
        [SVProgressHUD showSuccessWithStatus:@"支付成功"];
    }
    [[SKPaymentQueue defaultQueue] finishTransaction: transaction];
    
}


- (void)failedTransaction:(SKPaymentTransaction *)transaction {
    if(transaction.error.code != SKErrorPaymentCancelled) {
        [SVProgressHUD showErrorWithStatus:@"用户取消支付"];
    } else {
        [SVProgressHUD showErrorWithStatus:@"支付失败"];
    }
    [[SKPaymentQueue defaultQueue] finishTransaction: transaction];
}


- (void)restoreTransaction:(SKPaymentTransaction *)transaction {
    [[SKPaymentQueue defaultQueue] finishTransaction: transaction];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
