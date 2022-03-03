//
//  TPAudioTrackItemPlaceholderCell.m
//  dragDemo
//
//  Created by User on 2022/3/2.
//

#import "TPAudioTrackItemPlaceholderCell.h"
#import "Masonry.h"

@implementation TPAudioTrackItemPlaceholderCell
- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.borderView = [[UIView alloc] init];
        self.borderView.backgroundColor = [UIColor clearColor];
        [self.contentView addSubview:self.borderView];
        self.borderView.layer.borderColor = [UIColor yellowColor].CGColor;
        self.borderView.layer.borderWidth = 2.f;
        
        [self.borderView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self.contentView);
        }];
    }
    return self;
}
@end
