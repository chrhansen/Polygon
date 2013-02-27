//
//  PGModel.h
//  Polygon
//
//  Created by Christian Hansen on 21/12/12.
//  Copyright (c) 2012 Calcul8.it. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class PGView;

@interface PGModel : NSManagedObject

@property (nonatomic, retain) NSNumber * dateAdded;
@property (nonatomic, retain) NSString * pGModelID;
@property (nonatomic, retain) NSString * filePath;
@property (nonatomic, retain) NSString * globalURL;
@property (nonatomic, retain) UIImage * modelImage;
@property (nonatomic, retain) NSString * modelName;
@property (nonatomic, retain) NSNumber * modelSize;
@property (nonatomic, retain) NSOrderedSet *views;
@end

@interface PGModel (CoreDataGeneratedAccessors)

- (void)insertObject:(PGView *)value inViewsAtIndex:(NSUInteger)idx;
- (void)removeObjectFromViewsAtIndex:(NSUInteger)idx;
- (void)insertViews:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeViewsAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInViewsAtIndex:(NSUInteger)idx withObject:(PGView *)value;
- (void)replaceViewsAtIndexes:(NSIndexSet *)indexes withViews:(NSArray *)values;
- (void)addViewsObject:(PGView *)value;
- (void)removeViewsObject:(PGView *)value;
- (void)addViews:(NSOrderedSet *)values;
- (void)removeViews:(NSOrderedSet *)values;

@end
