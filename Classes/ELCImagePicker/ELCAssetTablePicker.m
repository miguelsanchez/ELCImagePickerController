//
//  AssetTablePicker.m
//
//  Created by ELC on 2/15/11.
//  Copyright 2011 ELC Technologies. All rights reserved.
//

#import "ELCAssetTablePicker.h"
#import "ELCAssetCell.h"
#import "ELCAsset.h"
#import "ELCAlbumPickerController.h"
#import "MSVUtils.h"

@interface ELCAssetTablePicker ()

@property (nonatomic, assign) int columns;

@end

@implementation ELCAssetTablePicker

@synthesize parent = _parent;;
@synthesize selectedAssetsLabel = _selectedAssetsLabel;
@synthesize assetGroup = _assetGroup;
@synthesize elcAssets = _elcAssets;
@synthesize singleSelection = _singleSelection;
@synthesize columns = _columns;

- (void)viewDidLoad
{
    [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
	[self.tableView setAllowsSelection:NO];

    NSMutableArray *tempArray = [[NSMutableArray alloc] init];
    self.elcAssets = tempArray;
    [tempArray release];
	
    if (self.immediateReturn) {
        
    } else {

      UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
      [button setImage:[UIImage imageNamed:@"navbar_ok.png"] forState:UIControlStateNormal];
      button.titleLabel.font = [UIFont fontWithName:@"SimplonBP-Bold" size:12.0f];
      [button setBackgroundColor:[UIColor clearColor]];
      button.frame=CGRectMake(0.0, 0.0, 20.0, 44.0);
      [button addTarget:self action:@selector(doneAction:) forControlEvents:UIControlEventTouchUpInside];

      UIView *wiselistButtonView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, 55.0, 44.0)];
      UILabel *wiselistLabel = [[UILabel alloc] initWithFrame:CGRectMake(15.0, 0.0, 45.0, 44.0)];
      wiselistLabel.font = [UIFont fontWithName:@"SimplonBP-Bold" size:12.0f];
      wiselistLabel.text = @"Albums";
      wiselistLabel.backgroundColor = [UIColor clearColor];
      wiselistLabel.textColor = [UIColor whiteColor];
      [wiselistButtonView addSubview:wiselistLabel];

      UIImageView *arrowButton = [[UIImageView alloc] initWithFrame:CGRectMake(0.0, 0, 10.0, 44.0)];
      [arrowButton setImage:[MSVUtils imageRotatedByDegrees:180 andImage:[UIImage imageNamed:@"wiselists_arrow.png"]]];
      arrowButton.contentMode = UIViewContentModeCenter;
      [wiselistButtonView addSubview:arrowButton];

      UIImage *wiselistTextImage = [MSVUtils grabImageFromView:wiselistButtonView];

      UIButton *button2 = [UIButton buttonWithType:UIButtonTypeCustom];
      [button2 setBackgroundColor:[UIColor clearColor]];
      [button2 setImage:wiselistTextImage forState:UIControlStateNormal];
      button2.frame=CGRectMake(0.0, 0.0, 55.0, 44.0);
      [button2 addTarget:self action:@selector(dismiss:) forControlEvents:UIControlEventTouchUpInside];

      UIBarButtonItem *rightButton = [[[UIBarButtonItem alloc] initWithCustomView:button] autorelease];
      UIBarButtonItem *leftButton = [[[UIBarButtonItem alloc] initWithCustomView:button2] autorelease];

      [self.navigationItem setRightBarButtonItem:rightButton animated:YES];
      [self.navigationItem setLeftBarButtonItem:leftButton animated:YES];
    }

	[self performSelectorInBackground:@selector(preparePhotos) withObject:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.columns = self.view.bounds.size.width / 80;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return YES;
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    self.columns = self.view.bounds.size.width / 80;
    [self.tableView reloadData];
}

- (void) dismiss:(id)sender
{
  [self.navigationController popViewControllerAnimated:YES];
}

- (void)preparePhotos
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

    NSLog(@"enumerating photos");
    [self.assetGroup enumerateAssetsUsingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop) {
        
        if(result == nil) {
            return;
        }

        ELCAsset *elcAsset = [[ELCAsset alloc] initWithAsset:result];
        [elcAsset setParent:self];
        [self.elcAssets addObject:elcAsset];
        [elcAsset release];
     }];
    NSLog(@"done enumerating photos");
    
    dispatch_sync(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
        // scroll to bottom
        long section = [self numberOfSectionsInTableView:self.tableView] - 1;
        long row = [self tableView:self.tableView numberOfRowsInSection:section] - 1;
        if (section >= 0 && row >= 0) {
            NSIndexPath *ip = [NSIndexPath indexPathForRow:row
                                                 inSection:section];
            [self.tableView scrollToRowAtIndexPath:ip
                                  atScrollPosition:UITableViewScrollPositionBottom
                                          animated:NO];
        }
    });
    
    [pool release];

}

- (void)doneAction:(id)sender
{	
	NSMutableArray *selectedAssetsImages = [[[NSMutableArray alloc] init] autorelease];
	    
	for(ELCAsset *elcAsset in self.elcAssets) {

		if([elcAsset selected]) {
			
			[selectedAssetsImages addObject:[elcAsset asset]];
		}
	}
        
    [self.parent selectedAssets:selectedAssetsImages];
}

- (void)assetSelected:(id)asset
{
    if (self.singleSelection) {

        for(ELCAsset *elcAsset in self.elcAssets) {
            if(asset != elcAsset) {
                elcAsset.selected = NO;
            }
        }
    }
    if (self.immediateReturn) {
        NSArray *singleAssetArray = [NSArray arrayWithObject:[asset asset]];
        [(NSObject *)self.parent performSelector:@selector(selectedAssets:) withObject:singleAssetArray afterDelay:0];
    }
}

#pragma mark UITableViewDataSource Delegate Methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return ceil([self.elcAssets count] / (float)self.columns);
}

- (NSArray *)assetsForIndexPath:(NSIndexPath *)path
{
    long index = path.row * self.columns;
    long length = MIN(self.columns, [self.elcAssets count] - index);
    return [self.elcAssets subarrayWithRange:NSMakeRange(index, length)];
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{    
    static NSString *CellIdentifier = @"Cell";
        
    ELCAssetCell *cell = (ELCAssetCell*)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];

    if (cell == nil) {		        
        cell = [[[ELCAssetCell alloc] initWithAssets:[self assetsForIndexPath:indexPath] reuseIdentifier:CellIdentifier] autorelease];

    } else {		
		[cell setAssets:[self assetsForIndexPath:indexPath]];
	}
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
	return 79;
}

- (int)totalSelectedAssets {
    
    int count = 0;
    
    for(ELCAsset *asset in self.elcAssets) {
		if([asset selected]) {   
            count++;	
		}
	}
    
    return count;
}

- (void)dealloc 
{
    [_assetGroup release];    
    [_elcAssets release];
    [_selectedAssetsLabel release];
    [super dealloc];    
}

@end
