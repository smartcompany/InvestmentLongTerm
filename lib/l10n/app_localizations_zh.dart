// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get selectAssetQuestion => '您想投资哪种资产？';

  @override
  String get loadingAssetData => '正在加载资产数据...';

  @override
  String get loadAssetError => '加载资产信息失败';

  @override
  String get retry => '重试';

  @override
  String investmentSettingsTitle(Object assetName) {
    return '$assetName 投资设置';
  }

  @override
  String get investmentAmountLabel => '投资金额';

  @override
  String get investmentTypeLabel => '投资方式';

  @override
  String get singleInvestment => '单次投资';

  @override
  String get recurringInvestment => '定投';

  @override
  String get investmentDurationLabel => '投资期限';

  @override
  String get viewResults => '查看结果';

  @override
  String get enterInvestmentAmount => '请输入投资金额';

  @override
  String yearsAgo(Object count) {
    return '$count年前';
  }

  @override
  String investmentSummary(Object amount, Object assetName, Object type) {
    return '如果您以$type方式在$assetName投资$amount？';
  }

  @override
  String singleInvestmentDate(Object date) {
    return '$date 一次性投资';
  }

  @override
  String recurringInvestmentDate(Object date, Object frequency) {
    return '从 $date 开始$frequency投资';
  }

  @override
  String get monthly => '每月';

  @override
  String get weekly => '每周';

  @override
  String get fetchingPriceData => '正在获取实时价格数据...';

  @override
  String get errorOccurred => '发生错误';

  @override
  String get goBack => '返回';

  @override
  String get investmentResults => '投资结果';

  @override
  String get bestReturn => '最高收益';

  @override
  String get cagr => '年均复合增长率 (CAGR)';

  @override
  String get returnOnInvestment => '投资回报';

  @override
  String totalInvested(Object amount) {
    return '总投资额 $amount';
  }

  @override
  String get compareInvestmentStrategies => '比较投资策略';

  @override
  String get assetGrowthTrend => '资产增长趋势';

  @override
  String get insightMessage => '如果时间是你的朋友，\n市场就是你的盟友。';

  @override
  String get share => '分享';

  @override
  String get recalculate => '重新计算';

  @override
  String get shareResults => '分享结果';

  @override
  String get copyText => '复制文本';

  @override
  String get copyTextDesc => '以文本形式复制结果';

  @override
  String get copiedToClipboard => '已复制到剪贴板';

  @override
  String get close => '关闭';

  @override
  String shareTextTitle(Object assetName, Object yearsAgo) {
    return '如果您在$yearsAgo年前投资$assetName，现在会有多少钱？';
  }

  @override
  String get shareTextFooter => 'InvestLongTerm 计算结果';

  @override
  String homeQuestionPart1(Object yearsAgo) {
    return '如果 $yearsAgo 年前';
  }

  @override
  String homeQuestionPart2(Object assetName) {
    return '投资了 $assetName，\n现在值多少钱？';
  }

  @override
  String get homeDescription => '相信时间的投资，亲自验证结果。';

  @override
  String get crypto => '加密货币';

  @override
  String get stock => '美股';

  @override
  String get failedToLoadAssetList => '加载资产列表失败。';

  @override
  String get frequencySelectionHint => '若同时选择，可在图表中与单次投资进行比较。';

  @override
  String get investmentFrequencyLabel => '投资周期（可多选）';

  @override
  String calculationError(Object error) {
    return '计算失败：$error';
  }

  @override
  String investmentStartDate(Object year, Object yearsAgo) {
    return '投资开始时间：$yearsAgo年前 ($year年)';
  }

  @override
  String get monthlyAndWeekly => '每月和每周';

  @override
  String summarySingle(Object amount, Object assetName, Object yearsAgo) {
    return '如果$yearsAgo年前一次性投资$amount于$assetName...';
  }

  @override
  String summaryRecurringMonthly(
    Object assetName,
    Object investMoney,
    Object yearsAgo,
  ) {
    return '如果$yearsAgo年前开始，每月在$assetName定投$investMoney会怎样？';
  }

  @override
  String summaryRecurringWeekly(
    Object assetName,
    Object investMoney,
    Object yearsAgo,
  ) {
    return '如果$yearsAgo年前开始，每周在$assetName定投$investMoney会怎样？';
  }

  @override
  String get saveAndShare => '保存并分享';

  @override
  String get basicShare => '分享';

  @override
  String get basicShareDesc => '通过通讯软件、邮件等分享';

  @override
  String get copyToClipboard => '复制结果到剪贴板';
}
