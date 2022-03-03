//
//  TPAnimeAudioTrackItemLayout.m
//  TPVideo
//
//  Created by User on 2022/3/1.
//  Copyright © 2022 Dreampix. All rights reserved.
//

#import "TPAnimeAudioTrackItemLayout.h"

@interface TPAnimeAudioTrackItemLayout ()
@property (nonatomic, strong) NSMutableArray<UICollectionViewLayoutAttributes *> *layoutItemAttrs;
@property (nonatomic, strong) NSMutableDictionary <NSIndexPath *, UICollectionViewLayoutAttributes *> *layoutItemIndexAttrMap;
@end

@implementation TPAnimeAudioTrackItemLayout
- (void)prepareLayout {
    [super prepareLayout];
    
    [self.layoutItemAttrs removeAllObjects];
    for(int i = 0; i < [self.delegate numberOfSection4TrackItemLayout]; i++) {
        for(int j = 0; j < [self.delegate numberOfRow4TrackItemLayoutInSection:i]; j++) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:j inSection:i];
            UICollectionViewLayoutAttributes *attr = [self layoutAttributesForItemAtIndexPath:indexPath];
            [self.layoutItemAttrs addObject:attr];
            [self.layoutItemIndexAttrMap setObject:attr forKey:indexPath];
        }
    }
}

- (CGSize)collectionViewContentSize {
    return self.delegate.trackLayoutContentSize;
}

- (NSArray<__kindof UICollectionViewLayoutAttributes *> *)layoutAttributesForElementsInRect:(CGRect)rect {
    return self.layoutItemAttrs;
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewLayoutAttributes *atti = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
    CGSize cellSize = [self.delegate layoutItemSizeAtIndexPath:indexPath];
    if ([self.delegate checkItemPlaceHolderInSection:indexPath.section]) {
        CGPoint panningPoint = [self.delegate currentCGPointOfDraggingItem];
        NSIndexPath *draggingIndexPath = [self getDraggingDestinationIndexPathWithPoint:panningPoint];
        float placeHolderX = panningPoint.x - cellSize.width/2.f;
        NSIndexPath *preIndexPath = [NSIndexPath indexPathForRow:draggingIndexPath.row-1 inSection:draggingIndexPath.section];
        UICollectionViewLayoutAttributes *preAttri = self.layoutItemIndexAttrMap[preIndexPath];
        BOOL placeHolderXOccupied = NO;
        if(placeHolderX < preAttri.frame.origin.x + preAttri.size.width) {
            placeHolderXOccupied = YES;
        }
        //判断当前x是否有cell占用，yes:寻找当前section最近可用的。 no：使用当前位置
        if (placeHolderXOccupied) {
            atti.frame = CGRectMake(preAttri.frame.origin.x + preAttri.size.width, draggingIndexPath.section * cellSize.height, cellSize.width, cellSize.height);
        }else {
            atti.frame = CGRectMake(placeHolderX, draggingIndexPath.section * cellSize.height, cellSize.width, cellSize.height);
        }
        atti.zIndex = 2;
        atti.alpha = [self.delegate sourceIndexPathOfDraggingItem] ? 1.f : 0.f;
    }else {
        atti.frame = CGRectMake(indexPath.row * (cellSize.width + 50), indexPath.section * cellSize.height, cellSize.width, cellSize.height);
        if ([self.delegate sourceIndexPathOfDraggingItem] == indexPath) {
            //处于拖拽状态的item在原位置隐藏起来。
            atti.alpha = 0.f;
        }else {
            atti.alpha = 1.f;
        }
    }
    return atti;
}

#pragma mark - Getter
- (NSMutableArray *)layoutItemAttrs {
    if (!_layoutItemAttrs) {
        _layoutItemAttrs = [NSMutableArray array];
    }
    return _layoutItemAttrs;
}

- (NSMutableDictionary<NSIndexPath *, UICollectionViewLayoutAttributes *> *)layoutItemIndexAttrMap {
    if (!_layoutItemIndexAttrMap) {
        _layoutItemIndexAttrMap = [NSMutableDictionary dictionary];
    }
    return _layoutItemIndexAttrMap;
}

#pragma mark - Public
- (NSIndexPath *)getDraggingDestinationIndexPathWithPoint:(CGPoint)point {
    NSIndexPath *pointAtIndexPath = [self.collectionView indexPathForItemAtPoint:point];
    NSLog(@"getDraggingDestinationIndexPathWithPoint=> %@", pointAtIndexPath.description);
    if (pointAtIndexPath && ![self.delegate checkItemPlaceHolderInSection:pointAtIndexPath.section]) {
        return pointAtIndexPath;
    }
    
    NSIndexPath *draggingIndexPath = [self.delegate sourceIndexPathOfDraggingItem];
    CGSize cellSize = [self.delegate layoutItemSizeAtIndexPath:draggingIndexPath];
    NSInteger draggingInSection = ceilf(point.y / cellSize.height) - 1;
    draggingInSection = MAX(0, draggingInSection);
    /**
     这样还得考虑一个问题：就是得改变 holder 的样式。fuck！
     */
    NSInteger draggingInRow = 0;
    NSInteger count = [self.delegate numberOfRow4TrackItemLayoutInSection:draggingInSection];
    float sectionWidth = cellSize.width*count;
    if (point.x >= sectionWidth) {
        //尾部插入
        draggingInRow = count;
    }else {
        draggingInRow = ceilf(point.y / cellSize.width) - 1;
    }
    return [NSIndexPath indexPathForRow:draggingInRow inSection:draggingInSection];
}
@end
