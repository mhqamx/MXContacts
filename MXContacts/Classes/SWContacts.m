//
//  SWContacts.m
//  XTUIKits
//
//  Created by leo on 2017/6/10.
//  Copyright © 2017年 leo. All rights reserved.
//

#import "SWContacts.h"

#import <AddressBook/AddressBook.h>
#import <AddressBookUI/AddressBookUI.h>

#import <ContactsUI/ContactsUI.h>
#import <Contacts/Contacts.h>

@interface SWContacts()<ABPeoplePickerNavigationControllerDelegate, CNContactPickerDelegate>

/**
 当前控制器
 */
@property (strong, nonatomic) UIViewController *parentController;

/**
 选择联系人回调
 */
@property (copy, nonatomic) void (^addressBookSelectedCompletion)(NSDictionary *contact);

/**
 联系人列表
 */
@property (strong, nonatomic) NSMutableArray *addressBooks;

@end

@implementation SWContacts

#pragma mark  - Public

+ (instancetype)sharedInstance {
    static SWContacts *addressBook;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        addressBook = [[SWContacts alloc] init];
    });
    return addressBook;
}

+ (void)checkAuthorizationStatusWithCompletion:(void (^)(BOOL))completion {
    [[SWContacts sharedInstance] addressBookAuthorization:completion];
}

+ (void)presentContactViewControllerWithTarget:(UIViewController *)parentController selectedCompletion:(void (^)(NSDictionary *))completion {
    [SWContacts sharedInstance].parentController = parentController;
    [SWContacts sharedInstance].addressBookSelectedCompletion = [completion copy];
    [[SWContacts sharedInstance] presentViewController];
}

+ (void)filterAddressBookWithKey:(NSString *)keyword withCount:(NSUInteger)count completed:(void (^)(NSArray *))completedBlock{
    __block void (^filterContactsCompletedBlock)(NSArray *) = [completedBlock copy];
    [SWContacts checkAuthorizationStatusWithCompletion:^(BOOL grant) {
        if (!grant) {
            filterContactsCompletedBlock(@[]);
        }else {
            filterContactsCompletedBlock([[SWContacts sharedInstance] filterAddressBookWithKey:keyword withCount:count]);
        }
        filterContactsCompletedBlock = NULL;
    }];
}

#pragma mark  - Private

static NSString *formatString(NSString *string) {
    if (!string || string.length == 0) {
        return @"";
    }
    return string;
}

#pragma mark 格式化号码
static NSString *formatterPhoneNumber(NSString *phoneNumber){
    phoneNumber = [phoneNumber stringByReplacingOccurrencesOfString:@"-" withString:@""];
    phoneNumber = [phoneNumber stringByReplacingOccurrencesOfString:@"+86" withString:@""];
    phoneNumber = [phoneNumber stringByReplacingOccurrencesOfString:@" " withString:@""];
    phoneNumber = [phoneNumber stringByReplacingOccurrencesOfString:@" " withString:@""];
    phoneNumber = [phoneNumber stringByReplacingOccurrencesOfString:@"(" withString:@""];
    phoneNumber = [phoneNumber stringByReplacingOccurrencesOfString:@")" withString:@""];
    return formatString(phoneNumber);
}

#pragma mark 检测通讯录是否授权
- (void)addressBookAuthorization:(void (^)(BOOL granted))completion {
    __block void (^_addressBookAuthCompletedBlock)(BOOL granted) = [completion copy];
    if (@available(iOS 9.0, *)) {
        CNAuthorizationStatus status = [CNContactStore authorizationStatusForEntityType:CNEntityTypeContacts];
        switch (status) {
            case CNAuthorizationStatusNotDetermined:
            {
                //未授权
                CNContactStore *contactStore = [[CNContactStore alloc] init];
                [contactStore requestAccessForEntityType:CNEntityTypeContacts completionHandler:^(BOOL granted, NSError * _Nullable error) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (!error && granted) {
                            _addressBookAuthCompletedBlock(granted);
                            _addressBookAuthCompletedBlock = NULL;
                        }else{
                            _addressBookAuthCompletedBlock(NO);
                            _addressBookAuthCompletedBlock = NULL;
                        }
                    });
                }];
            }
                break;
                
            case CNAuthorizationStatusAuthorized:
            {
                //已授权
                _addressBookAuthCompletedBlock(YES);
                _addressBookAuthCompletedBlock = NULL;
            }
                break;
                
            default:
            {
                _addressBookAuthCompletedBlock(NO);
                _addressBookAuthCompletedBlock = NULL;
            }
                break;
        }
    }else{
#if __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_9_0
        ABAuthorizationStatus status = ABAddressBookGetAuthorizationStatus();
        switch (status) {
            case kABAuthorizationStatusNotDetermined:
            {
                //未授权
                ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, NULL);
                ABAddressBookRequestAccessWithCompletion(addressBook, ^(bool granted, CFErrorRef error) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (!error && granted) {
                            _addressBookAuthCompletedBlock(granted);
                            _addressBookAuthCompletedBlock = NULL;
                        }else{
                            _addressBookAuthCompletedBlock(NO);
                            _addressBookAuthCompletedBlock = NULL;
                        }
                    });
                });
            }
                break;
                
            case CNAuthorizationStatusAuthorized:
            {
                //已授权
                _addressBookAuthCompletedBlock(YES);
                _addressBookAuthCompletedBlock = NULL;
            }
                break;
                
            default:
            {
                _addressBookAuthCompletedBlock(NO);
                _addressBookAuthCompletedBlock = NULL;
            }
                break;
        }
#endif
    }
}

#pragma mark 显示通讯录
- (void)presentViewController{
    __weak __typeof__(self) weakSelf = self;
    [self addressBookAuthorization:^(BOOL granted) {
        if (!granted) {
            //未授权
            return ;
        }
        __strong __typeof(weakSelf) strongSelf = weakSelf;
        if (@available(iOS 9.0, *)) {
            CNContactPickerViewController *pickerController = [[CNContactPickerViewController alloc] init];
            pickerController.delegate = strongSelf;
            pickerController.displayedPropertyKeys = @[CNContactGivenNameKey, CNContactFamilyNameKey, CNContactPhoneNumbersKey];
            [weakSelf.parentController presentViewController:pickerController animated:YES completion:nil];
        }else{
#if __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_9_0
            ABPeoplePickerNavigationController *pickerController = [[ABPeoplePickerNavigationController alloc] init];
            pickerController.peoplePickerDelegate = strongSelf;
            [weakSelf.parentController presentViewController:pickerController animated:YES completion:nil];
#endif
        }
    }];
}

#pragma mark 检索通讯录
- (NSArray *)filterAddressBookWithKey:(NSString *)keyword withCount:(NSUInteger)count {
    if (keyword.length < 4) {
        return @[];
    }
    
    NSMutableArray *response = [NSMutableArray arrayWithCapacity:4];
    if (@available(iOS 11.0, *)) {
        //iOS9以上使用系统自带通讯录检索功能
        CNContactStore *store = [[CNContactStore alloc] init];
        CNContactFetchRequest *request = [[CNContactFetchRequest alloc] initWithKeysToFetch:@[CNContactPhoneNumbersKey, CNContactGivenNameKey, CNContactFamilyNameKey]];
        NSError *error;
        
        __block NSString *phoneNumber = @"";
        __block NSString *contactName = @"";
        [store enumerateContactsWithFetchRequest:request error:&error usingBlock:^(CNContact * _Nonnull contact, BOOL * _Nonnull stop) {
            for (CNLabeledValue<CNPhoneNumber *> *values in contact.phoneNumbers) {
                if (response.count >= count) {
                    *stop = YES;
                }
                phoneNumber = formatterPhoneNumber([values labeledValueBySettingLabel:CNContactPhoneNumbersKey].value.stringValue);
                if (phoneNumber.length > 0 && [phoneNumber containsString:keyword]) {
                    contactName = [NSString stringWithFormat:@"%@%@",formatString(contact.familyName), formatString(contact.givenName)];
                    [response addObject:@{kSWContactsNameKey:contactName, kSWContactsPhoneKey:phoneNumber}];
                }
            }
        }];
    }else{
        for (NSDictionary *addressBook in self.addressBooks) {
            if (response.count >= count) {
                break;
            }
            NSString *phoneNumber = [addressBook objectForKey:kSWContactsPhoneKey];
            if ([phoneNumber hasPrefix:keyword]) {
                [response addObject:addressBook];
            }
        }
    }
    return response;
}

#pragma mark - CNContactPickerDelegate
- (void)contactPicker:(CNContactPickerViewController *)picker didSelectContactProperty:(nonnull CNContactProperty *)contactProperty  API_AVAILABLE(ios(9.0)){
    
    NSString *phoneNumber = ((CNPhoneNumber *)contactProperty.value).stringValue;
    phoneNumber = formatterPhoneNumber(phoneNumber);
    
    NSString *familyName = formatString(contactProperty.contact.familyName);
    NSString *givenName = formatString(contactProperty.contact.givenName);
    NSString *contactName = [NSString stringWithFormat:@"%@%@",familyName, givenName];
    
    NSDictionary *contact = @{kSWContactsNameKey:contactName, kSWContactsPhoneKey:phoneNumber};
    
    if (self.addressBookSelectedCompletion) {
        self.addressBookSelectedCompletion(contact);
        self.addressBookSelectedCompletion = NULL;
    }
    
    [self contactPickerDidCancel:picker];
}

- (void)contactPickerDidCancel:(CNContactPickerViewController *)picker API_AVAILABLE(ios(9.0)){
    
    picker.delegate = nil;
    [picker dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - ABPeoplePickerNavigationControllerDelegate
- (void)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker
                         didSelectPerson:(ABRecordRef)person
                                property:(ABPropertyID)property
                              identifier:(ABMultiValueIdentifier)identifier{
    ABMultiValueRef multiValue = ABRecordCopyValue(person, kABPersonPhoneProperty);
    CFIndex index = ABMultiValueGetIndexForIdentifier(multiValue,identifier);
    NSString *phoneNumber = (__bridge NSString *)(ABMultiValueCopyValueAtIndex(multiValue, index));
    phoneNumber = formatterPhoneNumber(phoneNumber);
    
    NSString *givenName = (__bridge NSString *)(ABRecordCopyValue(person, kABPersonFirstNameProperty));
    NSString *familyName = (__bridge NSString *)(ABRecordCopyValue(person, kABPersonLastNameProperty));
    
    NSString *contactName = [NSString stringWithFormat:@"%@%@", formatString(familyName), formatString(givenName)];
    
    NSDictionary *contact = @{kSWContactsNameKey:contactName, kSWContactsPhoneKey:phoneNumber};
    if (self.addressBookSelectedCompletion) {
        self.addressBookSelectedCompletion(contact);
        self.addressBookSelectedCompletion = NULL;
    }
    
    [self peoplePickerNavigationControllerDidCancel:peoplePicker];
}

- (void)peoplePickerNavigationControllerDidCancel:(ABPeoplePickerNavigationController *)peoplePicker {
    
    peoplePicker.peoplePickerDelegate = nil;
    [peoplePicker dismissViewControllerAnimated:YES completion:nil];
}

- (BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker shouldContinueAfterSelectingPerson:(ABRecordRef)person {
    
    return YES;
}

- (BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker shouldContinueAfterSelectingPerson:(ABRecordRef)person property:(ABPropertyID)property identifier:(ABMultiValueIdentifier)identifier {
    
    if (property != kABPersonPhoneProperty) {
        return NO;
    }
    
    ABMultiValueRef multiValue = ABRecordCopyValue(person, kABPersonPhoneProperty);
    CFIndex index = ABMultiValueGetIndexForIdentifier(multiValue,identifier);
    NSString *phoneNumber = (__bridge NSString *)(ABMultiValueCopyValueAtIndex(multiValue, index));
    phoneNumber = formatterPhoneNumber(phoneNumber);
    
    NSString *givenName = (__bridge NSString *)(ABRecordCopyValue(person, kABPersonFirstNameProperty));
    NSString *familyName = (__bridge NSString *)(ABRecordCopyValue(person, kABPersonLastNameProperty));
    
    NSString *contactName = [NSString stringWithFormat:@"%@%@", formatString(familyName), formatString(givenName)];
    
    NSDictionary *contact = @{kSWContactsNameKey:contactName, kSWContactsPhoneKey:phoneNumber};
    if (self.addressBookSelectedCompletion) {
        self.addressBookSelectedCompletion(contact);
        self.addressBookSelectedCompletion = NULL;
    }
    
    [self peoplePickerNavigationControllerDidCancel:peoplePicker];
    
    return NO;
}

#pragma mark - Getter/Setter
- (NSMutableArray *)addressBooks {
    if (!_addressBooks) {
        ABAddressBookRef addressBook = ABAddressBookCreate();
        CFArrayRef arrayRef = ABAddressBookCopyArrayOfAllPeople(addressBook);
        if (!arrayRef) {
            return nil;
        }
        
        ABRecordRef person;
        NSString *givenName = @"";
        NSString *familyName = @"";
        NSString *contactName = @"";
        
        _addressBooks = [NSMutableArray array];
        for (int i=0; i < CFArrayGetCount(arrayRef); i++) {
            
            person = CFArrayGetValueAtIndex(arrayRef, i);
            givenName = (__bridge NSString *)(ABRecordCopyValue(person, kABPersonFirstNameProperty));
            familyName = (__bridge NSString *)(ABRecordCopyValue(person, kABPersonLastNameProperty));
            contactName = [NSString stringWithFormat:@"%@%@", formatString(familyName), formatString(givenName)];
            //遍历号码
            ABMultiValueRef multiValue = ABRecordCopyValue(person, kABPersonPhoneProperty);
            for (int j = 0; j < ABMultiValueGetCount(multiValue); j++) {
                NSString *phoneNumber = (__bridge NSString *)(ABMultiValueCopyValueAtIndex(multiValue, j));
                phoneNumber = formatterPhoneNumber(phoneNumber);
                if (phoneNumber.length == 0) {
                    continue;
                }
                [_addressBooks addObject:@{kSWContactsNameKey:contactName, kSWContactsPhoneKey:phoneNumber}];
            }
        }
    }
    return _addressBooks;
}

@end
