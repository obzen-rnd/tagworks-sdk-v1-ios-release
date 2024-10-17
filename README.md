<img src="https://capsule-render.vercel.app/api?type=Waving&color=04FFF0&height=150&section=header&text=TagWorks-SDK-iOS&fontSize=45" />

![Generic badge](https://img.shields.io/badge/TagWorks_iOS_SDK-v1.1.11-green.svg)
![Generic badge](https://img.shields.io/badge/license-MIT-blue.svg)
![Generic badge](https://img.shields.io/badge/Platform-iOS-red.svg)
![Generic badge](https://img.shields.io/badge/support-swift-yellow.svg)
![Generic badge](https://img.shields.io/badge/support-objective--c-yellow.svg)

## Requirements

-   최소 iOS 버전 : iOS 9+

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
    pod 'TagWorks-SDK-iOS', 'release 최신 버전'
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

-   TagWorks.framework : 오프라인으로 제공

1.  TagWorks.framework 추가
    <br>

    1. `Xcode > Project 파일 > General > Frameworks, Libraries, and Embedded Content`의 `+` 버튼을 눌러주세요.<br><br>
    2. 좌측 하단의 `Add Other.. > Add Files..` 를 클릭해 제공받은 zip 파일내의 `TagWorks_SDK_iOS_v1.framework` 폴더를 추가해주세요.<br><br>
    3. `TagWorks_SDK_iOS_v1.framework` Embed 상태를 Embed & Sign 로 변경해주세요.<br>

    <br>

-   framework 폴더의 경로가 프로젝트 경로와 일치하지 않을 경우에는 Target의 `Build Settings > Search Path > Framework Search Paths` 값을 해당 framework 폴더의 경로로 변경해주세요.

#

<br>

## 초기화

| 옵션             | 타입    | 기본값 | 설명                                                                              |
| ---------------- | ------- | ------ | ---------------------------------------------------------------------------------                                    |
| siteId           | string  | null   | 행동 정보 수집 대상 사이트 식별자                                                    |
| baseUrl          | string  | null   | 행동 정보 데이터 수집 서버 url 주소                                                 |
| isUseIntervals   | boolean | false  | interval 사용 여부, false 일 경우 dispatchInterval 값이 무시되고 항상 즉시 발송된다.     |
| dispatchInterval | long    | 5      | 행동 정보 데이터 발송 주기 (최소 5초 설정), 초단위                                      |
| sessionTimeOut   | long    | 5      | 행동 정보 데이터 수집 서버의 http 응답 대기 최대 시간 (second)                          |
| userAgent        | string  | null   | user Agent 정보, 설정할 경우 설정된 값으로 전달                                      |
| appVersion       | string  | null   | Application 버전 정보, 설정하지 않을 경우 short version 전송                         |
| appName          | string  | null   | Application 이름, 설정하지 않을 경우 bundle name 전송                               |

<br>

-   **siteId** 및 **baseUrl** 을 설정하지 않는 경우 SDK 초기화 과정에서 오류가 발생합니다.
-   **isUseIntervals** 값을 false로 설정할 경우에는 dispatchInterval 값이 무시되고 항상 즉시 발송됩니다. <br>true로 설정할 경우에는 dispatchInterval 값에 지정된 초를 주기로 데이터를 발송합니다.
-   **dispatchInterval** 은 큐에 저장된 행동 정보 데이터를 지정한 초만큼 발송하기 때문에, 지정한 시간 사이에 어플리케이션이 종료되는 경우 발송 할 수 없으니 적절한 시간으로 지정해야 합니다.
-   이러한 경우를 대비하기 위하여 sceneWillResignActive 함수 내부(어플리케이션이 background 상태로 진입하는 부분)에서 dispatch() 메서드 호출을 권장합니다.
-   **TagWorks.sharedInstance** 객체를 통하여 Singleton Instance를 제공하며, 전역에서 호출 가능합니다.

<br>

> Swift

```swift
import TagWorks_SDK_iOS_v1

// TagWorks instance 설정
TagWorks.sharedInstance.setInstanceConfig(siteId: "00,AAAAAAAA",
                                          baseUrl: URL(string: "http://obzen.com/obzenTagWorks")!,
                                          isUseIntervals: false,
                                          dispatchInterval: 5,
                                          sessionTimeOut: 5,
                                          userAgent: nil,
                                          appVersion: "1.1.0",
                                          appName: "obzen App")

// SceneDelegate class 내부
func sceneWillResignActive(_ scene: UIScene) {
    // 어플리케이션이 background 상태 진입시 이벤트 큐에 남아있는 데이터 모두 전송
    TagWorks.sharedInstance.dispatch()
}
```

<br>

> Objective-C

```objc
// SPM으로 라이브러리 추가한 경우
@import TagWorks_SDK_iOS_v1;

// CocoaPod이나 릴리즈 프레임워크 파일로 추가한 경우
#import <TagWorks_SDK_iOS_v1/TagWorks_SDK_iOS_v1-Swift.h>

// TagWorks instance 설정
TagWorks *tagWorksInstance = TagWorks.sharedInstance;
[tagWorksInstance setInstanceConfigWithSiteId:@"00,AAAAAAAA"
                                      baseUrl:[NSURL URLWithString:@"http://obzen.com/obzenTagWorks"]
                               isUseIntervals:false
                             dispatchInterval:5
                               sessionTimeOut:5
                                    userAgent:nil
                                   appVersion:@"1.1.0"
                                      appName:@"obzen APP"];

// SceneDelegate class 내부
- (void) sceneWillResignActive:(UIScene *)scene {
    // 어플리케이션이 background 상태 진입시 이벤트 큐에 남아있는 데이터 모두 전송
    TagWorks *tagWorksInstance = TagWorks.sharedInstance;
    [tagWorksInstance dispatch];
}
```

## 사용자 설정

| 옵션        | 타입    | 기본값        | 설명                                                          |
| ---------- | ------ | ----------- | ------------------------------------------------------------- |
| userId     | string | null        | 수집 대상 고객 식별자 (사용자 계정)                           |
| isOptedOut | string | false       | 행동 정보 데이터 수집 여부 (true로 설정할 경우 수집하지 않음) |
| contentUrl | string | 패키지 주소    | 행동 정보 page Url 주소 (ex) APP://com.obzen.TagWorks-SDK-iOS |

<br>

-   행동 데이터 수집 대상이 되는 사용자를 설정하고 수집 여부를 지정합니다.
    <br><br>

> Swift

```swift
// 수집 대상자 고객 식별자 지정
TagWorks.sharedInstance.userId = id

// 고객이 설정한 개인정보 수집 여부에 따라 수집 여부 지정
TagWorks.sharedInstance.isOptedOut = false

// page url 주소 - 설정하지 않을 경우 기본값 지정 - APP://com.obzen.TagWorks-SDK-iOS
TagWorks.sharedInstance.contentUrl = URL(string: "http://obzen.com/")
```

<br>

> Objective-C

```objc
// 수집 대상자 고객 식별자 지정
[tagWorksInstance setUserId:@"user id"];

// 고객이 설정한 개인정보 수집 여부에 따라 수집 여부 지정
[tagWorksInstance setIsOptedOut:false];

// page url 주소 - 설정하지 않을 경우 기본값 지정 - APP://com.obzen.TagWorks-SDK-iOS
[tagWorksInstance setContentUrl:[NSURL URLWithString:@"http://obzen.com/"]];
```

## 데이터 구성

### Dimension 객체

-   Dimension은 사용자 상호작용 발생 시 수집하는 정보입니다.
-   문자형과 숫자형 두 개의 타입 중 원하는 타입을 선택하여 사용할 수 있습니다. (숫자형은 수치데이터 정보를 이용한 통계 목적으로 사용 가능)
-   key & value 형태로 값을 지정할 수 있으며, key 부분에는 <span style="color: #6ba455">숫자형 index</span>를 사용합니다.
    -   입력하는 index 값은 TagManager 제품에서 정의된 값으로 프로젝트 진행시 전달받을 수 있습니다.

<br>

> Swift

```swift
// Dimension - String Type
// stringValue 사용할 경우 문자형, numValue 사용할 경우 숫자형
let dim01 = Dimension(index: 1, stringValue: "계좌조회")
let dim02 = Dimension(WithType: Dimension.generalType, index: 2, stringValue: "잔금조회")

// Dimension - Numeric Type (Double형)
let dim03 = Dimension(index: 3, numValue: 50.0)
let dim04 = Dimension(WithType: Dimension.factType, index: 4, stringValue: "", numValue: 123.123)
```

<br>

> Objective-C

```objc
// Dimension - String Type
// stringValue 사용할 경우 문자형, numValue 사용할 경우 숫자형
Dimension *dim01 = [[Dimension alloc] initWithIndex:1 stringValue:@"계좌조회"];
Dimension *dim02 = [[Dimension alloc] initWithType:Dimension.generalType index:2 stringValue:@"잔금조회" numValue:0];

// Dimension - Numeric Type (Double형)
Dimension *dim03 = [[Dimension alloc] initWithIndex:3 numValue:50.0];
Dimension *dim04 = [[Dimension alloc] initWithType:Dimension.factType index:4 stringValue:@"" numValue:123.123];
```

### 공용 Dimension

-   공용 Dimension은 수집 로그 전송 시 공통적으로 전송해야 할 데이터를 설정하는 용도로 사용합니다.
-   공용 Dimension에서 사용된 index에 다른 Dimension을 덮어쓰지 않는 이상 한 번 설정된 공용 Dimension은 계속 유지됩니다.
-   setCommonDimension() 메서드를 사용하여 공용 Dimension 항목을 계속 추가할 수 있습니다.

<br>

> Swift

```swift
// set
let dim01 = Dimension(index: 1, stringValue: "계좌조회")
TagWorks.sharedInstance.setCommonDimension(dimension: dim01)                            // 객체 전달
TagWorks.sharedInstance.setCommonDimension(index: 2, numValue: 100.12)                  // 숫자형
TagWorks.sharedInstance.setCommonDimension(index: 3, stringValue: "비밀번호관리")           // 문자형
TagWorks.sharedInstance.setCommonDimension(type: Dimension.factType, index: 4, stringValue: "", numValue: 100.0) // 타입 지정

// get - Dimension 객체 return
let cDim001 = TagWorks.sharedInstance.getCommonDimension(WithTYpe: Dimension.generalType, index: 1)
let cDim002 = TagWorks.sharedInstance.getCommonDimension(WithTYpe: Dimension.factType, index: 2)

let cDim001Val = cDim001?.value         // 문자형 값
let cDim001Val2 = cDim002?.numValue     // 숫자형 값
```

<br>

> Objective-C

```objc
// set
Dimension *dim01 = [[Dimension alloc] initWithIndex:1 stringValue:@"계좌조회"];
[tagWorksInstance setCommonDimensionWithDimension:dim01];                               // 객체 전달
[tagWorksInstance setCommonDimensionWithIndex:2 numValue:100.12];                       // 숫자형
[tagWorksInstance setCommonDimensionWithIndex:3 stringValue:@"비밀번호관리"];               // 문자형
[tagWorksInstance setCommonDimensionWithType:Dimension.factType index:4 stringValue:@"" numValue:100.0];    // 타입 지정

// get
Dimension *cDim001 = [tagWorksInstance getCommonDimensionWithType: Dimension.generalType index:1];
Dimension *cDim002 = [tagWorksInstance getCommonDimensionWithType: Dimension.factType index:2];

NSString *cDim001Val = cDim001.value;   // 문자형 값
double cDim001Val2 = cDim002.numValue;  // 숫자형 값
```

### DataBundle 객체

-   기본 파라미터 및 Dimension을 쉽게 관리하기 위하여 DataBundle 객체를 제공합니다.
-   DataBundle 객체는 key와 value의 집합으로 구성됩니다.
-   key 값으로는 DataBundle 객체가 제공하는 기본 파라미터값을 사용하거나, String 값을 직접 입력할 수 있습니다.
-   putDimensions 메소드를 이용하여 Dimension 객체를 DataBundle 내부에 추가하여 사용할 수 있습니다.
    <br>
    <br>

#### DataBundle 객체의 key 값으로 사용 가능한 파라미터

| 파라미터                        | 타입    | 설명                                      |
| ----------------------------- | ------ | ---------------------------------------- |
| EVENT_TAG_NAME                | string | 이벤트 이름                                 |
| EVENT_TAG_PARAM_TITLE         | string | 화면 타이틀                                 |
| EVENT_TAG_PARAM_PAGE_PATH     | string | 화면 경로                                  |
| EVENT_TAG_PARAM_KEYWORD       | string | 검색어                                     |
| EVENT_TAG_PARAM_CUSTOM_PATH   | string | 사용자 정의 경로 - 추가 분석을 위한 경로          |
| EVENT_TAG_PARAM_ERROR_MSG     | string | 에러 메세지                                 |

<br>

#### <span style="color: #6ba455">EVENT_TAG_NAME</span> 값에 사용할 수 있는 Standard 이벤트

| EVENT_TAG_NAME | 설명                  |
| -------------- | -------------------- |
| PAGE_VIEW      | 페이지뷰 이벤트          |
| CLICK          | 클릭 이벤트             |
| SCROLL         | 화면 스크롤 이벤트       |
| DOWNLOAD       | 파일 다운로드 이벤트      |
| OUT_LINK       | 링크 이동 이벤트        |
| SEARCH         | 검색 이벤트            |
| ERROR          | 오류 발생 이벤트        |
| REFERRER       | 유입 경로 이벤트        |

<br>

> Swift

```swift
let bundle = DataBundle()

// 이벤트 이름 - Standard 이벤트 or 사용자 정의 이벤트명
bundle.putString(DataBundle.EVENT_TAG_NAME, EventTag.PAGE_View.description)
// 화면(뷰) 타이틀
bundle.putString(DataBundle.EVENT_TAG_PARAM_TITLE, "계좌관리")
// 화면 경로
bundle.putString(DataBundle.EVENT_TAG_PARAM_PAGE_PATH, "/home/bank/Account_Management")
// 검색어
bundle.putString(DataBundle.EVENT_TAG_PARAM_KEYWORD, "search keyword!")
// 사용자 정의 url
bundle.putString(DataBundle.EVENT_TAG_PARAM_CUSTOM_PATH, "/bank/Account")
// 에러 메세지
bundle.putString(DataBundle.EVENT_TAG_PARAM_ERROR_MSG, "Crash Exception Log or Message!")

let dim01 = Dimension(index: 1, stringValue: "이체")
let dim02 = Dimension(WithType: Dimension.factType, index: 2, stringValue: "", numValue: 10000.0)

// bundle 객체에 Dimension 추가
bundle.putDimensions([dim01, dim02])


// 기본 DataBundle 객체를 사용하여 새로운 DataBundle 객체 생성 시 initialize가 가능하며, 기존 DataBundle 객체 내용 또한 수정 가능
let bundle02 = DataBundle(bundle)
bundle02.putString(DataBundle.EVENT_TAG_PARAM_TITLE, "계좌이체")


// 사용자 정의 이벤트 설정
let bundle03 = DataBundle(bundle)
bundle03.putString(DataBundle.EVENT_TAG_NAME, "사용자 정의 이벤트명")
```

<br>

> Objective-C

```objc
DataBundle *bundle = [[DataBundle alloc] init];

// 이벤트 이름 - Standard 이벤트 or 사용자 정의 이벤트명
[bundle putString: DataBundle.EVENT_TAG_NAME value: [StandardEventTag toStringWithEventTag:EventTagPAGE_View]];
// 화면(뷰) 타이틀
[bundle putString: DataBundle.EVENT_TAG_PARAM_TITLE value:@"계좌관리"];
// 화면 경로
[bundle putString: DataBundle.EVENT_TAG_PARAM_PAGE_PATH value:@"/home/bank/Account_Management"];
// 검색어
[bundle putString: DataBundle.EVENT_TAG_PARAM_KEYWORD value:@"search keyword!"];
// 사용자 정의 url
[bundle putString: DataBundle.EVENT_TAG_PARAM_CUSTOM_PATH value:@"/bank/Account"];
// 에러 메세지
[bundle putString: DataBundle.EVENT_TAG_PARAM_ERROR_MSG value:@"Crash Exception!"];

Dimension *dim01 = [[Dimension alloc] initWithIndex:1 stringValue:@"이체"];       
Dimension *dim02 = [[Dimension alloc] initWithType:Dimension.factType index:2 stringValue:@"" numValue:10000.0];

// bundle 객체에 Dimension 추가
[bundle putDimensions: [NSArray arrayWithObjects:dim01, dim02, nil]];

// 기본 DataBundle 객체를 사용하여 새로운 DataBundle 객체 생성 시 initialize가 가능하며, 기존 DataBundle 객체 내용 또한 수정 가능
DataBundle *bundle02 = [[DataBundle alloc] init:bundle];
[bundle02 putString: DataBundle.EVENT_TAG_PARAM_TITLE value:@"계좌이체"];

// 사용자 정의 이벤트 설정
DataBundle *bundle03 = [[DataBundle alloc] init:bundle];
[bundle03 putString: DataBundle.EVENT_TAG_NAME value:@"사용자 정의 이벤트명"];
```

<br>

## 로그 전송

-   logEvent 함수를 호출하여 로그를 전송합니다.
-   로그 타입에는 페이지뷰, 이벤트 두 가지 타입이 존재합니다.
    <br>
    <br>

> Swift

```swift
let bundle = DataBundle()

bundle.putString(DataBundle.EVENT_TAG_NAME, EventTag.PAGE_View.description)
bundle.putString(DataBundle.EVENT_TAG_PARAM_TITLE, "계좌관리")
bundle.putString(DataBundle.EVENT_TAG_PARAM_PAGE_PATH, "/home/bank/Account_Management")
bundle.putString(DataBundle.EVENT_TAG_CUSTOM_PATH, "/bank/Account")

// 스크린뷰 전송
TagWorks.sharedInstance.logEvent(TagWorks.EVENT_TYPE_PAGE, bundle: bundle)


let cDim01 = Dimension(index: 1, stringValue: "구매")
let cDim02 = Dimension(WithType: Dimension.factType, index: 2, stringValue: "", numValue: 100)

// bundle 객체에 Dimension 추가
bundle.putDimensions([cDim01, cDim02])

bundle.putString(DataBundle.EVENT_TAG_NAME, EventTag.click.description)

// 이벤트 전송
TagWorks.sharedInstance.logEvent(TagWorks.EVENT_TYPE_USER_EVENT, bundle: bundle)
```

<br>

> Objective-C

```objc
DataBundle *bundle = [[DataBundle alloc] init];

[bundle putString: DataBundle.EVENT_TAG_NAME value: [StandardEventTag toStringWithEventTag:EventTagPAGE_View]];
[bundle putString: DataBundle.EVENT_TAG_PARAM_TITLE value:@"계좌관리"];
[bundle putString: DataBundle.EVENT_TAG_PARAM_PAGE_PATH value:@"/home/bank/Account_Management"];
[bundle putString: DataBundle.EVENT_TAG_PARAM_CUSTOM_PATH value:@"/bank/Account"];

// 스크린뷰 전송
[tagWorksInstance logEvent:TagWorks.EVENT_TYPE_PAGE bundle:bundle];

Dimension *cDim01 = [[Dimension alloc] initWithIndex:1 stringValue:@"이체"];
Dimension *cDim02 = [[Dimension alloc] initWithIndex:2 numValue:10000.0];

// bundle 객체에 Dimension 추가
[bundle putDimensions: [NSArray arrayWithObjects:cDim01, cDim02, nil]];
[bundle putString: DataBundle.EVENT_TAG_NAME value: [StandardEventTag toStringWithEventTag:EventTagCLICK]];

// 이벤트 전송
[tagWorksInstance logEvent:TagWorks.EVENT_TYPE_USER_EVENT bundle:bundle];
```

## Web View 연동

-   Web / App 연동을 위한 interface 를 제공합니다.
-   앱에서 Tag Manager Code Snippet 이 포함된 웹뷰를 실행하면, 웹뷰에서 발생된 이벤트는 SDK를 통하여 앱으로 전송됩니다.
-   WKWebViewConfiguration 설정 이외의 다른 설정은 필요하지 않습니다.
-   로그인 시 사용자 맵핑을 위해 로그인 시점에 userId 설정하는 부분과 App에서 설정한 Dimension 값을 WebView에서 사용하기 위해 쿠키를<br>
설정하는 부분에 있어 부분적인 대응 개발이 필요할 수 있습니다.
-   **만약 프로젝트에서 Precompiled Header를 사용할 경우, #import <WebKit/WebKit.h> 위치를 TagWorks 프레임워크 헤더 선언하는 위치 위에 선언 후 빌드해야 합니다.**

<br>

> Swift

```swift
// Web View 설정
let config = WKWebViewConfiguration()
config.userContentController = TagWorks.sharedInstnace.webViewInterface.getContentController()
webView = WKWebView(frame: view.bounds, configuration: config)
self.webViewContainerView.addSubView(webView)
```

<br>

> Objective-C

```objc
// Web View 설정
WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
config.userContentController = [[[TagWorks sharedInstance] webViewInterface] getContentController];

WKWebView *webView = [[WKWebView alloc] initWithFrame:CGRectZero configuration:config];
[self.webViewContainerView addSubview:webView];
```
