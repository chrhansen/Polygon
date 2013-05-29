//
//  PGStoreViewController.m
//  Flow2Go
//
//  Created by Christian Hansen on 13/02/13.
//  Copyright (c) 2013 Christian Hansen. All rights reserved.
//

#import "PGStoreViewController.h"
#import "MKStoreManager.h"
#import "PGStoreCell.h"
#import "SKProduct+PriceAsString.h"
#import "MBProgressHUD.h"
#import "KGNoise.h"

@interface PGStoreViewController ()

@property (weak, nonatomic) IBOutlet UIBarButtonItem *restoreButton;
@property (nonatomic, strong) NSArray *childrenOfPurchasedBatches;
@property (nonatomic, strong) MBProgressHUD *progressHUD;

@end

@implementation PGStoreViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
//    [[MKStoreManager sharedManager] removeAllKeychainData];
    [self _addObservings];
    [self _addNoiseBackground];
}


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [[MKStoreManager sharedManager] reloadProducts];
    if ([[self purchases] count] == 0) {
        [self.view addSubview:self.progressHUD];
        [self.progressHUD show:YES];
    }
}


- (void)_addObservings
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(productsFetched:) name:kProductFetchedNotification object:nil];
}


-(NSUInteger)supportedInterfaceOrientations
{
    if (IS_IPAD) {
        return UIInterfaceOrientationMaskAll;
    }
    return UIInterfaceOrientationMaskPortrait;
}

- (void)_addNoiseBackground
{
    KGNoiseRadialGradientView *collectionNoiseView = [[KGNoiseRadialGradientView alloc] initWithFrame:self.collectionView.bounds];
    collectionNoiseView.backgroundColor            = [UIColor colorWithWhite:0.5032 alpha:1.000];
    collectionNoiseView.alternateBackgroundColor   = [UIColor colorWithWhite:0.5051 alpha:1.000];
    collectionNoiseView.noiseOpacity = 0.07;
    collectionNoiseView.noiseBlendMode = kCGBlendModeNormal;
    self.collectionView.backgroundView = collectionNoiseView;
}


- (MBProgressHUD *)progressHUD
{
    if (_progressHUD == nil) {
        _progressHUD = [[MBProgressHUD alloc] initWithView:self.view];
        _progressHUD.dimBackground = YES;
        _progressHUD.removeFromSuperViewOnHide = YES;
    }
    return _progressHUD;
}

- (void)buyButtonTapped:(id)sender
{
    NSInteger productIndex = [(UIButton *)sender tag];
    [[MKStoreManager sharedManager] buyFeature:[[self purchases][productIndex] productIdentifier] onComplete:^(NSString *purchasedFeature, NSData *purchasedReceipt, NSArray *availableDownloads) {
        [self.progressHUD hide:YES];
        NSAssert([NSThread isMainThread], @"WTF! completion handler not on main thread");
        [self loadBatchPurchases];
        [self reloadProductWithIdentifier:purchasedFeature];
    } onCancelled:^{
        [self.progressHUD hide:YES];
        NSAssert([NSThread isMainThread], @"WTF! completion handler not on main thread");
    }];
}


- (IBAction)restoreTapped:(id)sender
{
    [[MKStoreManager sharedManager] restorePreviousTransactionsOnComplete:^{
        NSAssert([NSThread isMainThread], @"WTF! completion handler not on main thread");
        [self.progressHUD hide:YES];
        [self loadBatchPurchases];
        if ([[self purchases] count]) {
            [self.collectionView reloadItemsAtIndexPaths:[self.collectionView indexPathsForVisibleItems]];
        }
    } onError:^(NSError *error) {
        NSAssert([NSThread isMainThread], @"WTF! completion handler not on main thread");
        [self.progressHUD hide:YES];
        [self _presentErrorMessage:error.localizedDescription];
    }];
}



- (void)_presentErrorMessage:(NSString *)errorMessage
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", nil)
                                                        message:errorMessage
                                                       delegate:nil
                                              cancelButtonTitle:NSLocalizedString(@"OK", nil)
                                              otherButtonTitles:nil];
    [alertView show];
}


- (void)loadBatchPurchases
{
    NSDictionary *batchProducts = [NSDictionary dictionaryWithContentsOfFile: [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"MKStoreKitConfigs.plist"]][@"Non-Consumables-batch"];
    NSMutableArray *childProducts = [NSMutableArray array];
    for (SKProduct *product in [self purchases]) {
        if ([MKStoreManager isFeaturePurchased:product.productIdentifier] && batchProducts[product.productIdentifier]) {
            [childProducts addObjectsFromArray:batchProducts[product.productIdentifier]];
        }
    }
    self.childrenOfPurchasedBatches = childProducts;
}


#pragma mark Store updates
- (void)productsFetched:(NSNotification *)notification
{
    [self.progressHUD hide:YES];
    NSNumber *isProductsAvailable = notification.object;
    if (isProductsAvailable.boolValue) {
        [self loadBatchPurchases];
        [self.collectionView reloadData];
    }
}


- (void)reloadProductWithIdentifier:(NSString *)productIdentifier
{
    if (!productIdentifier) return;
    NSUInteger row = [[self purchases] indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
        SKProduct *product = (SKProduct *)obj;
        if (product.productIdentifier == productIdentifier) {
            *stop = YES;
            return YES;
        }
        return NO;
    }];
    [self.collectionView reloadItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:row inSection:0]]];
}

- (void)configureCell:(UICollectionViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    SKProduct *product = [[self purchases] objectAtIndex:indexPath.row];
    PGStoreCell *storeCell = (PGStoreCell *)cell;
    storeCell.titleLabel.text = product.localizedTitle;
    storeCell.descriptionLabel.text = product.localizedDescription;
    [storeCell.descriptionLabel sizeToFit];
    if ([self.childrenOfPurchasedBatches containsObject:product.productIdentifier]) {
        [storeCell.buyButton setTitle:NSLocalizedString(@"Unavailable", nil) forState:UIControlStateNormal];
        [storeCell.buyButton setEnabled:NO];
    }
    else if ([MKStoreManager isFeaturePurchased:product.productIdentifier]) {
        [storeCell.buyButton setTitle:NSLocalizedString(@"Purchased", nil) forState:UIControlStateNormal];
        [storeCell.buyButton setEnabled:NO];
    } else {
        [storeCell.buyButton setTitle:product.priceAsString forState:UIControlStateNormal];
        storeCell.buyButton.tag = indexPath.row;
        [storeCell.buyButton setEnabled:YES];
        if (storeCell.buyButton.allTargets.count == 0) {
            [storeCell.buyButton addTarget:self action:@selector(buyButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        }
    }
    storeCell.mainImageView.image = [self imageForProductIdentifier:product.productIdentifier];
}


- (UIImage *)imageForProductIdentifier:(NSString *)productIdentifier
{
    UIImage *image;
    if ([productIdentifier isEqualToString:@"it.calcul8.polygon.ansys"]) {
        image = IS_IPAD ? [UIImage imageNamed:@"fe-purchase-ipad"] : [UIImage imageNamed:@"fe-purchase"];
    } else if ([productIdentifier isEqualToString:@"it.calcul8.polygon.objmodels"]) {
        image = IS_IPAD ? [UIImage imageNamed:@"obj-purchase-ipad"] : [UIImage imageNamed:@"obj-purchase"];
    } else if ([productIdentifier isEqualToString:@"it.calcul8.polygon.daemodels"]) {
        image = IS_IPAD ? [UIImage imageNamed:@"dae-purchase-ipad"] : [UIImage imageNamed:@"dae-purchase"];
    } else if ([productIdentifier isEqualToString:@"it.calcul8.polygon.unlimitedmodels"]) {
        image = IS_IPAD ? [UIImage imageNamed:@"batch-purchase-ipad"] : [UIImage imageNamed:@"batch-purchase"];
    }
    return image;
}


- (NSArray *)purchases
{
    return [[[MKStoreManager sharedManager] purchasableObjects] sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        SKProduct *product1 = (SKProduct *)obj1;
        SKProduct *product2 = (SKProduct *)obj2;
        return [product2.productIdentifier compare:product1.productIdentifier];
    }];
}

#pragma mark - Table view data source
#pragma mark - UICollectionView Datasource
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [[self purchases] count];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Store Cell";
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:CellIdentifier forIndexPath:indexPath];
    if (cell) [self configureCell:cell atIndexPath:indexPath];
    return cell;
}


@end
