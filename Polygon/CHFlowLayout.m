//
//  CHFlowLayout.m
//  Polygon
//
//  Created by Christian Hansen on 20/12/12.
//  Copyright (c) 2012 Calcul8.it. All rights reserved.
//

#import "CHFlowLayout.h"
#import "ShelfView.h"

@implementation CHFlowLayout

-(id)init
{
    self = [super init];
    if (self) {
        self.itemSize = CGSizeMake(140, 150);
        self.scrollDirection = UICollectionViewScrollDirectionVertical;
        if (IS_IPAD) {
            self.itemSize = CGSizeMake(140, 150);
            self.sectionInset = UIEdgeInsetsMake(10.0, 70.0, 50, 70.0);
        } else {
            self.itemSize = CGSizeMake(120, 129);
            self.sectionInset = UIEdgeInsetsMake(30.0, 30.0, 50, 30.0);
        }
        self.minimumLineSpacing = 93.0;
        [self registerClass:[ShelfView class] forDecorationViewOfKind:@"ShelfView"];
    }
    return self;
}

//
//
//- (UICollectionViewLayoutAttributes *)layoutAttributesForDecorationViewOfKind:(NSString *)decorationViewKind atIndexPath:(NSIndexPath *)indexPath
//{
//    NSLog(@"layout for decoration!!");
//    return nil;
//}
//


- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewLayoutAttributes *attributes = [super layoutAttributesForItemAtIndexPath:indexPath];
    

    return attributes;
}

-(NSArray*)layoutAttributesForElementsInRect:(CGRect)rect
{
    NSMutableArray* array = [[super layoutAttributesForElementsInRect:rect] mutableCopy];
    
    NSUInteger firstShelfRow = rect.origin.y / 222;
    NSUInteger numberOfVisibleRows = 5;
//    NSLog(@"rect: %@, firstShelfRow: %d, numberOfVisibleRows: %d", NSStringFromCGRect(rect), firstShelfRow, numberOfVisibleRows);

    for (NSUInteger row = firstShelfRow; row < firstShelfRow + numberOfVisibleRows; row++)
    {
        UICollectionViewLayoutAttributes *attributes =
        [UICollectionViewLayoutAttributes layoutAttributesForDecorationViewOfKind:@"ShelfView" withIndexPath:[NSIndexPath indexPathForRow:row inSection:0]];
        attributes.frame = CGRectMake(0, row * 222, self.collectionView.bounds.size.width, 222);
//        NSLog(@"attributes.frame: %@", NSStringFromCGRect(attributes.frame));
        [array addObject:attributes];
    }
    
    return array;
}

@end
