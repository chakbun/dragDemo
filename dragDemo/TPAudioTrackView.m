//
//  TPAudioTrackView.m
//  TPVideo
//
//  Created by User on 2022/3/1.
//  Copyright © 2022 Dreampix. All rights reserved.
//

#import "TPAudioTrackView.h"
#import "TPAnimeAudioTrackItemLayout.h"
#import "Masonry.h"
#import "TPAudioTrackItemCell.h"
#import "TPAudioTrackItemPlaceholderCell.h"

@interface TPAudioTrackView ()<UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, TPAnimeAudioTrackItemLayoutDelegate>

@property (nonatomic, strong) UICollectionView *trackCollectionView;
@property (nonatomic, strong) TPAnimeAudioTrackItemLayout *itemLayout;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSMutableArray *> *tracksInfoDic;
@property (nonatomic, strong) NSMutableArray<NSMutableArray *> *tracksArray;
@property (nonatomic, strong) UIView *panningThumbView;
@property (nonatomic, strong) NSIndexPath *selectedIndexPath;
@property (nonatomic, strong) NSIndexPath *draggingIndexPath;

@property (nonatomic, assign) float trackItemWidth;

@property (nonatomic, assign) NSInteger draggingDestinationSection;
@property (nonatomic, assign) NSInteger draggingDestinationRow;
@end

@implementation TPAudioTrackView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.trackItemWidth = 100;
        self.tracksInfoDic = [@{
            @"track_1": @[@{@"name": @"audio1", @"color": [UIColor redColor],}],
            @"track_2": @[@{@"name": @"audio2", @"color": [UIColor greenColor],}],
            @"track_3": @[@{@"name": @"audio3", @"color": [UIColor blueColor],}],
        } mutableCopy];
        
        self.tracksArray = [self.tracksInfoDic.allValues mutableCopy];
        
        [self addSubview:self.trackCollectionView];
        [self.trackCollectionView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self);
        }];
    }
    return self;
}

#pragma mark - UICollectionViewDataSource
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return [self audioTrackLayout4NumberOfSections];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [self audioTrackLayout4NumberOfRowsInSection:section];
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == self.tracksArray.count) {
        TPAudioTrackItemPlaceholderCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"TPAudioTrackItemPlaceholderCell" forIndexPath:indexPath];
        return cell;
    }else {
        TPAudioTrackItemCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"TPAudioTrackItemCell" forIndexPath:indexPath];
        NSDictionary *info = self.tracksArray[indexPath.section][indexPath.row];
        cell.textLabel.text = info[@"name"];
        cell.backgroundColor = info[@"color"];
        return cell;
    }
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake(self.trackItemWidth, self.trackItemHeight);
}

#pragma mark - UICollectionViewDelegate
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (![self audioTrack4isPlaceHolderItemInSection:indexPath.section]) {
        self.selectedIndexPath = indexPath;
        for (TPAudioTrackItemCell *visibleCell in collectionView.visibleCells) {
            if ([visibleCell isKindOfClass:[TPAudioTrackItemCell class]]) {
                visibleCell.selectedMaskView.hidden = YES;
            }
        }
        TPAudioTrackItemCell *selectedCell = (TPAudioTrackItemCell *)[collectionView cellForItemAtIndexPath:indexPath];
        selectedCell.selectedMaskView.hidden = NO;
        if (self.delegate  && [self.delegate respondsToSelector:@selector(audioTrackView:didSelectedItemAtIndexPath:)]) {
            [self.delegate audioTrackView:self didSelectedItemAtIndexPath:indexPath];
        }
        self.trackSelected = YES;
        [self.itemLayout invalidateLayout];
    }
}

#pragma mark - TPAnimeAudioTrackItemLayoutDelegate
- (BOOL)audioTrackLayout4DidTrackSelected {
    return self.trackSelected;
}

- (NSInteger)audioTrackLayout4NumberOfRowsInSection:(NSInteger)section {
    if ([self audioTrack4isPlaceHolderItemInSection:section]) {
        return 1;
    }else {
        NSArray *audioModels = self.tracksArray[section];
        return audioModels.count;
    }
}

- (NSInteger)audioTrackLayout4NumberOfSections {
    return self.tracksArray.count + 1; //1:trackItemHolder;
}

- (CGSize)audioTrackLayout4ItemSizeAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake(self.trackItemWidth, self.trackItemHeight);
}

- (CGSize)audioTrackLayout4ContentSize {
    return CGSizeMake(self.trackItemWidth * 3, self.tracksArray.count * self.trackItemHeight);
}

- (NSIndexPath *_Nullable)audioTrack4DraggingIndexPath {
    return self.draggingIndexPath;
}

- (BOOL)audioTrack4isPlaceHolderItemInSection:(NSInteger)section {
    return section >= self.tracksArray.count;
}

- (CGPoint)audioTrackLayout4PanningPoint {
    return self.panningThumbView.center;
}

#pragma mark - Private
- (void)longPressGestureAction:(UILongPressGestureRecognizer *)longPressReg {
    CGPoint point = [longPressReg locationInView:self.trackCollectionView];
    NSIndexPath *indexPath = [self.trackCollectionView indexPathForItemAtPoint:point];
    switch (longPressReg.state) {
        case UIGestureRecognizerStateBegan: {
            if (!indexPath) {
                break;
            }
            self.draggingIndexPath = indexPath;
            UICollectionViewCell *cell = [self.trackCollectionView cellForItemAtIndexPath:indexPath];
            self.panningThumbView = [cell snapshotViewAfterScreenUpdates:NO];
            self.panningThumbView.frame = cell.frame;
            [self.trackCollectionView addSubview:self.panningThumbView];
            [self.itemLayout invalidateLayout];
        }
            break;
        case UIGestureRecognizerStateChanged: {
            self.panningThumbView.center = point;
            //往数据插入占位cell？
            if (!indexPath) {
                indexPath = [self.itemLayout getDraggingDestinationIndexPathWithPoint:point];
            }
            self.draggingDestinationSection = indexPath.section;
            self.draggingDestinationRow = indexPath.row;
//            NSLog(@"changing y:%.2f, section:%i row:%i", (float)point.y, (int)draggingInSection, (int)draggingInRow);
            [self.itemLayout invalidateLayout];
        }
            break;
        case UIGestureRecognizerStateEnded: {
            NSMutableArray *sourceTrackItems = [self.tracksArray[self.draggingIndexPath.section] mutableCopy];
            NSMutableArray *destinationTrackItems = sourceTrackItems;
            if (self.draggingIndexPath.section != self.draggingDestinationSection) {
                destinationTrackItems = [self.tracksArray[self.draggingDestinationSection] mutableCopy];
            }
            
            NSDictionary *sourceTrackItem = sourceTrackItems[self.draggingIndexPath.row];
            if (sourceTrackItems.count > self.draggingIndexPath.row) {
                [sourceTrackItems removeObjectAtIndex:self.draggingIndexPath.row];
            }
            
            if (destinationTrackItems.count < self.draggingDestinationRow) {
                self.draggingDestinationRow = destinationTrackItems.count;
            }
            [destinationTrackItems insertObject:sourceTrackItem atIndex:self.draggingDestinationRow];
            /**
             self.tracksArray 是否需要过滤一下，去掉空的数组？
             另外：是否需要更新字典内容？
             */
            [self.tracksArray replaceObjectAtIndex:self.draggingIndexPath.section withObject:sourceTrackItems];
            if (self.draggingIndexPath.section != self.draggingDestinationSection) {
                [self.tracksArray replaceObjectAtIndex:self.draggingDestinationSection withObject:destinationTrackItems];
            }
            [self.trackCollectionView reloadData];
            self.draggingIndexPath = nil;
            [self.panningThumbView removeFromSuperview];
            self.panningThumbView = nil;
        }
            break;
        default:
            break;
    }
}

#pragma mark - Getter
- (float)trackItemHeight {
    return self.trackSelected ? 40 : 10;
}

- (TPAnimeAudioTrackItemLayout *)itemLayout {
    if (!_itemLayout) {
        _itemLayout = [[TPAnimeAudioTrackItemLayout alloc] init];
        _itemLayout.delegate = self;
    }
    return _itemLayout;
}

- (UICollectionView *)trackCollectionView {
    if (!_trackCollectionView) {
        _trackCollectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:self.itemLayout];
        [_trackCollectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:@"TPAudioTrackViewCell"];
        _trackCollectionView.showsHorizontalScrollIndicator = NO;
        _trackCollectionView.delegate = self;
        _trackCollectionView.dataSource = self;
        _trackCollectionView.backgroundColor = [UIColor clearColor];
        _trackCollectionView.bounces = YES;
        _trackCollectionView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
        [_trackCollectionView registerClass:[TPAudioTrackItemCell class] forCellWithReuseIdentifier:@"TPAudioTrackItemCell"];
        [_trackCollectionView registerClass:[TPAudioTrackItemPlaceholderCell class] forCellWithReuseIdentifier:@"TPAudioTrackItemPlaceholderCell"];
        UILongPressGestureRecognizer *longGestureReg = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressGestureAction:)];
        longGestureReg.minimumPressDuration = 0.5;
        [_trackCollectionView addGestureRecognizer:longGestureReg];
        
    }
    return _trackCollectionView;
}

#pragma mark - Setter
- (void)setTrackSelected:(BOOL)trackSelected {
    _trackSelected = trackSelected;
    [self.itemLayout invalidateLayout];
}

@end
