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
        self.sectionInset = UIEdgeInsetsMake(10.0, 10.0, 10, 10.0);
        self.minimumLineSpacing = 50.0;
//        [self registerNib:[UINib nibWithNibName:@"Shelf_iPad" bundle:nil] forDecorationViewOfKind:@"ShelfView"];
        [self registerClass:[ShelfView class] forDecorationViewOfKind:@"ShelfView"];
    }
    return self;
}


- (UICollectionViewLayoutAttributes *)layoutAttributesForDecorationViewOfKind:(NSString *)decorationViewKind atIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"layout for decoration!!");
    return nil;
}




- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewLayoutAttributes *attributes = [super layoutAttributesForItemAtIndexPath:indexPath];
    

    return attributes;
}

-(NSArray*)layoutAttributesForElementsInRect:(CGRect)rect
{
    NSMutableArray* array = [[super layoutAttributesForElementsInRect:rect] mutableCopy];
    
//    for (NSUInteger row = 0; row < 10; row++)
//    {
//        UICollectionViewLayoutAttributes *attributes =
//        [UICollectionViewLayoutAttributes layoutAttributesForDecorationViewOfKind:@"ShelfView" withIndexPath:[NSIndexPath indexPathForRow:row inSection:0]];
//        attributes.frame = CGRectMake(0, 0, self.collectionView.bounds.size.width, 1200);
//        [array addObject:attributes];
//    }
    
    return array;
}

@end
