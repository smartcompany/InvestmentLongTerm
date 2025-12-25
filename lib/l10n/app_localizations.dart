import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ja'),
    Locale('ko'),
    Locale('zh'),
  ];

  /// No description provided for @selectAssetQuestion.
  ///
  /// In ko, this message translates to:
  /// **'어떤 자산에 투자 하시겠습니까?'**
  String get selectAssetQuestion;

  /// No description provided for @loadingAssetData.
  ///
  /// In ko, this message translates to:
  /// **'자산 데이터 불러오는 중...'**
  String get loadingAssetData;

  /// No description provided for @loadAssetError.
  ///
  /// In ko, this message translates to:
  /// **'자산 정보 로드 실패'**
  String get loadAssetError;

  /// No description provided for @retry.
  ///
  /// In ko, this message translates to:
  /// **'다시 시도'**
  String get retry;

  /// No description provided for @investmentSettingsTitle.
  ///
  /// In ko, this message translates to:
  /// **'{assetName} 투자 설정'**
  String investmentSettingsTitle(Object assetName);

  /// No description provided for @investmentAmountLabel.
  ///
  /// In ko, this message translates to:
  /// **'투자 금액'**
  String get investmentAmountLabel;

  /// No description provided for @investmentTypeLabel.
  ///
  /// In ko, this message translates to:
  /// **'투자 방식'**
  String get investmentTypeLabel;

  /// No description provided for @singleInvestment.
  ///
  /// In ko, this message translates to:
  /// **'단일 투자'**
  String get singleInvestment;

  /// No description provided for @recurringInvestment.
  ///
  /// In ko, this message translates to:
  /// **'정기 투자'**
  String get recurringInvestment;

  /// No description provided for @investmentDurationLabel.
  ///
  /// In ko, this message translates to:
  /// **'투자 기간'**
  String get investmentDurationLabel;

  /// No description provided for @viewResults.
  ///
  /// In ko, this message translates to:
  /// **'광고 보고 결과 보기'**
  String get viewResults;

  /// No description provided for @enterInvestmentAmount.
  ///
  /// In ko, this message translates to:
  /// **'투자 금액을 입력해주세요'**
  String get enterInvestmentAmount;

  /// No description provided for @yearsAgo.
  ///
  /// In ko, this message translates to:
  /// **'{count}년 전'**
  String yearsAgo(Object count);

  /// No description provided for @investmentSummary.
  ///
  /// In ko, this message translates to:
  /// **'{assetName}에 {amount}를 {type}로 투자했다면?'**
  String investmentSummary(Object amount, Object assetName, Object type);

  /// No description provided for @singleInvestmentDate.
  ///
  /// In ko, this message translates to:
  /// **'{date}에 한번에 투자'**
  String singleInvestmentDate(Object date);

  /// No description provided for @recurringInvestmentDate.
  ///
  /// In ko, this message translates to:
  /// **'{date}부터 {frequency} 투자'**
  String recurringInvestmentDate(Object date, Object frequency);

  /// No description provided for @monthly.
  ///
  /// In ko, this message translates to:
  /// **'매월'**
  String get monthly;

  /// No description provided for @weekly.
  ///
  /// In ko, this message translates to:
  /// **'매주'**
  String get weekly;

  /// No description provided for @fetchingPriceData.
  ///
  /// In ko, this message translates to:
  /// **'실제 가격 데이터를 가져오는 중...'**
  String get fetchingPriceData;

  /// No description provided for @errorOccurred.
  ///
  /// In ko, this message translates to:
  /// **'오류가 발생했습니다'**
  String get errorOccurred;

  /// No description provided for @goBack.
  ///
  /// In ko, this message translates to:
  /// **'돌아가기'**
  String get goBack;

  /// No description provided for @investmentResults.
  ///
  /// In ko, this message translates to:
  /// **'투자 결과'**
  String get investmentResults;

  /// No description provided for @bestReturn.
  ///
  /// In ko, this message translates to:
  /// **'최고 수익'**
  String get bestReturn;

  /// No description provided for @cagr.
  ///
  /// In ko, this message translates to:
  /// **'연평균 수익률 (CAGR)'**
  String get cagr;

  /// No description provided for @returnOnInvestment.
  ///
  /// In ko, this message translates to:
  /// **'투자 대비 수익'**
  String get returnOnInvestment;

  /// No description provided for @totalInvested.
  ///
  /// In ko, this message translates to:
  /// **'총 투자금 {amount}'**
  String totalInvested(Object amount);

  /// No description provided for @compareInvestmentStrategies.
  ///
  /// In ko, this message translates to:
  /// **'투자 방식 비교'**
  String get compareInvestmentStrategies;

  /// No description provided for @assetGrowthTrend.
  ///
  /// In ko, this message translates to:
  /// **'자산 성장 추이'**
  String get assetGrowthTrend;

  /// No description provided for @insightMessage.
  ///
  /// In ko, this message translates to:
  /// **'시간을 친구로 만든다면,\n시장은 당신의 편입니다.'**
  String get insightMessage;

  /// No description provided for @share.
  ///
  /// In ko, this message translates to:
  /// **'공유하기'**
  String get share;

  /// No description provided for @recalculate.
  ///
  /// In ko, this message translates to:
  /// **'다시 계산'**
  String get recalculate;

  /// No description provided for @shareResults.
  ///
  /// In ko, this message translates to:
  /// **'결과 공유하기'**
  String get shareResults;

  /// No description provided for @copyText.
  ///
  /// In ko, this message translates to:
  /// **'텍스트 복사'**
  String get copyText;

  /// No description provided for @copyTextDesc.
  ///
  /// In ko, this message translates to:
  /// **'텍스트로 결과 복사하기'**
  String get copyTextDesc;

  /// No description provided for @copiedToClipboard.
  ///
  /// In ko, this message translates to:
  /// **'복사되었습니다'**
  String get copiedToClipboard;

  /// No description provided for @close.
  ///
  /// In ko, this message translates to:
  /// **'닫기'**
  String get close;

  /// No description provided for @shareTextTitle.
  ///
  /// In ko, this message translates to:
  /// **'만약 {yearsAgo}년 전에 {assetName}에 {amount}를 투자했다면 지금 얼마일까?'**
  String shareTextTitle(Object amount, Object assetName, Object yearsAgo);

  /// No description provided for @shareTextFooter.
  ///
  /// In ko, this message translates to:
  /// **'장기 투자 매매 계산 결과'**
  String get shareTextFooter;

  /// No description provided for @downloadLink.
  ///
  /// In ko, this message translates to:
  /// **'다운로드: {url}'**
  String downloadLink(Object url);

  /// No description provided for @homeQuestionPart1.
  ///
  /// In ko, this message translates to:
  /// **'만약 {yearsAgo}년 전에'**
  String homeQuestionPart1(Object yearsAgo);

  /// No description provided for @homeQuestionPart2.
  ///
  /// In ko, this message translates to:
  /// **'{assetName}을 샀다면\n지금 얼마일까?'**
  String homeQuestionPart2(Object assetName);

  /// No description provided for @homeDescription.
  ///
  /// In ko, this message translates to:
  /// **'시간을 믿는 투자, 그 결과를 직접 확인해보세요.'**
  String get homeDescription;

  /// No description provided for @retirementQuestionPart1.
  ///
  /// In ko, this message translates to:
  /// **'내 자산으로'**
  String get retirementQuestionPart1;

  /// No description provided for @retirementQuestionPart2.
  ///
  /// In ko, this message translates to:
  /// **'얼마나 놀고 먹을 수 있을까?'**
  String get retirementQuestionPart2;

  /// No description provided for @retirementDescription.
  ///
  /// In ko, this message translates to:
  /// **'은퇴 후 자산 변화를 시뮬레이션해보세요.'**
  String get retirementDescription;

  /// No description provided for @pastAssetSimulation.
  ///
  /// In ko, this message translates to:
  /// **'그때 샀다면?'**
  String get pastAssetSimulation;

  /// No description provided for @retirementSimulation.
  ///
  /// In ko, this message translates to:
  /// **'내 돈으로?'**
  String get retirementSimulation;

  /// No description provided for @crypto.
  ///
  /// In ko, this message translates to:
  /// **'암호화폐'**
  String get crypto;

  /// No description provided for @stock.
  ///
  /// In ko, this message translates to:
  /// **'미국 주식'**
  String get stock;

  /// No description provided for @cash.
  ///
  /// In ko, this message translates to:
  /// **'현금'**
  String get cash;

  /// No description provided for @commodity.
  ///
  /// In ko, this message translates to:
  /// **'원자재'**
  String get commodity;

  /// No description provided for @failedToLoadAssetList.
  ///
  /// In ko, this message translates to:
  /// **'자산 목록을 불러오지 못했습니다.'**
  String get failedToLoadAssetList;

  /// No description provided for @frequencySelectionHint.
  ///
  /// In ko, this message translates to:
  /// **'둘 다 선택하면 단일 투자와 함께 그래프로 비교해볼 수 있어요.'**
  String get frequencySelectionHint;

  /// No description provided for @investmentFrequencyLabel.
  ///
  /// In ko, this message translates to:
  /// **'투자 주기 (중복 선택 가능)'**
  String get investmentFrequencyLabel;

  /// No description provided for @calculationError.
  ///
  /// In ko, this message translates to:
  /// **'계산 실패: {error}'**
  String calculationError(Object error);

  /// No description provided for @investmentStartDate.
  ///
  /// In ko, this message translates to:
  /// **'투자 시작 시점: {yearsAgo}년 전 ({year})'**
  String investmentStartDate(Object year, Object yearsAgo);

  /// No description provided for @monthlyAndWeekly.
  ///
  /// In ko, this message translates to:
  /// **'매월과 매주'**
  String get monthlyAndWeekly;

  /// No description provided for @summarySingle.
  ///
  /// In ko, this message translates to:
  /// **'{yearsAgo}년 전부터 {assetName}에 {amount}를 한 번 투자했다면...'**
  String summarySingle(Object amount, Object assetName, Object yearsAgo);

  /// No description provided for @summaryRecurringMonthly.
  ///
  /// In ko, this message translates to:
  /// **'{yearsAgo}년 전부터 {assetName}에 매월 {investMoney}를 투자하면 어떻게 될까요?'**
  String summaryRecurringMonthly(
    Object assetName,
    Object investMoney,
    Object yearsAgo,
  );

  /// No description provided for @summaryRecurringWeekly.
  ///
  /// In ko, this message translates to:
  /// **'{yearsAgo}년 전부터 {assetName}에 매주 {investMoney}를 투자하면 어떻게 될까요?'**
  String summaryRecurringWeekly(
    Object assetName,
    Object investMoney,
    Object yearsAgo,
  );

  /// No description provided for @saveAndShare.
  ///
  /// In ko, this message translates to:
  /// **'저장 & 공유하기'**
  String get saveAndShare;

  /// No description provided for @basicShare.
  ///
  /// In ko, this message translates to:
  /// **'기본 공유'**
  String get basicShare;

  /// No description provided for @basicShareDesc.
  ///
  /// In ko, this message translates to:
  /// **'메신저, 메일 등으로 공유'**
  String get basicShareDesc;

  /// No description provided for @copyToClipboard.
  ///
  /// In ko, this message translates to:
  /// **'클립보드에 결과 복사'**
  String get copyToClipboard;

  /// No description provided for @shareTextHeader.
  ///
  /// In ko, this message translates to:
  /// **'Time Capital 계산 결과'**
  String get shareTextHeader;

  /// No description provided for @finalValue.
  ///
  /// In ko, this message translates to:
  /// **'최종 가치'**
  String get finalValue;

  /// No description provided for @yieldRateLabel.
  ///
  /// In ko, this message translates to:
  /// **'수익률'**
  String get yieldRateLabel;

  /// No description provided for @gain.
  ///
  /// In ko, this message translates to:
  /// **'수익'**
  String get gain;

  /// No description provided for @totalInvestmentAmount.
  ///
  /// In ko, this message translates to:
  /// **'총 투자금액'**
  String get totalInvestmentAmount;

  /// No description provided for @kakaoTalk.
  ///
  /// In ko, this message translates to:
  /// **'카카오톡'**
  String get kakaoTalk;

  /// No description provided for @shareWithKakaoTalk.
  ///
  /// In ko, this message translates to:
  /// **'카카오톡으로 공유'**
  String get shareWithKakaoTalk;

  /// No description provided for @sharedToKakaoTalk.
  ///
  /// In ko, this message translates to:
  /// **'카카오톡으로 공유되었습니다!'**
  String get sharedToKakaoTalk;

  /// No description provided for @shareWithTextAndChart.
  ///
  /// In ko, this message translates to:
  /// **'텍스트와 차트 이미지 함께 공유'**
  String get shareWithTextAndChart;

  /// No description provided for @showMore.
  ///
  /// In ko, this message translates to:
  /// **'더보기'**
  String get showMore;

  /// No description provided for @showLess.
  ///
  /// In ko, this message translates to:
  /// **'접기'**
  String get showLess;

  /// No description provided for @simulationResultPrefix.
  ///
  /// In ko, this message translates to:
  /// **'{initialAsset} 의 {portfolio}를 {years}년간 보유하고 한달에 {monthlyWithdrawal}씩 쓴다고 하면 {years}년 후 최종 자산은 {finalAsset}이 됩니다.'**
  String simulationResultPrefix(
    String initialAsset,
    String portfolio,
    int years,
    String monthlyWithdrawal,
    String finalAsset,
  );

  /// No description provided for @simulationResultPrefixWithInflation.
  ///
  /// In ko, this message translates to:
  /// **'{initialAsset} 의 {portfolio}를 {years}년간 보유하고 현재 가치 기준 월 {monthlyWithdrawal}에 해당하는 금액을 쓴다고 하면 {years}년 후 최종 자산은 {finalAsset}이 됩니다.'**
  String simulationResultPrefixWithInflation(
    String initialAsset,
    String portfolio,
    int years,
    String monthlyWithdrawal,
    String finalAsset,
  );

  /// No description provided for @simulationResultTitle.
  ///
  /// In ko, this message translates to:
  /// **'시뮬레이션 결과'**
  String get simulationResultTitle;

  /// No description provided for @detailedStatistics.
  ///
  /// In ko, this message translates to:
  /// **'상세 통계'**
  String get detailedStatistics;

  /// No description provided for @simulationResultNoData.
  ///
  /// In ko, this message translates to:
  /// **'시뮬레이션 결과가 없습니다.'**
  String get simulationResultNoData;

  /// No description provided for @selectedScenario.
  ///
  /// In ko, this message translates to:
  /// **'선택한 시나리오: '**
  String get selectedScenario;

  /// No description provided for @scenarioPositive.
  ///
  /// In ko, this message translates to:
  /// **'긍정적 (+20%)'**
  String get scenarioPositive;

  /// No description provided for @scenarioNegative.
  ///
  /// In ko, this message translates to:
  /// **'부정적 (-20%)'**
  String get scenarioNegative;

  /// No description provided for @scenarioNeutral.
  ///
  /// In ko, this message translates to:
  /// **'중립적 (0%)'**
  String get scenarioNeutral;

  /// No description provided for @monthlyWithdrawalLabel.
  ///
  /// In ko, this message translates to:
  /// **'월 인출액: '**
  String get monthlyWithdrawalLabel;

  /// No description provided for @monthlyWithdrawalWithInflation.
  ///
  /// In ko, this message translates to:
  /// **'월 인출액: '**
  String get monthlyWithdrawalWithInflation;

  /// No description provided for @inflationRateApplied.
  ///
  /// In ko, this message translates to:
  /// **'인플레이션 {rate}% 적용'**
  String inflationRateApplied(double rate);

  /// No description provided for @assetValueTrend.
  ///
  /// In ko, this message translates to:
  /// **'자산 가치 추이'**
  String get assetValueTrend;

  /// No description provided for @totalAssets.
  ///
  /// In ko, this message translates to:
  /// **'전체 자산'**
  String get totalAssets;

  /// No description provided for @cumulativeWithdrawal.
  ///
  /// In ko, this message translates to:
  /// **'누적 인출액'**
  String get cumulativeWithdrawal;

  /// No description provided for @finalAsset.
  ///
  /// In ko, this message translates to:
  /// **'최종 자산'**
  String get finalAsset;

  /// No description provided for @cumulativeReturn.
  ///
  /// In ko, this message translates to:
  /// **'누적 수익률'**
  String get cumulativeReturn;

  /// No description provided for @totalWithdrawn.
  ///
  /// In ko, this message translates to:
  /// **'총 인출 금액'**
  String get totalWithdrawn;

  /// No description provided for @netProfit.
  ///
  /// In ko, this message translates to:
  /// **'순 수익'**
  String get netProfit;

  /// No description provided for @monthlyDetails.
  ///
  /// In ko, this message translates to:
  /// **'월별 상세 내역'**
  String get monthlyDetails;

  /// No description provided for @yearLabel.
  ///
  /// In ko, this message translates to:
  /// **'{year}년'**
  String yearLabel(int year);

  /// No description provided for @monthLabel.
  ///
  /// In ko, this message translates to:
  /// **'{month}월'**
  String monthLabel(int month);

  /// No description provided for @asset.
  ///
  /// In ko, this message translates to:
  /// **'자산'**
  String get asset;

  /// No description provided for @withdrawal.
  ///
  /// In ko, this message translates to:
  /// **'인출'**
  String get withdrawal;

  /// No description provided for @change.
  ///
  /// In ko, this message translates to:
  /// **'변동'**
  String get change;

  /// No description provided for @simulationSettings.
  ///
  /// In ko, this message translates to:
  /// **'시뮬레이션 설정'**
  String get simulationSettings;

  /// No description provided for @initialAssetAmount.
  ///
  /// In ko, this message translates to:
  /// **'초기 자산 금액'**
  String get initialAssetAmount;

  /// No description provided for @monthlyWithdrawalAmount.
  ///
  /// In ko, this message translates to:
  /// **'월 인출 금액'**
  String get monthlyWithdrawalAmount;

  /// No description provided for @simulationDuration.
  ///
  /// In ko, this message translates to:
  /// **'시뮬레이션 기간'**
  String get simulationDuration;

  /// No description provided for @year.
  ///
  /// In ko, this message translates to:
  /// **'년'**
  String get year;

  /// No description provided for @selectSimulationDuration.
  ///
  /// In ko, this message translates to:
  /// **'시뮬레이션 기간 선택'**
  String get selectSimulationDuration;

  /// No description provided for @confirm.
  ///
  /// In ko, this message translates to:
  /// **'확인'**
  String get confirm;

  /// No description provided for @scenarioSelection.
  ///
  /// In ko, this message translates to:
  /// **'시나리오 선택'**
  String get scenarioSelection;

  /// No description provided for @assetPortfolio.
  ///
  /// In ko, this message translates to:
  /// **'자산 포트폴리오'**
  String get assetPortfolio;

  /// No description provided for @addAsset.
  ///
  /// In ko, this message translates to:
  /// **'자산 추가'**
  String get addAsset;

  /// No description provided for @pleaseAddAssets.
  ///
  /// In ko, this message translates to:
  /// **'자산을 추가해주세요'**
  String get pleaseAddAssets;

  /// No description provided for @totalAllocation.
  ///
  /// In ko, this message translates to:
  /// **'총 비중'**
  String get totalAllocation;

  /// No description provided for @runSimulation.
  ///
  /// In ko, this message translates to:
  /// **'광고 보고 시뮬레이션 실행'**
  String get runSimulation;

  /// No description provided for @loadingAnnualReturn.
  ///
  /// In ko, this message translates to:
  /// **'연수익률 로딩 중...'**
  String get loadingAnnualReturn;

  /// No description provided for @pastAnnualReturn.
  ///
  /// In ko, this message translates to:
  /// **'과거 연평균 수익률 (CAGR)'**
  String get pastAnnualReturn;

  /// No description provided for @allocation.
  ///
  /// In ko, this message translates to:
  /// **'비중'**
  String get allocation;

  /// No description provided for @delete.
  ///
  /// In ko, this message translates to:
  /// **'삭제'**
  String get delete;

  /// No description provided for @calculatingAnnualReturn.
  ///
  /// In ko, this message translates to:
  /// **'연수익률 계산 중...'**
  String get calculatingAnnualReturn;

  /// No description provided for @won.
  ///
  /// In ko, this message translates to:
  /// **'원'**
  String get won;

  /// No description provided for @dollar.
  ///
  /// In ko, this message translates to:
  /// **'달러'**
  String get dollar;

  /// No description provided for @yen.
  ///
  /// In ko, this message translates to:
  /// **'엔'**
  String get yen;

  /// No description provided for @yuan.
  ///
  /// In ko, this message translates to:
  /// **'위안'**
  String get yuan;

  /// No description provided for @duration.
  ///
  /// In ko, this message translates to:
  /// **'기간'**
  String get duration;

  /// No description provided for @settings.
  ///
  /// In ko, this message translates to:
  /// **'설정'**
  String get settings;

  /// No description provided for @currencySettings.
  ///
  /// In ko, this message translates to:
  /// **'통화 설정'**
  String get currencySettings;

  /// No description provided for @currencyKRW.
  ///
  /// In ko, this message translates to:
  /// **'원 (KRW)'**
  String get currencyKRW;

  /// No description provided for @currencyUSD.
  ///
  /// In ko, this message translates to:
  /// **'달러 (USD)'**
  String get currencyUSD;

  /// No description provided for @currencyJPY.
  ///
  /// In ko, this message translates to:
  /// **'엔 (JPY)'**
  String get currencyJPY;

  /// No description provided for @currencyCNY.
  ///
  /// In ko, this message translates to:
  /// **'위안 (CNY)'**
  String get currencyCNY;

  /// No description provided for @currencyDefault.
  ///
  /// In ko, this message translates to:
  /// **'기본값 (언어별 자동)'**
  String get currencyDefault;

  /// No description provided for @currencyKRWDesc.
  ///
  /// In ko, this message translates to:
  /// **'한국 원'**
  String get currencyKRWDesc;

  /// No description provided for @currencyUSDDesc.
  ///
  /// In ko, this message translates to:
  /// **'미국 달러'**
  String get currencyUSDDesc;

  /// No description provided for @currencyJPYDesc.
  ///
  /// In ko, this message translates to:
  /// **'일본 엔'**
  String get currencyJPYDesc;

  /// No description provided for @currencyCNYDesc.
  ///
  /// In ko, this message translates to:
  /// **'중국 위안'**
  String get currencyCNYDesc;

  /// No description provided for @currencyDefaultDesc.
  ///
  /// In ko, this message translates to:
  /// **'언어에 따라 자동으로 설정'**
  String get currencyDefaultDesc;

  /// No description provided for @retirementQuestionPrefix.
  ///
  /// In ko, this message translates to:
  /// **'내 자산'**
  String get retirementQuestionPrefix;

  /// No description provided for @retirementQuestionMiddle.
  ///
  /// In ko, this message translates to:
  /// **'으로'**
  String get retirementQuestionMiddle;

  /// No description provided for @retirementQuestionMonthlyPrefix.
  ///
  /// In ko, this message translates to:
  /// **'매월'**
  String get retirementQuestionMonthlyPrefix;

  /// No description provided for @retirementQuestionSuffix.
  ///
  /// In ko, this message translates to:
  /// **'을 쓰면서'**
  String get retirementQuestionSuffix;

  /// No description provided for @retirementQuestionEnd.
  ///
  /// In ko, this message translates to:
  /// **'동안 놀고 먹을 수 있을까?'**
  String get retirementQuestionEnd;

  /// No description provided for @inflationRate.
  ///
  /// In ko, this message translates to:
  /// **'연간 인플레이션율'**
  String get inflationRate;

  /// No description provided for @inflationRateDesc.
  ///
  /// In ko, this message translates to:
  /// **'매년 생활비가 증가하는 비율을 설정하세요'**
  String get inflationRateDesc;

  /// No description provided for @inflationRatePercent.
  ///
  /// In ko, this message translates to:
  /// **'{rate}%'**
  String inflationRatePercent(double rate);

  /// No description provided for @adWillBeShown.
  ///
  /// In ko, this message translates to:
  /// **'결과 보기 전에 광고가 표시됩니다'**
  String get adWillBeShown;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ja', 'ko', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ja':
      return AppLocalizationsJa();
    case 'ko':
      return AppLocalizationsKo();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
