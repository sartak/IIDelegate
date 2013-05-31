`[IIDelegate delegateForProtocol:@protocol(...) withMethods:@{name: block}]` creates a new class, at runtime, that conforms with the given protocol and responds to the specified methods. It then returns an instance of that new class so you can plug it into a UIKit delegate or elsewhere.

This means you can use Objective C's closure capabilities to bind actions directly to data, rather than needing to fake it by adding class attributes on your view controller.

Unfortunately you can't use `@selector(...)` as an `NSDictionary` key, so `IIDelegate` expects strings describing selectors instead. Sorry. :(

### Create a `UITableViewDataSource` delegate on the fly:

    -(id) dataSourceForArray:(NSArray *)array {
        return [IIDelegate delegateForProtocol:@protocol(UITableViewDataSource)
                                   withMethods:@{
            @"tableView:numberOfRowsInSection:":^NSInteger(id _delegate, UITableView *tableView, NSInteger section) {
                return [array count];
            },
            @"tableView:cellForRowAtIndexPath:":^UITableViewCell*(id _delegate, UITableView *tableView, NSIndexPath *indexPath) {
                UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
                NSString *name = array[indexPath.row];
                cell.textLabel.text = name;
                return cell;
            },
        }];
    }
    
    -(void) viewDidLoad {
        NSArray *states = @[@"AL", @"AK", @"AZ", @"AR", @"CA", @"CO", @"CT", @"DE", @"DC", @"FL", @"GA", @"HI", @"ID", @"IL", @"IN", @"IA", @"KS", @"KY", @"ME", @"MD", @"MA", @"MI", @"MN", @"MS", @"MO", @"MT", @"NE", @"NV", @"NH", @"NJ", @"NM", @"NY", @"NC", @"ND", @"OH", @"OK", @"OR", @"PA", @"PR", @"RI", @"SC", @"SD", @"TN", @"TX", @"VT", @"VI", @"VA", @"WA", @"WV", @"WI"];
        NSArray *prefectures = @[@"北海道", @"青森", @"岩手", @"宮城", @"秋田", @"山形", @"福島", @"茨城", @"栃木", @"群馬", @"埼玉", @"千葉", @"東京", @"神奈川", @"新潟", @"富山", @"石川", @"福井", @"山梨", @"長野", @"岐阜", @"静岡", @"愛知", @"三重", @"滋賀", @"京都", @"大阪", @"兵庫", @"奈良", @"和歌山", @"鳥取", @"島根", @"岡山", @"広島", @"山口", @"徳島", @"香川", @"愛媛", @"高知", @"福岡", @"佐賀", @"長崎", @"熊本", @"大分", @"宮崎", @"鹿児島", @"沖縄"];
    
        self.stateTable.dataSource = [self dataSourceForArray:states];
        self.prefectureTable.dataSource = [self dataSourceForArray:prefectures];
    }

### Create a `UIActionSheetDelegate` on the fly:

    -(IBAction) tappedDelete:(Record *)record {
        id delegate = [IIDelegate delegateForProtocol:@protocol(UIActionSheetDelegate)
                                          withMethods:@{
            @"actionSheet:willDismissWithButtonIndex:":^(id _delegate, UIActionSheet *actionSheet, NSInteger buttonIndex) {
                if (buttonIndex == actionSheet.destructiveButtonIndex) {
                    [record delete];
                }
                else if (buttonIndex == actionSheet.firstOtherButtonIndex) {
                    [record setImmortal];
                }
            },
        }];

        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"You Serious?"
                                                                 delegate:delegate
                                                        cancelButtonTitle:@"Cancel"
                                                   destructiveButtonTitle:@"Delete"
                                                        otherButtonTitles:@"Never", nil];
        [actionSheet showInView:self.view];
    }
