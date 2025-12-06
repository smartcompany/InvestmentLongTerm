// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get selectAssetQuestion => '어떤 자산에 투자 하시겠습니까?';

  @override
  String get loadingAssetData => '자산 데이터 불러오는 중...';

  @override
  String get loadAssetError => '자산 정보 로드 실패';

  @override
  String get retry => '다시 시도';

  @override
  String investmentSettingsTitle(Object assetName) {
    return '$assetName 투자 설정';
  }

  @override
  String get investmentAmountLabel => '투자 금액';

  @override
  String get investmentTypeLabel => '투자 방식';

  @override
  String get singleInvestment => '단일 투자';

  @override
  String get recurringInvestment => '정기 투자';

  @override
  String get investmentDurationLabel => '투자 기간';

  @override
  String get viewResults => '결과 보기';

  @override
  String get enterInvestmentAmount => '투자 금액을 입력해주세요';

  @override
  String yearsAgo(Object count) {
    return '$count년 전';
  }

  @override
  String investmentSummary(Object amount, Object assetName, Object type) {
    return '$assetName에 $amount를 $type로 투자했다면?';
  }

  @override
  String singleInvestmentDate(Object date) {
    return '$date에 한번에 투자';
  }

  @override
  String recurringInvestmentDate(Object date, Object frequency) {
    return '$date부터 $frequency 투자';
  }

  @override
  String get monthly => '매월';

  @override
  String get weekly => '매주';

  @override
  String get fetchingPriceData => '실제 가격 데이터를 가져오는 중...';

  @override
  String get errorOccurred => '오류가 발생했습니다';

  @override
  String get goBack => '돌아가기';

  @override
  String get investmentResults => '투자 결과';

  @override
  String get bestReturn => '최고 수익';

  @override
  String get cagr => '연평균 수익률 (CAGR)';

  @override
  String get returnOnInvestment => '투자 대비 수익';

  @override
  String totalInvested(Object amount) {
    return '총 투자금 $amount';
  }

  @override
  String get compareInvestmentStrategies => '투자 방식 비교';

  @override
  String get assetGrowthTrend => '자산 성장 추이';

  @override
  String get insightMessage => '시간을 친구로 만든다면,\n시장은 당신의 편입니다.';

  @override
  String get share => '공유하기';

  @override
  String get recalculate => '다시 계산';

  @override
  String get shareResults => '결과 공유하기';

  @override
  String get copyText => '텍스트 복사';

  @override
  String get copyTextDesc => '텍스트로 결과 복사하기';

  @override
  String get copiedToClipboard => '복사되었습니다';

  @override
  String get close => '닫기';

  @override
  String shareTextTitle(Object amount, Object assetName, Object yearsAgo) {
    return '만약 $yearsAgo년 전에 $assetName에 $amount를 투자했다면 지금 얼마일까?';
  }

  @override
  String get shareTextFooter => '장기 투자 매매 계산 결과';

  @override
  String downloadLink(Object url) {
    return '다운로드: $url';
  }

  @override
  String homeQuestionPart1(Object yearsAgo) {
    return '만약 $yearsAgo년 전에';
  }

  @override
  String homeQuestionPart2(Object assetName) {
    return '$assetName을 샀다면\n지금 얼마일까?';
  }

  @override
  String get homeDescription => '시간을 믿는 투자, 그 결과를 직접 확인해보세요.';

  @override
  String get retirementQuestionPart1 => '내 자산으로';

  @override
  String get retirementQuestionPart2 => '얼마나 놀고 먹을 수 있을까?';

  @override
  String get retirementDescription => '은퇴 후 자산 변화를 시뮬레이션해보세요.';

  @override
  String get pastAssetSimulation => '그때 샀다면?';

  @override
  String get retirementSimulation => '내 돈으로?';

  @override
  String get crypto => '암호화폐';

  @override
  String get stock => '미국 주식';

  @override
  String get failedToLoadAssetList => '자산 목록을 불러오지 못했습니다.';

  @override
  String get frequencySelectionHint => '둘 다 선택하면 단일 투자와 함께 그래프로 비교해볼 수 있어요.';

  @override
  String get investmentFrequencyLabel => '투자 주기 (중복 선택 가능)';

  @override
  String calculationError(Object error) {
    return '계산 실패: $error';
  }

  @override
  String investmentStartDate(Object year, Object yearsAgo) {
    return '투자 시작 시점: $yearsAgo년 전 ($year)';
  }

  @override
  String get monthlyAndWeekly => '매월과 매주';

  @override
  String summarySingle(Object amount, Object assetName, Object yearsAgo) {
    return '$yearsAgo년 전부터 $assetName에 $amount를 한 번 투자했다면...';
  }

  @override
  String summaryRecurringMonthly(
    Object assetName,
    Object investMoney,
    Object yearsAgo,
  ) {
    return '$yearsAgo년 전부터 $assetName에 매월 $investMoney를 투자하면 어떻게 될까요?';
  }

  @override
  String summaryRecurringWeekly(
    Object assetName,
    Object investMoney,
    Object yearsAgo,
  ) {
    return '$yearsAgo년 전부터 $assetName에 매주 $investMoney를 투자하면 어떻게 될까요?';
  }

  @override
  String get saveAndShare => '저장 & 공유하기';

  @override
  String get basicShare => '기본 공유';

  @override
  String get basicShareDesc => '메신저, 메일 등으로 공유';

  @override
  String get copyToClipboard => '클립보드에 결과 복사';

  @override
  String get shareTextHeader => 'Time Capital 계산 결과';

  @override
  String get finalValue => '최종 가치';

  @override
  String get yieldRateLabel => '수익률';

  @override
  String get gain => '수익';

  @override
  String get totalInvestmentAmount => '총 투자금액';

  @override
  String get kakaoTalk => '카카오톡';

  @override
  String get shareWithKakaoTalk => '카카오톡으로 공유';

  @override
  String get sharedToKakaoTalk => '카카오톡으로 공유되었습니다!';

  @override
  String get shareWithTextAndChart => '텍스트와 차트 이미지 함께 공유';

  @override
  String get showMore => '더보기';

  @override
  String get showLess => '접기';

  @override
  String simulationResultPrefix(
    String initialAsset,
    String portfolio,
    int years,
    String monthlyWithdrawal,
    String finalAsset,
  ) {
    return '$initialAsset 의 $portfolio를 $years년간 보유하고 한달에 $monthlyWithdrawal씩 쓴다고 하면 $years년 후 최종 자산은 $finalAsset이 됩니다.';
  }

  @override
  String get simulationResultTitle => '시뮬레이션 결과';

  @override
  String get detailedStatistics => '상세 통계';

  @override
  String get simulationResultNoData => '시뮬레이션 결과가 없습니다.';

  @override
  String get selectedScenario => '선택한 시나리오: ';

  @override
  String get scenarioPositive => '긍정적 (+20%)';

  @override
  String get scenarioNegative => '부정적 (-20%)';

  @override
  String get scenarioNeutral => '중립적 (0%)';

  @override
  String get monthlyWithdrawalLabel => '월 인출액: ';

  @override
  String get assetValueTrend => '자산 가치 추이';

  @override
  String get totalAssets => '전체 자산';

  @override
  String get cumulativeWithdrawal => '누적 인출액';

  @override
  String get finalAsset => '최종 자산';

  @override
  String get cumulativeReturn => '누적 수익률';

  @override
  String get totalWithdrawn => '총 인출 금액';

  @override
  String get netProfit => '순 수익';

  @override
  String get monthlyDetails => '월별 상세 내역';

  @override
  String yearLabel(int year) {
    return '$year년';
  }

  @override
  String monthLabel(int month) {
    return '$month월';
  }

  @override
  String get asset => '자산';

  @override
  String get withdrawal => '인출';

  @override
  String get change => '변동';

  @override
  String get simulationSettings => '시뮬레이션 설정';

  @override
  String get initialAssetAmount => '초기 자산 금액';

  @override
  String get monthlyWithdrawalAmount => '월 인출 금액';

  @override
  String get simulationDuration => '시뮬레이션 기간';

  @override
  String get year => '년';

  @override
  String get selectSimulationDuration => '시뮬레이션 기간 선택';

  @override
  String get confirm => '확인';

  @override
  String get scenarioSelection => '시나리오 선택';

  @override
  String get assetPortfolio => '자산 포트폴리오';

  @override
  String get addAsset => '자산 추가';

  @override
  String get pleaseAddAssets => '자산을 추가해주세요';

  @override
  String get totalAllocation => '총 비중';

  @override
  String get runSimulation => '시뮬레이션 실행';

  @override
  String get loadingAnnualReturn => '연수익률 로딩 중...';

  @override
  String get pastAnnualReturn => '과거 연평균 수익률 (CAGR)';

  @override
  String get allocation => '비중';

  @override
  String get delete => '삭제';

  @override
  String get calculatingAnnualReturn => '연수익률 계산 중...';

  @override
  String get won => '원';

  @override
  String get dollar => '달러';

  @override
  String get yen => '엔';

  @override
  String get yuan => '위안';

  @override
  String get duration => '기간';

  @override
  String get settings => '설정';

  @override
  String get currencySettings => '통화 설정';

  @override
  String get currencyKRW => '원 (KRW)';

  @override
  String get currencyUSD => '달러 (USD)';

  @override
  String get currencyJPY => '엔 (JPY)';

  @override
  String get currencyCNY => '위안 (CNY)';

  @override
  String get currencyDefault => '기본값 (언어별 자동)';

  @override
  String get currencyKRWDesc => '한국 원';

  @override
  String get currencyUSDDesc => '미국 달러';

  @override
  String get currencyJPYDesc => '일본 엔';

  @override
  String get currencyCNYDesc => '중국 위안';

  @override
  String get currencyDefaultDesc => '언어에 따라 자동으로 설정';

  @override
  String get retirementQuestionPrefix => '내 자산';

  @override
  String get retirementQuestionMiddle => '으로';

  @override
  String get retirementQuestionMonthlyPrefix => '매월';

  @override
  String get retirementQuestionSuffix => '을 쓰면서';

  @override
  String get retirementQuestionEnd => '동안 놀고 먹을 수 있을까?';
}
