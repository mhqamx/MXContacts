//
//  SWContacts.h
//  XTUIKits
//
//  Created by leo on 2017/6/10.
//  Copyright © 2017年 leo. All rights reserved.
//

#import <UIKit/UIKit.h>

#define kSWContactsNameKey @"userName"
#define kSWContactsPhoneKey @"phoneNumber"

@interface SWContacts : NSObject

/**
 显示通讯录选择页面

 @param parentController 福控制器
 @param completion 选择联系人回调页面
 */
+ (void)presentContactViewControllerWithTarget:(UIViewController *)parentController selectedCompletion:(void (^)(NSDictionary *contact))completion;

/**
 检索通讯录

 @param keyword 关键字
 @param count 返回数据长度
 */
+ (void)filterAddressBookWithKey:(NSString *)keyword withCount:(NSUInteger)count completed:(void (^)(NSArray *contacts))completedBlock;

/**
 检测权限

 @param completion 回调
 */
+ (void)checkAuthorizationStatusWithCompletion:(void (^)(BOOL grant))completion;

@end
