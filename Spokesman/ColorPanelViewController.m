//
//  ColorPanelViewController.m
//  SBPlayer
//
//  Created by sycf_ios on 2017/3/16.
//  Copyright © 2017年 shibiao. All rights reserved.
//

#import "ColorPanelViewController.h"

@interface ColorPanelViewController () <NSCollectionViewDelegate, NSCollectionViewDataSource>

@end

@implementation ColorPanelViewController
-(void)awakeFromNib{
    [super awakeFromNib];
        [self setupColor];
}
- (void)viewDidLoad {
    [super viewDidLoad];
    _iconCollectionView.delegate = self;
    _iconCollectionView.dataSource = self;
    
    [self.iconCollectionView reloadData];
}

-(NSInteger)numberOfSectionsInCollectionView:(NSCollectionView *)collectionView
{
    return 1;
}

-(NSInteger)collectionView:(NSCollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    if([collectionView.identifier isEqualToString:@"iconCollectionView"])
    {
        return self.imageSourceArray.count;
    }
    return 0;
}

-(NSCollectionViewItem *)collectionView:(NSCollectionView *)collectionView itemForRepresentedObjectAtIndexPath:(NSIndexPath *)indexPath
{
    if([collectionView.identifier isEqualToString:@"iconCollectionView"])
    {
        NSCollectionViewItem* item = [collectionView makeItemWithIdentifier:@"iconCollectionItem" forIndexPath:indexPath];
        NSString* imageName = [self.imageSourceArray objectAtIndex:indexPath.item];
        item.imageView.image = [NSImage imageNamed:imageName];
        return item;
    }
    else
        return nil;
}

-(void)collectionView:(NSCollectionView *)collectionView didSelectItemsAtIndexPaths:(NSSet<NSIndexPath *> *)indexPaths
{
    NSArray<NSIndexPath*>* myset = indexPaths.allObjects;
    NSString* selectedImageName = [self.imageSourceArray objectAtIndex:myset[0].item];
    if ([self.delegate respondsToSelector:@selector(colorPanel:changeImageWithButtonImage:)]) {
        [self.delegate colorPanel:self changeImageWithButtonImage:[NSImage imageNamed:selectedImageName]];
    }
}

-(void)setupColor{
    //setup normal color
    /*
    [self setButton:self.colorOne withColor:[NSColor redColor]];
    [self setButton:self.colorTwo withColor:[NSColor greenColor]];
    [self setButton:self.colorThree withColor:[NSColor blueColor]];
    [self setButton:self.colorFour withColor:[NSColor blackColor]];
    [self setButton:self.colorFive withColor:[NSColor purpleColor]];
    [self setButton:self.colorSix withColor:[NSColor magentaColor]];
    [self setButton:self.colorSeven withColor:[NSColor orangeColor]];
    [self setButton:self.colorEight withColor:[NSColor brownColor]];*/
    _iconCollectionView.delegate = self;
    _iconCollectionView.dataSource = self;
    
    [self.iconCollectionView reloadData];
}
-(void)setButton:(NSButton *)button withColor:(NSColor *)color{
    button.wantsLayer = YES;
    button.bordered = NO;
    button.layer.backgroundColor = color.CGColor;
}
- (IBAction)clickedColorPanel:(id)sender {
    NSImageView *button = (NSImageView *)sender;
    self.currentButton = button;
    if ([self.delegate respondsToSelector:@selector(colorPanel:changeImageWithButtonImage:)]) {
        [self.delegate colorPanel:self changeImageWithButtonImage:button.image];
    }
}

@end
