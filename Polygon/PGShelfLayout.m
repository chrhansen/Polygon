//
//  CHFlowLayout.m
//  Polygon
//
//  Created by Christian Hansen on 20/12/12.
//  Copyright (c) 2012 Calcul8.it. All rights reserved.
//

#import "PGShelfLayout.h"
#import "PGShelfView.h"

@interface PGShelfLayout ()

@property (nonatomic, strong) NSDictionary *shelfRects;

@end

@implementation PGShelfLayout

-(id)init
{
    self = [super init];
    if (self) {
        self.scrollDirection = UICollectionViewScrollDirectionVertical;
        if (IS_IPAD) {
            self.itemSize = CGSizeMake(140, 150);
            self.sectionInset = UIEdgeInsetsMake(10.0, 70.0, 50, 70.0);
        } else {
            self.itemSize = CGSizeMake(120, 129);
            self.sectionInset = UIEdgeInsetsMake(30.0, 30.0, 50, 30.0);
        }
        self.minimumLineSpacing = 222.0f - self.itemSize.height;
        [self registerClass:[PGShelfView class] forDecorationViewOfKind:@"ShelfView"];
    }
    return self;
}


// Do all the calculations for determining where shelves go here
- (void)prepareLayout
{
    // call super so flow layout can do all the math for cells, headers, and footers
    [super prepareLayout];
    
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    
    if (self.scrollDirection == UICollectionViewScrollDirectionVertical)
    {
        // Calculate where shelves go in a vertical layout
        int sectionCount = [self.collectionView numberOfSections];
        
        CGFloat y = 0;
        CGFloat availableWidth = self.collectionViewContentSize.width - (self.sectionInset.left + self.sectionInset.right);
        int itemsAcross = floorf((availableWidth + self.minimumInteritemSpacing) / (self.itemSize.width + self.minimumInteritemSpacing));
        
        for (int section = 0; section < sectionCount; section++)
        {
           // y += self.headerReferenceSize.height;
            y += self.sectionInset.top;
            
            int itemCount = [self.collectionView numberOfItemsInSection:section];
            int rows = ceilf(itemCount/(float)itemsAcross);
            for (int row = 0; row < rows; row++)
            {
                y += self.itemSize.height;
                dictionary[[NSIndexPath indexPathForItem:row inSection:section]] = [NSValue valueWithCGRect:CGRectMake(0, row*222, self.collectionViewContentSize.width, 222)];
                
                if (row < rows - 1)
                    y += self.minimumLineSpacing;
            }
            
            y += self.sectionInset.bottom;
            y += self.footerReferenceSize.height;
        }
    }
    else
    {
        // Calculate where shelves go in a horizontal layout
        CGFloat y = self.sectionInset.top;
        CGFloat availableHeight = self.collectionViewContentSize.height - (self.sectionInset.top + self.sectionInset.bottom);
        int itemsAcross = floorf((availableHeight + self.minimumInteritemSpacing) / (self.itemSize.height + self.minimumInteritemSpacing));
        CGFloat interval = ((availableHeight - self.itemSize.height) / (itemsAcross <= 1? 1 : itemsAcross - 1)) - self.itemSize.height;
        for (int row = 0; row < itemsAcross; row++)
        {
            y += self.itemSize.height;
            dictionary[[NSIndexPath indexPathForItem:row inSection:0]] = [NSValue valueWithCGRect:CGRectMake(0, roundf(y - 32), self.collectionViewContentSize.width, 37)];
            
            y += interval;
        }
    }
    
    self.shelfRects = [NSDictionary dictionaryWithDictionary:dictionary];
}

-(NSArray*)layoutAttributesForElementsInRect:(CGRect)rect
{
    NSMutableArray* array = [[super layoutAttributesForElementsInRect:rect] mutableCopy];
    [self.shelfRects enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        if (CGRectIntersectsRect([obj CGRectValue], rect))
        {
            UICollectionViewLayoutAttributes *attributes = [UICollectionViewLayoutAttributes layoutAttributesForDecorationViewOfKind:@"ShelfView" withIndexPath:key];
            attributes.frame = [obj CGRectValue];
            attributes.zIndex = 0;
            [array addObject:attributes];
        }
    }];
    
    array = [NSArray arrayWithArray:array];
    
    return array;
}


- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewLayoutAttributes *attributes = [super layoutAttributesForItemAtIndexPath:indexPath];
    attributes.zIndex = 1;
    return attributes;
}


// layout attributes for a specific decoration view
- (UICollectionViewLayoutAttributes *)layoutAttributesForDecorationViewOfKind:(NSString *)decorationViewKind atIndexPath:(NSIndexPath *)indexPath
{
    id shelfRect = self.shelfRects[indexPath];
    if (!shelfRect)
        return nil; // no shelf at this index (this is probably an error)
    
    UICollectionViewLayoutAttributes *attributes = [UICollectionViewLayoutAttributes layoutAttributesForDecorationViewOfKind:@"ShelfView" withIndexPath:indexPath];
    attributes.frame = [shelfRect CGRectValue];
    attributes.zIndex = 0; // shelves go behind other views
    
    return attributes;
}


@end
