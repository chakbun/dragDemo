//
//  TPAudioTrackItemCell.m
//  dragDemo
//
//  Created by User on 2022/3/2.
//

#import "TPAudioTrackItemCell.h"
#import "Masonry.h"

@implementation TPAudioTrackItemCell
- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.textLabel = [[UILabel alloc] init];
        self.textLabel.textColor = [UIColor blackColor];
        self.textLabel.font = [UIFont systemFontOfSize:10.f];
        [self.contentView addSubview:self.textLabel];
        
        self.selectedMaskView = [[UIView alloc] init];
        self.selectedMaskView.hidden = YES;
        self.selectedMaskView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.5];
        [self.contentView addSubview:self.selectedMaskView];
        
        [self.textLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self.contentView);
        }];
        
        [self.selectedMaskView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self.contentView);
        }];
    }
    return self;
}
@end
