// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get selectAssetQuestion => 'どの資産に投資しますか？';

  @override
  String get loadingAssetData => '資産データを読み込み中...';

  @override
  String get loadAssetError => '資産情報の読み込みに失敗しました';

  @override
  String get retry => '再試行';

  @override
  String investmentSettingsTitle(Object assetName) {
    return '$assetName 投資設定';
  }

  @override
  String get investmentAmountLabel => '投資額';

  @override
  String get investmentTypeLabel => '投資方法';

  @override
  String get singleInvestment => '一括投資';

  @override
  String get recurringInvestment => '積立投資';

  @override
  String get investmentDurationLabel => '投資期間';

  @override
  String get viewResults => '結果を見る';

  @override
  String get enterInvestmentAmount => '投資額を入力してください';

  @override
  String yearsAgo(Object count) {
    return '$count年前';
  }

  @override
  String investmentSummary(Object amount, Object assetName, Object type) {
    return '$assetNameに$amountを$typeで投資したら？';
  }

  @override
  String singleInvestmentDate(Object date) {
    return '$dateに一括投資';
  }

  @override
  String recurringInvestmentDate(Object date, Object frequency) {
    return '$dateから$frequency投資';
  }

  @override
  String get monthly => '毎月';

  @override
  String get weekly => '毎週';

  @override
  String get fetchingPriceData => '価格データを取得中...';

  @override
  String get errorOccurred => 'エラーが発生しました';

  @override
  String get goBack => '戻る';

  @override
  String get investmentResults => '投資結果';

  @override
  String get bestReturn => '最高収益';

  @override
  String get cagr => '年平均成長率 (CAGR)';

  @override
  String get returnOnInvestment => '投資収益';

  @override
  String totalInvested(Object amount) {
    return '総投資額 $amount';
  }

  @override
  String get compareInvestmentStrategies => '投資戦略の比較';

  @override
  String get assetGrowthTrend => '資産成長推移';

  @override
  String get insightMessage => '時間を味方につければ、\n市場はあなたの味方です。';

  @override
  String get share => '共有';

  @override
  String get recalculate => '再計算';

  @override
  String get shareResults => '結果を共有';

  @override
  String get copyText => 'テキストをコピー';

  @override
  String get copyTextDesc => '結果をテキストとしてコピー';

  @override
  String get copiedToClipboard => 'クリップボードにコピーしました';

  @override
  String get close => '閉じる';

  @override
  String shareTextTitle(Object amount, Object assetName, Object yearsAgo) {
    return 'もし$yearsAgo年前に$assetNameに$amountを投資していたら、今はいくら？';
  }

  @override
  String get shareTextFooter => '長期投資取引計算結果';

  @override
  String downloadLink(Object url) {
    return 'ダウンロード: $url';
  }

  @override
  String homeQuestionPart1(Object yearsAgo) {
    return 'もし $yearsAgo 年前に';
  }

  @override
  String homeQuestionPart2(Object assetName) {
    return '$assetName を買っていたら、\n今はいくら？';
  }

  @override
  String get homeDescription => '時間を信じる投資、その結果を自分で確認してみよう。';

  @override
  String get crypto => '暗号資産';

  @override
  String get stock => '米国株';

  @override
  String get failedToLoadAssetList => '資産リストの読み込みに失敗しました。';

  @override
  String get frequencySelectionHint => '両方選択すると、一括投資と比較してグラフで見ることができます。';

  @override
  String get investmentFrequencyLabel => '投資サイクル（複数選択可）';

  @override
  String calculationError(Object error) {
    return '計算失敗: $error';
  }

  @override
  String investmentStartDate(Object year, Object yearsAgo) {
    return '投資開始時点: $yearsAgo年前 ($year年)';
  }

  @override
  String get monthlyAndWeekly => '毎月と毎週';

  @override
  String summarySingle(Object amount, Object assetName, Object yearsAgo) {
    return '$yearsAgo年前から$assetNameに$amountを一括投資していたら...';
  }

  @override
  String summaryRecurringMonthly(
    Object assetName,
    Object investMoney,
    Object yearsAgo,
  ) {
    return '$yearsAgo年前から$assetNameに毎月$investMoneyを投資していたらどうなる？';
  }

  @override
  String summaryRecurringWeekly(
    Object assetName,
    Object investMoney,
    Object yearsAgo,
  ) {
    return '$yearsAgo年前から$assetNameに毎週$investMoneyを投資していたらどうなる？';
  }

  @override
  String get saveAndShare => '保存 & 共有';

  @override
  String get basicShare => '共有';

  @override
  String get basicShareDesc => 'メッセンジャーやメールで共有';

  @override
  String get copyToClipboard => '結果をクリップボードにコピー';

  @override
  String get shareTextHeader => 'Time Capital 計算結果';

  @override
  String get finalValue => '最終価値';

  @override
  String get yieldRateLabel => '収益率';

  @override
  String get gain => '収益';

  @override
  String get totalInvestmentAmount => '総投資額';

  @override
  String get kakaoTalk => 'KakaoTalk';

  @override
  String get shareWithKakaoTalk => 'KakaoTalkで共有';

  @override
  String get sharedToKakaoTalk => 'KakaoTalkで共有されました！';
}
