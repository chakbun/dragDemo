//
//  TPAnimeAudioTrackItemLayout.m
//  TPVideo
//
//  Created by User on 2022/3/1.
//  Copyright © 2022 Dreampix. All rights reserved.
//

#import "TPAnimeAudioTrackItemLayout.h"
#import "TPAnimeTrackLayoutViewFunc.h"

#define TPAnimeAudioTrackItemLayoutBorderUnlimited -1

@interface TPAnimeAudioTrackItemLayout ()
@property (nonatomic, strong) NSMutableArray<UICollectionViewLayoutAttributes *> *layoutItemAttrs;
@property (nonatomic, strong) NSMutableDictionary <NSIndexPath *, UICollectionViewLayoutAttributes *> *layoutItemIndexAttrMap;
//牺牲点空间换取时间。
@property (nonatomic, strong) NSMutableDictionary <NSNumber *, NSMutableArray<UICollectionViewLayoutAttributes *> *> *layoutItemSectionAttrsMap;

@property (nonatomic, assign) CGRect associationCellFrame;

@property (nonatomic, assign) BOOL indexPathChangeable;

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
         ### 1 同一行拖动
         => 1.1 没有改变当前数组顺序（indexpath不变）：判断点击cell 的 pre right 和 next left；
         => 1.2 改变了当前数组顺序（indexpath 改变）
         ==> 1.2.1 与cell重合 ，判断当前触碰点与位于重合cell中点位置。
         ===> 1.2.1.1 位于中点左边 👈，判断重合cell left 是否有足够空间（或切割）；
         ===> 1.2.1.2 位于中点右边 👉，判断重合cell right 是否有足够空间（或切割）；
         ==> 1.2.2 与cell不重合：判断同 1.1；
         
         ### 2 跨行拖动
         => 2.1 目标行有元素？
         ==> 2.1.1 无，直接在当前行移动。
         ==> 2.1.2 有，手指点x 最近的 nearest Cell 左 or 右 ？
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
         ====> 2.1.2.2.2 否，nearest Cell  右边是否够空间放下音频 ？好似一定会够的。






         
         */
        CGPoint currentThumbPoint = [self.delegate currentCGPointOfDraggingItem];
        UICollectionViewLayoutAttributes *sourceItemAttri = self.layoutItemIndexAttrMap[sourceIndexPath];
        
        NSIndexPath *nearestIndexPath = [self nearestIndexPathForLayoutItemAtPoint:currentThumbPoint];
        NSLog(@"nearestIndexPath=%@",nearestIndexPath.description);
        UICollectionViewLayoutAttributes *nearestItemAttri = self.layoutItemIndexAttrMap[nearestIndexPath];
        if ([self.delegate isAutoAssociationInSection:nearestIndexPath.section]) {
            nearestItemAttri = nil;
        }

        BOOL draggingIndexPathChanged = nearestIndexPath != sourceIndexPath;
        BOOL lastItemInSection = (nearestIndexPath.row == [self.delegate numberOfRow4TrackItemLayoutInSection:nearestIndexPath.section] -1 );
        
        UICollectionViewLayoutAttributes *preItemAttri = nil;
        UICollectionViewLayoutAttributes *nexItemAttri = nil;
        if (nearestItemAttri) {
            NSIndexPath *preIndexPath = previousIndexPath(nearestIndexPath);
            NSIndexPath *nexIndexPath = nextIndexPathOf(nearestIndexPath);
            preItemAttri = self.layoutItemIndexAttrMap[preIndexPath];
            nexItemAttri = self.layoutItemIndexAttrMap[nexIndexPath];
        }
        
        float autoAssociationViewLeft = currentThumbPoint.x - widthOfRect(sourceItemAttri.frame)/2.f;
        float autoAssociationViewRight = currentThumbPoint.x + widthOfRect(sourceItemAttri.frame)/2.f;
        float autoAssociationViewTop = currentThumbPoint.y;
        float autoAssociationViewWidth = widthOfRect(sourceItemAttri.frame);
        
        float borderLeft = TPAnimeAudioTrackItemLayoutBorderUnlimited;
        float borderRight = TPAnimeAudioTrackItemLayoutBorderUnlimited;
        
        NSIndexPath *overLapIndexPath = [self.collectionView indexPathForItemAtPoint:currentThumbPoint];
        if (overLapIndexPath == sourceIndexPath) {
            overLapIndexPath = nil;
        }
        
        self.indexPathChangeable = YES;
        
        if (currentThumbPoint.y >= topOfRect(sourceItemAttri.frame) && currentThumbPoint.y < bottomOfRect(sourceItemAttri.frame)) {
            //same section
            if (draggingIndexPathChanged) {
                //case 1.2
                if (nearestIndexPath.row < sourceIndexPath.row) {
                    //drag to left
                    if(rightOfRect(nearestItemAttri.frame) > autoAssociationViewLeft) {
                        // case 1.2.1 重合了
                        overLapIndexPath = nearestIndexPath;
                        UICollectionViewLayoutAttributes *overLapAttri = nearestItemAttri;
                        if (currentThumbPoint.x < centerXOfRect(overLapAttri.frame)) {
                            NSIndexPath *preOverLapIndexPath = previousIndexPath(overLapIndexPath);
                            UICollectionViewLayoutAttributes *preOverLapAttri = nil;
                            if (preOverLapIndexPath != sourceIndexPath) {
                                preOverLapAttri = self.layoutItemIndexAttrMap[preOverLapIndexPath];
                            }
                            if (preOverLapAttri) {
                                float gapWidth = leftOfRect(overLapAttri.frame) - rightOfRect(preOverLapAttri.frame);
                                if (gapWidth < autoAssociationViewWidth) {
                                    //放不下->裁剪。
                                    autoAssociationViewWidth = gapWidth;
                                    autoAssociationViewLeft = leftOfRect(overLapAttri.frame) - autoAssociationViewWidth;
                                }else if(leftOfRect(overLapAttri.frame) - currentThumbPoint.x < autoAssociationViewWidth) {
                                    //放得下，但是当前触碰起点放不下，需要改变left。
                                    autoAssociationViewLeft = leftOfRect(overLapAttri.frame) - autoAssociationViewWidth;
                                }
                            }else {
                                //不存在，所以 preOverLapIndexPath 是第一个元素。
                                if (leftOfRect(overLapAttri.frame) > 0) {
                                    if (leftOfRect(overLapAttri.frame) < autoAssociationViewWidth) {
                                        autoAssociationViewWidth = leftOfRect(overLapAttri.frame); //case:x=0;
                                    }
                                    autoAssociationViewLeft = rightOfRect(preOverLapAttri.frame) - autoAssociationViewWidth;
                                }else {
                                    self.indexPathChangeable = NO;
                                }
                            }
                        }else {
                            //这里可能在最靠近cell的右边。
                            NSIndexPath *nexOverLapIndexPath = nextIndexPathOf(overLapIndexPath);
                            UICollectionViewLayoutAttributes *nexOverLapAttri = nil;
                            if (nexOverLapIndexPath != sourceIndexPath) {
                                nexOverLapAttri = self.layoutItemIndexAttrMap[nexOverLapIndexPath];
                            }
                            if (nexOverLapAttri) {
                                //存在下一个，判断是否放得下。
                                float gapWidth = leftOfRect(nexOverLapAttri.frame) - rightOfRect(overLapAttri.frame);
                                if (gapWidth < autoAssociationViewWidth) {
                                    //放不下->裁剪。
                                    autoAssociationViewWidth = gapWidth;
                                    autoAssociationViewLeft = rightOfRect(overLapAttri.frame);
                                }else if(currentThumbPoint.x - rightOfRect(overLapAttri.frame) < autoAssociationViewWidth){
                                    //放得下，但是当前触碰起点放不下，需要改变left。
                                    autoAssociationViewLeft = rightOfRect(overLapAttri.frame);
                                }
                            }else {
                                autoAssociationViewLeft = rightOfRect(overLapAttri.frame);
                            }
                        }
                    }else {
                        // case 1.2.2 不重合
                        if (autoAssociationViewLeft <= rightOfRect(nearestItemAttri.frame)) {
                            autoAssociationViewLeft = rightOfRect(nearestItemAttri.frame);
                        }
                    }
                }else {
                    //drag to right
                    if((leftOfRect(nearestItemAttri.frame) < autoAssociationViewLeft + autoAssociationViewWidth) && (currentThumbPoint.x < rightOfRect(nearestItemAttri.frame))) {
                        //重合
                        overLapIndexPath = nearestIndexPath;
                        UICollectionViewLayoutAttributes *overLapAttri = nearestItemAttri;
                        if (currentThumbPoint.x < centerXOfRect(overLapAttri.frame)) {
                            NSIndexPath *preOverLapIndexPath = previousIndexPath(overLapIndexPath);
                            UICollectionViewLayoutAttributes *preOverLapAttri = nil;
                            if (preOverLapIndexPath != sourceIndexPath) {
                                preOverLapAttri = self.layoutItemIndexAttrMap[preOverLapIndexPath];
                            }
                            if (preOverLapAttri) {
                                float gapWidth = leftOfRect(overLapAttri.frame) - rightOfRect(preOverLapAttri.frame);
                                if (gapWidth < autoAssociationViewWidth) {
                                    //放不下->裁剪。
                                    autoAssociationViewWidth = gapWidth;
                                    autoAssociationViewLeft = leftOfRect(overLapAttri.frame) - autoAssociationViewWidth;
                                }else if(leftOfRect(overLapAttri.frame) - currentThumbPoint.x < autoAssociationViewWidth) {
                                    //放得下，但是当前触碰起点放不下，需要改变left。
                                    autoAssociationViewLeft = leftOfRect(overLapAttri.frame) - autoAssociationViewWidth;
                                }
                            }else {
                                //可能是自己（preOverLapIndexPath == sourceIndexPath）
                                if (currentThumbPoint.x - leftOfRect(overLapAttri.frame) <= autoAssociationViewWidth) {
                                    autoAssociationViewLeft = leftOfRect(overLapAttri.frame) - autoAssociationViewWidth;
                                }
                            }
                        }else {
                            NSIndexPath *nexOverLapIndexPath = nextIndexPathOf(overLapIndexPath);
                            UICollectionViewLayoutAttributes *nexOverLapAttri = nil;
                            if (nexOverLapIndexPath != sourceIndexPath) {
                                nexOverLapAttri = self.layoutItemIndexAttrMap[nexOverLapIndexPath];
                            }
                            if (nexOverLapAttri) {
                                //存在下一个，判断是否放得下。
                                float gapWidth = leftOfRect(nexOverLapAttri.frame) - rightOfRect(overLapAttri.frame);
                                if (gapWidth < autoAssociationViewWidth) {
                                    //放不下->裁剪。
                                    autoAssociationViewWidth = gapWidth;
                                    autoAssociationViewLeft = rightOfRect(overLapAttri.frame);
                                }else if(currentThumbPoint.x - rightOfRect(overLapAttri.frame) < autoAssociationViewWidth){
                                    //放得下，但是当前触碰起点放不下，需要改变left。
                                    autoAssociationViewLeft = rightOfRect(overLapAttri.frame);
                                }
                            }else {
                                autoAssociationViewLeft = rightOfRect(overLapAttri.frame);
                            }
                        }
                    }else {
                        // 不重合
                        if (autoAssociationViewLeft < (leftOfRect(nearestItemAttri.frame) - autoAssociationViewWidth)) {
                            autoAssociationViewLeft = leftOfRect(nearestItemAttri.frame) - autoAssociationViewWidth;
                        }
                        
                    }
                }
            }else {
                //case 1.2
                if (preItemAttri) {
                    borderLeft = rightOfRect(preItemAttri.frame);
                }
                if (nexItemAttri) {
                    borderRight = leftOfRect(nexItemAttri.frame);
                }
                if (borderLeft != TPAnimeAudioTrackItemLayoutBorderUnlimited && autoAssociationViewLeft <= borderLeft) {
                    autoAssociationViewLeft = borderLeft;
                    //判断是否放得下。
                    if((borderRight - borderLeft < autoAssociationViewWidth) && (borderRight != TPAnimeAudioTrackItemLayoutBorderUnlimited)) {
                        autoAssociationViewWidth = borderRight - borderLeft;
                    }
                }else if(borderRight != TPAnimeAudioTrackItemLayoutBorderUnlimited && autoAssociationViewRight > borderRight){
                    autoAssociationViewLeft = borderRight - autoAssociationViewWidth;
                }
            }
            
            autoAssociationViewTop = topOfRect(sourceItemAttri.frame);

        }else {
            //different section
            if (nearestItemAttri) {
                //==> 2.1.2 有，手指点x 最近的 nearest Cell 左 or 右 ？
                if(currentThumbPoint.x < centerXOfRect(nearestItemAttri.frame)) {
                    //===> 2.1.2.1  左 👈， nearest Cell  的左边 存在 pre cell ？
                    UICollectionViewLayoutAttributes *preNearAttri = self.layoutItemIndexAttrMap[previousIndexPath(nearestIndexPath)];
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
                    if (nextNearAttri) {
                        //====> 2.1.2.2.1 是，两 cell 之间是否够空间放下音频 ？
                        float gapWidth = leftOfRect(nextNearAttri.frame) - rightOfRect(nearestItemAttri.frame);
                        if(gapWidth < autoAssociationViewWidth) {
                            //=====> 2.1.2.2.1.1 否，大于最小音频单位 ？Y=> 裁剪，N=> 不允许移动到这里。
                            if (gapWidth > 0) {
                                autoAssociationViewWidth = gapWidth;
                                autoAssociationViewLeft = rightOfRect(nextNearAttri.frame);
                            }else {
                                self.indexPathChangeable = NO;
                            }
                        }else if((currentThumbPoint.x - rightOfRect(nearestItemAttri.frame)) < autoAssociationViewWidth/2.f) {
                            //=====> 2.1.2.2.1.2 是，手指点x 与 nearest Cell 之间是否够空间放下（音频/2） ？PS: 音频/2 => 手指点x是中心。
                            //======> 2.1.2.2.1.2.1 否，assCell left = nearest Cell right。
                            autoAssociationViewLeft = rightOfRect(nearestItemAttri.frame);
                        }
                    }else {
                        //====> 2.1.2.2.2 否，nearest Cell  右边是否够空间放下音频 ？好似一定会够的。
                    }
                }
                
                autoAssociationViewTop = topOfRect(nearestItemAttri.frame);
            }else {
                //=> 2.1.1
                autoAssociationViewTop = heightOfRect([self frameOfDraggingItem]) * nearestIndexPath.section;
            }
        }
        
        atti.frame = CGRectMake(autoAssociationViewLeft, autoAssociationViewTop, autoAssociationViewWidth, heightOfRect(sourceItemAttri.frame));
    
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
    
    if (boundLeft == boundRight) {
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
