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
- (NSInteger)audioTrackLayout4NumberOfSections;
- (NSInteger)audioTrackLayout4NumberOfRowsInSection:(NSInteger)section;
- (BOOL)audioTrackLayout4DidTrackSelected;
- (CGSize)audioTrackLayout4ItemSizeAtIndexPath:(NSIndexPath *)indexPath;
- (CGSize)audioTrackLayout4ContentSize;
- (NSIndexPath *_Nullable)audioTrack4DraggingIndexPath;
- (BOOL)audioTrack4isPlaceHolderItemInSection:(NSInteger)section;
- (CGPoint)audioTrackLayout4PanningPoint;
@end

@interface TPAnimeAudioTrackItemLayout : UICollectionViewFlowLayout

@property (nonatomic, weak) id<TPAnimeAudioTrackItemLayoutDelegate> delegate;

- (NSIndexPath *)getDraggingDestinationIndexPathWithPoint:(CGPoint)point;

@end

NS_ASSUME_NONNULL_END
