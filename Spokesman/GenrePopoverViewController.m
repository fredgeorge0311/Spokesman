//
//  GenrePopoverViewController.m
//  Spokesman
//
//  Created by Chaitanya VRK on 08/12/18.
//  Copyright © 2018 troomobile. All rights reserved.
//

#import "GenrePopoverViewController.h"

@interface GenrePopoverViewController ()

@end

@implementation GenrePopoverViewController

int selectedGenreCount;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
    
    selectedGenreCount = 0;
    _selectedGenres = [NSMutableArray array];
    
    if(!_isArtist)
    {
        _genreActor.enabled = false;
        _genreActress.enabled = false;
        _genreModel.enabled = false;
        _genreSocialMedia.enabled = false;
        
        _genreActor.state = 0;
        _genreActress.state = 0;
        _genreModel.state = 0;
        _genreSocialMedia.state = 0;
    }
    else
    {
        _genreActor.enabled = true;
        _genreActress.enabled = true;
        _genreModel.enabled = true;
        _genreSocialMedia.enabled = true;
        
        _genreActor.state = 0;
        _genreActress.state = 0;
        _genreModel.state = 0;
        _genreSocialMedia.state = 0;
    }
}

-(void)clearAllCheckboxes{
    for (NSView *subview in _genreParentView.subviews)
    {
        if(((NSButton*)subview).state == 1)
        {
            ((NSButton*)subview).state = 0;
        }
    }
}

-(void)updateButtonStates
{
    int count = _selectedGenres.count;
    for (NSView *subview in _genreParentView.subviews)
    {
        if(((NSButton*)subview).state == 0)
        {
            if(count > 1)
                ((NSButton*)subview).enabled = false;
            else
                ((NSButton*)subview).enabled = true;
        }
    }
    
    if(_isArtist)
    {
        if(count < 2)
        {
            _genreActor.enabled = true;
            _genreActress.enabled = true;
            _genreModel.enabled = true;
            _genreSocialMedia.enabled = true;
        }
    }
    else
    {
        _genreActor.enabled = false;
        _genreActress.enabled = false;
        _genreModel.enabled = false;
        _genreSocialMedia.enabled = false;
        
        _genreActor.state = 0;
        _genreActress.state = 0;
        _genreModel.state = 0;
        _genreSocialMedia.state = 0;
    }
}

- (void)updateGenreSelection:(id _Nonnull)sender genre:(NSString*)genre{
    if(((NSButton*)sender).state == 1){
        selectedGenreCount++;
        [_selectedGenres addObject:genre];
    }
    else{
        selectedGenreCount--;
        [_selectedGenres removeObject:genre];
    }
    
    if(selectedGenreCount < 0)
        selectedGenreCount = 0;
    
    [self updateButtonStates];
}

- (IBAction)genreArabClick:(id)sender {
    [self updateGenreSelection:sender genre:@"Arab"];
}
- (IBAction)genreBluesClick:(id)sender {
    [self updateGenreSelection:sender genre:@"Blues"];
}
- (IBAction)genreAfroClick:(id)sender {
    [self updateGenreSelection:sender genre:@"Afro"];
}
- (IBAction)genreChristianClick:(id)sender {
    [self updateGenreSelection:sender genre:@"Christian"];
}
- (IBAction)genreClassicalClick:(id)sender {
    [self updateGenreSelection:sender genre:@"Classical"];
}
- (IBAction)genreComedyClick:(id)sender {
    [self updateGenreSelection:sender genre:@"Comedy"];
}
- (IBAction)genreCountryClick:(id)sender {
    [self updateGenreSelection:sender genre:@"Country"];
}

- (IBAction)genreChillClick:(id)sender{
    [self updateGenreSelection:sender genre:@"Chill"];
}

- (IBAction)genreDanceClick:(id)sender{
    [self updateGenreSelection:sender genre:@"Dance"];
}

- (IBAction)genreDecadesClick:(id)sender{
    [self updateGenreSelection:sender genre:@"Decades"];
}

- (IBAction)genreDesiClick:(id)sender{
    [self updateGenreSelection:sender genre:@"Desi"];
}

- (IBAction)genreDinnerClick:(id)sender{
    [self updateGenreSelection:sender genre:@"Dinner"];
}

- (IBAction)genreDiscoClick:(id)sender{
    [self updateGenreSelection:sender genre:@"Disco"];
}

- (IBAction)genreFocusClick:(id)sender{
    [self updateGenreSelection:sender genre:@"Focus"];
}

- (IBAction)genreFolkClick:(id)sender{
    [self updateGenreSelection:sender genre:@"Folk"];
}

- (IBAction)genreFunkClick:(id)sender{
    [self updateGenreSelection:sender genre:@"Funk"];
}

- (IBAction)genreGamingClick:(id)sender{
    [self updateGenreSelection:sender genre:@"Gaming"];
}

- (IBAction)genreHolidaysClick:(id)sender{
    [self updateGenreSelection:sender genre:@"Holidays"];
}

- (IBAction)genreHipHopClick:(id)sender{
    [self updateGenreSelection:sender genre:@"Hip-Hop"];
}

- (IBAction)genreIndieClick:(id)sender{
    [self updateGenreSelection:sender genre:@"Indie"];
}

- (IBAction)genreJazzClick:(id)sender{
    [self updateGenreSelection:sender genre:@"Jazz"];
}

- (IBAction)genreKPopClick:(id)sender{
    [self updateGenreSelection:sender genre:@"Pop"];
}

- (IBAction)genreLatinClick:(id)sender{
    [self updateGenreSelection:sender genre:@"Latin"];
}

- (IBAction)genreMetalClick:(id)sender{
    [self updateGenreSelection:sender genre:@"Metal"];
}

- (IBAction)genreMoodClick:(id)sender{
    [self updateGenreSelection:sender genre:@"Mood"];
}

- (IBAction)genrePopClick:(id)sender{
    [self updateGenreSelection:sender genre:@"Pop"];
}

- (IBAction)genrePunkClick:(id)sender{
    [self updateGenreSelection:sender genre:@"Punk"];
}

- (IBAction)genreRapClick:(id)sender{
    [self updateGenreSelection:sender genre:@"Rap"];
}

- (IBAction)genreReggaeClick:(id)sender{
    [self updateGenreSelection:sender genre:@"Reggae"];
}

- (IBAction)genreRockClick:(id)sender{
    [self updateGenreSelection:sender genre:@"Rock"];
}

- (IBAction)genreRomanceClick:(id)sender{
    [self updateGenreSelection:sender genre:@"Romance"];
}

- (IBAction)genreRnBClick:(id)sender{
    [self updateGenreSelection:sender genre:@"R&B"];
}

- (IBAction)genreSleepClick:(id)sender{
    [self updateGenreSelection:sender genre:@"Sleep"];
}

- (IBAction)genreSinglesClick:(id)sender{
    [self updateGenreSelection:sender genre:@"Singles"];
}

- (IBAction)genreSoulClick:(id)sender{
    [self updateGenreSelection:sender genre:@"Soul"];
}

- (IBAction)genreTVMoviesClick:(id)sender{
    [self updateGenreSelection:sender genre:@"TV & Movies"];
}

- (IBAction)genreTravelClick:(id)sender{
    [self updateGenreSelection:sender genre:@"Travel"];
}

- (IBAction)genreWordClick:(id)sender{
    [self updateGenreSelection:sender genre:@"Word"];
}

- (IBAction)genreWorkoutClick:(id)sender{
    [self updateGenreSelection:sender genre:@"Workout"];
}
- (IBAction)genreEDMClick:(id)sender {
    [self updateGenreSelection:sender genre:@"EDM"];
}


- (IBAction)genreActorClick:(id)sender{
    [self updateGenreSelection:sender genre:@"Actor"];
}

- (IBAction)genreActressClick:(id)sender{
    [self updateGenreSelection:sender genre:@"Actress"];
}

- (IBAction)genreModelClick:(id)sender{
    [self updateGenreSelection:sender genre:@"Model"];
}

- (IBAction)genreSocialMediaClick:(id)sender{
    [self updateGenreSelection:sender genre:@"Social Media Personality"];
}

@end
