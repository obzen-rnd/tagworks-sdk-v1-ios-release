<img src="https://capsule-render.vercel.app/api?type=Waving&color=04FFF0&height=150&section=header&text=TagWorks-SDK-iOS&fontSize=45" />

![Generic badge](https://img.shields.io/badge/version-v1.1.22-green.svg)
![Generic badge](https://img.shields.io/badge/license-ApacheLicense2.0-blue.svg)
![Generic badge](https://img.shields.io/badge/Platform-iOS-red.svg)
![Generic badge](https://img.shields.io/badge/support-swift-yellow.svg)
![Generic badge](https://img.shields.io/badge/support-objective--c-yellow.svg)

## 목차
- [목차](#목차)
- [Requirements](#requirements)
- [Installation](#installation)
  - [CocoaPods](#cocoapods)
  - [SPM](#spm)
  - [직접 설치](#직접-설치)
- [SDK 설정](#sdk-설정)
- [사용자 설정](#사용자-설정)
- [데이터 구성](#데이터-구성)
  - [Dimension](#dimension)
  - [공용 Dimension](#공용-dimension)
    - [Dimension 추가](#dimension-추가)
    - [Dimension 가져오기](#dimension-가져오기)
    - [Dimension 삭제](#dimension-삭제)
  - [DataBundle](#databundle)
    - [DataBundle 객체의 key 값으로 사용 가능한 파라미터](#databundle-객체의-key-값으로-사용-가능한-파라미터)
    - [EVENT\_TAG\_NAME 에 대응하는 값으로 사용할 수 있는 Standard 태그](#event_tag_name-에-대응하는-값으로-사용할-수-있는-standard-태그)
- [로그 전송](#로그-전송)
- [Web View 연동](#web-view-연동)
- [딥링크 (유입 경로 추적)](#딥링크-유입-경로-추적)

<br>
<br>

## Requirements

-   최소 iOS 버전 : iOS 9+
  
<br>
<br>

## Installation

### CocoaPods

1. 명령어를 입력하여 `Podfile` 파일을 생성해주세요.

```bash
cd path/to/project
touch Podfile
```

<br>

2. `Podfile` 파일 내용을 아래와 같이 채워주세요.

```bash
target '[Project Name]' do
    pod 'TagWorks-SDK-iOS', :git => 'https://github.com/obzen-rnd/tagworks-sdk-v1-ios-release.git', :tag => 'release 최신 버전'
end
```

<br>

3. 터미널을 열어 아래와 같은 명령어를 입력해주세요.

```bash
cd path/to/project
pod install --repo-update
```

### SPM

-   Swift Package Manager(SPM)을 통해 iOS SDK를 설치할 수 있습니다.
    <br>

1. Xcode에서 File > Add packages로 이동합니다.

<center><img width="500" alt="ios_01" src="https://github.com/user-attachments/assets/37229da4-6171-4760-a877-d6c0841b701d"></center>

<br>

2. TagWorks iOS SDK 추가하기
   Apple Swift Package 윈도우가 나타나면 검색창에 TagWorks 패키지의 주소<br>
   `https://github.com/obzen-rnd/tagworks-sdk-v1-ios-release`를 입력한 후 검색합니다.<br>
   이후 버전을 선택한 후 Add package 버튼을 클릭합니다.<br>

<center><img width="500" alt="ios_02" src="https://github.com/user-attachments/assets/140a846e-4ba7-4919-b710-d58a0ac4a57b"></center>
<br>

3. 원하는 타겟을 선택한 이후 패키지를 추가합니다.<br>
4. SDK가 정상적으로 설치되었다면 `Package Dependencies`에 TagWorks가 표시됩니다.

### 직접 설치

-   TagWorks_SDK_iOS_v1.framework : 오프라인으로 제공

1.  TagWorks_SDK_iOS_v1.framework 추가
    <br>

    1. `Xcode > Project 파일 > General > Frameworks, Libraries, and Embedded Content`의 `+` 버튼을 눌러주세요.<br><br>
    2. 좌측 하단의 `Add Other.. > Add Files..` 를 클릭해 제공받은 zip 파일내의 `TagWorks_SDK_iOS_v1.framework` 폴더를 추가해주세요.<br><br>
    3. `TagWorks_SDK_iOS_v1.framework` Embed 상태를 Embed & Sign 로 변경해주세요.<br>

    <br>

-   framework 폴더의 경로가 프로젝트 경로와 일치하지 않을 경우에는 Target의 `Build Settings > Search Path > Framework Search Paths` 값을 해당 framework 폴더의 경로로 변경해주세요.

-------------

<br>

## SDK 설정

| 옵션             | 타입    | 기본값 | 설명                                                                              |
| ---------------- | ------- | ------ | ---------------------------------------------------------------------------------                                    |
| siteId           | String  | null   | 행동 정보 수집 대상 사이트 식별자                                                    |
| baseUrl          | String  | null   | 행동 정보 데이터 수집 서버 url 주소                                                 |
| isUseIntervals   | Bool    | false  | interval 사용 여부, false 일 경우 dispatchInterval 값이 무시되고 항상 즉시 발송된다.     |
| dispatchInterval | Double  | 3      | 행동 정보 데이터 발송 주기 (최소 3초, 최대 10초 설정), 초단위                                      |
| sessionTimeOut   | Double  | 5      | 행동 정보 데이터 수집 서버의 연결 대기 시간 (second), <b>최소 3초, 최대 60초 설정                          |
| userAgent        | String  | null   | user Agent 정보, 설정할 경우 설정된 값으로 전달                                      |
| appVersion       | String  | null   | Application 버전 정보, 설정하지 않을 경우 short version 전송                         |
| appName          | String  | null   | Application 이름, 설정하지 않을 경우 bundle name 전송                               |
| isUseDynamicParameter | Bool   | false | Dimension 동적 파라미터 사용 여부 (기본값 : false)                               |
|                                                                                   |

<br>

-   **siteId** 및 **baseUrl** 을 설정하지 않는 경우 SDK 초기화 과정에서 오류가 발생합니다.
-   **isUseIntervals** 값을 false로 설정할 경우에는 dispatchInterval 값이 무시되고 항상 즉시 발송됩니다. <br>true로 설정할 경우에는 dispatchInterval 값에 지정된 초를 주기로 데이터를 발송합니다.
-   **dispatchInterval** 은 큐에 저장된 행동 정보 데이터를 지정한 초만큼 발송하기 때문에, 지정한 시간 사이에 어플리케이션이 종료되는 경우 발송 할 수 없으니 적절한 시간으로 지정해야 합니다.
-   이러한 경우를 대비하기 위하여 sceneWillResignActive 함수 내부(어플리케이션이 background 상태로 진입하는 부분)에서 dispatch() 메서드 호출을 권장합니다.
-   **isUseDynamicParameter** 값을 true로 설정할 경우 Dimension의 key값을 문자형으로 사용하고, false로 설정할 경우 key값을 정수형으로 사용해야 합니다.
    - **isUseDynamicParameter** 에 <span style="color:rgb(223, 95, 56)">설정한 값에 따른 해당 메소드와는 다른 Dimension 메소드를 사용 시 데이터가 올바르게 전송되지 않을 수 있습니다.</span>
-   **TagWorks.sharedInstance** 객체를 통하여 Singleton Instance를 제공하며, 전역에서 호출 가능합니다.

<br>

> Swift

```swift
// 둘 중 추가한 방법에 따라 SDK import
// SPM 또는 CocoaPod 으로 라이브러리 추가한 경우
import TagWorks_SDK_iOS

// 릴리즈 프레임워크 파일로 추가한 경우
import TagWorks_SDK_iOS_v1



// TagWorks instance 설정
TagWorks.sharedInstance.setInstanceConfig(siteId: "00,AAAAAAAA",
                                          baseUrl: URL(string: "http://obzen.com/obzenTagWorks")!,
                                          isUseIntervals: false,
                                          dispatchInterval: 5,
                                          sessionTimeOut: 5,
                                          userAgent: nil,
                                          appVersion: "1.1.0",
                                          appName: "obzen App",
                                          isUseDynamicParameter: true)

//
// *** isUseIntervals : true 로 설정한 경우에만 설정 필요 ***
//
// SceneDelegate class 내부
func sceneWillResignActive(_ scene: UIScene) {
    // 어플리케이션이 background 상태 진입시 태깅 큐에 남아있는 데이터 모두 전송
    TagWorks.sharedInstance.dispatch()
}
```

<br>

> Objective-C

```objc
// 셋 중 추가한 방법에 따라 SDK import
// 1. SPM으로 라이브러리 추가한 경우
@import TagWorks_SDK_iOS;

// 2. CocoaPod 으로 추가한 경우
#import <TagWorks_SDK_iOS/TagWorks_SDK_iOS-Swift.h>

// 3. 릴리즈 프레임워크 파일로 추가한 경우
#import <TagWorks_SDK_iOS_v1/TagWorks_SDK_iOS_v1-Swift.h>



// TagWorks instance 설정
TagWorks *tagWorksInstance = TagWorks.sharedInstance;
[tagWorksInstance setInstanceConfigWithSiteId:@"00,AAAAAAAA"
                                      baseUrl:[NSURL URLWithString:@"http://obzen.com/obzenTagWorks"]
                               isUseIntervals:NO
                             dispatchInterval:5
                               sessionTimeOut:5
                                    userAgent:nil
                                   appVersion:@"1.1.0"
                                      appName:@"obzen APP"
                        isUseDynamicParameter:YES];

//
// *** isUseIntervals : true 로 설정한 경우에만 설정 필요 ***
//
// SceneDelegate class 내부
- (void) sceneWillResignActive:(UIScene *)scene {
    // 어플리케이션이 background 상태 진입시 태깅 큐에 남아있는 데이터 모두 전송
    TagWorks *tagWorksInstance = TagWorks.sharedInstance;
    [tagWorksInstance dispatch];
}
```
<br>

## 사용자 설정

| 옵션        | 타입    | 기본값        | 설명                                                           |
| ---------- | ------ | ----------- | ------------------------------------------------------------- |
| userId     | String | null        | 수집 대상 고객 식별자 (사용자 계정)                                   |
| adId       | String | null        | 수집 대상 광고 식별자                                              |
| isOptedOut | String | false       | 행동 정보 데이터 수집 여부 (true로 설정할 경우 수집하지 않음)              |
| contentUrl | String | 패키지 주소    | 행동 정보 page Url 주소 (ex) APP://com.obzen.TagWorks-SDK-iOS    |
| isDebugLogPrint | Bool | false    | SDK 디버그 용도로 로그 출력 여부                                     | 
|                                                                                                   |

<br>

-   행동 데이터 수집 대상이 되는 사용자를 설정하고 수집 여부를 지정합니다.
    <br><br>

> Swift

```swift
// 수집 대상자 고객 식별자 지정
TagWorks.sharedInstance.userId = "userid"

// 수집 대상자 광고 식별자 지정
TagWorks.sharedInstance.adId = "광고식별자 UUID"

// 고객이 설정한 개인정보 수집 여부에 따라 수집 여부 지정
TagWorks.sharedInstance.isOptedOut = false

// page url 주소 - 설정하지 않을 경우 기본값 지정 (APP://[AppBundleIdentifier])
TagWorks.sharedInstance.contentUrl = URL(string: "http://obzen.com/")

// SDK 디버그 용도 로그 출력
TagWorks.sharedInstance.isDebugLogPrint = true
```

<br>

> Objective-C

```objc
// 수집 대상자 고객 식별자 지정
[TagWorks.sharedInstance setUserId:@"userid"];

TagWorks.sharedInstance.adId = @"광고식별자 UUID";

// 고객이 설정한 개인정보 수집 여부에 따라 수집 여부 지정
[TagWorks.sharedInstance setIsOptedOut:NO];

// page url 주소 - 설정하지 않을 경우 기본값 지정 (APP://[AppBundleIdentifier])
[TagWorks.sharedInstance setContentUrl:[NSURL URLWithString:@"http://obzen.com/"]];

// SDK 디버그 용도 로그 출력
TagWorks.sharedInstance.isDebugLogPrint = YES;
```

<br>

## 데이터 구성

### Dimension

- 디멘젼은 Tagworks SDK를 통해 로그 발송 시 사용자 행동 정보를 수집하는 데이터 정보입니다.
- <span style="color: #6ba455">공용 디멘젼</span>은 한번 설정하면 개별 디멘젼과 함께 로그 발송 시 전달이 되며, TagWorks SDK 인스턴스에 할당이 되어 삭제를 하지 않는 한 계속 정보를 가지고 있습니다.
- <span style="color: #6ba455">개별 디멘젼</span>은 로그 발송 시 파라미터로 전달이 되는 DataBundle 객체에 담기는 행동 정보로, 일반적으로 지역 변수로 처리 시 로그 전송 후 정보가 초기화되어 사라집니다.
- 로그 전송 시 <span style="color: #6ba455">항상 전달이 되어야 하는 정보들은 보통 공용 디멘젼에 할당을 하여 사용하며, 일회성으로 사용하는 정보들은 개별 디멘젼을 사용 하시는 것을 권고</span>드립니다.
- 해당 디멘젼 관련 내용은 iOS/Android 동일합니다.
- 데이터 정보로는 문자형과 숫자형 두 개의 타입 중 원하는 타입을 선택하여 사용할 수 있습니다. (숫자형은 수치데이터 정보를 이용한 통계 목적으로 사용 가능)
- key & value 형태로 값을 설정할 수 있으며, key 값 부분에는 SDK 초기화 시 설정한 isUseDynamicParameter 설정 값에 따라 <span style="color: #6ba455">Int</span> 또는 <span style="color: #6ba455">String</span> 값을 사용합니다.
  - isUseDynamicParameter 를 true 로 설정하는 경우 <span style="color: #6ba455">key 값으로 동적 파라미터를 사용</span>
- 입력하는 key 값은 TagManager 제품에서 정의된 값으로 프로젝트 진행시 전달받을 수 있습니다.

<br>

> Swift

```swift
// # Dimension - index를 사용하여 설정
// stringValue 사용할 경우 문자형, numValue 사용할 경우 숫자형
let dim01 = Dimension(index: 1, value: "계좌조회")
let dim02 = Dimension(index: 2, numValue: 5000.0)

// # Dimension - 동적 파라미터 사용 시
let dim03 = Dimension(key: "사용자행동01", value: "계좌조회")
let dim04 = Dimension(key: "사용자행동02", numValue: 10000.0)
```

<br>

> Objective-C

```objc
// # Dimension - index를 사용하여 설정
// stringValue 사용할 경우 문자형, numValue 사용할 경우 숫자형
Dimension *dim01 = [[Dimension alloc] initWithIndex: 1 value: @"계좌조회"];
Dimension *dim02 = [[Dimension alloc] initWithIndex: 2 numValue: 5000.0];

// # Dimension - 동적 파라미터 사용 시
Dimension *dim03 = [[Dimension alloc] initWithKey:@"사용자행동01" value:@"계좌조회"];
Dimension *dim04 = [[Dimension alloc] initWithKey:@"사용자행동02" numValue:10000.0];
```

<br>

### 공용 Dimension

-   공용 Dimension은 태깅 로그 전송 시 <span style="color: #6ba455">공통적으로 전송해야 할 데이터를 설정하는 용도</span>로 사용합니다.
-   공용 Dimension에서 사용된 index 및 key 값에 다른 Dimension을 덮어쓰지 않는 이상 한 번 설정된 공용 Dimension은 계속 유지됩니다.
-   동적 파라미터 사용 여부에 따라 해당하는 메소드를 사용하여 항목 추가/가져오기 및 삭제를 할 수 있습니다.
-   setCommonDimension() / setDynamicCommonDimension() 메소드를 사용하여 공용 Dimension 항목을 계속 추가할 수 있습니다.
-   getCommonDimension() / getDynamicCommonDimension() 메소드를 사용하여 공용 Dimension 항목을 가져올 수 있습니다.

<br>

#### Dimension 추가

> Swift

```swift
// # set (객체, Array, Dimension index 및 value 가능)
// index를 사용하여 설정 (SDK 초기화 설정 시 isUseDynamicParameter를 설정하지 않거나 false로 설정한 경우 사용)
let dim01 = Dimension(index: 1, value: "계좌조회")
let dim02 = Dimension(index: 2, numValue: 99999.9)

TagWorks.sharedInstance.setCommonDimension(dim01)                            // 객체 전달
TagWorks.sharedInstance.setCommonDimension(dim02)
// 또는
TagWorks.sharedInstance.setCommonDimensions([dim01, dim02])                  // Array 전달

TagWorks.sharedInstance.setCommonDimension(index: 3, value: "비밀번호관리")      // 문자형
TagWorks.sharedInstance.setCommonDimension(index: 4, numValue: 10000.0)       // 숫자형
```
```swift
// # set (객체, Array, Dimension index 및 value 가능)
// 동적 파라미터 key 값을 사용하여 설정 (SDK 초기화 설정 시 isUseDynamicParameter를 true로 설정한 경우 사용)
let dim01 = Dimension(key: "사용자행동01", value: "계좌조회")
let dim02 = Dimension(key: "사용자행동02", numValue: 99999.0)

TagWorks.sharedInstance.setDynamicCommonDimension(dim01)                     // 객체 전달
TagWorks.sharedInstance.setDynamicCommonDimension(dim02)
// 또는
TagWorks.sharedInstance.setDynamicCommonDimensions([dim01, dim02])           // Array 전달

TagWorks.sharedInstance.setDynamicCommonDimension(key: "사용자행동03", value: "비밀번호관리")  // 문자형
TagWorks.sharedInstance.setDynamicCommonDimension(key: "사용자행동04", numValue: 10000.0)    // 숫자형

```

> Objective-C

```swift
// index를 사용하여 설정 (SDK 초기화 설정 시 isUseDynamicParameter를 설정하지 않거나 false로 설정한 경우 사용)
// # set (객체, Array, Dimension 타입/index 및 value 가능)
Dimension *dim01 = [[Dimension alloc] initWithIndex: 1 value:@"계좌조회"];
Dimension *dim02 = [[Dimension alloc] initWithIndex: 2 numValue:99999.9];

[TagWorks.sharedInstance setCommonDimension: dim01];                                          // 객체 전달
[TagWorks.sharedInstance setCommonDimension: dim02]; 
// 또는
[TagWorks.sharedInstance setCommonDimensions:[NSArray arrayWithObjects: dim01, dim02, nil]];  // Array 전달

[TagWorks.sharedInstance setCommonDimensionWithIndex: 3 value: @"비밀번호관리"];                 // 문자형
[TagWorks.sharedInstance setCommonDimensionWithIndex: 4 numValue: 10000.0];                   // 숫자형
```
```swift
// 동적 파라미터 key 값을 사용하여 설정 (SDK 초기화 설정 시 isUseDynamicParameter를 true로 설정한 경우 사용)
// # set (객체, Array, Dimension key 및 value 가능)
Dimension *dim01 = [[Dimension alloc] initWithKey: @"사용자행동01" value:@"계좌조회"];
Dimension *dim02 = [[Dimension alloc] initWithKey: @"사용자행동02" numValue:99999.9];

[TagWorks.sharedInstance setDynamicCommonDimension: dim01];                                       // 객체 전달
[TagWorks.sharedInstance setDynamicCommonDimension: dim02]; 
// 또는
[TagWorks.sharedInstance setDynamicCommonDimensions:[NSArray arrayWithObjects: dim01, dim02, nil]];  // Array 전달

[TagWorks.sharedInstance setDynamicCommonDimensionWithKey: @"사용자행동03" value: @"비밀번호관리"];     // 문자형
[TagWorks.sharedInstance setDynamicCommonDimensionWithKey: @"사용자행동04" numValue: 10000.0];       // 숫자형
```
<br>

#### Dimension 가져오기

> Swift

```swift
// 타입과 index를 사용하여 가져오기 (SDK 초기화 설정 시 isUseDynamicParameter를 설정하지 않거나 false로 설정한 경우 사용)
// # get - Dimension Array return
let commonDimension = TagWorks.sharedInstance.getCommonDimensions()

// # get - Dimension 객체 return
let cDim001 = TagWorks.sharedInstance.getCommonDimension(WithTYpe: Dimension.generalType, index: 1)
let cDim002 = TagWorks.sharedInstance.getCommonDimension(WithTYpe: Dimension.factType, index: 3)

let cDim001Val = cDim001?.value         // 문자형 값
let cDim001Val2 = cDim002?.numValue     // 숫자형 값
```
```swift
// 동적 파라미터 key 값을 사용하여 가져오기 (SDK 초기화 설정 시 isUseDynamicParameter를 true로 설정한 경우 사용)
// # get - Dimension Array return
let commonDimension = TagWorks.sharedInstance.getDynamicCommonDimensions()

// # get - Dimension 객체 return
let cDim001 = TagWorks.sharedInstance.getDynamicCommonDimension(key: "사용자행동01")
let cDim002 = TagWorks.sharedInstance.getDynamicCommonDimension(key: "사용자행동02")

let cDim001Val = cDim001?.value         // 문자형 값
let cDim001Val2 = cDim002?.numValue     // 숫자형 값
```

> Objective-C

```swift
// 타입과 index를 사용하여 가져오기 (SDK 초기화 설정 시 isUseDynamicParameter를 설정하지 않거나 false로 설정한 경우 사용)
// # get - Dimension Array return
NSArray<Dimension *> *commonDimension = TagWorks.sharedInstance.getCommonDimensions;

// # get - Dimension 객체 return
Dimension *cDim001 = [TagWorks.sharedInstance getCommonDimensionWithType: Dimension.generalType index: 1];
Dimension *cDim002 = [TagWorks.sharedInstance getCommonDimensionWithType: Dimension.factType index: 3];

NSString *cDim001Val = cDim001.value;     // 문자형 값
double cDim001Val2 = cDim002.numValue;    // 숫자형 값
```

```swift
// 동적 파라미터 key 값을 사용하여 가져오기 (SDK 초기화 설정 시 isUseDynamicParameter를 true로 설정한 경우 사용)
// # get - Dimension Array return
NSArray<Dimension *> *commonDimension = TagWorks.sharedInstance.getDynamicCommonDimensions()

// # get - Dimension 객체 return
Dimension *cDim001 = [TagWorks.sharedInstance getDynamicCommonDimensionWithKey: @"사용자행동01"];
Dimension *cDim002 = [TagWorks.sharedInstance getDynamicCommonDimensionWithKey: @"사용자행동02"];

NSString *cDim001Val = cDim001.value;      // 문자형 값
double cDim001Val2 = cDim002.numValue;     // 숫자형 값
```
<br>

#### Dimension 삭제
> Swift
```swift
// 타입과 index를 사용하여 삭제하기 (SDK 초기화 설정 시 isUseDynamicParameter를 설정하지 않거나 false로 설정한 경우 사용)
// # 전체 삭제
TagWorks.sharedInstance.removeAllCommonDimension()

// # 해당 타입 및 index 삭제
TagWorks.sharedInstance.removeCommonDimension(WithType: Dimension.generalType, index: 1)
```

```swift
// 동적 파라미터 key 값을 사용하여 삭제하기 (SDK 초기화 설정 시 isUseDynamicParameter를 true로 설정한 경우 사용)
// # 전체 삭제
TagWorks.sharedInstance.removeAllDynamicCommonDimension()

// # 해당 key 값 삭제
TagWorks.sharedInstance.removeDynamicCommonDimension(key: "사용자행동01")
```

<br>

> Objective-C

```swift
// 타입과 index를 사용하여 삭제하기 (SDK 초기화 설정 시 isUseDynamicParameter를 설정하지 않거나 false로 설정한 경우 사용)
// # 전체 삭제
[TagWorks.sharedInstance removeAllCommonDimension];

// # 해당 타입 및 index 삭제
[TagWorks.sharedInstance removeCommonDimensionWithType: Dimension.generalType index:1];
```

```swift
// 동적 파라미터 key 값을 사용하여 삭제하기 (SDK 초기화 설정 시 isUseDynamicParameter를 true로 설정한 경우 사용)
// # 전체 삭제
[TagWorks.sharedInstance removeAllDynamicCommonDimension];

// # 해당 key 값 삭제
[TagWorks.sharedInstance removeDynamicCommonDimensionWithKey: @"사용자행동01"];
```

<br>

### DataBundle

-   태깅 로그를 전송 하기 위해 필요한 정보들을 담는 클래스로 기본 파라미터 및 Dimension 정보를 쉽게 관리할 수 있습니다.
-   DataBundle 클래스는 key와 value의 집합으로 구성된 컨테이너입니다.
-   태그명 Key에 대응하는 값으로는 DataBundle 클래스가 제공하는 기본 태그 값을 사용하거나, 사용자 정의 String 값을 직접 입력할 수 있습니다.
-   putDimensions() 또는 putDynamicDimension() 메소드를 이용하여 Dimension 객체를 DataBundle 내부에 추가하여 개별 디멘젼으로 사용할 수 있습니다.
    <br>
    <br>

#### DataBundle 객체의 key 값으로 사용 가능한 파라미터

| 파라미터                        | 타입    | 설명                                      |
| ----------------------------- | ------ | ---------------------------------------- |
| EVENT_TAG_NAME                | String | 태그명                                 |
| EVENT_TAG_PARAM_TITLE         | String | 태그 화면 타이틀                             |
| EVENT_TAG_PARAM_PAGE_PATH     | String | 태그 화면 경로                              |
| EVENT_TAG_PARAM_KEYWORD       | String | 태그 검색어                                 |
| EVENT_TAG_PARAM_CUSTOM_PATH   | String | 태그 사용자 정의 경로 - 추가 분석을 위한 경로      |
| EVENT_TAG_PARAM_ERROR_MSG     | String | 태그 에러 메세지                             |

<br>

#### <span style="color: #6ba455">EVENT_TAG_NAME</span> 에 대응하는 값으로 사용할 수 있는 Standard 태그

| EVENT_TAG_NAME | 설명                  |
| -------------- | -------------------- |
| PAGE_VIEW      | 페이지뷰 태그          |
| CLICK          | 클릭 태그             |
| SCROLL         | 화면 스크롤 태그       |
| DOWNLOAD       | 파일 다운로드 태그      |
| OUT_LINK       | 링크 이동 태그        |
| SEARCH         | 검색 태그            |
| ERROR          | 오류 발생 태그        |
| REFERRER       | 유입 경로 태그        |

<br>

> Swift

```swift
let bundle = DataBundle()

// # 기본 설정
// 태그명 - Standard 태그 or 사용자 정의 태그명
bundle.putString(DataBundle.EVENT_TAG_NAME, EventTag.PAGE_VIEW.description)
// 또는
bundle.putString(DataBundle.EVENT_TAG_NAME, StandardEventTag.PAGE_VIEW)

// 화면(뷰) 타이틀
bundle.putString(DataBundle.EVENT_TAG_PARAM_TITLE, "화면이름")
// 화면 경로
bundle.putString(DataBundle.EVENT_TAG_PARAM_PAGE_PATH, "/화면경로")
// 검색어
bundle.putString(DataBundle.EVENT_TAG_PARAM_KEYWORD, "검색어")
// 사용자 정의 url
bundle.putString(DataBundle.EVENT_TAG_PARAM_CUSTOM_PATH, "/사용자정의경로")
// 에러 메세지
bundle.putString(DataBundle.EVENT_TAG_PARAM_ERROR_MSG, "Crash Exception Log or Message!")
```

```swift
// 기존 DataBundle 객체를 사용하여 새로운 DataBundle 객체 생성 시 initialize가 가능하며, 기존 DataBundle 객체 내용 또한 수정 가능
let bundle02 = DataBundle(bundle)

bundle02.putString(DataBundle.EVENT_TAG_NAME, "사용자 정의 태그명")
bundle02.putString(DataBundle.EVENT_TAG_PARAM_TITLE, "화면이름02")
```

```swift
// # DataBundle에 저장할 Dimension 설정
//==============================================================================================================
// 타입과 index를 사용하여 Dimension 설정 (SDK 초기화 설정 시 isUseDynamicParameter를 설정하지 않거나 false로 설정한 경우 사용)

let dim01 = Dimension(index: 1, value: "이체")
let dim02 = Dimension(index: 2, numValue: 10000.0)

// bundle 객체에 일반 Dimension 추가
bundle.putDimension(dim01)          // 단일 객체
bundle.putDimensions([dim02])       // Array 형 객체

// bundle 객체의 Dimension 가져오기
let dimensions = bundle.getDimensions()                                         // Dimension Array 값
let dimension = bundle.getDimension(WithType: Dimension.generalType, index: 1)  // 해당 타입 index의 Dimension

// bundle 객체의 Dimension 삭제
bundle.removeAllDimension()                                         // 전체 삭제
bundle.removeDimension(WithType: Dimension.generalType, index: 1)   // 해당 타입 index의 Dimension 삭제


//==============================================================================================================
// 동적 파라미터 key 값을 사용하여 Dimension 설정 (SDK 초기화 설정 시 isUseDynamicParameter를 true로 설정한 경우 사용)
let dim01 = Dimension(key: "사용자행동01", value: "이체")
let dim02 = Dimension(key: "사용자행동02", numValue: 10000.0)

// bundle 객체에 일반 Dimension 추가
bundle.putDynamicDimension(dim01)           // 단일 객체
bundle.putDynamicDimensions([dim02])        // Array 형 객체

// bundle 객체의 Dimension 가져오기
let dimensions = bundle.getDynamicDimensions()                // Dimension Array 값
let dimension = bundle.getDynamicDimension(key: "사용자행동01")  // 해당 key의 Dimension

// bundle 객체의 Dimension 삭제
bundle.removeAllDynamicDimension()                            // 전체 삭제
bundle.removeDynamicDimension(key: "사용자행동01")               // 해당 key의 Dimension 삭제

```

<br>

> Objective-C

```swift
DataBundle *bundle = [[DataBundle alloc] init];

// # 기본 설정
// 태그 이름 - Standard 태그 or 사용자 정의 태그명
[bundle putString: DataBundle.EVENT_TAG_NAME value: [StandardEventTag toStringWithEventTag:EventTagPAGE_VIEW]];
// 또는
[bundle putString: DataBundle.EVENT_TAG_NAME value: StandardEventTag.PAGE_VIEW];

// 화면(뷰) 타이틀
[bundle putString: DataBundle.EVENT_TAG_PARAM_TITLE value:@"화면이름"];
// 화면 경로
[bundle putString: DataBundle.EVENT_TAG_PARAM_PAGE_PATH value:@"/화면경로"];
// 검색어
[bundle putString: DataBundle.EVENT_TAG_PARAM_KEYWORD value:@"검색어"];
// 사용자 정의 url
[bundle putString: DataBundle.EVENT_TAG_PARAM_CUSTOM_PATH value:@"/사용자정의경로"];
// 에러 메세지
[bundle putString: DataBundle.EVENT_TAG_PARAM_ERROR_MSG value:@"Crash Exception Log or Message!"];
```

```swift
// 기본 DataBundle 객체를 사용하여 새로운 DataBundle 객체 생성 시 initialize가 가능하며, 기존 DataBundle 객체 내용 또한 수정 가능
DataBundle *bundle02 = [[DataBundle alloc] init: bundle];

[bundle02 putString: DataBundle.EVENT_TAG_NAME value: @"사용자 정의 태그명"];
[bundle02 putString: DataBundle.EVENT_TAG_PARAM_TITLE value: @"화면이름02"];
```

```swift
// # DataBundle에 저장할 Dimension 설정
//==============================================================================================================
// 타입과 index를 사용하여 Dimension 설정 (SDK 초기화 설정 시 isUseDynamicParameter를 설정하지 않거나 false로 설정한 경우 사용)

Dimension *dim01 = [[Dimension alloc] initWithIndex:1 value:@"이체"];       
Dimension *dim02 = [[Dimension alloc] initWithIndex:2 numValue:10000.0];

// bundle 객체에 Dimension 추가
[bundle putDimension: dim01];                                       // 단일 객체
[bundle putDimensions: [NSArray arrayWithObjects:dim02, nil]];      // Array 형 객체

// bundle 객체의 Dimension 가져오기
NSArray<Dimension *> dimensions = [bundle getDimensions];                             // Dimension Array 값
Dimension *dimension = [bundle getDimensionWithType:Dimension.generalType index: 1];  // 해당 타입 index의 Dimension

// bundle 객체의 Dimension 삭제
[bundle removeAllDimension];                                         // 전체 삭제
[bundle removeDimensionWithType:Dimension.generalType index: 1];     // 해당 타입 index의 Dimension 삭제


//==============================================================================================================
// 동적 파라미터 key 값을 사용하여 Dimension 설정 (SDK 초기화 설정 시 isUseDynamicParameter를 true로 설정한 경우 사용)

Dimension *dim01 = [[Dimension alloc] initWithKey:@"사용자행동01" value:@"이체"];
Dimension *dim02 = [[Dimension alloc] initWithKey:@"사용자행동01" numValue:10000.0];

// bundle 객체에 Dimension 추가
[bundle putDynamicDimension: dim01];                                       // 단일 객체
[bundle putDynamicDimensions: [NSArray arrayWithObjects:dim02, nil]];      // Array 형 객체

// bundle 객체의 Dimension 가져오기
NSArray<Dimension *> dimensions = [bundle getDynamicDimensions];          // Dimension Array 값
Dimension *dimension = [bundle getDynamicDimensionWithKey:@"사용자행동01"];  // 해당 key의 Dimension

// bundle 객체의 Dimension 삭제
[bundle removeAllDynamicDimension];                                       // 전체 삭제
[bundle removeDynamicDimensionWithKey:@"사용자행동01"];                      // 해당 key의 Dimension 삭제

```

<br>

## 로그 전송

-   logEvent 함수를 호출하여 로그를 전송합니다.
-   로그 타입에는 페이지뷰, 사용자 태그 두 가지 타입이 존재합니다.
    <br>
    <br>

> Swift

```swift
let bundle = DataBundle()

bundle.putString(DataBundle.EVENT_TAG_NAME, StandardEventTag.PAGE_VIEW)
bundle.putString(DataBundle.EVENT_TAG_PARAM_TITLE, "화면이름")
bundle.putString(DataBundle.EVENT_TAG_PARAM_PAGE_PATH, "/화면경로")
bundle.putString(DataBundle.EVENT_TAG_PARAM_CUSTOM_PATH, "/사용자정의경로")

// # 1.페이지뷰 태깅 로그 전송하는 경우
TagWorks.sharedInstance.logEvent(TagWorks.EVENT_TYPE_PAGE, bundle: bundle)

//======================================================================================

// # 2.사용자정의 태깅 로그 전송하는 경우
TagWorks.sharedInstance.logEvent(TagWorks.EVENT_TYPE_USER_EVENT, bundle: bundle)
```

<br>

> Objective-C

```swift
DataBundle *bundle = [[DataBundle alloc] init];

[bundle putString: DataBundle.EVENT_TAG_NAME value: StandardEventTag.PAGE_VIEW];
[bundle putString: DataBundle.EVENT_TAG_PARAM_TITLE value:@"화면이름"];
[bundle putString: DataBundle.EVENT_TAG_PARAM_PAGE_PATH value:@"/화면경로"];
[bundle putString: DataBundle.EVENT_TAG_PARAM_CUSTOM_PATH value:@"/사용자정의경로"];

// # 1.페이지뷰 태깅 로그 전송하는 경우
[TagWorks.sharedInstance logEvent:TagWorks.EVENT_TYPE_PAGE bundle:bundle];

//======================================================================================

// # 2.사용자정의 태깅 로그 전송하는 경우
[TagWorks.sharedInstance logEvent:TagWorks.EVENT_TYPE_USER_EVENT bundle:bundle];
```

<br>

## Web View 연동

-   Web / App 연동을 위한 interface 를 제공합니다.
-   앱에서 Tag Manager Code Snippet 이 포함된 웹뷰를 실행하면, 웹뷰에서 발생된 태깅은 SDK를 통하여 앱으로 전송됩니다.
-   WKWebViewConfiguration 설정 이외의 다른 설정은 필요하지 않습니다.
-   로그인 시 사용자 맵핑을 위해 로그인 시점에 userId 설정하는 부분과 App에서 설정한 Dimension 값을 WebView에서 사용하기 위해 쿠키를<br>
설정하는 부분에 있어 부분적인 대응 개발이 필요할 수 있습니다.
-   <span style="color: #00FFFF">만약 프로젝트에서 Precompiled Header에서 WebKit이 선언되어 있는 경우, #import <WebKit/WebKit.h> 위치를 TagWorks 프레임워크 헤더 선언하는 위치 위에 선언 후 빌드해야 합니다.</span>

<br>

> Swift

```swift
// Web View 설정
// WKUserContentController()를 처음 사용할 경우
let config = WKWebViewConfiguration()
config.userContentController = TagWorks.sharedInstnace.webViewInterface.getContentController()
webView = WKWebView(frame: view.bounds, configuration: config)
self.webViewContainerView.addSubView(webView)


// 기존에 WKUserContentController()를 사용 중인 경우 (권장)
let userContentController = WKUserContentController()       
TagWorks.sharedInstance.webViewInterface.addTagworksWebInterface(userContentController)
config.userContentController = userContentController
webView = WKWebView(frame: view.bounds, configuration: config)
self.webViewContainerView.addSubView(webView)
```

<br>

> Objective-C

```objc
// Web View 설정
// WKUserContentController()를 처음 사용할 경우
WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
config.userContentController = [[[TagWorks sharedInstance] webViewInterface] getContentController];
WKWebView *webView = [[WKWebView alloc] initWithFrame:CGRectZero configuration:config];
[self.webViewContainerView addSubview:webView];


// 기존에 WKUserContentController()를 사용 중인 경우 (권장)
WKUserContentController *userContentController = [[WKUserContentController alloc] init];
[[TagWorks sharedInstance].webViewInterface addTagworksWebInterface:userContentController];
config.userContentController = userContentController;
WKWebView *webView = [[WKWebView alloc] initWithFrame:CGRectZero configuration:config];
[self.webViewContainerView addSubview:webView];
```

<br>

## 딥링크 (유입 경로 추적)

- Referrer 정보가 포함되어 있는 URL로 부터 앱이 실행이 된 경우, 해당 Referrer 정보를 서버로 수집이 가능합니다.
- 앱에서 해당 URL 정보를 받아오는 함수 내부에 다음과 같은 TagWorks SDK 인터페이스를 호출합니다.
> **Swift**

```swift
TagWorks.sharedInstance.sendReferrerEvent(openURL: <referrer url>)
```
> **Objective-C**
```obj-c
[TagWorks.sharedInstance sendReferrerEventWithOpenURL: <referrer url>];
```