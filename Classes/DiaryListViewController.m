#import "DiaryListViewController.h"
#import "HatenaXMLParser.h"
#import "HatenaTouchAppDelegate.h"
#import "HatenaAtomPub.h"
#import "DiaryListCell.h"
#import "DiaryViewController.h"
#import "DiaryNextCell.h"

#define ROWNUM_PER_PAGE 20

@implementation DiaryListViewController

@synthesize diaryListView;
@synthesize diaryList;
@synthesize draft;
@synthesize forceReload;

- (void)dealloc {
	[dateFormatter1 release];
	[dateFormatter2 release];
	[diaryList release];
	[diaryListView setDelegate:nil];
	[diaryListView release];
	[super dealloc];
}

- (BOOL)isDraft {
	return draft;
}

- (void)_loadDiaryList {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
	
	HatenaAtomPub *atomPub = [[HatenaAtomPub alloc] init];
	NSData *data = [atomPub requestBlogCollectionWhetherDraft:draft pageNumber:page];
	
	HatenaXMLParser *parser = [HatenaXMLParser alloc]; 
	[parser parseXMLOfData:data entryTag:@"entry" target:self callBack:@selector(addDiaryList:) parseError:nil];
	
	[parser release];
	[atomPub release];
	
	[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
	[pool release];
}

- (void)loadDiaryList {
	[NSThread detachNewThreadSelector:@selector(_loadDiaryList) toTarget:self withObject:nil];
}

- (void)addDiaryList:(id)entry {
	if (!diaryList) {
		diaryList = [[NSMutableArray alloc] initWithCapacity:ROWNUM_PER_PAGE];
	}
	[diaryList addObject:entry];
	[diaryListView reloadData];
}

- (void)refleshIfNeeded {
	if (forceReload || !diaryList) {
		[diaryList removeAllObjects];
		[self loadDiaryList];
		[diaryListView reloadData];
		forceReload = NO;
	}
}

- (void)loadNext {
	page += 1;
	[self loadDiaryList];
}

- (BOOL)deleteEntry:(NSDictionary *)entry {
	NSString *editURI = [entry objectForKey:@"edit"];
	BOOL success = NO;
	
	HatenaAtomPub *atomPub = [[HatenaAtomPub alloc] init];
	success = [atomPub requestDeleteEntry:editURI];
	
	[atomPub release];
	
	return success;
}

#pragma mark <UITableViewDataSource> Methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	NSInteger count = [diaryList count];
	if (count == 0) {
		return 0;
	} else {
		return count + 1;
	}
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	if (indexPath.row == [diaryList count]) {
		DiaryNextCell *cell = (DiaryNextCell *)[tableView dequeueReusableCellWithIdentifier:@"DiaryNextCell"];
		if (cell == nil) {
			cell = [[[DiaryNextCell alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 320.0f, 64.0f) reuseIdentifier:@"DiaryNextCell"] autorelease];
		}

		return cell;
	} else {
		DiaryListCell *cell = (DiaryListCell *)[tableView dequeueReusableCellWithIdentifier:@"DiaryListCell"];
		if (cell == nil) {
			cell = [[[DiaryListCell alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 320.0f, 64.0f) reuseIdentifier:@"DiaryListCell"] autorelease];
		}
		
		NSDictionary *entry = [diaryList objectAtIndex:indexPath.row];	
		[cell setTitleText:[entry objectForKey:@"title"]];
		NSDate *date = [dateFormatter1 dateFromString:[entry objectForKey:@"published"]];
		[cell setDateText:[dateFormatter2 stringFromDate:date]];
		[cell setNumberText:[NSString stringWithFormat:@"%d", (ROWNUM_PER_PAGE * (page <= 1 ? 0 : page - 2)) + indexPath.row + 1]];

		return cell;
	}
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	HatenaTouchAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
	return [NSString stringWithFormat:NSLocalizedString(@"DiaryOf", nil), [delegate.userSettings userName], draft ? NSLocalizedString(@"DraftSectionTitle", nil) : @""];
}

#pragma mark <UITableViewDelegate> Methods

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	if (indexPath.row == [diaryList count]) {
		[self loadNext];
		[tableView deselectRowAtIndexPath:indexPath animated:YES];
		return;
	}
	
	DiaryViewController *controller = [[[DiaryViewController alloc] 
											 initWithNibName:@"DiaryView" bundle:nil] autorelease];
	
	NSDictionary *entry = [diaryList objectAtIndex:indexPath.row];
	controller.titleTextForEdit = [entry objectForKey:@"title"];
	controller.editURI = [entry objectForKey:@"edit"];
	
	if (draft) {
		controller.diaryTextForEdit = [entry objectForKey:@"content"];
		controller.editDraft = YES;
	} else {
		HatenaAtomPub *atomPub = [[HatenaAtomPub alloc] init];
		NSData *data = [atomPub requestBlogEntryWithURI:controller.editURI];
		
		XMLParser *parser = nil;
		NSDictionary *items = nil;
		if (data) {
			parser = [[XMLParser alloc] init];
			[parser parseXMLOfData:data entryTag:@"entry" parseError:nil];
			items = [[parser items] objectAtIndex:0];
		} else {
			[tableView deselectRowAtIndexPath:indexPath animated:YES];
			[atomPub release];
			return;
		}
		
		controller.editEntry = YES;
		controller.diaryTextForEdit = [items objectForKey:@"hatena:syntax"];	
		
		[parser release];
		[atomPub release];
	}
	
	[[self navigationController] pushViewController:controller animated:YES];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
	if (editingStyle == UITableViewCellEditingStyleDelete) {
		NSDictionary *entry = [diaryList objectAtIndex:indexPath.row];
		if ([self deleteEntry:entry]) {
			[diaryList removeObjectAtIndex:indexPath.row];
			[tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:YES];
		}
	}
}

#pragma mark <UIViewController> Methods

- (void)loadView {
	[diaryListView release];
	diaryListView = nil;
	diaryListView = [[UITableView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 320.0f, 460.0f)];
	[diaryListView setRowHeight:64.0f];
	[diaryListView setDelegate:self];
	[diaryListView setDataSource:self];
	[self setView:diaryListView];
}

- (void)viewDidLoad {
	[super viewDidLoad];
	dateFormatter1 = [[NSDateFormatter alloc] init];
	[dateFormatter1 setDateFormat:@"yyyy-MM-dd'T'HH:mm:sszzz"];
	dateFormatter2 = [[NSDateFormatter alloc] init];
	[dateFormatter2 setDateStyle:NSDateFormatterLongStyle];
	[dateFormatter2 setTimeStyle:NSDateFormatterMediumStyle];
	page = 1;
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	[self refleshIfNeeded];
}

- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
}

@end
