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
@property (nonatomic, strong) UIView *draggingThumbView;
@property (nonatomic, strong) NSIndexPath *selectedIndexPath;
@property (nonatomic, strong) NSIndexPath *draggingIndexPath;

@property (nonatomic, assign) float trackItemWidth;

@property (nonatomic, assign) NSInteger destinationSectionOfDraggingItem;
@property (nonatomic, assign) NSInteger destinationRowOfDraggingItem;

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
    return [self numberOfSection4TrackItemLayout];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [self numberOfRow4TrackItemLayoutInSection:section];
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
    if (![self checkItemPlaceHolderInSection:indexPath.section]) {
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
- (BOOL)didTrackViewActive {
    return self.trackSelected;
}

- (NSInteger)numberOfRow4TrackItemLayoutInSection:(NSInteger)section {
    if ([self checkItemPlaceHolderInSection:section]) {
        return 1;
    }else {
        NSArray *audioModels = self.tracksArray[section];
        return audioModels.count;
    }
}

- (NSInteger)numberOfSection4TrackItemLayout {
    return self.tracksArray.count + (self.draggingIndexPath ? 1 : 0);
}

- (CGSize)layoutItemSizeAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake(self.trackItemWidth, self.trackItemHeight);
}

- (CGSize)trackLayoutContentSize {
    return CGSizeMake(self.trackItemWidth * 3, self.tracksArray.count * self.trackItemHeight);
}

- (NSIndexPath *_Nullable)sourceIndexPathOfDraggingItem {
    return self.draggingIndexPath;
}

- (BOOL)checkItemPlaceHolderInSection:(NSInteger)section {
    return section >= self.tracksArray.count;
}

- (CGPoint)currentCGPointOfDraggingItem {
    return self.draggingThumbView.center;
}

#pragma mark - Private
- (void)longPressGestureAction:(UILongPressGestureRecognizer *)longPressReg {
    CGPoint pressedPointInCollectionView = [longPressReg locationInView:self.trackCollectionView];
    NSIndexPath *pressedIndexPath = [self.trackCollectionView indexPathForItemAtPoint:pressedPointInCollectionView];
    switch (longPressReg.state) {
        case UIGestureRecognizerStateBegan: {
            if (!pressedIndexPath) {
                //没有按中轨道的items
                break;
            }
            self.draggingIndexPath = pressedIndexPath;
            
            UICollectionViewCell *cell = [self.trackCollectionView cellForItemAtIndexPath:pressedIndexPath];
            self.draggingThumbView = [cell snapshotViewAfterScreenUpdates:NO];
            self.draggingThumbView.frame = cell.frame;
            [self.trackCollectionView addSubview:self.draggingThumbView];
            [self.trackCollectionView reloadData];
//            [self.itemLayout invalidateLayout];
        }
            break;
        case UIGestureRecognizerStateChanged: {
            self.draggingThumbView.center = pressedPointInCollectionView;
            //预判占位cell的存在，必须手动计算 indexpath 。否则 indexpath 可能是 占位cell 的。
            pressedIndexPath = [self.itemLayout getDraggingDestinationIndexPathWithPoint:pressedPointInCollectionView];
            self.destinationSectionOfDraggingItem = pressedIndexPath.section;
            self.destinationRowOfDraggingItem = pressedIndexPath.row;
//            NSLog(@"changing y:%.2f, section:%i row:%i", (float)point.y, (int)destinationSectionOfDraggingItem, (int)destinationRowOfDraggingItem);
            [self.itemLayout invalidateLayout];
        }
            break;
        case UIGestureRecognizerStateEnded: {
            NSMutableArray *sourceTrackItems = [self.tracksArray[self.draggingIndexPath.section] mutableCopy];
            NSMutableArray *destinationTrackItems = sourceTrackItems;
            if (self.draggingIndexPath.section != self.destinationSectionOfDraggingItem) {
                destinationTrackItems = [self.tracksArray[self.destinationSectionOfDraggingItem] mutableCopy];
            }
            
            NSDictionary *sourceTrackItem = sourceTrackItems[self.draggingIndexPath.row];
            if (sourceTrackItems.count > self.draggingIndexPath.row) {
                [sourceTrackItems removeObjectAtIndex:self.draggingIndexPath.row];
            }
            
            if (destinationTrackItems.count < self.destinationRowOfDraggingItem) {
                self.destinationRowOfDraggingItem = destinationTrackItems.count;
            }
            [destinationTrackItems insertObject:sourceTrackItem atIndex:self.destinationRowOfDraggingItem];
            /**
             self.tracksArray 是否需要过滤一下，去掉空的数组？
             另外：是否需要更新字典内容？
             */
            [self.tracksArray replaceObjectAtIndex:self.draggingIndexPath.section withObject:sourceTrackItems];
            if (self.draggingIndexPath.section != self.destinationSectionOfDraggingItem) {
                [self.tracksArray replaceObjectAtIndex:self.destinationSectionOfDraggingItem withObject:destinationTrackItems];
            }
            self.draggingIndexPath = nil;
            [self.draggingThumbView removeFromSuperview];
            self.draggingThumbView = nil;
            [self.trackCollectionView reloadData];
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
        longGestureReg.minimumPressDuration = 0.3;
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
