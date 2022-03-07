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
//牺牲点空间换取时间。
@property (nonatomic, strong) NSMutableDictionary <NSNumber *, NSMutableArray<UICollectionViewLayoutAttributes *> *> *layoutItemSectionAttrsMap;

@property (nonatomic, assign) CGRect associationCellFrame;

@end

@implementation TPAnimeAudioTrackItemLayout
- (void)prepareLayout {
    [super prepareLayout];
    
    [self.layoutItemAttrs removeAllObjects];
    [self.layoutItemIndexAttrMap removeAllObjects];
    [self.layoutItemSectionAttrsMap removeAllObjects];
    for(int i = 0; i < [self.delegate numberOfSection4TrackItemLayout]; i++) {
        NSMutableArray *sectionAttrsArray = [NSMutableArray array];
        for(int j = 0; j < [self.delegate numberOfRow4TrackItemLayoutInSection:i]; j++) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:j inSection:i];
            UICollectionViewLayoutAttributes *attr = [self layoutAttributesForItemAtIndexPath:indexPath];
            [self.layoutItemAttrs addObject:attr];
            [self.layoutItemIndexAttrMap setObject:attr forKey:indexPath];
            [sectionAttrsArray addObject:attr];
        }
        [self.layoutItemSectionAttrsMap setObject:sectionAttrsArray forKey:@(i)];
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
    NSIndexPath *sourceIndexPath = [self.delegate sourceIndexPathOfDraggingItem];
    if ([self.delegate isAutoAssociationInSection:indexPath.section]) {
        /**
         这里是自动联想占位图的布局
         */
        CGRect soureItemFrame = [self.delegate layoutItemFrameAtIndexPath:sourceIndexPath];
        CGPoint currentDraggingPoint = [self.delegate currentCGPointOfDraggingItem];
        
        NSIndexPath *draggingIndexPath = [self.collectionView indexPathForItemAtPoint:currentDraggingPoint];
        BOOL draggingAboveItemCell = draggingIndexPath && ![self.delegate isAutoAssociationInSection:draggingIndexPath.section];
        if (!draggingAboveItemCell) {
            draggingIndexPath = [self nearestIndexPathForLayoutItemAtPoint:currentDraggingPoint];
        }
        
        float autoAssociationViewX = currentDraggingPoint.x - soureItemFrame.size.width/2.f;
        UICollectionViewLayoutAttributes *preAttri = self.layoutItemIndexAttrMap[draggingIndexPath];
        BOOL placeHolderXOccupied = NO;
        if ((draggingIndexPath.row == [self.delegate numberOfRow4TrackItemLayoutInSection:draggingIndexPath.section] -1) && draggingIndexPath != sourceIndexPath) {
            placeHolderXOccupied = autoAssociationViewX < (preAttri.frame.origin.x + preAttri.size.width);
        }
        //判断当前x是否有cell占用，yes:寻找当前section最近可用的。 no：使用当前位置
        if (placeHolderXOccupied) {
            atti.frame = CGRectMake(preAttri.frame.origin.x + preAttri.size.width, draggingIndexPath.section * soureItemFrame.size.height, soureItemFrame.size.width, soureItemFrame.size.height);
        }else {
            atti.frame = CGRectMake(autoAssociationViewX, draggingIndexPath.section * soureItemFrame.size.height, soureItemFrame.size.width, soureItemFrame.size.height);
        }
        NSLog(@"associationCellFrame=%@", NSStringFromCGRect(atti.frame));
        self.associationCellFrame = atti.frame;
        atti.zIndex = 2;
        atti.alpha = sourceIndexPath ? 1.f : 0.f;
    }else {
        //这里是元素cell布局。（音频元素etc）
        atti.frame = [self.delegate layoutItemFrameAtIndexPath:indexPath];
        if (sourceIndexPath == indexPath) {
            //处于拖拽状态的item在原位置隐藏起来。
            atti.alpha = 0.f;
        }else {
            atti.alpha = 1.f;
        }
    }
    return atti;
}

#pragma mark - Getter
- (CGRect)autoAssociationCellRect {
    return self.associationCellFrame;
}

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

- (NSMutableDictionary <NSNumber *, NSMutableArray<UICollectionViewLayoutAttributes *> *> *)layoutItemSectionAttrsMap {
    if (!_layoutItemSectionAttrsMap) {
        _layoutItemSectionAttrsMap = [NSMutableDictionary dictionary];
    }
    return _layoutItemSectionAttrsMap;
}

#pragma mark - Public
- (NSIndexPath *)nearestIndexPathForLayoutItemAtPoint:(CGPoint)point {
    NSIndexPath *sourceIndexPath = [self.delegate sourceIndexPathOfDraggingItem];
    CGRect itemFrame = [self.delegate layoutItemFrameAtIndexPath:sourceIndexPath];
    NSInteger pointInSection = ceilf(point.y / itemFrame.size.height) - 1;
    pointInSection = MAX(0, pointInSection);
    NSArray *attrsInSection = self.layoutItemSectionAttrsMap[@(pointInSection)];
    NSInteger pointInNearestRow = getRowByBinaryCheck(attrsInSection, point.x);
    return [NSIndexPath indexPathForRow:pointInNearestRow inSection:pointInSection];
}

#pragma mark - Function
NSInteger getRowByBinaryCheck(NSArray *sources, float checkX) {
    NSInteger index = 0, lowerBound = 0, upperBound = sources.count;
    NSInteger midBound;
    while (lowerBound < upperBound) {
        midBound = lowerBound + (upperBound - lowerBound) / 2;
        UICollectionViewLayoutAttributes *attr = sources[midBound];
        if (attr.frame.origin.x < checkX) {
            lowerBound = midBound  + 1;
        }else {
            upperBound = midBound;
        }
    }
    
    if (lowerBound == upperBound) {
        if(upperBound == sources.count) {
            index = sources.count - 1;
        }else if(lowerBound == 0){
            index = 0;
        }else {
            index = lowerBound;
        }
    }
    return index;
}

@end
