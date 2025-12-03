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
}
