//
//  WWIMPSessionListingViewController.m
//  wwimp
//
//  Created by Darryl H. Thomas on 11/2/15.
//  Copyright © 2015 Darryl H. Thomas. All rights reserved.
//

@import AVKit;
#import "WWIMPSessionListingViewController.h"
#import "WWIMPImageDataSource.h"

@interface WWIMPSessionListingViewController ()
@property (nonatomic) NSIndexPath *focusedIndexPath;
@property (nonatomic) float playRate;
@property (nonatomic, retain) AVPlayer *player;
@end

@implementation WWIMPSessionListingViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.playRate = 1.5;
    [self reloadTableViewIfNeeded];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)setSessions:(NSArray *)sessions
{
    _sessions = [sessions copy];
    [self reloadTableViewIfNeeded];
}

- (void)reloadTableViewIfNeeded
{
    if (self.isViewLoaded) {
        [self.tableView reloadData];
    }
}

- (void)updateSessionDetailsWithIndexPath:(NSIndexPath *)indexPath
{
    [self.imageLoadingActivityIndicatorView stopAnimating];
    self.focusedIndexPath = indexPath;
    NSDictionary *session = self.sessions[indexPath.row];
    self.descriptionLabel.text = session[@"description"];
    self.yearLabel.text = [session[@"year"] stringValue];
    self.titleLabel.text = [NSString stringWithFormat:@"%@ – %@", session[@"id"], session[@"title"]];
    self.shelfImageView.image = nil;
    
    self.descriptionLabel.hidden = NO;
    self.yearLabel.hidden = NO;
    self.titleLabel.hidden = NO;
    self.shelfImageView.hidden = NO;

    NSString *imageKey = [NSString stringWithFormat:@"%@-%@", [session[@"year"] stringValue], [session[@"id"] stringValue]];
    NSURL *imageSourceURL = [NSURL URLWithString:session[@"images"][@"shelf"]];
    if (imageSourceURL == nil) {
        self.shelfImageView.image = [UIImage imageNamed:@"MissingShelfImage"];
    } else {
        __weak WWIMPSessionListingViewController *weakSelf = self;
        [self.imageLoadingActivityIndicatorView startAnimating];
        [self.imageDataSource retrieveImageWithKey:imageKey sourceURL:imageSourceURL completionQueue:nil completionHandler:^(NSString * _Nonnull key, UIImage * _Nullable image, NSError * _Nullable error) {
            __strong WWIMPSessionListingViewController *strongSelf = weakSelf;
            if (strongSelf != nil && [strongSelf.focusedIndexPath isEqual:indexPath]) {
                NSDictionary *session = strongSelf.sessions[indexPath.row];
                NSString *currentImageKey = [NSString stringWithFormat:@"%@-%@", [session[@"year"] stringValue], [session[@"id"] stringValue]];
                if ([currentImageKey isEqualToString:key]) {
                    strongSelf.shelfImageView.image = image;
                    [strongSelf.imageLoadingActivityIndicatorView stopAnimating];
                }
            }
        }];
    }
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    UITableViewCell *selectedCell = sender;
    NSIndexPath *indexPath = [self.tableView indexPathForCell:selectedCell];
    NSDictionary *session = self.sessions[indexPath.row];
    AVPlayerViewController *viewController = [segue destinationViewController];
    
    if (self.player != nil) {
        [self.player removeObserver:self forKeyPath:@"rate"];
    }
    
    self.player = [[AVPlayer alloc] initWithURL:[NSURL URLWithString:session[@"download_hd"]]];
    viewController.player = self.player;
    self.player.currentItem.audioTimePitchAlgorithm = AVAudioTimePitchAlgorithmSpectral;
    self.player.rate = self.playRate;
    
    [self.player addObserver:self forKeyPath:@"rate" options:0 context:0];
}

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (context == 0) {
//        NSLog(@"rate changed to %g (%d)%@%@%@", self.player.rate,
//              (int)self.player.status,
//              self.player.currentItem.playbackBufferEmpty? @" empty" : @"",
//              self.player.currentItem.playbackBufferFull? @" full" : @"",
//              self.player.currentItem.playbackLikelyToKeepUp? @" keep": @""
//              );
//        NSLog(@"changeDict = %@", change);
        
        if(self.player.rate==0.0) {
        } else if(self.player.rate  > 2) {
            // seeking
        } else if(self.player.rate!=self.playRate) {
//            NSLog(@"fix play rate = %g -> %g", self.player.rate, self.playRate);
            self.player.rate = self.playRate;
        }
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.sessions count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *session = self.sessions[indexPath.row];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"SessionCell" forIndexPath:indexPath];
    cell.textLabel.text = session[@"title"];
    cell.detailTextLabel.text = [session[@"id"] stringValue];
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didUpdateFocusInContext:(UITableViewFocusUpdateContext *)context withAnimationCoordinator:(UIFocusAnimationCoordinator *)coordinator
{
    NSIndexPath *nextIndexPath = context.nextFocusedIndexPath;
    if (nextIndexPath) {
        [self updateSessionDetailsWithIndexPath:nextIndexPath];
    }
}

@end
