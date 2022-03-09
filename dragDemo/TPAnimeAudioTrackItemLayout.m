//
//  TPAnimeAudioTrackItemLayout.m
//  TPVideo
//
//  Created by User on 2022/3/1.
//  Copyright © 2022 Dreampix. All rights reserved.
//

#import "TPAnimeAudioTrackItemLayout.h"
#import "TPAnimeTrackLayoutViewFunc.h"

#define TPAnimeAudioTrackItemLayoutAssCellHeightInInsert 3

@interface TPAnimeAudioTrackItemLayout ()
@property (nonatomic, strong) NSMutableArray<UICollectionViewLayoutAttributes *> *layoutItemAttrs;
@property (nonatomic, strong) NSMutableDictionary <NSIndexPath *, UICollectionViewLayoutAttributes *> *layoutItemIndexAttrMap;
//牺牲点空间换取时间。
@property (nonatomic, strong) NSMutableDictionary <NSNumber *, NSMutableArray<UICollectionViewLayoutAttributes *> *> *layoutItemSectionAttrsMap;

@property (nonatomic, assign) CGRect associationCellFrame;

@property (nonatomic, assign) BOOL indexPathChangeable; //是否可插入。
@property (nonatomic, assign) NSInteger insertSection; //0: 没有新增行，1:新增行。

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
         assCell = 自动联想cell。
         nearest Cell = 当前手指x位置最靠近的被拖动元素那个 cell;
         
         ### 1 同一行拖动
         => 1.1 最近的 nearest Cell 改变了 ？
         ==> 1.1.1 否，往左 ⬅️ or右 ➡️ 移动 ？
         ===> 1.1.1.1 左👈，nearest Cell  的左边存在 pre cell ？
         ====> 1.1.1.1.1 是 ，assCell left < pre cell right ? Y=> assCell left == pre cell right，N=> assCell center = 手指点x。
         ====> 1.1.1.1.2 否，assCell left > 0 ? Y=> assCell center = 手指点x，N=> assCell left = 0;
         ===> 1.1.1.2 右👉，nearest Cell  的右边存在 next cell ？
         ====> 1.1.1.2.1 是 ，assCell right > next cell left ? Y=> assCell right ==  next cell left，N=> assCell center = 手指点x。
         ====> 1.1.1.2.2 否，好像没有限制。

         ==> 1.1.2 是，手指点x 最近的 nearest Cell 左 ⬅️ or右 ➡️ ？
         ===> 1.1.2.1  左 👈， nearest Cell  的左边 存在 pre cell ？
         ====> 1.1.2.1.1 是，两 cell 之间是否够空间放下音频 ？(判断是否是 source index)
         =====> 1.1.2.1.1.1 否，大于最小音频单位 ？Y=> 裁剪，N=> 不允许移动到这里。
         =====> 1.1.2.1.1.2 是，手指点x 与 nearest Cell 之间是否够空间放下（音频/2） ？PS: 音频/2 => 手指点x是中心。
         ======> 1.1.2.1.1.2.1 否，assCell right = nearest Cell left。
         ======> 1.1.2.1.1.2.2 是，assCell center = 手指点x。
         ====> 1.1.2.1.2 否，nearest Cell  左边是否够空间放下音频 ？
         =====> 1.1.2.1.2.1 否，大于最小音频单位 ？Y=> 裁剪，N=> 不允许移动到这里。
         =====> 1.1.2.1.2.2 是，手指点x 与 nearest Cell 之间是否够空间放下（音频/2） ？PS: 音频/2 => 手指点x是中心。
         ======> 1.1.2.1.2.2.1 否，assCell left = nearest Cell right。
         ======> 1.1.2.1.2.2.2 是，assCell center = 手指点x。
         ===> 1.1.2.2  右 👉， nearest Cell  的右边 存在 next cell ？
         ====> 1.1.2.2.1 是，两 cell 之间是否够空间放下音频 ？(判断是否是 source index)
         =====> 1.1.2.2.1.1 否，大于最小音频单位 ？Y=> 裁剪，N=> 不允许移动到这里。
         =====> 1.1.2.2.1.2 是，手指点x 与 nearest Cell 之间是否够空间放下（音频/2） ？PS: 音频/2 => 手指点x是中心。
         ======> 1.1.2.2.1.2.1 否，assCell left = nearest Cell right。
         ======> 1.1.2.2.1.2.2 是，assCell center = 手指点x。
         ====> 1.1.2.2.2 否，assCell left < nearest cell right ? Y=> assCell left == nearest cell right，N=> assCell center = 手指点x。

         ### 2 跨行拖动
         => 2.1 目标行有元素？
         ==> 2.1.1 无，直接在当前行移动。
         ==> 2.1.2 有，手指点x 最近的 nearest Cell 左 ⬅️ or右 ➡️ ？
         ===> 2.1.2.1  左 👈， nearest Cell  的左边 存在 pre cell ？
         ====> 2.1.2.1.1 是，两 cell 之间是否够空间放下音频 ？
         =====> 2.1.2.1.1.1 否，大于最小音频单位 ？Y=> 裁剪，N=> 不允许移动到这里。
         =====> 2.1.2.1.1.2 是，手指点x 与 nearest Cell 之间是否够空间放下（音频/2） ？PS: 音频/2 => 手指点x是中心。
         ======> 2.1.2.1.1.2.1 否，assCell right = nearest Cell left。
         ======> 2.1.2.1.1.2.2 是，assCell center = 手指点x。
         ====> 2.1.2.1.2 否，nearest Cell  左边是否够空间放下音频 ？
         =====> 2.1.2.1.2.1 否，大于最小音频单位 ？Y=> 裁剪，N=> 不允许移动到这里。
         =====> 2.1.2.1.2.2 是，手指点x 与 nearest Cell 之间是否够空间放下音频 ？
         ======> 2.1.2.1.2.2.1 否，assCell right = nearest Cell left。
         ======> 2.1.2.1.2.2.2 是，assCell center = 手指点x。
         ===> 2.1.2.2  右 👉， nearest Cell  的右边 存在 next cell ？
         ====> 2.1.2.2.1 是，两 cell 之间是否够空间放下音频 ？
         =====> 2.1.2.2.1.1 否，大于最小音频单位 ？Y=> 裁剪，N=> 不允许移动到这里。
         =====> 2.1.2.2.1.2 是，手指点x 与 nearest Cell 之间是否够空间放下（音频/2） ？PS: 音频/2 => 手指点x是中心。
         ======> 2.1.2.2.1.2.1 否，assCell left = nearest Cell right。
         ======> 2.1.2.2.1.2.2 是，assCell center = 手指点x。
         ====> 2.1.2.2.2 否，assCell left < nearest cell right ? Y=> assCell left == nearest cell right，N=> assCell center = 手指点x。
         */
        CGPoint currentThumbPoint = [self.delegate currentCGPointOfDraggingItem];
        UICollectionViewLayoutAttributes *sourceItemAttri = self.layoutItemIndexAttrMap[sourceIndexPath];
        
        NSIndexPath *nearestIndexPath = [self nearestIndexPathForLayoutItemAtPoint:currentThumbPoint];
//        NSLog(@"nearestIndexPath=%@",nearestIndexPath.description);
        UICollectionViewLayoutAttributes *nearestItemAttri = self.layoutItemIndexAttrMap[nearestIndexPath];
        if ([self.delegate isAutoAssociationInSection:nearestIndexPath.section]) {
            nearestItemAttri = nil;
        }

        BOOL draggingIndexPathChanged = nearestIndexPath != sourceIndexPath;
        
        UICollectionViewLayoutAttributes *preItemAttri = nil;
        UICollectionViewLayoutAttributes *nexItemAttri = nil;
        if (nearestItemAttri) {
            NSIndexPath *preIndexPath = previousIndexPath(nearestIndexPath);
            NSIndexPath *nexIndexPath = nextIndexPathOf(nearestIndexPath);
            if (preIndexPath) {
                preItemAttri = self.layoutItemIndexAttrMap[preIndexPath];
            }
            nexItemAttri = self.layoutItemIndexAttrMap[nexIndexPath];
        }
        
        float autoAssociationViewLeft = currentThumbPoint.x - widthOfRect(sourceItemAttri.frame)/2.f;
        float autoAssociationViewRight = currentThumbPoint.x + widthOfRect(sourceItemAttri.frame)/2.f;
        float autoAssociationViewTop = currentThumbPoint.y;
        float autoAssociationViewWidth = widthOfRect(sourceItemAttri.frame);
        float autoAssociationViewHeight = heightOfRect(sourceItemAttri.frame);

        NSIndexPath *overLapIndexPath = [self.collectionView indexPathForItemAtPoint:currentThumbPoint];
        if (overLapIndexPath == sourceIndexPath) {
            overLapIndexPath = nil;
        }
        
        self.indexPathChangeable = YES;
        self.insertSection = 0;
        if (currentThumbPoint.y >= topOfRect(sourceItemAttri.frame) && currentThumbPoint.y < bottomOfRect(sourceItemAttri.frame)) {
            //### 1 同一行拖动
            /**
             插入一段逻辑：在行内，但距离上下边界不足 若干 0.25 && 行数<max
             */
            autoAssociationViewTop = topOfRect(sourceItemAttri.frame);
            if (currentThumbPoint.y < topOfRectWithRatioMargin(sourceItemAttri.frame, 0.25)) {
                autoAssociationViewHeight = TPAnimeAudioTrackItemLayoutAssCellHeightInInsert;
                self.insertSection = 1;
            }else if(currentThumbPoint.y > bottomOfRectWithRatioMargin(sourceItemAttri.frame, 0.25)) {
                autoAssociationViewHeight = TPAnimeAudioTrackItemLayoutAssCellHeightInInsert;
                autoAssociationViewTop = bottomOfRect(sourceItemAttri.frame) - autoAssociationViewHeight;
                self.insertSection = 1;
            }else {
                if (draggingIndexPathChanged) {
                    //==> 1.1.2 是，手指点x 最近的 nearest Cell 左 ⬅️ or右 ➡️ ？
                    if(currentThumbPoint.x < centerXOfRect(nearestItemAttri.frame)) {
                        UICollectionViewLayoutAttributes *preNearAttri = self.layoutItemIndexAttrMap[previousIndexPath(nearestIndexPath)];
                        if (preNearAttri.indexPath == sourceIndexPath) {
                            preNearAttri = nil;
                        }
                        if (preNearAttri) {
                            float gapWidth = leftOfRect(nearestItemAttri.frame) - rightOfRect(preNearAttri.frame);
                            if (gapWidth < autoAssociationViewWidth) {
                                if (gapWidth > 0) {
                                    autoAssociationViewWidth = gapWidth;
                                    autoAssociationViewLeft = rightOfRect(preNearAttri.frame);
                                }else {
                                    self.indexPathChangeable = NO;
                                }
                            }else if(currentThumbPoint.x - leftOfRect(nearestItemAttri.frame) < autoAssociationViewWidth/2.f){
                                autoAssociationViewLeft = leftOfRect(nearestItemAttri.frame) - autoAssociationViewWidth;
                            }
                        }else {
                            if (leftOfRect(nearestItemAttri.frame) < autoAssociationViewWidth) {
                                if (leftOfRect(nearestItemAttri.frame) > 0) {
                                    autoAssociationViewWidth = leftOfRect(nearestItemAttri.frame);
                                    autoAssociationViewLeft = 0;
                                }else {
                                    self.indexPathChangeable = NO;
                                }
                            }else {
                                if ((leftOfRect(nearestItemAttri.frame) - currentThumbPoint.x) < autoAssociationViewWidth/2.f) {
                                    autoAssociationViewLeft = leftOfRect(nearestItemAttri.frame) - autoAssociationViewWidth;
                                }
                            }
                        }
                        if (leftOfRect(nearestItemAttri.frame) < autoAssociationViewRight) {
                            autoAssociationViewLeft = leftOfRect(nearestItemAttri.frame) - autoAssociationViewWidth;
                        }
                    }else {
                        UICollectionViewLayoutAttributes *nextNearAttri = self.layoutItemIndexAttrMap[nextIndexPathOf(nearestIndexPath)];
                        if (nextNearAttri.indexPath == sourceIndexPath) {
                            nextNearAttri = nil;
                        }
                        if (nextNearAttri) {
                            float gapWidth = leftOfRect(nextNearAttri.frame) - rightOfRect(nearestItemAttri.frame);
                            if(gapWidth < autoAssociationViewWidth) {
                                if (gapWidth > 0) {
                                    autoAssociationViewWidth = gapWidth;
                                    autoAssociationViewLeft = rightOfRect(nearestItemAttri.frame);
                                }else {
                                    self.indexPathChangeable = NO;
                                }
                            }else if((currentThumbPoint.x - rightOfRect(nearestItemAttri.frame)) < autoAssociationViewWidth/2.f) {
                                autoAssociationViewLeft = rightOfRect(nearestItemAttri.frame);
                            }
                        }else {
                            if (autoAssociationViewLeft < rightOfRect(nearestItemAttri.frame)) {
                                autoAssociationViewLeft = rightOfRect(nearestItemAttri.frame);
                            }
                        }
                    }
                }else {
                    //==> 1.1.1 否，往左 ⬅️ or右 ➡️ 移动 ？
                    if (currentThumbPoint.x < centerXOfRect(sourceItemAttri.frame)) {
                        //===> 1.1.1.1 左👈，nearest Cell  的左边存在 pre cell ？
                        if (preItemAttri) {
                            if (autoAssociationViewLeft < rightOfRect(preItemAttri.frame)) {
                                autoAssociationViewLeft = rightOfRect(preItemAttri.frame);
                            }
                        }else {
                            if (autoAssociationViewLeft < 0) {
                                autoAssociationViewLeft = 0;
                            }
                        }
                    }else {
                        //===> 1.1.1.2 右👉，nearest Cell  的右边存在 next cell ？
                        if (nexItemAttri) {
                            if (autoAssociationViewRight > leftOfRect(nexItemAttri.frame)) {
                                autoAssociationViewLeft = leftOfRect(nexItemAttri.frame) - autoAssociationViewWidth;
                            }
                        }else {
                            
                        }
                    }
                }
            }

        }else {
            //### 2 跨行拖动(超出边距)
            if (currentThumbPoint.y < 0) {
                autoAssociationViewHeight = TPAnimeAudioTrackItemLayoutAssCellHeightInInsert;
                autoAssociationViewTop = 0;
                self.insertSection = 1;
            }else if(currentThumbPoint.y > self.delegate.trackLayoutContentSize.height) {
                autoAssociationViewHeight = TPAnimeAudioTrackItemLayoutAssCellHeightInInsert;
                autoAssociationViewTop = self.delegate.trackLayoutContentSize.height-autoAssociationViewHeight;
                self.insertSection = 1;
            }else
            if (nearestItemAttri) {
                //==> 2.1.2 有，手指点x 最近的 nearest Cell 左 or 右 ？
                if(currentThumbPoint.x < centerXOfRect(nearestItemAttri.frame)) {
                    //===> 2.1.2.1  左 👈， nearest Cell  的左边 存在 pre cell ？
                    UICollectionViewLayoutAttributes *preNearAttri = self.layoutItemIndexAttrMap[previousIndexPath(nearestIndexPath)];
                    if (preNearAttri.indexPath == sourceIndexPath) {
                        preNearAttri = nil;
                    }
                    if (preNearAttri) {
                        //====> 2.1.2.1.1 是，两 cell 之间是否够空间放下音频 ？
                        float gapWidth = leftOfRect(nearestItemAttri.frame) - rightOfRect(preNearAttri.frame);
                        
                        if (gapWidth < autoAssociationViewWidth) {
                            //=====> 2.1.2.1.1 否，大于最小音频单位 ？Y=> 裁剪，N=> 不允许移动到这里。
                            if (gapWidth > 0) {
                                autoAssociationViewWidth = gapWidth;
                                autoAssociationViewLeft = rightOfRect(preNearAttri.frame);
                            }else {
                                self.indexPathChangeable = NO;
                            }
                        }else if(currentThumbPoint.x - leftOfRect(nearestItemAttri.frame) < autoAssociationViewWidth/2.f){
                            //=====> 2.1.2.1.2 是，手指点x 与 nearest Cell 之间是否够空间放下（音频/2） ？PS: 音频/2 => 手指点x是中心。
                            //======> 2.1.2.1.2.1 否，assCell right = nearest Cell left。
                            autoAssociationViewLeft = leftOfRect(nearestItemAttri.frame) - autoAssociationViewWidth;
                        }
                    }else {
                        //====> 2.1.2.1.2 否，nearest Cell  左边是否够空间放下音频 ？
                        if (leftOfRect(nearestItemAttri.frame) < autoAssociationViewWidth) {
                            //=====> 2.1.2.1.2.1 否，大于最小音频单位 ？Y=> 裁剪，N=> 不允许移动到这里。
                            if (leftOfRect(nearestItemAttri.frame) > 0) {
                                autoAssociationViewWidth = leftOfRect(nearestItemAttri.frame);
                                autoAssociationViewLeft = 0;
                            }else {
                                self.indexPathChangeable = NO;
                            }
                        }else {
                            //=====> 2.1.2.1.2.2 是，手指点x 与 nearest Cell 之间是否够空间放下音频 ？
                            if ((leftOfRect(nearestItemAttri.frame) - currentThumbPoint.x) < autoAssociationViewWidth/2.f) {
                                //======> 2.1.2.1.2.1 否，assCell right = nearest Cell left。
                                autoAssociationViewLeft = leftOfRect(nearestItemAttri.frame) - autoAssociationViewWidth;
                            }
                        }
                    }
                    if (leftOfRect(nearestItemAttri.frame) < autoAssociationViewRight) {
                        autoAssociationViewLeft = leftOfRect(nearestItemAttri.frame) - autoAssociationViewWidth;
                    }
                }else {
                    //===> 2.1.2.2  右 👉， nearest Cell  的右边 存在 next cell ？
                    UICollectionViewLayoutAttributes *nextNearAttri = self.layoutItemIndexAttrMap[nextIndexPathOf(nearestIndexPath)];
                    if (nextNearAttri.indexPath == sourceIndexPath) {
                        nextNearAttri = nil;
                    }
                    if (nextNearAttri) {
                        //====> 2.1.2.2.1 是，两 cell 之间是否够空间放下音频 ？
                        float gapWidth = leftOfRect(nextNearAttri.frame) - rightOfRect(nearestItemAttri.frame);
                        if(gapWidth < autoAssociationViewWidth) {
                            //=====> 2.1.2.2.1.1 否，大于最小音频单位 ？Y=> 裁剪，N=> 不允许移动到这里。
                            if (gapWidth > 0) {
                                autoAssociationViewWidth = gapWidth;
                                autoAssociationViewLeft = rightOfRect(nearestItemAttri.frame);
                            }else {
                                self.indexPathChangeable = NO;
                            }
                        }else if((currentThumbPoint.x - rightOfRect(nearestItemAttri.frame)) < autoAssociationViewWidth/2.f) {
                            //=====> 2.1.2.2.1.2 是，手指点x 与 nearest Cell 之间是否够空间放下（音频/2） ？PS: 音频/2 => 手指点x是中心。
                            //======> 2.1.2.2.1.2.1 否，assCell left = nearest Cell right。
                            autoAssociationViewLeft = rightOfRect(nearestItemAttri.frame);
                        }
                    }else {
                        //====> 2.1.2.2.2 否， assCell left < nearest cell right ? Y=> assCell left == nearest cell right，N=> assCell center = 手指点x。
                        if (autoAssociationViewLeft < rightOfRect(nearestItemAttri.frame)) {
                            autoAssociationViewLeft = rightOfRect(nearestItemAttri.frame);
                        }
                        
                    }
                }
                
                autoAssociationViewTop = topOfRect(nearestItemAttri.frame);
            }else {
                //=> 2.1.1
                autoAssociationViewTop = heightOfRect([self frameOfDraggingItem]) * nearestIndexPath.section;
            }
        }
        
        atti.frame = CGRectMake(autoAssociationViewLeft, autoAssociationViewTop, autoAssociationViewWidth, autoAssociationViewHeight);
    
        self.associationCellFrame = atti.frame;
        atti.zIndex = 2;
        atti.alpha = sourceIndexPath ? 1.f : 0.f;
//        atti.alpha = self.indexPathChangeable ? 1.f : 0.f;
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
- (NSInteger)autoAssociationCellInNewSection {
    return self.insertSection;
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
- (NSInteger)fixTargeRowWithSection:(NSInteger)section row:(NSInteger)row {
    /**
     由于 nearestIndexPath 使用最靠近的 cell 会出现偏差。这里需要做插入的修正。
     */
    
    NSIndexPath *cIndexPath = [NSIndexPath indexPathForRow:row inSection:section];
    NSIndexPath *pIndexPath = nil;
    if (row > 0) {
        pIndexPath = [NSIndexPath indexPathForRow:row-1 inSection:section];
    }
    NSIndexPath *nIndexPath = [NSIndexPath indexPathForRow:row+1 inSection:section];
    
    UICollectionViewLayoutAttributes *cAttri = self.layoutItemIndexAttrMap[cIndexPath];
    UICollectionViewLayoutAttributes *nAttri = self.layoutItemIndexAttrMap[nIndexPath];
    
    UICollectionViewLayoutAttributes *pAttri = nil;
    if (pIndexPath) {
        pAttri = self.layoutItemIndexAttrMap[pIndexPath];
    }
    
    if (pAttri) {
        if(rightOfRect(pAttri.frame) > self.autoAssociationCellRect.origin.x) {
            return pIndexPath.row;
        }
    }
    
    if (cAttri) {
        if(rightOfRect(cAttri.frame) > self.autoAssociationCellRect.origin.x) {
            return cIndexPath.row;
        }
    }
    
    if (nAttri) {
        if(rightOfRect(nAttri.frame) > self.autoAssociationCellRect.origin.x) {
            return nIndexPath.row;
        }
    }else {
        return row+1;
    }
    return row;
}

- (CGRect)frameOfDraggingItem {
    NSIndexPath *sourceIndexPath = [self.delegate sourceIndexPathOfDraggingItem];
    CGRect itemFrame = [self.delegate layoutItemFrameAtIndexPath:sourceIndexPath];
    return itemFrame;
}

- (NSIndexPath *)nearestIndexPathForLayoutItemAtPoint:(CGPoint)point {
    CGRect itemFrame = [self frameOfDraggingItem];
    NSInteger pointInSection = ceilf(point.y / itemFrame.size.height) - 1;
    pointInSection = MAX(0, pointInSection);
    
    if([self.delegate isAutoAssociationInSection:pointInSection]) {
        return [NSIndexPath indexPathForRow:0 inSection:pointInSection];
    }

    NSArray *attrsInSection = self.layoutItemSectionAttrsMap[@(pointInSection)];
    NSInteger pointInNearestRow = getRowByBinaryCheck(attrsInSection, point.x);

    //修正：
    if (attrsInSection.count > pointInNearestRow) {
        UICollectionViewLayoutAttributes *targetAttri = attrsInSection[pointInNearestRow];
        if (point.x < leftOfRect(targetAttri.frame)) {
            //位于左边👈
            NSInteger preNearestRow = pointInNearestRow - 1;
            if (preNearestRow >= 0) {
                UICollectionViewLayoutAttributes *preTargetAttri = attrsInSection[preNearestRow];
                if(fabs(point.x - rightOfRect(preTargetAttri.frame)) < fabs(point.x - leftOfRect(targetAttri.frame))) {
                    pointInNearestRow = preNearestRow;
                }
            }
        }else {
            //👉
            NSInteger nexNearestRow = pointInNearestRow - 1;
            if (nexNearestRow < attrsInSection.count) {
                UICollectionViewLayoutAttributes *nexTargetAttri = attrsInSection[nexNearestRow];
                if(fabs(point.x - leftOfRect(nexTargetAttri.frame)) < fabs(point.x - rightOfRect(targetAttri.frame))) {
                    pointInNearestRow = nexNearestRow;
                }
            }
            
        }
    }
   
    return [NSIndexPath indexPathForRow:pointInNearestRow inSection:pointInSection];
}

#pragma mark - Function
NSInteger getRowByBinaryCheck(NSArray *sources, float checkX) {
    NSInteger index = 0, boundLeft = 0, boundRight = sources.count;
    NSInteger boundMid;
    while (boundLeft < boundRight) {
        boundMid = boundLeft + (boundRight - boundLeft) / 2;
        UICollectionViewLayoutAttributes *attr = sources[boundMid];
        if (attr.frame.origin.x < checkX) {
            boundLeft = boundMid  + 1;
        }else {
            boundRight = boundMid;
        }
    }
    
    if (boundLeft == boundRight && sources.count > 0) {
        if(boundRight == sources.count) {
            index = sources.count - 1;
        }else if(boundLeft == 0){
            index = 0;
        }else {
            index = boundLeft;
        }
    }
    return index;
}

@end
