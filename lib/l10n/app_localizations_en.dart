// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get selectAssetQuestion => 'Which asset would you like to invest in?';

  @override
  String get loadingAssetData => 'Loading asset data...';

  @override
  String get loadAssetError => 'Failed to load asset info';

  @override
  String get retry => 'Retry';

  @override
  String investmentSettingsTitle(Object assetName) {
    return '$assetName Investment Settings';
  }

  @override
  String get investmentAmountLabel => 'Investment Amount';

  @override
  String get investmentTypeLabel => 'Investment Type';

  @override
  String get singleInvestment => 'Lump Sum';

  @override
  String get recurringInvestment => 'Recurring';

  @override
  String get investmentDurationLabel => 'Duration';

  @override
  String get viewResults => 'View Results';

  @override
  String get enterInvestmentAmount => 'Please enter investment amount';

  @override
  String yearsAgo(Object count) {
    return '$count years ago';
  }

  @override
  String investmentSummary(Object amount, Object assetName, Object type) {
    return 'If you invested $amount in $assetName via $type?';
  }

  @override
  String singleInvestmentDate(Object date) {
    return 'Invested once on $date';
  }

  @override
  String recurringInvestmentDate(Object date, Object frequency) {
    return 'Invested $frequency starting $date';
  }

  @override
  String get monthly => 'monthly';

  @override
  String get weekly => 'weekly';

  @override
  String get fetchingPriceData => 'Fetching real price data...';

  @override
  String get errorOccurred => 'An error occurred';

  @override
  String get goBack => 'Go Back';

  @override
  String get investmentResults => 'Investment Results';

  @override
  String get bestReturn => 'Best Return';

  @override
  String get cagr => 'CAGR';

  @override
  String get returnOnInvestment => 'Return on Investment';

  @override
  String totalInvested(Object amount) {
    return 'Total Invested $amount';
  }

  @override
  String get compareInvestmentStrategies => 'Compare Strategies';

  @override
  String get assetGrowthTrend => 'Asset Growth Trend';

  @override
  String get insightMessage =>
      'If you make time your friend,\nthe market is on your side.';

  @override
  String get share => 'Share';

  @override
  String get recalculate => 'Recalculate';

  @override
  String get shareResults => 'Share Results';

  @override
  String get copyText => 'Copy Text';

  @override
  String get copyTextDesc => 'Copy results as text';

  @override
  String get copiedToClipboard => 'Copied to clipboard';

  @override
  String get close => 'Close';

  @override
  String shareTextTitle(Object amount, Object assetName, Object yearsAgo) {
    return 'If you invested $amount in $assetName $yearsAgo years ago, how much would it be now?';
  }

  @override
  String get shareTextFooter =>
      'Long-term Investment Trading Calculation Result';

  @override
  String downloadLink(Object url) {
    return 'Download: $url';
  }

  @override
  String homeQuestionPart1(Object yearsAgo) {
    return 'If $yearsAgo years ago,';
  }

  @override
  String homeQuestionPart2(Object assetName) {
    return 'you invested in $assetName,\nhow much would it be?';
  }

  @override
  String get homeDescription => 'Trust in time, verify the results yourself.';

  @override
  String get retirementQuestionPart1 => 'With my assets,';

  @override
  String get retirementQuestionPart2 => 'how long can I live comfortably?';

  @override
  String get retirementDescription =>
      'Simulate how your assets change after retirement.';

  @override
  String get pastAssetSimulation => 'If I bought it then?';

  @override
  String get retirementSimulation => 'With my money?';

  @override
  String get crypto => 'Cryptocurrency';

  @override
  String get stock => 'US Stock';

  @override
  String get failedToLoadAssetList => 'Failed to load asset list.';

  @override
  String get frequencySelectionHint =>
      'Select both to compare with single investment on the graph.';

  @override
  String get investmentFrequencyLabel =>
      'Frequency (Multiple selection allowed)';

  @override
  String calculationError(Object error) {
    return 'Calculation failed: $error';
  }

  @override
  String investmentStartDate(Object year, Object yearsAgo) {
    return 'Start Date: $yearsAgo years ago ($year)';
  }

  @override
  String get monthlyAndWeekly => 'monthly and weekly';

  @override
  String summarySingle(Object amount, Object assetName, Object yearsAgo) {
    return 'If you invested $amount in $assetName once $yearsAgo years ago...';
  }

  @override
  String summaryRecurringMonthly(
    Object assetName,
    Object investMoney,
    Object yearsAgo,
  ) {
    return 'What if you invested $investMoney monthly in $assetName starting $yearsAgo years ago?';
  }

  @override
  String summaryRecurringWeekly(
    Object assetName,
    Object investMoney,
    Object yearsAgo,
  ) {
    return 'What if you invested $investMoney weekly in $assetName starting $yearsAgo years ago?';
  }

  @override
  String get saveAndShare => 'Save & Share';

  @override
  String get basicShare => 'Share';

  @override
  String get basicShareDesc => 'Share via messenger, email, etc.';

  @override
  String get copyToClipboard => 'Copy result to clipboard';

  @override
  String get shareTextHeader => 'Time Capital Calculation Result';

  @override
  String get finalValue => 'Final Value';

  @override
  String get yieldRateLabel => 'Yield Rate';

  @override
  String get gain => 'Gain';

  @override
  String get totalInvestmentAmount => 'Total Investment Amount';

  @override
  String get kakaoTalk => 'KakaoTalk';

  @override
  String get shareWithKakaoTalk => 'Share with KakaoTalk';

  @override
  String get sharedToKakaoTalk => 'Shared to KakaoTalk!';

  @override
  String get shareWithTextAndChart => 'Share text and chart image together';

  @override
  String get showMore => 'Show More';

  @override
  String get showLess => 'Show Less';

  @override
  String simulationResultPrefix(
    String initialAsset,
    String portfolio,
    int years,
    String monthlyWithdrawal,
    String finalAsset,
  ) {
    return 'If you hold $portfolio worth $initialAsset for $years years and spend $monthlyWithdrawal per month, your final asset after $years years will be $finalAsset.';
  }

  @override
  String get simulationResultTitle => 'Simulation Result';

  @override
  String get detailedStatistics => 'Detailed Statistics';

  @override
  String get simulationResultNoData => 'No simulation results available.';

  @override
  String get selectedScenario => 'Selected Scenario: ';

  @override
  String get scenarioPositive => 'Positive (+20%)';

  @override
  String get scenarioNegative => 'Negative (-20%)';

  @override
  String get scenarioNeutral => 'Neutral (0%)';

  @override
  String get monthlyWithdrawalLabel => 'Monthly Withdrawal: ';

  @override
  String get assetValueTrend => 'Asset Value Trend';

  @override
  String get totalAssets => 'Total Assets';

  @override
  String get cumulativeWithdrawal => 'Cumulative Withdrawal';

  @override
  String get finalAsset => 'Final Asset';

  @override
  String get cumulativeReturn => 'Cumulative Return';

  @override
  String get totalWithdrawn => 'Total Withdrawn';

  @override
  String get netProfit => 'Net Profit';

  @override
  String get monthlyDetails => 'Monthly Details';

  @override
  String yearLabel(int year) {
    return '$year';
  }

  @override
  String monthLabel(int month) {
    return '$month';
  }

  @override
  String get asset => 'Asset';

  @override
  String get withdrawal => 'Withdrawal';

  @override
  String get change => 'Change';

  @override
  String get simulationSettings => 'Simulation Settings';

  @override
  String get initialAssetAmount => 'Initial Asset Amount';

  @override
  String get monthlyWithdrawalAmount => 'Monthly Withdrawal Amount';

  @override
  String get simulationDuration => 'Simulation Duration';

  @override
  String get year => 'year';

  @override
  String get selectSimulationDuration => 'Select Simulation Duration';

  @override
  String get confirm => 'Confirm';

  @override
  String get scenarioSelection => 'Scenario Selection';

  @override
  String get assetPortfolio => 'Asset Portfolio';

  @override
  String get addAsset => 'Add Asset';

  @override
  String get pleaseAddAssets => 'Please add assets';

  @override
  String get totalAllocation => 'Total Allocation';

  @override
  String get runSimulation => 'Run Simulation';

  @override
  String get loadingAnnualReturn => 'Loading annual return...';

  @override
  String get pastAnnualReturn => 'Past Annual Average Return (CAGR)';

  @override
  String get allocation => 'Allocation';

  @override
  String get delete => 'Delete';

  @override
  String get calculatingAnnualReturn => 'Calculating annual return...';

  @override
  String get won => 'Won';

  @override
  String get dollar => 'Dollar';

  @override
  String get yen => 'Yen';

  @override
  String get yuan => 'Yuan';

  @override
  String get duration => 'Duration';

  @override
  String get settings => 'Settings';

  @override
  String get currencySettings => 'Currency Settings';

  @override
  String get currencyKRW => 'Won (KRW)';

  @override
  String get currencyUSD => 'Dollar (USD)';

  @override
  String get currencyJPY => 'Yen (JPY)';

  @override
  String get currencyCNY => 'Yuan (CNY)';

  @override
  String get currencyDefault => 'Default (Auto by Language)';

  @override
  String get currencyKRWDesc => 'Korean Won';

  @override
  String get currencyUSDDesc => 'US Dollar';

  @override
  String get currencyJPYDesc => 'Japanese Yen';

  @override
  String get currencyCNYDesc => 'Chinese Yuan';

  @override
  String get currencyDefaultDesc => 'Automatically set by language';
}
