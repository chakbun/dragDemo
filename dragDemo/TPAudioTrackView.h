//
//  TPAudioTrackView.h
//  TPVideo
//
//  Created by User on 2022/3/1.
//  Copyright © 2022 Dreampix. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class TPAudioTrackView;

@protocol TPAudioTrackViewDelegate <NSObject>

- (void)audioTrackView:(TPAudioTrackView *)trackView didSelectedItemAtIndexPath:(NSIndexPath *)indexpath;

@end

@interface TPAudioTrackView : UIView

@property (nonatomic, weak) id<TPAudioTrackViewDelegate> delegate;

@property (nonatomic, assign) BOOL trackSelected;


@end

NS_ASSUME_NONNULL_END
