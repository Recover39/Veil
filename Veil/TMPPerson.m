//
//  TMPPerson.m
//  Pine
//
//  Created by soojin on 8/3/14.
//  Copyright (c) 2014 Recover39. All rights reserved.
//

#import "TMPPerson.h"

@implementation TMPPerson

- (NSComparisonResult) sortForIndex:(TMPPerson*)otherPerson {
	// 기본 localizedCaseInsensitiveCompare는 숫자, 영문(대소무시), 한글 순 정렬
	// 한글 > 영문(대소구분 없음) > 숫자 > $
	// 그외 특수문자는 전부 무시한채 인덱싱
	// $는 예외
	
	// self 가 @"ㄱ" 보다 작고 (한글이 아니고) , comp 가 @"ㄱ"보다 같거나 클때 - 무조건 크다
	// 비교하면 -1 0 1 이 작다, 같다, 크다 순이므로 +1 을 하면 한글일때 YES 아니면 NO 가 된다.
	// self 가 한글이고 comp 가 한글이 아닐때 무조건 작다인 조건과
	// self 가 글자(한/영)이 아니고 comp가 글자(한/영)일 때 무조건 크다인 조건을 반영한다.
	NSString* left = [NSString stringWithFormat:@"%@%@",
					  [self.name localizedCaseInsensitiveCompare:@"ㄱ"]+1 ? @"0" :
					  !([self.name localizedCaseInsensitiveCompare:@"a"]+1) ? @"2" :
					  @"1", self.name];
	NSString* right = [NSString stringWithFormat:@"%@%@",
					   [otherPerson.name localizedCaseInsensitiveCompare:@"ㄱ"]+1 ? @"0" :
					   !([otherPerson.name localizedCaseInsensitiveCompare:@"a"]+1) ? @"2" :
					   @"1", otherPerson.name];
    
	return [left localizedCaseInsensitiveCompare:right];
}

@end
