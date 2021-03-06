#import "WPAssetViewController.h"

@import AVFoundation;
@import AVKit;

#import "WPVideoPlayerView.h"

@interface WPAssetViewController () <WPVideoPlayerViewDelegate>

@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) WPVideoPlayerView *videoView;

@property (nonatomic, strong) UIActivityIndicatorView *activityIndicatorView;

@end

@implementation WPAssetViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor blackColor];

    [self.view addSubview:self.imageView];
    self.imageView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.imageView.leftAnchor constraintEqualToAnchor:self.view.leftAnchor].active = YES;
    [self.imageView.widthAnchor constraintEqualToAnchor:self.view.widthAnchor].active = YES;
    [self.imageView.topAnchor constraintEqualToAnchor:self.topLayoutGuide.topAnchor].active = YES;
    [self.imageView.heightAnchor constraintEqualToAnchor:self.view.heightAnchor].active = YES;

    [self.view addSubview:self.videoView];
    self.videoView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.videoView.leftAnchor constraintEqualToAnchor:self.view.leftAnchor].active = YES;
    [self.videoView.widthAnchor constraintEqualToAnchor:self.view.widthAnchor].active = YES;
    [self.videoView.topAnchor constraintEqualToAnchor:self.topLayoutGuide.topAnchor].active = YES;
    [self.videoView.heightAnchor constraintEqualToAnchor:self.view.heightAnchor].active = YES;
    self.videoView.delegate = self;

    [self.view addSubview:self.activityIndicatorView];
    self.activityIndicatorView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.activityIndicatorView.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor].active = YES;
    [self.activityIndicatorView.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor].active = YES;

    NSString *actionTitle = NSLocalizedString(@"Add", @"Remove asset from media picker list");
    if (self.selected) {
        actionTitle = NSLocalizedString(@"Remove", @"Add asset to media picker list");
    }

    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:actionTitle style:UIBarButtonItemStylePlain target:self action:@selector(selectAction:)];

    [self showAsset];
}

- (UIImageView *)imageView
{
    if (_imageView) {
        return _imageView;
    }
    _imageView = [[UIImageView alloc] init];
    _imageView.contentMode = UIViewContentModeScaleAspectFit;
    _imageView.backgroundColor = [UIColor blackColor];
    _imageView.userInteractionEnabled = YES;
    [_imageView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapOnAsset:)]];
    return _imageView;
}

- (WPVideoPlayerView *)videoView
{
    if (_videoView) {
        return _videoView;
    }
    _videoView = [[WPVideoPlayerView alloc] init];
    [_videoView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapOnAsset:)]];
    return _videoView;
}


- (UIActivityIndicatorView *)activityIndicatorView
{
    if (_activityIndicatorView) {
        return _activityIndicatorView;
    }

    _activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];

    return _activityIndicatorView;
}

- (void)showAsset
{
    self.imageView.hidden = YES;
    self.videoView.hidden = YES;
    if (self.asset == nil) {
        self.imageView.image = nil;
        self.videoView.videoURL = nil;
        return;
    }
    switch ([self.asset assetType]) {
        case WPMediaTypeImage:
            [self showImageAsset];
        break;
        case WPMediaTypeVideo:
            [self showVideoAsset];
        break;
        default:
            return;
        break;
    }
}

- (void)showImageAsset
{
    self.imageView.hidden = NO;
    [self.activityIndicatorView startAnimating];
    __weak __typeof__(self) weakSelf = self;
    [self.asset imageWithSize:CGSizeZero completionHandler:^(UIImage *result, NSError *error) {
        __typeof__(self) strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [strongSelf.activityIndicatorView stopAnimating];
            if (error) {
                [strongSelf showError:error];
                return;
            }
            strongSelf.imageView.image = result;
        });
    }];
}

- (void)showVideoAsset
{
    self.videoView.hidden = NO;
    [self.activityIndicatorView startAnimating];
    __weak __typeof__(self) weakSelf = self;
    [self.asset videoAssetWithCompletionHandler:^(AVAsset *asset, NSError *error) {
        __typeof__(self) strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }
        dispatch_async(dispatch_get_main_queue(), ^{            
            if (error) {
                [strongSelf showError:error];
                return;
            }
            strongSelf.videoView.asset = asset;
        });
    }];
}

- (void)showError:(NSError *)error {
    [self.activityIndicatorView stopAnimating];
    if (self.delegate) {
        [self.delegate assetViewController:self failedWithError:error];
    }
}

- (void)handleTapOnAsset:(UIGestureRecognizer *)gestureRecognizer
{
    if (gestureRecognizer.state == UIGestureRecognizerStateEnded) {
        [self.navigationController setNavigationBarHidden:!self.navigationController.isNavigationBarHidden animated:YES];
    }
}

- (void)selectAction:(UIBarButtonItem *)button
{
    self.selected = !self.selected;
    if (self.delegate) {
        [self.delegate assetViewController:self selectionChanged:self.selected];    
    }
}

- (CGSize)preferredContentSize
{
    CGSize size = self.view.bounds.size;

    // Scale the preferred content size to be the same aspect
    // ratio as the asset we're displaying.
    CGSize pixelSize = [self.asset pixelSize];
    CGFloat scaleFactor = pixelSize.height / pixelSize.width;

    return CGSizeMake(size.width, size.width * scaleFactor);
}

#pragma mark - WPVideoPlayerViewDelegate

- (void)videoPlayerViewStarted:(WPVideoPlayerView *)playerView {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.activityIndicatorView stopAnimating];
    });
}

- (void)videoPlayerViewFinish:(WPVideoPlayerView *)playerView {

}

- (void)videoPlayerView:(WPVideoPlayerView *)playerView didFailWithError:(NSError *)error {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.activityIndicatorView stopAnimating];
        if (error) {
            [self showError:error];
            return;
        }
    });
}

@end
