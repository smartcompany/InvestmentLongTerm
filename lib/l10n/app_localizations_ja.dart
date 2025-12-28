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
  String get viewResults => '広告を見て結果を見る';

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
  String get retirementQuestionPart1 => '私の資産で';

  @override
  String get retirementQuestionPart2 => 'どれくらい遊んで食べられる？';

  @override
  String get retirementDescription => '退職後の資産変化をシミュレーションしてみましょう。';

  @override
  String get pastAssetSimulation => 'あの時買っていたら？';

  @override
  String get retirementSimulation => '退職できる？';

  @override
  String get crypto => '暗号資産';

  @override
  String get stock => '米国株';

  @override
  String get koreanStock => '韓国株';

  @override
  String get cash => '現金';

  @override
  String get commodity => '商品';

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

  @override
  String get shareWithTextAndChart => 'テキストとチャート画像を一緒に共有';

  @override
  String get showMore => 'もっと見る';

  @override
  String get showLess => '折りたたむ';

  @override
  String simulationResultPrefix(
    String initialAsset,
    String portfolio,
    int years,
    String monthlyWithdrawal,
    String finalAsset,
  ) {
    return '$initialAsset の $portfolio を $years 年間保有し、毎月 $monthlyWithdrawal ずつ使うとすると、$years 年後の最終資産は $finalAsset になります。';
  }

  @override
  String simulationResultPrefixWithInflation(
    String initialAsset,
    String portfolio,
    int years,
    String monthlyWithdrawal,
    String finalAsset,
  ) {
    return '$initialAsset の $portfolio を $years 年間保有し、現在の価値基準で月 $monthlyWithdrawal に相当する金額を使うとすると、$years 年後の最終資産は $finalAsset になります。';
  }

  @override
  String get simulationResultTitle => 'シミュレーション結果';

  @override
  String get detailedStatistics => '詳細統計';

  @override
  String get simulationResultNoData => 'シミュレーション結果がありません。';

  @override
  String get selectedScenario => '選択したシナリオ: ';

  @override
  String get scenarioPositive => 'ポジティブ (+20%)';

  @override
  String get scenarioNegative => 'ネガティブ (-20%)';

  @override
  String get scenarioNeutral => 'ニュートラル (0%)';

  @override
  String get monthlyWithdrawalLabel => '月間引出額: ';

  @override
  String get monthlyWithdrawalWithInflation => '月間引出額: ';

  @override
  String inflationRateApplied(double rate) {
    return 'インフレ率 $rate% 適用';
  }

  @override
  String get assetValueTrend => '資産価値の推移';

  @override
  String get totalAssets => '総資産';

  @override
  String get cumulativeWithdrawal => '累積引出額';

  @override
  String get finalAsset => '最終資産';

  @override
  String get cumulativeReturn => '累積収益率';

  @override
  String get totalWithdrawn => '総引出額';

  @override
  String get netProfit => '純利益';

  @override
  String get monthlyDetails => '月別詳細';

  @override
  String yearLabel(int year) {
    return '$year年';
  }

  @override
  String monthLabel(int month) {
    return '$month月';
  }

  @override
  String get asset => '資産';

  @override
  String get withdrawal => '引出';

  @override
  String get change => '変動';

  @override
  String get simulationSettings => 'シミュレーション設定';

  @override
  String get initialAssetAmount => '初期資産額';

  @override
  String get monthlyWithdrawalAmount => '月間引出額';

  @override
  String get simulationDuration => 'シミュレーション期間';

  @override
  String get year => '年';

  @override
  String get selectSimulationDuration => 'シミュレーション期間を選択';

  @override
  String get confirm => '確認';

  @override
  String get scenarioSelection => 'シナリオ選択';

  @override
  String get assetPortfolio => '資産ポートフォリオ';

  @override
  String get addAsset => '資産を追加';

  @override
  String get pleaseAddAssets => '資産を追加してください';

  @override
  String get totalAllocation => '総配分';

  @override
  String get runSimulation => '広告を見てシミュレーション実行';

  @override
  String get loadingAnnualReturn => '年間収益率を読み込み中...';

  @override
  String get pastAnnualReturn => '過去年平均収益率 (CAGR)';

  @override
  String get allocation => '配分';

  @override
  String get delete => '削除';

  @override
  String get calculatingAnnualReturn => '年間収益率を計算中...';

  @override
  String get won => 'ウォン';

  @override
  String get dollar => 'ドル';

  @override
  String get yen => '円';

  @override
  String get yuan => '元';

  @override
  String get duration => '期間';

  @override
  String get settings => '設定';

  @override
  String get currencySettings => '通貨設定';

  @override
  String get currencyKRW => 'ウォン (KRW)';

  @override
  String get currencyUSD => 'ドル (USD)';

  @override
  String get currencyJPY => '円 (JPY)';

  @override
  String get currencyCNY => '元 (CNY)';

  @override
  String get currencyDefault => 'デフォルト (言語別自動)';

  @override
  String get currencyKRWDesc => '韓国ウォン';

  @override
  String get currencyUSDDesc => '米ドル';

  @override
  String get currencyJPYDesc => '日本円';

  @override
  String get currencyCNYDesc => '中国元';

  @override
  String get currencyDefaultDesc => '言語に応じて自動設定';

  @override
  String get retirementQuestionPrefix => '私の資産';

  @override
  String get retirementQuestionMiddle => 'で';

  @override
  String get retirementQuestionMonthlyPrefix => '毎月';

  @override
  String get retirementQuestionSuffix => 'を使いながら';

  @override
  String get retirementQuestionEnd => '間遊んで食べられる？';

  @override
  String get inflationRate => '연간 인플레이션율';

  @override
  String get inflationRateDesc => '매년 생활비가 증가하는 비율을 설정하세요';

  @override
  String inflationRatePercent(double rate) {
    return '$rate%';
  }

  @override
  String get adWillBeShown => '結果を見る前に広告が表示されます';
}
