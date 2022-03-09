//
//  ViewController.m
//  dragDemo
//
//  Created by User on 2022/3/2.
//

#import "ViewController.h"
#import "TPAudioTrackView.h"
#import "Masonry.h"

@interface ViewController ()<TPAudioTrackViewDelegate>
@property (nonatomic, strong) TPAudioTrackView *trView;
@end

@implementation ViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    UITapGestureRecognizer *tapGestureRec = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGestureAction:)];
    tapGestureRec.cancelsTouchesInView = NO;
    [self.view addGestureRecognizer:tapGestureRec];

    self.trView = [[TPAudioTrackView alloc] init];
    self.trView.delegate = self;
    self.trView.backgroundColor = [UIColor lightGrayColor];
    [self.view addSubview:self.trView];
    [self.trView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.leading.trailing.equalTo(self.view);
        make.height.mas_equalTo(30);
    }];
}

- (void)tapGestureAction:(UITapGestureRecognizer *)reg {
//    [self.trView mas_updateConstraints:^(MASConstraintMaker *make) {
//        make.height.mas_equalTo(30);
//    }];
//    self.trView.trackSelected = NO;
}

- (void)audioTrackView:(id)trackView didSelectedItemAtIndexPath:(NSIndexPath *)indexpath {
    [self.trView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(80);
    }];
}

@end
