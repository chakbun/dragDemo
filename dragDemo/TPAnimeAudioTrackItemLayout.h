//
//  TPAnimeAudioTrackItemLayout.h
//  TPVideo
//
//  Created by User on 2022/3/1.
//  Copyright © 2022 Dreampix. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol TPAnimeAudioTrackItemLayoutDelegate <NSObject>

@required
- (NSInteger)numberOfSection4TrackItemLayout;
- (NSInteger)numberOfRow4TrackItemLayoutInSection:(NSInteger)section;
- (BOOL)didTrackViewActive; //yes：被选中状态（更大）

- (CGSize)layoutItemSizeAtIndexPath:(NSIndexPath *)indexPath;
- (CGSize)trackLayoutContentSize;

- (NSIndexPath *_Nullable)sourceIndexPathOfDraggingItem; //移动块的源头
- (CGPoint)currentCGPointOfDraggingItem; //移动块的相对父view的(x,y)
- (BOOL)checkItemPlaceHolderInSection:(NSInteger)section; //是否是拖动显示的展位section
@end

@interface TPAnimeAudioTrackItemLayout : UICollectionViewFlowLayout

@property (nonatomic, weak) id<TPAnimeAudioTrackItemLayoutDelegate> delegate;

- (NSIndexPath *)getDraggingDestinationIndexPathWithPoint:(CGPoint)point;

@end

NS_ASSUME_NONNULL_END
