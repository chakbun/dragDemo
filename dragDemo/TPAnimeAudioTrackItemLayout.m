//
//  TPAnimeAudioTrackItemLayout.m
//  TPVideo
//
//  Created by User on 2022/3/1.
//  Copyright © 2022 Dreampix. All rights reserved.
//

#import "TPAnimeAudioTrackItemLayout.h"

#pragma mark - Function
static float leftOfRect(CGRect rect) {
    return rect.origin.x;
}

static float widthOfRect(CGRect rect) {
    return rect.size.width;
}
static float centerXOfRect(CGRect rect) {
    return leftOfRect(rect) + widthOfRect(rect)/2.f;
}

@interface TPAnimeAudioTrackItemLayout ()
@property (nonatomic, strong) NSMutableArray<UICollectionViewLayoutAttributes *> *layoutItemAttrs;
@property (nonatomic, strong) NSMutableDictionary <NSIndexPath *, UICollectionViewLayoutAttributes *> *layoutItemIndexAttrMap;
//牺牲点空间换取时间。
@property (nonatomic, strong) NSMutableDictionary <NSNumber *, NSMutableArray<UICollectionViewLayoutAttributes *> *> *layoutItemSectionAttrsMap;

@property (nonatomic, assign) CGRect associationCellFrame;

@property (nonatomic, assign) NSInteger compareIndexPathPosition;

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
        
        NSIndexPath *currentPointOnIndexPath = [self.collectionView indexPathForItemAtPoint:currentDraggingPoint];
        NSIndexPath *compareIndexPath = nil;
        NSLog(@"draggingIndexPath=%@", currentPointOnIndexPath.description);
        BOOL isAutoAssociationcCellIndexPath = [self.delegate isAutoAssociationInSection:currentPointOnIndexPath.section];
        BOOL draggingAboveItemCell = currentPointOnIndexPath && !isAutoAssociationcCellIndexPath && (currentPointOnIndexPath != sourceIndexPath);
        
        float autoAssociationViewX = currentDraggingPoint.x - widthOfRect(soureItemFrame)/2.f;

        self.compareIndexPathPosition = 0; //0:pre 1:next;
        
        if (draggingAboveItemCell) {
            //判断是在 cell 中点的左边还是右边。
            if (!isAutoAssociationcCellIndexPath) {
                //当前手指所在的 cell 的 UICollectionViewLayoutAttributes 👇
                UICollectionViewLayoutAttributes *abvCellattri = self.layoutItemIndexAttrMap[currentPointOnIndexPath];
                float abvCellCenterX = centerXOfRect(abvCellattri.frame);
                if (currentDraggingPoint.x > abvCellCenterX) {
                    NSLog(@"autoAssociationViewX > abvCellCenterX =======> right");
                    //寻找下一个元素的空位。
                    NSIndexPath *nextIndexPath = [NSIndexPath indexPathForRow:currentPointOnIndexPath.row + 1 inSection:currentPointOnIndexPath.section];
                    if(self.layoutItemIndexAttrMap[nextIndexPath]) {
                        //表示有下一个元素。
                        compareIndexPath = nextIndexPath;
                        self.compareIndexPathPosition = 1;
                    }else {
                        compareIndexPath = currentPointOnIndexPath;
                        //没有下一个元素，插到末尾。
                    }
                    
                }else {
                    NSLog(@"autoAssociationViewX < abvCellCenterX =======> left");
                    //寻找上一个元素
                    NSIndexPath *preIndexPath = [NSIndexPath indexPathForRow:currentPointOnIndexPath.row - 1 inSection:currentPointOnIndexPath.section];
                    if(self.layoutItemIndexAttrMap[preIndexPath]) {
                        //有上一个元素。
                        compareIndexPath = preIndexPath;
                        self.compareIndexPathPosition = 0;
                    }else {
                        //没有上一个元素。
                    }
                    
                }
            }
        }else {
            //### CASE3
            currentPointOnIndexPath = [self nearestIndexPathForLayoutItemAtPoint:currentDraggingPoint];
            compareIndexPath = currentPointOnIndexPath;
            self.compareIndexPathPosition = 0;
        }
        
        UICollectionViewLayoutAttributes *compareAttri = self.layoutItemIndexAttrMap[compareIndexPath];
        BOOL placeHolderXOccupied = NO;
        
        if (self.compareIndexPathPosition == 0) {
            //比较左边👈
            if ((compareIndexPath.row == [self.delegate numberOfRow4TrackItemLayoutInSection:currentPointOnIndexPath.section] -1) && currentPointOnIndexPath != sourceIndexPath && (compareIndexPath = currentPointOnIndexPath)) {
                //### FOR CASE3 above
                placeHolderXOccupied = ( autoAssociationViewX < centerXOfRect(compareAttri.frame));
            }else if(currentPointOnIndexPath != sourceIndexPath){
                //不在自己原来位置上的拖动。
                placeHolderXOccupied = ( autoAssociationViewX > leftOfRect(compareAttri.frame));
            }else if(currentPointOnIndexPath == sourceIndexPath){
                //比较自己
                if (compareAttri.frame.origin.x) {
                    
                }
            }
        }else {
            //比较右边👉
        }
        
        //判断当前x是否有cell占用，yes:寻找当前section最近可用的。 no：使用当前位置
        //这里还得根据塞入的位置改变 size。
        if (placeHolderXOccupied) {
            atti.frame = CGRectMake(compareAttri.frame.origin.x + compareAttri.size.width, currentPointOnIndexPath.section * soureItemFrame.size.height, soureItemFrame.size.width, soureItemFrame.size.height);
        }else {
            atti.frame = CGRectMake(autoAssociationViewX, currentPointOnIndexPath.section * soureItemFrame.size.height, soureItemFrame.size.width, soureItemFrame.size.height);
        }
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
- (NSInteger)autoAssociationInsertPosition {
    return self.compareIndexPathPosition;
}

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
