//
//  TPAnimeAudioTrackItemLayout.m
//  TPVideo
//
//  Created by User on 2022/3/1.
//  Copyright © 2022 Dreampix. All rights reserved.
//

#import "TPAnimeAudioTrackItemLayout.h"

@interface TPAnimeAudioTrackItemLayout ()
@property (nonatomic, strong) NSMutableArray<UICollectionViewLayoutAttributes *> *attrArray;
@property (nonatomic, strong) NSMutableDictionary <NSIndexPath *, UICollectionViewLayoutAttributes *> *layoutAttributeMapping;
@end

@implementation TPAnimeAudioTrackItemLayout
- (void)prepareLayout {
    [super prepareLayout];
    [self.attrArray removeAllObjects];
    
    for(int i = 0; i < [self.delegate audioTrackLayout4NumberOfSections]; i++) {
        for(int j = 0; j < [self.delegate audioTrackLayout4NumberOfRowsInSection:i]; j++) {
            UICollectionViewLayoutAttributes *attr = [self layoutAttributesForItemAtIndexPath:[NSIndexPath indexPathForRow:j inSection:i]];
            [self.attrArray addObject:attr];
        }
    }
}

- (CGSize)collectionViewContentSize {
    return self.delegate.audioTrackLayout4ContentSize;
}

- (NSArray<__kindof UICollectionViewLayoutAttributes *> *)layoutAttributesForElementsInRect:(CGRect)rect {
    return self.attrArray;
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewLayoutAttributes *atti = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
    CGSize cellSize = [self.delegate audioTrackLayout4ItemSizeAtIndexPath:indexPath];
    if ([self.delegate audioTrack4isPlaceHolderItemInSection:indexPath.section]) {
        CGPoint panningPoint = [self.delegate audioTrackLayout4PanningPoint];
        NSIndexPath *draggingIndexPath = [self getDraggingDestinationIndexPathWithPoint:panningPoint];
        float placeHolderX = panningPoint.x - cellSize.width/2.f;
        NSIndexPath *preIndexPath = [NSIndexPath indexPathForRow:draggingIndexPath.row-1 inSection:draggingIndexPath.section];
        UICollectionViewLayoutAttributes *preAttri = self.layoutAttributeMapping[preIndexPath];
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
        atti.alpha = [self.delegate audioTrack4DraggingIndexPath] ? 1.f : 0.f;
    }else {
        atti.frame = CGRectMake(indexPath.row * (cellSize.width + 50), indexPath.section * cellSize.height, cellSize.width, cellSize.height);
        if ([self.delegate audioTrack4DraggingIndexPath] == indexPath) {
            atti.alpha = 0.f;
        }else {
            atti.alpha = 1.f;
        }
        self.layoutAttributeMapping[indexPath] = atti;
    }
    return atti;
}

- (NSMutableArray *)attrArray {
    if (!_attrArray) {
        _attrArray = [NSMutableArray array];
    }
    return _attrArray;
}

- (NSMutableDictionary<NSIndexPath *, UICollectionViewLayoutAttributes *> *)layoutAttributeMapping {
    if (!_layoutAttributeMapping) {
        _layoutAttributeMapping = [NSMutableDictionary dictionary];
    }
    return _layoutAttributeMapping;
}

#pragma mark - Public
- (NSIndexPath *)getDraggingDestinationIndexPathWithPoint:(CGPoint)point {
    NSIndexPath *pointAtIndexPath = [self.collectionView indexPathForItemAtPoint:point];
    NSLog(@"getDraggingDestinationIndexPathWithPoint=> %@", pointAtIndexPath.description);
    if (pointAtIndexPath && ![self.delegate audioTrack4isPlaceHolderItemInSection:pointAtIndexPath.section]) {
        return pointAtIndexPath;
    }
    
    NSIndexPath *draggingIndexPath = [self.delegate audioTrack4DraggingIndexPath];
    CGSize cellSize = [self.delegate audioTrackLayout4ItemSizeAtIndexPath:draggingIndexPath];
    NSInteger draggingInSection = ceilf(point.y / cellSize.height) - 1;
    draggingInSection = MAX(0, draggingInSection);
    /**
     这样还得考虑一个问题：就是得改变 holder 的样式。fuck！
     */
    NSInteger draggingInRow = 0;
    NSInteger count = [self.delegate audioTrackLayout4NumberOfRowsInSection:draggingInSection];
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
