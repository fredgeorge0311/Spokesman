//
//  GenrePopoverViewController.h
//  Spokesman
//
//  Created by Chaitanya VRK on 08/12/18.
//  Copyright © 2018 troomobile. All rights reserved.
//

#import "ViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface GenrePopoverViewController : ViewController

-(void)clearAllCheckboxes;

@property BOOL isArtist;

@property NSMutableArray* selectedGenres;
@property (strong) IBOutlet NSView *genreParentView;

@property (strong) IBOutlet NSButton *genreArab;
- (IBAction)genreArabClick:(id)sender;
@property (strong) IBOutlet NSButton *genreAfro;
- (IBAction)genreAfroClick:(id)sender;
@property (strong) IBOutlet NSButton *genreBlues;
- (IBAction)genreBluesClick:(id)sender;
@property (strong) IBOutlet NSButton *genreChristian;
- (IBAction)genreChristianClick:(id)sender;
@property (strong) IBOutlet NSButton *genreClassical;
- (IBAction)genreClassicalClick:(id)sender;
@property (strong) IBOutlet NSButton *genreComedy;
- (IBAction)genreComedyClick:(id)sender;
@property (strong) IBOutlet NSButton *genreCountry;
- (IBAction)genreCountryClick:(id)sender;

@property (strong) IBOutlet NSButton *genreChill;
- (IBAction)genreChillClick:(id)sender;

@property (strong) IBOutlet NSButton *genreDance;
- (IBAction)genreDanceClick:(id)sender;

@property (strong) IBOutlet NSButton *genreDecades;
- (IBAction)genreDecadesClick:(id)sender;

@property (strong) IBOutlet NSButton *genreDesi;
- (IBAction)genreDesiClick:(id)sender;

@property (strong) IBOutlet NSButton *genreDinner;
- (IBAction)genreDinnerClick:(id)sender;

@property (strong) IBOutlet NSButton *genreDisco;
- (IBAction)genreDiscoClick:(id)sender;
@property (strong) IBOutlet NSButton *genreEDM;
- (IBAction)genreEDMClick:(id)sender;

@property (strong) IBOutlet NSButton *genreFocus;
- (IBAction)genreFocusClick:(id)sender;

@property (strong) IBOutlet NSButton *genreFolk;
- (IBAction)genreFolkClick:(id)sender;

@property (strong) IBOutlet NSButton *genreFunk;
- (IBAction)genreFunkClick:(id)sender;

@property (strong) IBOutlet NSButton *genreGaming;
- (IBAction)genreGamingClick:(id)sender;

@property (strong) IBOutlet NSButton *genreHolidays;
- (IBAction)genreHolidaysClick:(id)sender;

@property (strong) IBOutlet NSButton *genreHipHop;
- (IBAction)genreHipHopClick:(id)sender;

@property (strong) IBOutlet NSButton *genreIndie;
- (IBAction)genreIndieClick:(id)sender;

@property (strong) IBOutlet NSButton *genreJazz;
- (IBAction)genreJazzClick:(id)sender;

@property (strong) IBOutlet NSButton *genreKPop;
- (IBAction)genreKPopClick:(id)sender;

@property (strong) IBOutlet NSButton *genreLatin;
- (IBAction)genreLatinClick:(id)sender;

@property (strong) IBOutlet NSButton *genreMetal;
- (IBAction)genreMetalClick:(id)sender;

@property (strong) IBOutlet NSButton *genreMood;
- (IBAction)genreMoodClick:(id)sender;

@property (strong) IBOutlet NSButton *genrePop;
- (IBAction)genrePopClick:(id)sender;

@property (strong) IBOutlet NSButton *genrePunk;
- (IBAction)genrePunkClick:(id)sender;

@property (strong) IBOutlet NSButton *genreRap;
- (IBAction)genreRapClick:(id)sender;

@property (strong) IBOutlet NSButton *genreReggae;
- (IBAction)genreReggaeClick:(id)sender;

@property (strong) IBOutlet NSButton *genreRock;
- (IBAction)genreRockClick:(id)sender;

@property (strong) IBOutlet NSButton *genreRomance;
- (IBAction)genreRomanceClick:(id)sender;

@property (strong) IBOutlet NSButton *genreRnB;
- (IBAction)genreRnBClick:(id)sender;

@property (strong) IBOutlet NSButton *genreSleep;
- (IBAction)genreSleepClick:(id)sender;

@property (strong) IBOutlet NSButton *genreSingles;
- (IBAction)genreSinglesClick:(id)sender;

@property (strong) IBOutlet NSButton *genreSoul;
- (IBAction)genreSoulClick:(id)sender;

@property (strong) IBOutlet NSButton *genreTVMovies;
- (IBAction)genreTVMoviesClick:(id)sender;

@property (strong) IBOutlet NSButton *genreTravel;
- (IBAction)genreTravelClick:(id)sender;

@property (strong) IBOutlet NSButton *genreWord;
- (IBAction)genreWordClick:(id)sender;

@property (strong) IBOutlet NSButton *genreWorkout;
- (IBAction)genreWorkoutClick:(id)sender;

@property (strong) IBOutlet NSButton *genreActor;
- (IBAction)genreActorClick:(id)sender;

@property (strong) IBOutlet NSButton *genreActress;
- (IBAction)genreActressClick:(id)sender;

@property (strong) IBOutlet NSButton *genreModel;
- (IBAction)genreModelClick:(id)sender;

@property (strong) IBOutlet NSButton *genreSocialMedia;
- (IBAction)genreSocialMediaClick:(id)sender;

@end

NS_ASSUME_NONNULL_END
